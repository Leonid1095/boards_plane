#!/bin/bash
# PLGames Board - One-Line Installer (Pre-built Images)
# curl -fsSL https://raw.githubusercontent.com/Leonid1095/boards_plane/main/install-prebuilt.sh | bash
#
# Features:
# - Uses pre-built Docker images from GitHub Container Registry
# - No build required (2-3 minutes vs 20-30 minutes)
# - Works on any server with Docker (2GB RAM minimum vs 8GB for build)
# - Automatic HTTPS with Let's Encrypt (optional)
# - Interactive setup with domain or IP

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}"
echo "╔════════════════════════════════════════════════════════════╗"
echo "║                                                            ║"
echo "║           PLGames Board - Quick Install                   ║"
echo "║                                                            ║"
echo "║   🚀 Ready in 2-3 minutes (uses pre-built images)        ║"
echo "║                                                            ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${YELLOW}⚠️  Рекомендуется запустить с sudo${NC}"
    echo "   Продолжить? (y/n)"
    read -r response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Check Docker
echo -e "${BLUE}🔍 Проверка Docker...${NC}"
if ! command -v docker &> /dev/null; then
    echo -e "${YELLOW}Docker не установлен. Устанавливаю...${NC}"
    curl -fsSL https://get.docker.com | sh
    systemctl start docker
    systemctl enable docker
    echo -e "${GREEN}✓ Docker установлен${NC}"
else
    echo -e "${GREEN}✓ Docker найден${NC}"
fi

# Check Docker Compose
if ! command -v docker compose &> /dev/null && ! command -v docker-compose &> /dev/null; then
    echo -e "${YELLOW}Docker Compose не установлен${NC}"
    echo "Устанавливаю Docker Compose v2..."
    mkdir -p /usr/local/lib/docker/cli-plugins
    curl -SL https://github.com/docker/compose/releases/latest/download/docker-compose-linux-x86_64 \
         -o /usr/local/lib/docker/cli-plugins/docker-compose
    chmod +x /usr/local/lib/docker/cli-plugins/docker-compose
    echo -e "${GREEN}✓ Docker Compose установлен${NC}"
else
    echo -e "${GREEN}✓ Docker Compose найден${NC}"
fi

# Check disk space
AVAILABLE_GB=$(df -BG / | tail -1 | awk '{print $4}' | sed 's/G//')
if [ "$AVAILABLE_GB" -lt 10 ]; then
    echo -e "${RED}❌ Недостаточно места на диске: ${AVAILABLE_GB}GB (требуется минимум 10GB)${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Место на диске: ${AVAILABLE_GB}GB${NC}"

# Create directory
INSTALL_DIR="${HOME}/plgames-board"
echo ""
echo -e "${BLUE}📁 Директория установки: ${INSTALL_DIR}${NC}"
mkdir -p "${INSTALL_DIR}"
cd "${INSTALL_DIR}"

# Download docker-compose.yml
echo ""
echo -e "${BLUE}📥 Загрузка конфигурации...${NC}"
curl -fsSL https://raw.githubusercontent.com/Leonid1095/boards_plane/main/docker-compose.prebuilt.yml \
     -o docker-compose.yml

# Interactive configuration
echo ""
echo -e "${BLUE}⚙️  Настройка${NC}"
echo ""
echo "Выберите режим установки:"
echo "  1) Домен с HTTPS (автоматический SSL через Let's Encrypt)"
echo "  2) IP адрес с HTTP (без SSL)"
echo ""
read -p "Ваш выбор (1/2): " setup_choice

if [ "$setup_choice" = "1" ]; then
    # Domain with HTTPS
    echo ""
    read -p "Введите ваш домен (например, plgames.example.com): " DOMAIN

    if [ -z "$DOMAIN" ]; then
        echo -e "${RED}❌ Домен не может быть пустым${NC}"
        exit 1
    fi

    # Download Caddy config
    curl -fsSL https://raw.githubusercontent.com/Leonid1095/boards_plane/main/docker-compose.https.yml \
         -o docker-compose.override.yml

    BASE_URL="https://${DOMAIN}"
    FRONTEND_PORT="443"
    BACKEND_PORT="3010"

    echo -e "${GREEN}✓ Настроен домен: ${DOMAIN}${NC}"
    echo -e "${YELLOW}⚠️  Убедитесь, что DNS записи для ${DOMAIN} указывают на этот сервер!${NC}"

else
    # IP with HTTP
    SERVER_IP=$(curl -s ifconfig.me || hostname -I | awk '{print $1}')
    echo ""
    echo -e "Обнаружен IP: ${GREEN}${SERVER_IP}${NC}"
    read -p "Использовать этот IP? (y/n): " use_ip

    if [[ ! "$use_ip" =~ ^[Yy]$ ]]; then
        read -p "Введите IP адрес сервера: " SERVER_IP
    fi

    DOMAIN="${SERVER_IP}"
    BASE_URL="http://${SERVER_IP}:8080"
    FRONTEND_PORT="8080"
    BACKEND_PORT="3010"

    echo -e "${GREEN}✓ Настроен IP: ${SERVER_IP}${NC}"
fi

# Generate secure password
DB_PASSWORD=$(openssl rand -base64 32 | tr -dc 'a-zA-Z0-9' | head -c 24)

# Create .env file
cat > .env << EOF
# PLGames Board Configuration
# Generated: $(date)

# Domain/IP
DOMAIN=${DOMAIN}
BASE_URL=${BASE_URL}

# Ports
FRONTEND_PORT=${FRONTEND_PORT}
BACKEND_PORT=${BACKEND_PORT}

# Database
DB_USER=plgames
DB_PASSWORD=${DB_PASSWORD}
DB_NAME=plgames
POSTGRES_PORT=5432

# Node
NODE_ENV=production

# Optional: AI (OpenRouter)
AFFINE_COPILOT_ENABLED=false
# AFFINE_COPILOT_OPENROUTER_API_KEY=your-key-here
# AFFINE_COPILOT_OPENROUTER_MODEL=meta-llama/llama-3.1-70b-instruct

# Optional: OAuth (Yandex)
# AFFINE_OAUTH_OIDC_ISSUER=https://oauth.yandex.ru
# OIDC_CLIENT_ID=your-client-id
# OIDC_CLIENT_SECRET=your-client-secret
# AFFINE_OAUTH_OIDC_ARGS_SCOPE=openid
EOF

echo -e "${GREEN}✓ Конфигурация сохранена в .env${NC}"

# Pull images
echo ""
echo -e "${BLUE}📦 Загрузка Docker образов (2-3 минуты)...${NC}"
docker compose pull

# Start services
echo ""
echo -e "${BLUE}🚀 Запуск сервисов...${NC}"
docker compose up -d

# Wait for services
echo ""
echo -e "${BLUE}⏳ Ожидание запуска сервисов (30-60 секунд)...${NC}"
sleep 10

# Health check
echo ""
echo -e "${BLUE}🏥 Проверка работоспособности...${NC}"
MAX_ATTEMPTS=12
ATTEMPT=0

while [ $ATTEMPT -lt $MAX_ATTEMPTS ]; do
    if curl -sf http://localhost:3010/api/healthz > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Backend работает${NC}"
        break
    fi
    ATTEMPT=$((ATTEMPT + 1))
    echo -n "."
    sleep 5
done

if [ $ATTEMPT -eq $MAX_ATTEMPTS ]; then
    echo ""
    echo -e "${YELLOW}⚠️  Backend еще не готов, но это нормально${NC}"
    echo "   Проверьте логи: docker compose logs -f"
fi

# Show status
echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                                                            ║${NC}"
echo -e "${GREEN}║           ✅ PLGames Board установлен!                    ║${NC}"
echo -e "${GREEN}║                                                            ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}🌐 Доступ:${NC} ${GREEN}${BASE_URL}${NC}"
echo ""
echo -e "${BLUE}📊 Полезные команды:${NC}"
echo ""
echo "  Статус сервисов:"
echo "    cd ${INSTALL_DIR} && docker compose ps"
echo ""
echo "  Логи:"
echo "    cd ${INSTALL_DIR} && docker compose logs -f"
echo ""
echo "  Остановить:"
echo "    cd ${INSTALL_DIR} && docker compose down"
echo ""
echo "  Обновить до новой версии:"
echo "    cd ${INSTALL_DIR} && docker compose pull && docker compose up -d"
echo ""
echo "  Бэкап базы данных:"
echo "    cd ${INSTALL_DIR} && docker compose exec postgres pg_dump -U plgames plgames > backup.sql"
echo ""

if [ "$setup_choice" = "1" ]; then
    echo -e "${YELLOW}⚠️  Важно для HTTPS:${NC}"
    echo "  1. Убедитесь, что DNS запись ${DOMAIN} указывает на ${SERVER_IP}"
    echo "  2. Откройте порты: 80, 443"
    echo "     sudo ufw allow 80/tcp"
    echo "     sudo ufw allow 443/tcp"
    echo ""
fi

echo -e "${GREEN}✨ Готово! Откройте ${BASE_URL} в браузере${NC}"
echo ""
