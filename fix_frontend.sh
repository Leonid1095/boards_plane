#!/bin/bash
set -e

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Исправление развертывания фронтенда...${NC}"

# 1. Находим ID контейнера фронтенда
echo -e "${YELLOW}Поиск контейнера frontend...${NC}"
# Пытаемся найти через docker compose
CONTAINER_ID=$(docker compose -f docker-compose.prod.yml ps -q frontend 2>/dev/null)

# Если не нашли через compose, ищем по имени образа или части имени
if [ -z "$CONTAINER_ID" ]; then
    echo -e "${YELLOW}Контейнер не найден через compose, ищем по имени...${NC}"
    CONTAINER_ID=$(docker ps -q --filter "name=frontend" | head -n1)
fi

if [ -z "$CONTAINER_ID" ]; then
    echo -e "${RED}Ошибка: Контейнер фронтенда не найден!${NC}"
    echo -e "${YELLOW}Убедитесь, что 'docker compose -f docker-compose.prod.yml up -d' был выполнен успешно.${NC}"
    exit 1
fi

echo -e "${GREEN}Найден контейнер: $CONTAINER_ID${NC}"

# 2. Создаем целевую директорию
echo -e "${YELLOW}Создание директории /var/www/plgames...${NC}"
sudo mkdir -p /var/www/plgames

# 3. Копируем файлы
echo -e "${YELLOW}Копирование файлов из контейнера (это может занять немного времени)...${NC}"
# Очищаем старые файлы, чтобы избежать мусора
sudo rm -rf /var/www/plgames/*

# Копируем из /usr/share/caddy - именно туда Dockerfile кладет собранные файлы
if sudo docker cp "$CONTAINER_ID":/usr/share/caddy/. /var/www/plgames/; then
    echo -e "${GREEN}Файлы успешно скопированы!${NC}"
else
    echo -e "${RED}Ошибка при копировании файлов.${NC}"
    exit 1
fi

# 4. Исправляем права
echo -e "${YELLOW}Настройка прав доступа...${NC}"
sudo chown -R www-data:www-data /var/www/plgames 2>/dev/null || sudo chown -R 33:33 /var/www/plgames 2>/dev/null || true
sudo chmod -R 755 /var/www/plgames

# 5. Перезагружаем Caddy
echo -e "${YELLOW}Перезагрузка Caddy...${NC}"
if sudo systemctl reload caddy; then
    echo -e "${GREEN}Caddy успешно перезагружен.${NC}"
else
    echo -e "${YELLOW}Не удалось перезагрузить Caddy (возможно, он не запущен как сервис). Пробуем restart...${NC}"
    sudo systemctl restart caddy || echo -e "${RED}Не удалось перезапустить Caddy. Проверьте статус вручную.${NC}"
fi

echo -e "${GREEN}=========================================${NC}"
echo -e "${GREEN}   Исправление завершено! 🚀${NC}"
echo -e "${GREEN}=========================================${NC}"
echo -e "Проверьте сайт: https://uwow-guide.online"
