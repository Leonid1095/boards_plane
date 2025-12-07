#!/bin/bash
#
# PLGames Board - Скрипт для разработки
# Быстрая пересборка и запуск локально
#
# Использование: bash dev.sh
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
warning() { echo -e "${YELLOW}⚠${NC} $1"; }
error() { echo -e "${RED}✗${NC} $1"; }

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  PLGames Board - Разработка"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Проверка Docker
if ! command -v docker &> /dev/null; then
    error "Docker не установлен!"
    echo "Установите: https://docs.docker.com/engine/install/"
    exit 1
fi

# Проверка .env
if [ ! -f .env ]; then
    error "Файл .env не найден!"
    echo ""
    echo "Создайте .env файл или скопируйте из примера:"
    echo "  cp .env.example .env"
    exit 1
fi

# Меню
echo "Выберите действие:"
echo ""
echo "1) Быстрый запуск (пересборка + запуск)"
echo "2) Только пересборка"
echo "3) Только запуск"
echo "4) Остановка"
echo "5) Полная очистка и пересборка"
echo "6) Логи (live)"
echo "7) Статус"
echo ""
read -p "Ваш выбор [1-7]: " CHOICE

case $CHOICE in
    1)
        info "Быстрый запуск..."
        info "Остановка старых контейнеров..."
        docker compose down

        info "Пересборка образов..."
        docker compose build

        info "Запуск..."
        docker compose up -d

        sleep 3
        docker compose ps
        echo ""
        success "Запущено!"
        echo ""
        echo "🌐 Frontend:  http://localhost:8080"
        echo "🔧 Backend:   http://localhost:3010"
        echo "📊 GraphQL:   http://localhost:3010/graphql"
        echo ""
        echo "Логи: docker compose logs -f"
        ;;

    2)
        info "Пересборка образов..."
        docker compose build
        success "Собрано!"
        ;;

    3)
        info "Запуск контейнеров..."
        docker compose up -d
        sleep 3
        docker compose ps
        success "Запущено!"
        ;;

    4)
        info "Остановка контейнеров..."
        docker compose down
        success "Остановлено!"
        ;;

    5)
        warning "Полная очистка (БД будет удалена!)"
        read -p "Продолжить? [y/N]: " CONFIRM
        if [[ $CONFIRM =~ ^[Yy]$ ]]; then
            info "Остановка и удаление..."
            docker compose down -v

            info "Очистка Docker кэша..."
            docker system prune -f

            info "Пересборка с нуля..."
            docker compose build --no-cache

            info "Запуск..."
            docker compose up -d

            sleep 5
            docker compose ps
            success "Полная пересборка завершена!"
        else
            error "Отменено"
        fi
        ;;

    6)
        info "Просмотр логов (Ctrl+C для выхода)..."
        docker compose logs -f
        ;;

    7)
        info "Статус контейнеров:"
        echo ""
        docker compose ps
        echo ""

        # Проверка доступности
        if curl -sf http://localhost:3010/api/healthz &>/dev/null; then
            success "Backend: ✓ работает"
        else
            error "Backend: ✗ не отвечает"
        fi

        if curl -sf http://localhost:8080 &>/dev/null; then
            success "Frontend: ✓ работает"
        else
            warning "Frontend: проверьте доступность"
        fi
        ;;

    *)
        error "Неверный выбор"
        exit 1
        ;;
esac

exit 0
