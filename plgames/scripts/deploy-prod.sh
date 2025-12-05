#!/usr/bin/env bash
set -euo pipefail

if [[ "$(id -u)" -ne 0 ]]; then
  echo "This script must be run as root."
  exit 1
fi

DOMAIN="${PLG_DOMAIN:-}"
ADMIN_EMAIL="${PLG_ADMIN_EMAIL:-}"
REPO_URL="${PLG_REPO_URL:-https://github.com/PLGamesHQ/plgames.git}"
BRANCH="${PLG_BRANCH:-main}"
INSTALL_DIR="${PLG_INSTALL_DIR:-/opt/plgames}"
# By default use the invoking user (SUDO_USER if running via sudo) to avoid permission mismatches
SERVICE_USER="${PLG_SERVICE_USER:-${SUDO_USER:-$(id -un)}}"
PUBLIC_DIR="${PLG_PUBLIC_DIR:-/var/www/plgames}"
SERVER_PORT="${PLG_SERVER_PORT:-3010}"
DB_USER="${PLG_DB_USER:-plgames}"
DB_NAME="${PLG_DB_NAME:-plgames}"
DB_PASSWORD="${PLG_DB_PASSWORD:-}"
LOCAL_HOST="${PLG_LOCAL_HOST:-localhost}"
BASE_URL=""
YARN_ENV="YARN_ENABLE_IMMUTABLE_INSTALLS=false"

if [[ -z "${DB_PASSWORD}" ]]; then
  DB_PASSWORD="$(openssl rand -hex 16)"
fi

git_silence_prompts() {
  export GIT_TERMINAL_PROMPT=0
  export GIT_SSH_COMMAND="${GIT_SSH_COMMAND:-ssh -oBatchMode=yes}"
}

trust_repo_path() {
  sudo -u "${SERVICE_USER}" git config --global --add safe.directory "${INSTALL_DIR}" || true
  sudo git config --system --add safe.directory "${INSTALL_DIR}" || true
}

stop_conflicting_services() {
  if systemctl is-active --quiet nginx; then
    log "Stopping nginx to free ports 80/443 for Caddy"
    systemctl stop nginx || true
    systemctl disable nginx || true
  fi
}

prompt_domain() {
  if [[ -z "${DOMAIN}" ]]; then
    read -r -p "Enter domain for PLGames (leave blank for local host/IP): " DOMAIN
  fi

  if [[ -z "${DOMAIN}" ]]; then
    DOMAIN="${LOCAL_HOST}"
    BASE_URL="http://${DOMAIN}"
  else
    BASE_URL="https://${DOMAIN}"
  fi

  if [[ -z "${ADMIN_EMAIL}" ]]; then
    ADMIN_EMAIL="admin@${DOMAIN}"
  fi
}

DATABASE_URL="postgresql://${DB_USER}:${DB_PASSWORD}@127.0.0.1:5432/${DB_NAME}"

log() {
  printf '\n[%s] %s\n' "$(date +'%Y-%m-%d %H:%M:%S')" "$*"
}

ensure_user() {
  if ! id -u "${SERVICE_USER}" >/dev/null 2>&1; then
    log "Creating service user ${SERVICE_USER}"
    useradd --system --create-home --home-dir "${INSTALL_DIR}" --shell /bin/bash "${SERVICE_USER}"
  fi

  usermod -aG docker "${SERVICE_USER}" || true
}

install_dependencies() {
  log "Installing system dependencies"
  apt-get update
  apt-get install -y \
    build-essential \
    ca-certificates \
    gnupg \
    curl \
    git \
    pkg-config \
    python3 \
    python3-pip \
    libssl-dev \
    openssl \
    unzip \
    docker.io \
    docker-compose-plugin \
    debian-keyring \
    debian-archive-keyring \
    apt-transport-https

  systemctl enable --now docker
}

install_caddy() {
  if ! command -v caddy >/dev/null 2>&1; then
    log "Installing Caddy web server"
    curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
    curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | tee /etc/apt/sources.list.d/caddy-stable.list
    apt-get update
    apt-get install -y caddy
  fi
}

install_node_corepack() {
  if ! command -v node >/dev/null 2>&1 || [[ "$(node -v)" != v22* ]]; then
    log "Installing Node.js 22.x"
    curl -fsSL https://deb.nodesource.com/setup_22.x | bash -
    apt-get install -y nodejs
  fi

  log "Enabling Corepack"
  corepack enable
  corepack prepare yarn@4.9.1 --activate
}

install_rust() {
  if sudo -u "${SERVICE_USER}" bash -lc 'command -v cargo >/dev/null 2>&1'; then
    return
  fi
  log "Installing Rust toolchain"
  sudo -u "${SERVICE_USER}" bash -lc 'curl --proto "=https" --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y'
}

clone_repository() {
  git_silence_prompts

  if [[ ! -d "${INSTALL_DIR}" ]]; then
    mkdir -p "${INSTALL_DIR}"
    chown "${SERVICE_USER}:${SERVICE_USER}" "${INSTALL_DIR}"
  fi

  if [[ ! -d "${INSTALL_DIR}/.git" ]]; then
    log "Cloning repository into ${INSTALL_DIR}"
    sudo -u "${SERVICE_USER}" git clone --branch "${BRANCH}" "${REPO_URL}" "${INSTALL_DIR}"
    trust_repo_path
  else
    log "Repository exists, fetching latest changes"
    trust_repo_path
    if ! sudo -u "${SERVICE_USER}" bash -lc "cd '${INSTALL_DIR}' && git fetch --all && git checkout '${BRANCH}' && git pull --ff-only"; then
      log "Fetch failed (likely missing credentials). Continuing with existing code."
    fi
  fi
}

prepare_env_files() {
  log "Preparing environment files"
  sudo -u "${SERVICE_USER}" cp -n "${INSTALL_DIR}/.docker/dev/compose.yml.example" "${INSTALL_DIR}/.docker/dev/compose.yml" || true
  sudo -u "${SERVICE_USER}" cp -n "${INSTALL_DIR}/.docker/dev/.env.example" "${INSTALL_DIR}/.docker/dev/.env" || true
  sudo -u "${SERVICE_USER}" cp -n "${INSTALL_DIR}/packages/backend/server/.env.example" "${INSTALL_DIR}/packages/backend/server/.env" || true

  cat > "${INSTALL_DIR}/.docker/dev/.env" <<EOF
DB_VERSION=16
DB_USERNAME=${DB_USER}
DB_PASSWORD=${DB_PASSWORD}
DB_DATABASE_NAME=${DB_NAME}
MANTICORE_VERSION=10.1.0
EOF

  cat > "${INSTALL_DIR}/packages/backend/server/.env" <<EOF
DATABASE_URL="${DATABASE_URL}"
REDIS_SERVER_HOST=127.0.0.1
AFFINE_SERVER_EXTERNAL_URL="${BASE_URL}"
AFFINE_SERVER_HOST="${DOMAIN}"
AFFINE_SERVER_PORT=${SERVER_PORT}
PLG_BASE_URL="${BASE_URL}"
EOF

  chown "${SERVICE_USER}:${SERVICE_USER}" "${INSTALL_DIR}/.docker/dev/.env" "${INSTALL_DIR}/packages/backend/server/.env"
}

build_project() {
  log "Installing node dependencies and building workspace"
  sudo -u "${SERVICE_USER}" bash -lc "
    cd '${INSTALL_DIR}' && \
    env ${YARN_ENV} corepack yarn install --mode skip-build && \
    corepack yarn plgames init && \
    corepack yarn plgames @affine/native build && \
    corepack yarn plgames @affine/server-native build && \
    corepack yarn plgames @affine/reader build
  "
}

start_data_services() {
  log "Starting Postgres/Redis stack via Docker Compose"
  bash -lc "cd '${INSTALL_DIR}' && docker compose -f ./.docker/dev/compose.yml up -d"
}

run_migrations() {
  log "Running database migrations and data init"
  sudo -u "${SERVICE_USER}" bash -lc "cd '${INSTALL_DIR}' && DATABASE_URL='${DATABASE_URL}' corepack yarn plgames server init"
}

build_artifacts() {
  log "Building backend and frontend artifacts"
  sudo -u "${SERVICE_USER}" bash -lc "
    cd '${INSTALL_DIR}' && \
    corepack yarn plgames @affine/server build && \
    PUBLIC_PATH=/ corepack yarn plgames @affine/web build
  "
}

stage_frontend() {
  log "Staging frontend dist to ${PUBLIC_DIR}"
  rm -rf "${PUBLIC_DIR}"
  mkdir -p "${PUBLIC_DIR}"
  cp -r "${INSTALL_DIR}/packages/frontend/apps/web/dist/"* "${PUBLIC_DIR}/"
  chown -R caddy:caddy "${PUBLIC_DIR}"
}

configure_caddy() {
  log "Configuring Caddy for ${DOMAIN}"
  cat > /etc/caddy/Caddyfile <<EOF
{
    email ${ADMIN_EMAIL}
}

${DOMAIN} {
    encode gzip zstd

    @api path /api/* /graphql* /telemetry/* /socket.io/* /worker/* /health* /metrics* /auth/* /storage/* /workspace/*
    reverse_proxy @api http://127.0.0.1:${SERVER_PORT}

    handle {
        root * ${PUBLIC_DIR}
        try_files {path} /index.html
        file_server
    }
}
EOF

  systemctl reload caddy || systemctl restart caddy
}

configure_systemd() {
  log "Creating systemd service for PLGames backend"
  cat > /etc/systemd/system/plgames-server.service <<EOF
[Unit]
Description=PLGames API Server
After=network.target docker.service
Requires=docker.service

[Service]
User=${SERVICE_USER}
Group=${SERVICE_USER}
WorkingDirectory=${INSTALL_DIR}
Environment=NODE_ENV=production
Environment=AFFINE_SERVER_EXTERNAL_URL=${BASE_URL}
Environment=AFFINE_SERVER_HOST=${DOMAIN}
Environment=AFFINE_SERVER_PORT=${SERVER_PORT}
Environment=DATABASE_URL=${DATABASE_URL}
Environment=REDIS_SERVER_HOST=127.0.0.1
ExecStart=/usr/bin/node packages/backend/server/dist/main.js
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF

  systemctl daemon-reload
  systemctl enable --now plgames-server
}

print_summary() {
  cat <<EOF

Deployment completed.

- Frontend assets served from ${PUBLIC_DIR} via Caddy (${BASE_URL})
- Backend Node service managed by systemd unit: plgames-server
- Database credentials:
    user: ${DB_USER}
    password: ${DB_PASSWORD}
    name: ${DB_NAME}
- To view service logs: journalctl -u plgames-server -f
- To update the app later:
    sudo bash ${INSTALL_DIR}/scripts/deploy-prod.sh   # rerun after pulling latest code

EOF
}

main() {
  install_dependencies
  install_caddy
  stop_conflicting_services
  ensure_user
  prompt_domain
  install_node_corepack
  install_rust
  clone_repository
  prepare_env_files
  build_project
  start_data_services
  run_migrations
  build_artifacts
  stage_frontend
  configure_caddy
  configure_systemd
  print_summary
}

main "$@"
