#!/bin/bash
set -e

# Функция проверки наличия команды
command_exists() {
  command -v "$1" >/dev/null 2>&1
}

echo "Добро пожаловать в установщик PLGames!"

# Проверка Docker
if ! command_exists docker; then
  echo "Ошибка: Docker не установлен. Пожалуйста, установите Docker и попробуйте снова."
  exit 1
fi

# Проверка Docker Compose
if ! docker compose version >/dev/null 2>&1; then
  echo "Ошибка: Плагин Docker Compose не установлен. Пожалуйста, установите его и попробуйте снова."
  exit 1
fi

# Генерация .env файла
echo "Настройка окружения..."
read -p "Введите домен (например, localhost или example.com): " DOMAIN
DOMAIN=${DOMAIN:-localhost}

read -p "Введите имя пользователя БД [plgames]: " DB_USER
DB_USER=${DB_USER:-plgames}

read -p "Введите пароль БД [plgames]: " DB_PASSWORD
DB_PASSWORD=${DB_PASSWORD:-plgames}

read -p "Введите имя базы данных [plgames]: " DB_NAME
DB_NAME=${DB_NAME:-plgames}

if [ "$DOMAIN" = "localhost" ]; then
  BASE_URL="http://localhost:8080"
else
  BASE_URL="https://$DOMAIN"
fi

cat > .env <<EOF
DOMAIN=$DOMAIN
BASE_URL=$BASE_URL
DB_USER=$DB_USER
DB_PASSWORD=$DB_PASSWORD
DB_NAME=$DB_NAME
EOF

echo "Файл .env создан."

# Запуск Docker Compose
echo "Запуск сервисов..."
docker compose -f docker-compose.prod.yml up -d --build

echo "Установка завершена!"
echo "Фронтенд: http://localhost:8080 (или ваш домен)"
echo "Бэкенд: http://localhost:3010"
