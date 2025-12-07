# PLGames - Справочник команд

## Быстрый запуск

```bash
# Один скрипт для всего
bash quick-deploy.sh
```

## Управление Docker

### Запуск/Остановка

```bash
# Запустить все сервисы
docker compose up -d

# Остановить все сервисы
docker compose down

# Остановить + удалить данные (БД, volumes)
docker compose down -v

# Перезапустить все
docker compose restart

# Перезапустить только backend
docker compose restart backend

# Остановить один сервис
docker compose stop backend

# Запустить один сервис
docker compose start backend
```

### Сборка

```bash
# Собрать все образы
docker compose build

# Собрать без кэша (полная пересборка)
docker compose build --no-cache

# Собрать только backend
docker compose build backend

# Собрать и сразу запустить
docker compose up -d --build
```

### Просмотр статуса и логов

```bash
# Статус всех контейнеров
docker compose ps

# Логи всех сервисов (live)
docker compose logs -f

# Логи только backend
docker compose logs -f backend

# Последние 50 строк логов
docker compose logs --tail=50 backend

# Логи с временными метками
docker compose logs -f -t backend

# Логи за последний час
docker compose logs --since 1h backend
```

## Работа с контейнерами

### Вход в контейнер

```bash
# Зайти в backend (bash)
docker compose exec backend bash

# Зайти в backend (sh, если bash нет)
docker compose exec backend sh

# Зайти в PostgreSQL
docker compose exec postgres bash

# Запустить psql
docker compose exec postgres psql -U plgames -d plgames
```

### Выполнение команд

```bash
# Выполнить команду в backend
docker compose exec backend node -v

# Проверить переменные окружения
docker compose exec backend env | grep PRISMA

# Проверить файлы Prisma
docker compose exec backend ls -la /app/node_modules/.prisma/client/

# Запустить yarn команду
docker compose exec backend yarn --version
```

## База данных (PostgreSQL)

### Подключение

```bash
# Подключиться к БД через psql
docker compose exec postgres psql -U plgames -d plgames

# Или через docker напрямую
docker exec -it <postgres_container_id> psql -U plgames -d plgames
```

### SQL команды внутри psql

```sql
-- Список таблиц
\dt

-- Описание таблицы
\d table_name

-- Список БД
\l

-- Выход
\q

-- Выполнить SQL
SELECT * FROM "User" LIMIT 10;

-- Показать размер БД
SELECT pg_size_pretty(pg_database_size('plgames'));
```

### Бэкап и восстановление

```bash
# Создать бэкап
docker compose exec postgres pg_dump -U plgames plgames > backup.sql

# Восстановить из бэкапа
docker compose exec -T postgres psql -U plgames plgames < backup.sql

# Полный бэкап с данными
docker compose exec postgres pg_dump -U plgames -Fc plgames > backup.dump

# Восстановить полный бэкап
docker compose exec -T postgres pg_restore -U plgames -d plgames < backup.dump
```

## Prisma

### Внутри контейнера

```bash
# Зайти в backend
docker compose exec backend bash

# Генерация Prisma клиента
npx prisma generate

# Миграции БД
npx prisma migrate deploy

# Prisma Studio (GUI для БД)
npx prisma studio --port 5555

# Проверка схемы
npx prisma validate

# Форматирование схемы
npx prisma format
```

### Из хоста (если Prisma установлен)

```bash
cd plgames/packages/backend/server

# Генерация клиента
npx prisma generate

# Создание миграции
npx prisma migrate dev --name migration_name

# Применение миграций
npx prisma migrate deploy
```

## Мониторинг и диагностика

### Проверка работоспособности

```bash
# Проверка backend API
curl http://localhost:3010/api/healthz

# Проверка frontend
curl http://localhost:8080

# Проверка PostgreSQL
docker compose exec postgres pg_isready -U plgames

# Проверка Redis
docker compose exec redis redis-cli ping
```

### Использование ресурсов

```bash
# Статистика контейнеров (CPU, RAM, Network)
docker stats

# Использование дискового пространства
docker system df

# Детальная информация
docker system df -v
```

### Инспекция

```bash
# Детальная информация о контейнере
docker inspect <container_name>

# Информация о сети
docker network inspect plane_plgames-network

# Информация о volume
docker volume inspect plane_postgres_data
```

## Очистка

### Удаление данных

```bash
# Удалить контейнеры и volumes
docker compose down -v

# Удалить образы
docker compose down --rmi all

# Удалить все (контейнеры, сети, volumes, образы)
docker compose down -v --rmi all
```

### Очистка Docker

```bash
# Очистка неиспользуемых ресурсов
docker system prune

# Полная очистка (ОСТОРОЖНО!)
docker system prune -af --volumes

# Удалить неиспользуемые образы
docker image prune -a

# Удалить неиспользуемые volumes
docker volume prune

# Удалить неиспользуемые сети
docker network prune
```

## Отладка

### Проблемы с сборкой

```bash
# Сборка с выводом всех деталей
docker compose build --progress=plain --no-cache

# Сборка конкретного stage (для multi-stage Dockerfile)
docker build --target builder -f plgames/Dockerfile.plgames plgames/

# Сохранить лог сборки
docker compose build --no-cache 2>&1 | tee build.log
```

### Проблемы при запуске

```bash
# Запуск с выводом логов в терминал
docker compose up

# Запуск только одного сервиса
docker compose up backend

# Пересоздать контейнеры
docker compose up -d --force-recreate

# Пересоздать и пересобрать
docker compose up -d --force-recreate --build
```

### Проверка сети

```bash
# Проверить сетевое подключение между контейнерами
docker compose exec backend ping postgres

# Проверить DNS
docker compose exec backend nslookup postgres

# Проверить порты
docker compose exec backend netstat -tlnp
```

## Переменные окружения

### Просмотр

```bash
# Все переменные в контейнере
docker compose exec backend env

# Конкретная переменная
docker compose exec backend printenv DATABASE_URL

# Переменные Prisma
docker compose exec backend env | grep PRISMA
```

### Изменение

```bash
# 1. Отредактируйте .env файл
nano .env

# 2. Пересоздайте контейнеры
docker compose up -d --force-recreate
```

## Работа с файлами

### Копирование файлов

```bash
# Из контейнера на хост
docker compose cp backend:/app/dist ./local-dist

# С хоста в контейнер
docker compose cp ./local-file backend:/app/

# Логи из контейнера
docker compose cp backend:/var/log/app.log ./app.log
```

### Просмотр файлов

```bash
# Просмотреть файл в контейнере
docker compose exec backend cat /app/package.json

# Просмотреть файл с tail
docker compose exec backend tail -f /var/log/app.log

# Просмотреть структуру директории
docker compose exec backend ls -laR /app/node_modules/.prisma
```

## Производительность

### Профилирование

```bash
# Время выполнения команды
time docker compose exec backend node --version

# Использование памяти процессом
docker compose exec backend ps aux

# Top процессов в контейнере
docker compose exec backend top
```

### Оптимизация

```bash
# Очистка кэша npm/yarn
docker compose exec backend yarn cache clean

# Пересборка с BuildKit (быстрее)
DOCKER_BUILDKIT=1 docker compose build

# Параллельная сборка
docker compose build --parallel
```

## Безопасность

### Проверка уязвимостей

```bash
# Сканирование образа (если установлен trivy)
trivy image plgames-backend:latest

# Проверка зависимостей
docker compose exec backend yarn audit

# Обновление зависимостей
docker compose exec backend yarn upgrade-interactive
```

### Права доступа

```bash
# Проверить права файлов
docker compose exec backend ls -la /app

# Изменить владельца (если нужно)
docker compose exec backend chown -R node:node /app

# Проверить пользователя в контейнере
docker compose exec backend whoami
```

## Полезные алиасы

Добавьте в `~/.bashrc` или `~/.zshrc`:

```bash
# Docker compose
alias dc='docker compose'
alias dcu='docker compose up -d'
alias dcd='docker compose down'
alias dcl='docker compose logs -f'
alias dcb='docker compose build'
alias dcp='docker compose ps'

# PLGames specific
alias plg-logs='docker compose logs -f backend'
alias plg-restart='docker compose restart backend'
alias plg-bash='docker compose exec backend bash'
alias plg-db='docker compose exec postgres psql -U plgames -d plgames'
alias plg-status='docker compose ps && curl -s http://localhost:3010/api/healthz'
```

После добавления:
```bash
source ~/.bashrc  # или ~/.zshrc
```

## Шпаргалка

### Обычный день работы

```bash
# Утро - запуск
docker compose up -d

# Проверка статуса
docker compose ps

# Просмотр логов
docker compose logs -f backend

# Вечер - остановка
docker compose down
```

### Что-то сломалось

```bash
# 1. Смотрим логи
docker compose logs --tail=100 backend

# 2. Перезапускаем
docker compose restart backend

# 3. Если не помогло - пересоздаем
docker compose up -d --force-recreate backend

# 4. Если и это не помогло - пересобираем
docker compose build --no-cache backend
docker compose up -d backend
```

### Обновление кода

```bash
# 1. Остановка
docker compose down

# 2. Обновление кода (git pull или копирование файлов)
cd plgames && git pull

# 3. Пересборка
docker compose build

# 4. Запуск
docker compose up -d
```

---

**Совет:** Держите этот файл открытым в соседней вкладке терминала для быстрого доступа к командам.
