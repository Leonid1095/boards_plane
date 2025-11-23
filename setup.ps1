$ErrorActionPreference = "Stop"

Write-Host "Добро пожаловать в установщик PLGames!" -ForegroundColor Cyan

# Проверка Docker
if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Error "Docker не установлен. Пожалуйста, установите Docker Desktop и попробуйте снова."
    exit 1
}

# Генерация .env файла
Write-Host "Настройка окружения..." -ForegroundColor Yellow

$DOMAIN = Read-Host "Введите домен (по умолчанию: localhost)"
if ([string]::IsNullOrWhiteSpace($DOMAIN)) { $DOMAIN = "localhost" }

$DB_USER = Read-Host "Введите имя пользователя БД (по умолчанию: plgames)"
if ([string]::IsNullOrWhiteSpace($DB_USER)) { $DB_USER = "plgames" }

$DB_PASSWORD = Read-Host "Введите пароль БД (по умолчанию: plgames)"
if ([string]::IsNullOrWhiteSpace($DB_PASSWORD)) { $DB_PASSWORD = "plgames" }

$DB_NAME = Read-Host "Введите имя базы данных (по умолчанию: plgames)"
if ([string]::IsNullOrWhiteSpace($DB_NAME)) { $DB_NAME = "plgames" }

if ($DOMAIN -eq "localhost") {
    $BASE_URL = "http://localhost:8080"
}
else {
    $BASE_URL = "https://$DOMAIN"
}

$EnvContent = @"
DOMAIN=$DOMAIN
BASE_URL=$BASE_URL
DB_USER=$DB_USER
DB_PASSWORD=$DB_PASSWORD
DB_NAME=$DB_NAME
"@

Set-Content -Path .env -Value $EnvContent
Write-Host "Файл .env создан." -ForegroundColor Green

# Запуск Docker Compose
Write-Host "Запуск сервисов..." -ForegroundColor Yellow
docker compose -f docker-compose.prod.yml up -d --build

Write-Host "Установка завершена!" -ForegroundColor Green
Write-Host "Фронтенд: http://localhost:8080 (или ваш домен)"
Write-Host "Бэкенд: http://localhost:3010"
