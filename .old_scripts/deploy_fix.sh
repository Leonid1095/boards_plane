#!/bin/bash
set -e

# Цвета
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

WORKDIR="/opt/plgames"

echo -e "${YELLOW}=== Запуск полного исправления развертывания PLGames ===${NC}"

cd "$WORKDIR" || { echo -e "${RED}Директория $WORKDIR не найдена!${NC}"; exit 1; }

# 1. Очистка конфликтующих контейнеров
echo -e "${YELLOW}1. Остановка конфликтующих контейнеров...${NC}"

# Функция для остановки контейнера по порту
stop_by_port() {
    local port=$1
    local ids=$(docker ps --format "{{.ID}} {{.Ports}}" | grep ":$port->" | awk '{print $1}')
    if [ -n "$ids" ]; then
        echo -e "${YELLOW}Останавливаем контейнеры на порту $port: $ids${NC}"
        docker stop $ids
        docker rm $ids
    fi
}

stop_by_port 3010
stop_by_port 8080

# Также остановим специфические контейнеры, которые могут мешать
docker stop affine_server nash_miro-frontend-1 2>/dev/null || true
docker rm affine_server nash_miro-frontend-1 2>/dev/null || true

# 2. Запуск правильного окружения
echo -e "${YELLOW}2. Сборка и запуск контейнеров через docker-compose.prod.yml...${NC}"
# Убедимся, что старые контейнеры от этого компоуза тоже остановлены
docker compose -f docker-compose.prod.yml down --remove-orphans

if docker compose -f docker-compose.prod.yml up -d --build; then
    echo -e "${GREEN}Контейнеры успешно запущены!${NC}"
else
    echo -e "${RED}Ошибка при запуске docker compose.${NC}"
    exit 1
fi

echo -e "${YELLOW}Ждем 10 секунд для инициализации...${NC}"
sleep 10

# 3. Копирование файлов фронтенда
echo -e "${YELLOW}3. Копирование файлов фронтенда на хост...${NC}"

# Находим ID контейнера фронтенда
FRONTEND_ID=$(docker compose -f docker-compose.prod.yml ps -q frontend)

if [ -z "$FRONTEND_ID" ]; then
    echo -e "${RED}Ошибка: Контейнер frontend не найден после запуска!${NC}"
    exit 1
fi

echo -e "${GREEN}Контейнер фронтенда найден: $FRONTEND_ID${NC}"

# Создаем директорию
sudo mkdir -p /var/www/plgames
# Очищаем
sudo rm -rf /var/www/plgames/*

# Копируем
if sudo docker cp "$FRONTEND_ID":/usr/share/caddy/. /var/www/plgames/; then
    echo -e "${GREEN}Файлы скопированы в /var/www/plgames${NC}"
else
    echo -e "${RED}Ошибка копирования файлов из контейнера.${NC}"
    exit 1
fi

# Права
sudo chown -R www-data:www-data /var/www/plgames 2>/dev/null || sudo chown -R 33:33 /var/www/plgames 2>/dev/null || true
sudo chmod -R 755 /var/www/plgames

# 4. Перезагрузка Host Caddy
echo -e "${YELLOW}4. Перезагрузка Caddy на хосте...${NC}"
if sudo systemctl reload caddy; then
    echo -e "${GREEN}Caddy перезагружен.${NC}"
else
    echo -e "${YELLOW}Reload не сработал, пробуем restart...${NC}"
    sudo systemctl restart caddy
fi

echo -e "${GREEN}=========================================${NC}"
echo -e "${GREEN}   Готово! Проверяйте сайт. 🚀${NC}"
echo -e "${GREEN}=========================================${NC}"
