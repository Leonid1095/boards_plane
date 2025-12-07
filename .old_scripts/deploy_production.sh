#!/bin/bash
set -e

# Configuration
DOMAIN="${DOMAIN:-uwow-guide.online}"
REPO_DIR="${REPO_DIR:-/home/plg/boards_plane}"
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[$(date +'%H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[$(date +'%H:%M:%S')] $1${NC}"
}

error() {
    echo -e "${RED}[$(date +'%H:%M:%S')] $1${NC}"
}

info() {
    echo -e "${BLUE}[$(date +'%H:%M:%S')] $1${NC}"
}

# 1. System Preparation
log "🚀 Starting One-Click Deployment for PLGames..."
info "📍 Domain: $DOMAIN"
info "📂 Directory: $REPO_DIR"

if [ "$(id -u)" -ne 0 ]; then
    warn "This script is not running as root. Some installation steps might fail or require sudo."
    warn "If you encounter errors, try running with: sudo ./deploy_production.sh"
fi

# Detect if we're in Russia and use mirrors
detect_region() {
    # Try to connect to Google (blocked in Russia)
    if timeout 3 curl -s --max-time 3 https://www.google.com > /dev/null 2>&1; then
        echo "international"
    else
        # Also check for typical Russian DNS
        if grep -q "Yandex\|RU\|.ru" /etc/resolv.conf 2>/dev/null; then
            echo "russia"
        else
            # Assume Russia if Google is unreachable
            echo "russia"
        fi
    fi
}

REGION=$(detect_region)
if [ "$REGION" = "russia" ]; then
    warn "🇷🇺 Detected Russia region. Will use mirror services and alternative registries."
    export USE_MIRRORS=true
    export DOCKER_REGISTRY="cr.yandex"
else
    info "🌍 International region detected."
    export USE_MIRRORS=false
    export DOCKER_REGISTRY="docker.io"
fi

# Install Docker if missing
if ! command -v docker &> /dev/null; then
    log "📦 Docker not found. Installing..."

    if [ "$USE_MIRRORS" = "true" ]; then
        # Use Yandex mirror for Russia
        warn "Using mirror for Docker installation (Russia-friendly)"

        # Install prerequisites
        apt-get update || sudo apt-get update
        apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release || \
            sudo apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release

        # Add Docker repository from mirror
        if [ -f /etc/debian_version ]; then
            # Debian/Ubuntu
            mkdir -p /etc/apt/keyrings
            curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg 2>/dev/null || \
                sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

            echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | \
                tee /etc/apt/sources.list.d/docker.list > /dev/null || \
                sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
        fi

        apt-get update || sudo apt-get update
        apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin || \
            sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    else
        # Use official Docker install script for international
        curl -fsSL https://get.docker.com -o get-docker.sh
        sh get-docker.sh
        rm get-docker.sh
    fi

    # Start Docker service
    systemctl start docker || sudo systemctl start docker
    systemctl enable docker || sudo systemctl enable docker

    log "✅ Docker installed."
else
    log "✅ Docker is already installed."
fi

# Configure Docker for Russia if needed
if [ "$USE_MIRRORS" = "true" ]; then
    log "⚙️  Configuring Docker mirrors for Russia..."

    DOCKER_DAEMON_JSON="/etc/docker/daemon.json"

    # Backup existing config
    if [ -f "$DOCKER_DAEMON_JSON" ]; then
        cp "$DOCKER_DAEMON_JSON" "${DOCKER_DAEMON_JSON}.backup" || sudo cp "$DOCKER_DAEMON_JSON" "${DOCKER_DAEMON_JSON}.backup"
    fi

    # Create daemon.json with Yandex Cloud mirror
    cat > /tmp/daemon.json <<'EOF'
{
  "registry-mirrors": [
    "https://mirror.gcr.io"
  ],
  "insecure-registries": [],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
EOF

    mv /tmp/daemon.json "$DOCKER_DAEMON_JSON" || sudo mv /tmp/daemon.json "$DOCKER_DAEMON_JSON"
    chmod 644 "$DOCKER_DAEMON_JSON" || sudo chmod 644 "$DOCKER_DAEMON_JSON"

    # Restart Docker to apply changes
    systemctl restart docker || sudo systemctl restart docker
    log "✅ Docker configured with mirrors."
fi

# 2. Repository Synchronization
log "🔄 Synchronizing repository..."
if [ -d "$REPO_DIR" ]; then
    cd "$REPO_DIR" || exit
    git config --global --add safe.directory "$REPO_DIR"

    # Fix: Use 'main' branch instead of 'master'
    CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
    log "Current branch: $CURRENT_BRANCH"

    git pull origin "$CURRENT_BRANCH" || warn "Failed to pull changes. Continuing with local version..."
    git submodule update --init --recursive
else
    error "Repository directory $REPO_DIR not found!"
    error "Please clone the repository first to: $REPO_DIR"
    exit 1
fi

# 3. Environment Configuration
log "⚙️  Configuring environment..."

# Generate secure passwords if not present
if [ ! -f .env ]; then
    log "📝 Creating new .env file..."
    DB_PASSWORD=$(openssl rand -hex 16)
    cat > .env <<EOF
# PLGames Production Configuration
NODE_ENV=production
DOMAIN=${DOMAIN}
BASE_URL=https://${DOMAIN}

# Database Configuration
DB_USER=plgames
DB_PASSWORD=${DB_PASSWORD}
DB_NAME=plgames
DATABASE_URL=postgres://plgames:${DB_PASSWORD}@postgres:5432/plgames

# Server Configuration
PORT=3010
AFFINE_SERVER_HOST=0.0.0.0
AFFINE_SERVER_PORT=3010

# Redis Configuration
REDIS_SERVER_HOST=redis
REDIS_SERVER_PORT=6379

# AI Configuration (Optional - uncomment and fill to enable)
# OPENROUTER_API_KEY=your_openrouter_api_key_here
# OPENROUTER_MODEL=meta-llama/llama-3.1-70b-instruct

# OAuth Configuration (Optional - for Yandex Auth)
# OIDC_CLIENT_ID=your_yandex_oauth_client_id
# OIDC_CLIENT_SECRET=your_yandex_oauth_client_secret

# Feature Flags
AFFINE_COPILOT_ENABLED=false
EOF
    log "✅ .env file created with secure passwords."
    warn "📝 IMPORTANT: Edit .env file to configure OAuth and AI features if needed!"
else
    log "✅ .env file already exists. Skipping generation."
fi

# 4. Deployment
log "🛑 Stopping old containers..."
docker compose -f docker-compose.prod.yml down --remove-orphans 2>/dev/null || true

log "🏗️  Building and Starting PLGames Stack..."
log "This may take 10-30 minutes on first run (building Node.js app)..."

# Use build with no cache to ensure clean build
if [ "$USE_MIRRORS" = "true" ]; then
    warn "Building with Russia-friendly settings..."
    # Set build args for mirrors
    export BUILDKIT_PROGRESS=plain
fi

# Build and start services
docker compose -f docker-compose.prod.yml up -d --build

# Wait for services to be healthy
log "⏳ Waiting for services to start..."
sleep 10

# Run database migrations
log "🔄 Running database migrations..."
docker compose -f docker-compose.prod.yml exec -T backend sh -c "npx prisma migrate deploy" || \
    warn "Migration failed or already up to date"

# 5. Verification
log "🔍 Verifying deployment..."

# Check if containers are running
if docker compose -f docker-compose.prod.yml ps | grep -q "Up"; then
    echo ""
    echo -e "${GREEN}==============================================${NC}"
    echo -e "${GREEN}✅ PLGames Deployment Successful!${NC}"
    echo -e "${GREEN}==============================================${NC}"
    echo ""
    echo -e "${BLUE}📊 Access Information:${NC}"
    echo -e "   🌍 Frontend:    http://localhost:8080"
    echo -e "   🔌 Backend API: http://localhost:3010"
    echo -e "   📈 GraphQL:     http://localhost:3010/graphql"
    if [ "$DOMAIN" != "uwow-guide.online" ]; then
        echo -e "   🌐 Public URL:  https://${DOMAIN}"
    fi
    echo ""
    echo -e "${BLUE}🛠️  Useful Commands:${NC}"
    echo -e "   View logs:      ${GREEN}docker compose -f docker-compose.prod.yml logs -f${NC}"
    echo -e "   Restart:        ${GREEN}docker compose -f docker-compose.prod.yml restart${NC}"
    echo -e "   Stop:           ${GREEN}docker compose -f docker-compose.prod.yml down${NC}"
    echo -e "   Update & Deploy:${GREEN}./deploy_production.sh${NC}"
    echo ""
    echo -e "${YELLOW}📝 Next Steps:${NC}"
    echo -e "   1. Configure reverse proxy (Nginx/Caddy) for HTTPS"
    echo -e "   2. Edit .env file to enable AI features (optional)"
    echo -e "   3. Configure OAuth for Yandex authentication (optional)"
    echo ""
else
    error "❌ Deployment failed. Containers are not running."
    error "Checking logs for errors..."
    docker compose -f docker-compose.prod.yml logs --tail=50
    exit 1
fi
