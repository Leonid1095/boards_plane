#!/bin/bash
#
# AI Update Script - Умный помощник для обновления PLGames Board
# Автоматически определяет текущее состояние и выполняет нужные действия
#

set -e

# Цвета
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

info() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

# ШАГ 1: Найти проект
info "Поиск проекта..."
if [ -d "/opt/plgames" ]; then
    PROJECT_DIR="/opt/plgames"
elif [ -d "/home/plgames/boards_plane" ]; then
    PROJECT_DIR="/home/plgames/boards_plane"
elif [ -d "$HOME/boards_plane" ]; then
    PROJECT_DIR="$HOME/boards_plane"
else
    error "Проект не найден! Запустите: curl -fsSL https://raw.githubusercontent.com/Leonid1095/boards_plane/main/install.sh | sudo bash"
    exit 1
fi

info "Проект найден: $PROJECT_DIR"
cd "$PROJECT_DIR"

# ШАГ 2: Проверить Docker
if ! command -v docker &> /dev/null; then
    error "Docker не установлен!"
    exit 1
fi

if ! docker ps &> /dev/null; then
    warn "Docker не запущен, запускаю..."
    sudo systemctl start docker
    sleep 3
fi

# ШАГ 3: Backup конфигурации
if [ -f ".env" ]; then
    cp .env .env.backup.$(date +%Y%m%d_%H%M%S)
    info "Backup создан"
fi

# ШАГ 4: Скачать обновления
info "Проверка обновлений..."
git fetch origin main

LOCAL=$(git rev-parse HEAD)
REMOTE=$(git rev-parse origin/main)

if [ "$LOCAL" = "$REMOTE" ]; then
    info "Проект уже актуален ✓"
else
    info "Доступны обновления, скачиваю..."
    git pull origin main
    git submodule update --init --recursive
    info "Обновления скачаны ✓"
fi

# ШАГ 5: Перезапуск
info "Перезапуск сервисов..."
docker compose down
docker compose up -d

# ШАГ 6: Ожидание
info "Ожидание запуска (30 секунд)..."
sleep 30

# ШАГ 7: Миграции
info "Проверка миграций..."
docker compose exec backend sh -c "npx prisma migrate deploy" 2>/dev/null || warn "Миграции не требуются"

# ШАГ 8: Проверка
info "Проверка работы..."
docker compose ps

if curl -s http://localhost:3010/graphql &> /dev/null; then
    info "✓ Backend работает"
else
    error "✗ Backend не отвечает"
    docker compose logs backend --tail=30
fi

# Готово
echo ""
info "✅ Готово!"
echo ""
echo "Документация: https://github.com/Leonid1095/boards_plane/blob/main/INSTALL.md"
echo "Сайт: http://$(curl -s ifconfig.me 2>/dev/null || echo "localhost"):8080"
