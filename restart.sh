#!/bin/bash
#
# PLGames Board - Скрипт перезапуска и управления
#
# Использование: bash restart.sh [action]
# Действия: restart, rebuild, logs, status
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

# Определение compose файла
get_compose_file() {
    if [ -f docker-compose.yml ]; then
        echo "docker-compose.yml"
    elif [ -f docker-compose.prod.yml ]; then
        echo "docker-compose.prod.yml"
    else
        error "Не найден docker-compose файл!"
        exit 1
    fi
}

# Статус
show_status() {
    COMPOSE_FILE=$(get_compose_file)
    info "Статус сервисов ($COMPOSE_FILE):"
    echo ""
    docker compose -f "$COMPOSE_FILE" ps
    echo ""

    # Проверка здоровья
    info "Проверка здоровья:"

    # PostgreSQL
    if docker compose -f "$COMPOSE_FILE" exec -T postgres pg_isready &>/dev/null; then
        success "PostgreSQL: работает"
    else
        error "PostgreSQL: не работает"
    fi

    # Backend
    BACKEND_PORT=$(grep BACKEND_PORT .env 2>/dev/null | cut -d= -f2 || echo "3010")
    if curl -sf http://localhost:${BACKEND_PORT}/api/healthz &>/dev/null; then
        success "Backend: работает"
    else
        warning "Backend: не отвечает или еще запускается"
    fi

    # Frontend
    FRONTEND_PORT=$(grep FRONTEND_PORT .env 2>/dev/null | cut -d= -f2 || echo "8080")
    if curl -sf http://localhost:${FRONTEND_PORT} &>/dev/null; then
        success "Frontend: работает"
    else
        warning "Frontend: не отвечает или еще запускается"
    fi
}

# Перезапуск
restart_services() {
    COMPOSE_FILE=$(get_compose_file)
    info "Перезапуск сервисов..."

    docker compose -f "$COMPOSE_FILE" restart

    success "Сервисы перезапущены"

    sleep 3
    show_status
}

# Полная пересборка
rebuild_services() {
    COMPOSE_FILE=$(get_compose_file)

    warning "Внимание! Будет выполнена полная пересборка образов"
    read -p "Продолжить? [y/N]: " -r
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        info "Отменено"
        exit 0
    fi

    info "Остановка сервисов..."
    docker compose -f "$COMPOSE_FILE" down

    info "Пересборка образов (это займет время)..."
    docker compose -f "$COMPOSE_FILE" build --no-cache 2>&1 | tee /tmp/plgames-rebuild.log

    if [ ${PIPESTATUS[0]} -eq 0 ]; then
        success "Образы пересобраны"
    else
        error "Ошибка пересборки! Проверьте лог: /tmp/plgames-rebuild.log"
        exit 1
    fi

    info "Запуск сервисов..."
    docker compose -f "$COMPOSE_FILE" up -d

    success "Сервисы запущены"

    sleep 5
    show_status
}

# Логи
show_logs() {
    COMPOSE_FILE=$(get_compose_file)
    SERVICE=$1

    if [ -z "$SERVICE" ]; then
        info "Показ логов всех сервисов (Ctrl+C для выхода):"
        docker compose -f "$COMPOSE_FILE" logs -f
    else
        info "Показ логов сервиса: $SERVICE (Ctrl+C для выхода):"
        docker compose -f "$COMPOSE_FILE" logs -f "$SERVICE"
    fi
}

# Остановка
stop_services() {
    COMPOSE_FILE=$(get_compose_file)

    read -p "Остановить все сервисы? [y/N]: " -r
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        info "Отменено"
        exit 0
    fi

    info "Остановка сервисов..."
    docker compose -f "$COMPOSE_FILE" down

    success "Сервисы остановлены"
}

# Запуск
start_services() {
    COMPOSE_FILE=$(get_compose_file)
    info "Запуск сервисов..."

    docker compose -f "$COMPOSE_FILE" up -d

    success "Сервисы запущены"

    sleep 3
    show_status
}

# Очистка
cleanup() {
    warning "Внимание! Это удалит все контейнеры, volumes и данные!"
    read -p "Вы уверены? Введите 'yes' для подтверждения: " -r
    if [ "$REPLY" != "yes" ]; then
        info "Отменено"
        exit 0
    fi

    COMPOSE_FILE=$(get_compose_file)

    info "Полная очистка..."
    docker compose -f "$COMPOSE_FILE" down -v --remove-orphans

    success "Очистка завершена"
}

# Помощь
show_help() {
    cat << EOF

PLGames Board - Управление сервисами

Использование: bash restart.sh [команда] [опции]

Команды:
  status              Показать статус всех сервисов
  restart             Перезапустить все сервисы
  rebuild             Полная пересборка образов
  start               Запустить сервисы
  stop                Остановить сервисы
  logs [service]      Показать логи (всех или конкретного сервиса)
  cleanup             Полная очистка (удалить все данные)
  help                Показать эту справку

Примеры:
  bash restart.sh status
  bash restart.sh restart
  bash restart.sh logs backend
  bash restart.sh rebuild

Доступные сервисы для логов:
  - backend
  - frontend
  - postgres
  - redis

EOF
}

# Главная функция
main() {
    ACTION=${1:-status}

    case $ACTION in
        status)
            show_status
            ;;
        restart)
            restart_services
            ;;
        rebuild)
            rebuild_services
            ;;
        start)
            start_services
            ;;
        stop)
            stop_services
            ;;
        logs)
            show_logs "$2"
            ;;
        cleanup)
            cleanup
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            error "Неизвестная команда: $ACTION"
            show_help
            exit 1
            ;;
    esac
}

main "$@"
