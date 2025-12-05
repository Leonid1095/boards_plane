#!/usr/bin/env bash
set -euo pipefail

REPO_URL="${PLGAMES_REPO_URL:-https://github.com/PLGamesHQ/plgames.git}"
INSTALL_DIR="${PLGAMES_DIR:-/opt/plgames}"
BRANCH="${PLGAMES_BRANCH:-main}"
NODE_VERSION="${PLGAMES_NODE_VERSION:-22}"
YARN_VERSION="${PLGAMES_YARN_VERSION:-4.9.1}"
YARN_ENV="YARN_ENABLE_IMMUTABLE_INSTALLS=false"
DB_USER="${PLG_DB_USER:-plgames}"
DB_PASSWORD="${PLG_DB_PASSWORD:-plgames}"
DB_NAME="${PLG_DB_NAME:-plgames}"
SUPPORT_EMAIL="${PLG_SUPPORT_EMAIL:-}"
SERVER_PORT=3010

log() {
  printf '\n[%s] %s\n' "$(date +'%Y-%m-%d %H:%M:%S')" "$*"
}

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    log "Missing required command: $1"
    exit 1
  fi
}

assert_ubuntu_24() {
  if [[ ! -f /etc/os-release ]]; then
    log "Unable to detect OS from /etc/os-release"
    exit 1
  fi
  . /etc/os-release
  if [[ "${ID}" != "ubuntu" ]] || [[ "${VERSION_ID%%.*}" -lt 24 ]]; then
    log "This installer targets Ubuntu 24.x. Detected ${PRETTY_NAME}."
    exit 1
  fi
}

install_apt_dependencies() {
  log "Installing apt dependencies"
  sudo apt-get update
  sudo apt-get install -y \
    build-essential \
    ca-certificates \
    curl \
    git \
    pkg-config \
    python3 \
    unzip \
    libssl-dev \
    libsqlite3-dev \
    docker.io \
    docker-compose-plugin
  sudo systemctl enable --now docker
}

install_node() {
  if command -v node >/dev/null 2>&1 && node -v | grep -q "v${NODE_VERSION}"; then
    log "Node.js ${NODE_VERSION} already installed"
    return
  fi
  log "Installing Node.js ${NODE_VERSION}.x"
  curl -fsSL "https://deb.nodesource.com/setup_${NODE_VERSION}.x" | sudo -E bash -
  sudo apt-get install -y nodejs
}

install_corepack_tooling() {
  log "Enabling Corepack and preparing Yarn ${YARN_VERSION}"
  sudo corepack enable
  sudo corepack prepare "yarn@${YARN_VERSION}" --activate
}

install_rust() {
  if command -v cargo >/dev/null 2>&1; then
    log "Rust toolchain already installed"
    return
  fi
  log "Installing Rust toolchain"
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
  export PATH="$HOME/.cargo/bin:$PATH"
}

clone_repository() {
  export GIT_TERMINAL_PROMPT=0
  if [[ -d "${INSTALL_DIR}" ]]; then
    log "Updating repository in ${INSTALL_DIR}"
    git -C "${INSTALL_DIR}" fetch --all --tags
    git -C "${INSTALL_DIR}" checkout "${BRANCH}"
    git -C "${INSTALL_DIR}" pull --ff-only || log "Fetch/pull failed, continuing with existing code"
  else
    log "Cloning ${REPO_URL} into ${INSTALL_DIR}"
    sudo mkdir -p "${INSTALL_DIR}"
    sudo chown "$(id -u)":"$(id -g)" "${INSTALL_DIR}"
    git clone --branch "${BRANCH}" "${REPO_URL}" "${INSTALL_DIR}"
  fi
}

bootstrap_env_files() {
  log "Bootstrapping environment files"
  cp -n "${INSTALL_DIR}/.docker/dev/compose.yml.example" "${INSTALL_DIR}/.docker/dev/compose.yml"

  log "Configuring domain"
  local domain_input="${PLG_DOMAIN:-}"
  local local_host="${PLG_LOCAL_HOST:-}"
  local domain=""
  local base_url=""
  local server_host=""

  if [[ -z "${domain_input}" ]]; then
    read -r -p "Enter domain for PLGames (leave blank for local host/IP): " domain_input
  fi

  if [[ -z "${domain_input}" ]]; then
    if [[ -z "${local_host}" ]]; then
      read -r -p "Enter local host/IP [127.0.0.1]: " local_host
    fi
    server_host="${local_host:-127.0.0.1}"
    domain="${server_host}"
    base_url="http://${server_host}:8080"
  else
    domain="${domain_input}"
    server_host="${domain_input}"
    base_url="https://${domain_input}"
  fi

  local support_email
  if [[ -n "${SUPPORT_EMAIL}" ]]; then
    support_email="${SUPPORT_EMAIL}"
  elif [[ -n "${domain_input}" ]]; then
    support_email="support@${domain_input}"
  else
    support_email="support@${server_host}"
  fi

  cat > "${INSTALL_DIR}/.docker/dev/.env" <<EOF
DB_VERSION=16
DB_USERNAME=${DB_USER}
DB_PASSWORD=${DB_PASSWORD}
DB_DATABASE_NAME=${DB_NAME}
MANTICORE_VERSION=10.1.0
EOF

  cat > "${INSTALL_DIR}/packages/backend/server/.env" <<EOF
DATABASE_URL="postgres://${DB_USER}:${DB_PASSWORD}@localhost:5432/${DB_NAME}"
REDIS_SERVER_HOST=127.0.0.1
AFFINE_SERVER_EXTERNAL_URL="${base_url}"
AFFINE_SERVER_HOST="${server_host}"
AFFINE_SERVER_PORT=${SERVER_PORT}
PLG_BASE_URL="${base_url}"
PLG_SUPPORT_EMAIL="${support_email}"
EOF
}

bootstrap_dependencies() {
  log "Installing JavaScript and native dependencies"
  (cd "${INSTALL_DIR}" && env ${YARN_ENV} corepack yarn install --mode skip-build || true)
  (cd "${INSTALL_DIR}" && corepack yarn plgames init || true)
  (cd "${INSTALL_DIR}" && corepack yarn plgames @affine/server-native build || true)
  (cd "${INSTALL_DIR}" && corepack yarn plgames @affine/native build || true)
}

start_dev_stack() {
  log "Starting PostgreSQL, Redis, and Mailhog via Docker Compose"
  (cd "${INSTALL_DIR}" && sudo docker compose -f ./.docker/dev/compose.yml up -d)
  log "Running initial database migrations and seed"
  (cd "${INSTALL_DIR}" && corepack yarn plgames server init)
}

print_summary() {
  cat <<'EOF'

PLGames self-hosting bootstrap complete.

Next steps:
  1. Review and adjust packages/backend/server/.env with production secrets.
  2. Start the backend API:
       corepack yarn plgames server dev
  3. In a separate shell start the web client:
       corepack yarn dev
  4. Access the app at the domain/host you provided (default http://127.0.0.1:8080).

Docker services can be managed with:
  sudo docker compose -f ./.docker/dev/compose.yml logs -f
  sudo docker compose -f ./.docker/dev/compose.yml down

EOF
}

main() {
  assert_ubuntu_24
  install_apt_dependencies
  install_node
  install_corepack_tooling
  install_rust
  clone_repository
  bootstrap_env_files
  bootstrap_dependencies
  start_dev_stack
  print_summary
}

main "$@"
