#!/bin/bash

# PLGames Quick Start Script
# This script helps you get started quickly with minimal configuration

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

clear
echo -e "${BLUE}"
cat << "EOF"
    ____  __    ______
   / __ \/ /   / ____/___ _____ ___  ___  _____
  / /_/ / /   / / __/ __ `/ __ `__ \/ _ \/ ___/
 / ____/ /___/ /_/ / /_/ / / / / / /  __(__  )
/_/   /_____/\____/\__,_/_/ /_/ /_/\___/____/

Open Source CRM & Project Management
EOF
echo -e "${NC}"
echo -e "${GREEN}Quick Start Configuration Wizard${NC}"
echo ""

# Check if running as root
if [ "$(id -u)" -eq 0 ]; then
    echo -e "${YELLOW}⚠️  Warning: Running as root. This is fine for initial setup.${NC}"
fi

# Step 1: Domain Configuration
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}Step 1: Domain Configuration${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "Enter your domain name (or leave empty for localhost):"
read -p "Domain [localhost]: " DOMAIN
DOMAIN=${DOMAIN:-localhost}

if [ "$DOMAIN" = "localhost" ]; then
    BASE_URL="http://localhost:8080"
else
    BASE_URL="https://$DOMAIN"
fi

echo -e "${GREEN}✓ Domain set to: $DOMAIN${NC}"
echo ""

# Step 2: AI Configuration
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}Step 2: AI Features (Optional)${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "Do you want to enable AI features?"
echo "You'll need an OpenRouter API key from https://openrouter.ai/"
read -p "Enable AI? (y/N): " ENABLE_AI

if [[ "$ENABLE_AI" =~ ^[Yy]$ ]]; then
    read -p "Enter your OpenRouter API key: " OPENROUTER_KEY
    read -p "Select model [meta-llama/llama-3.1-70b-instruct]: " AI_MODEL
    AI_MODEL=${AI_MODEL:-meta-llama/llama-3.1-70b-instruct}
    AI_ENABLED=true
    echo -e "${GREEN}✓ AI features enabled${NC}"
else
    AI_ENABLED=false
    OPENROUTER_KEY=""
    AI_MODEL=""
    echo -e "${YELLOW}✓ AI features disabled${NC}"
fi
echo ""

# Step 3: OAuth Configuration
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}Step 3: OAuth Configuration (Optional)${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "Do you want to enable Yandex OAuth for authentication?"
echo "Create an OAuth app at https://oauth.yandex.ru/client/new"
read -p "Enable OAuth? (y/N): " ENABLE_OAUTH

if [[ "$ENABLE_OAUTH" =~ ^[Yy]$ ]]; then
    read -p "Enter Yandex OAuth Client ID: " OAUTH_CLIENT_ID
    read -p "Enter Yandex OAuth Client Secret: " OAUTH_CLIENT_SECRET
    OAUTH_ENABLED=true
    echo -e "${GREEN}✓ OAuth enabled${NC}"
else
    OAUTH_ENABLED=false
    OAUTH_CLIENT_ID=""
    OAUTH_CLIENT_SECRET=""
    echo -e "${YELLOW}✓ OAuth disabled (using email/password auth)${NC}"
fi
echo ""

# Step 4: Generate .env file
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}Step 4: Generating Configuration${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Generate secure passwords
DB_PASSWORD=$(openssl rand -hex 16)
SESSION_SECRET=$(openssl rand -hex 32)
JWT_SECRET=$(openssl rand -hex 32)

# Create .env file
cat > .env <<EOF
# PLGames Production Configuration
# Generated: $(date)

# ==========================================
# Basic Configuration
# ==========================================
NODE_ENV=production
DOMAIN=$DOMAIN
BASE_URL=$BASE_URL

# ==========================================
# Database Configuration
# ==========================================
DB_USER=plgames
DB_PASSWORD=$DB_PASSWORD
DB_NAME=plgames
DATABASE_URL=postgres://plgames:$DB_PASSWORD@postgres:5432/plgames

# ==========================================
# Server Configuration
# ==========================================
PORT=3010
AFFINE_SERVER_HOST=0.0.0.0
AFFINE_SERVER_PORT=3010
AFFINE_SERVER_EXTERNAL_URL=$BASE_URL

# ==========================================
# Redis Configuration
# ==========================================
REDIS_SERVER_HOST=redis
REDIS_SERVER_PORT=6379

# ==========================================
# Security
# ==========================================
SESSION_SECRET=$SESSION_SECRET
JWT_SECRET=$JWT_SECRET

EOF

# Add AI configuration if enabled
if [ "$AI_ENABLED" = true ]; then
    cat >> .env <<EOF
# ==========================================
# AI Configuration
# ==========================================
AFFINE_COPILOT_ENABLED=true
AFFINE_COPILOT_OPENROUTER_API_KEY=$OPENROUTER_KEY
AFFINE_COPILOT_OPENROUTER_MODEL=$AI_MODEL

EOF
else
    cat >> .env <<EOF
# ==========================================
# AI Configuration
# ==========================================
AFFINE_COPILOT_ENABLED=false

EOF
fi

# Add OAuth configuration if enabled
if [ "$OAUTH_ENABLED" = true ]; then
    cat >> .env <<EOF
# ==========================================
# OAuth Configuration
# ==========================================
AFFINE_OAUTH_OIDC_ISSUER=https://oauth.yandex.ru
OIDC_CLIENT_ID=$OAUTH_CLIENT_ID
OIDC_CLIENT_SECRET=$OAUTH_CLIENT_SECRET
AFFINE_OAUTH_OIDC_ARGS_SCOPE=openid

EOF
fi

# Add feature flags
cat >> .env <<EOF
# ==========================================
# Feature Flags
# ==========================================
AFFINE_TELEMETRY_ENABLED=false
AFFINE_METRICS_ENABLED=true
EOF

chmod 600 .env
echo -e "${GREEN}✓ Configuration file created: .env${NC}"
echo ""

# Step 5: Summary
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}Configuration Summary${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "Domain:       ${GREEN}$DOMAIN${NC}"
echo -e "Base URL:     ${GREEN}$BASE_URL${NC}"
echo -e "AI Features:  $([ "$AI_ENABLED" = true ] && echo -e "${GREEN}Enabled${NC}" || echo -e "${YELLOW}Disabled${NC}")"
echo -e "OAuth:        $([ "$OAUTH_ENABLED" = true ] && echo -e "${GREEN}Enabled${NC}" || echo -e "${YELLOW}Disabled${NC}")"
echo ""

# Step 6: Deployment confirmation
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}Ready to Deploy!${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "Your configuration is ready. The deployment will:"
echo "  1. Install Docker (if needed)"
echo "  2. Build the application (15-30 minutes)"
echo "  3. Start all services"
echo "  4. Run database migrations"
echo ""
read -p "Start deployment now? (Y/n): " START_DEPLOY

if [[ ! "$START_DEPLOY" =~ ^[Nn]$ ]]; then
    echo ""
    echo -e "${GREEN}Starting deployment...${NC}"
    echo ""

    # Make deploy script executable
    chmod +x deploy_production.sh

    # Run deployment
    if [ "$(id -u)" -eq 0 ]; then
        ./deploy_production.sh
    else
        echo -e "${YELLOW}Deployment requires sudo privileges...${NC}"
        sudo ./deploy_production.sh
    fi
else
    echo ""
    echo -e "${YELLOW}Deployment cancelled.${NC}"
    echo "To deploy later, run: ${GREEN}sudo ./deploy_production.sh${NC}"
    echo ""
fi

# Final message
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}Next Steps${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "1. Configure HTTPS (recommended):"
echo "   ${GREEN}sudo apt install nginx certbot python3-certbot-nginx${NC}"
echo "   See INSTALL_RU.md for details"
echo ""
echo "2. Access your installation:"
echo "   Frontend: ${GREEN}http://$(hostname -I | awk '{print $1}'):8080${NC}"
echo "   Backend:  ${GREEN}http://$(hostname -I | awk '{print $1}'):3010${NC}"
echo ""
echo "3. View logs:"
echo "   ${GREEN}docker compose -f docker-compose.prod.yml logs -f${NC}"
echo ""
echo "4. Read full documentation:"
echo "   ${GREEN}cat README.md${NC}"
echo "   ${GREEN}cat INSTALL_RU.md${NC}"
echo ""
echo -e "${GREEN}Happy PLGames! 🎉${NC}"
echo ""
