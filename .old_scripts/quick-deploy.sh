#!/bin/bash
#
# PLGames - Быстрый запуск (AFFINE основа)
# Минимальная настройка для первого запуска
#

set -e

# Цвета
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

info() { echo -e "${BLUE}ℹ${NC} $1"; }
success() { echo -e "${GREEN}✓${NC} $1"; }
error() { echo -e "${RED}✗${NC} $1"; }
warning() { echo -e "${YELLOW}⚠${NC} $1"; }

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  PLGames - Быстрый запуск (AFFINE)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# 1. Проверка Docker
if ! command -v docker &> /dev/null; then
    error "Docker не установлен!"
    echo "Установите Docker: https://docs.docker.com/engine/install/"
    exit 1
fi
success "Docker установлен: $(docker --version)"

# 2. Остановка старых контейнеров
info "Остановка старых контейнеров..."
docker compose down 2>/dev/null || true

# 3. Очистка (опционально)
read -p "Очистить старые образы и пересобрать? [y/N]: " -r
if [[ $REPLY =~ ^[Yy]$ ]]; then
    warning "Удаление старых образов..."
    docker compose down -v 2>/dev/null || true
    docker system prune -f 2>/dev/null || true
    BUILD_CACHE="--no-cache"
else
    BUILD_CACHE=""
fi

# 4. Сборка
info "Сборка Docker образов..."
echo ""
warning "Это займет 10-20 минут при первой сборке"
echo ""

# Используем исправленный Dockerfile
if ! docker compose build $BUILD_CACHE 2>&1 | tee /tmp/plgames-build.log; then
    error "Ошибка сборки!"
    echo ""
    echo "Последние строки лога:"
    tail -50 /tmp/plgames-build.log
    echo ""
    error "Полный лог: /tmp/plgames-build.log"
    exit 1
fi

success "Образы собраны"

# 5. Запуск
info "Запуск сервисов..."
docker compose up -d

# 6. Ожидание готовности
info "Ожидание готовности сервисов..."
echo ""

# PostgreSQL
info "Проверка PostgreSQL..."
for i in {1..30}; do
    if docker compose exec -T postgres pg_isready -U plgames &>/dev/null; then
        success "PostgreSQL готов"
        break
    fi
    echo -n "."
    sleep 2
done
echo ""

# Backend
info "Проверка Backend..."
for i in {1..60}; do
    if curl -sf http://localhost:3010/api/healthz &>/dev/null; then
        success "Backend готов"
        break
    fi

    # Показываем прогресс
    if [ $((i % 5)) -eq 0 ]; then
        echo "  Ожидание... ($i/60)"
        # Показать последние логи для диагностики
        docker compose logs --tail=3 backend 2>/dev/null || true
    fi

    sleep 2
done
echo ""

# 7. Проверка статуса
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Статус сервисов"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
docker compose ps
echo ""

# 8. Проверка работоспособности
BACKEND_OK=false
FRONTEND_OK=false

if curl -sf http://localhost:3010/api/healthz &>/dev/null; then
    success "Backend API: http://localhost:3010"
    BACKEND_OK=true
else
    error "Backend не отвечает на http://localhost:3010"
fi

if curl -sf http://localhost:8080 &>/dev/null; then
    success "Frontend: http://localhost:8080"
    FRONTEND_OK=true
else
    warning "Frontend может быть еще не готов"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Информация для доступа"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "🌐 Frontend:     http://localhost:8080"
echo "🔧 Backend API:  http://localhost:3010"
echo "📊 GraphQL:      http://localhost:3010/graphql"
echo "💾 База данных:  PostgreSQL на порту 5432"
echo ""
echo "📁 Директория:   $(pwd)"
echo "📝 Конфигурация: .env"
echo ""
echo "Команды управления:"
echo "  docker compose ps           # Статус"
echo "  docker compose logs -f      # Логи (все)"
echo "  docker compose logs -f backend  # Логи backend"
echo "  docker compose restart      # Перезапуск"
echo "  docker compose down         # Остановка"
echo "  docker compose down -v      # Остановка + удаление данных"
echo ""

# Показать логи если что-то не работает
if [ "$BACKEND_OK" = false ]; then
    error "Backend не запустился! Показываю логи:"
    echo ""
    docker compose logs --tail=50 backend
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    error "Проверьте логи выше для диагностики"
    exit 1
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
success "PLGames успешно запущен!"
echo ""
info "Откройте http://localhost:8080 в браузере"
echo ""
