# 🚨 PLGames Board - Устранение проблем при развертывании

**Для:** AI-ассистента или администратора
**Проблема:** Backend не запускается, сайт отдает 502 ошибку
**Статус:** Диагностика и исправление

---

## 📊 Типичная ситуация

### Что работает:
- ✅ PostgreSQL контейнер запущен
- ✅ Redis контейнер запущен
- ✅ Caddy сервер запущен
- ✅ Контейнеры созданы
- ✅ .env файл настроен

### Что НЕ работает:
- ❌ Backend сервер на порту 3010 не отвечает
- ❌ Сайт отдает 502 Bad Gateway (Caddy не может достучаться до backend)
- ❌ Database migrations не выполнены

### Почему это происходит:
1. **Проблема с миграциями** - Prisma не может найти schema или не может выполнить миграции
2. **Проблема со сборкой** - Backend не собрался правильно в Docker
3. **Проблема с переменными** - Отсутствуют или неправильно заданы env переменные
4. **Проблема с сетью** - Backend не может подключиться к PostgreSQL

---

## 🔍 ШАГ 1: Диагностика проблемы

### 1.1. Проверьте статус контейнеров

```bash
# На сервере uwow-guide.online
cd /home/plgames/boards_plane

# Проверьте статус всех контейнеров
docker compose -f docker-compose.prod.yml ps
```

**Ожидаемый результат:**
```
NAME                          STATUS              PORTS
boards_plane-backend-1        Up (healthy)        0.0.0.0:3010->3010/tcp
boards_plane-frontend-1       Up                  0.0.0.0:8080->80/tcp
boards_plane-postgres-1       Up (healthy)        5432/tcp
boards_plane-redis-1          Up                  6379/tcp
```

**Если backend показывает "Restarting" или "Exited":**
```
boards_plane-backend-1        Restarting (1)      # ❌ ПРОБЛЕМА!
```

### 1.2. Проверьте логи backend контейнера

```bash
# Посмотрите последние 100 строк логов
docker compose -f docker-compose.prod.yml logs backend --tail=100

# Или в режиме реального времени
docker compose -f docker-compose.prod.yml logs -f backend
```

**Ищите ошибки:**

#### Ошибка 1: Prisma schema не найден
```
Error: Could not find Prisma Schema at ./schema.prisma
```
**Причина:** schema.prisma не скопирован в Docker image
**Решение:** Пересобрать образ (см. раздел "Пересборка backend")

#### Ошибка 2: Database migration failed
```
Error: P3009: migrate found failed migrations
```
**Причина:** Неудачные миграции в базе данных
**Решение:** Сбросить миграции (см. раздел "Сброс миграций")

#### Ошибка 3: Cannot connect to database
```
Error: Can't reach database server at postgres:5432
```
**Причина:** Backend не может подключиться к PostgreSQL
**Решение:** Проверить network и DATABASE_URL (см. раздел "Проверка сети")

#### Ошибка 4: Module not found
```
Error: Cannot find module '@affine/server'
```
**Причина:** Зависимости не установлены или сборка не завершена
**Решение:** Пересобрать образ с чистым кэшем

### 1.3. Проверьте подключение к базе данных

```bash
# Попробуйте подключиться к PostgreSQL из backend контейнера
docker compose -f docker-compose.prod.yml exec backend sh -c "apt-get update && apt-get install -y postgresql-client && psql \$DATABASE_URL -c 'SELECT version();'"
```

**Ожидаемый результат:**
```
PostgreSQL 16.x on x86_64-pc-linux-gnu
```

**Если ошибка:**
```
psql: error: connection to server at "postgres" failed
```
Значит проблема с сетью Docker.

### 1.4. Проверьте что порт 3010 слушается

```bash
# На сервере проверьте что порт 3010 открыт
netstat -tlnp | grep 3010

# Или с помощью ss
ss -tlnp | grep 3010

# Или попробуйте curl
curl -I http://localhost:3010/graphql
```

**Ожидаемый результат:**
```
HTTP/1.1 400 Bad Request
# или
HTTP/1.1 200 OK
```

**Если "Connection refused":**
```
curl: (7) Failed to connect to localhost port 3010: Connection refused
```
Значит backend не запущен.

---

## 🔧 ШАГ 2: Решение типичных проблем

### Решение 1: Пересборка backend образа

Если backend не запускается или есть ошибки со schema.prisma:

```bash
cd /home/plgames/boards_plane

# Остановите контейнеры
docker compose -f docker-compose.prod.yml down

# Удалите старый образ backend
docker compose -f docker-compose.prod.yml rm -f backend
docker rmi boards_plane-backend || true

# Пересоберите БЕЗ кэша
docker compose -f docker-compose.prod.yml build --no-cache backend

# Запустите заново
docker compose -f docker-compose.prod.yml up -d
```

**Ожидаемое время:** 15-30 минут на сборку

**После сборки проверьте логи:**
```bash
docker compose -f docker-compose.prod.yml logs -f backend
```

Должно быть:
```
[Nest] ... INFO [NestApplication] Nest application successfully started
```

### Решение 2: Сброс и выполнение миграций

Если есть ошибки миграций:

```bash
cd /home/plgames/boards_plane

# Вариант A: Выполнить миграции (если backend запущен)
docker compose -f docker-compose.prod.yml exec backend sh -c "npx prisma migrate deploy"

# Вариант B: Выполнить миграции вручную (если backend не запускается)
# Сначала запустите только базы данных
docker compose -f docker-compose.prod.yml up -d postgres redis

# Подождите 10 секунд
sleep 10

# Запустите временный контейнер для миграций
docker compose -f docker-compose.prod.yml run --rm backend sh -c "npx prisma migrate deploy"

# Теперь запустите backend
docker compose -f docker-compose.prod.yml up -d backend
```

**Ожидаемый результат:**
```
✓ Applying migration `20241201_initial_crm`
✓ Applying migration `20241201_add_crm_tables`
✓ All migrations have been successfully applied
```

### Решение 3: Полный сброс базы данных (ОПАСНО!)

**⚠️ ВНИМАНИЕ: Это удалит ВСЕ данные в базе!**

Используйте только если:
- Это первое развертывание (нет важных данных)
- Миграции безнадежно сломаны
- Вы готовы потерять все данные

```bash
cd /home/plgames/boards_plane

# Остановите все контейнеры
docker compose -f docker-compose.prod.yml down

# УДАЛИТЕ том PostgreSQL (ВСЕ ДАННЫЕ БУДУТ ПОТЕРЯНЫ!)
docker volume rm boards_plane_postgres_data

# Запустите заново (база будет пустой)
docker compose -f docker-compose.prod.yml up -d

# Подождите 30 секунд для инициализации PostgreSQL
sleep 30

# Выполните миграции на чистой базе
docker compose -f docker-compose.prod.yml exec backend sh -c "npx prisma migrate deploy"
```

### Решение 4: Использование упрощенной версии (только backend)

Если frontend не нужен или не собирается:

```bash
cd /home/plgames/boards_plane

# Используйте упрощенную версию
docker compose -f docker-compose.simple.yml down
docker compose -f docker-compose.simple.yml build --no-cache
docker compose -f docker-compose.simple.yml up -d

# Проверьте логи
docker compose -f docker-compose.simple.yml logs -f backend
```

Это запустит только:
- Backend (порт 3010)
- PostgreSQL
- Redis

Frontend придется настраивать отдельно.

### Решение 5: Проверка и исправление .env файла

```bash
# Проверьте что .env существует
cat /home/plgames/boards_plane/.env

# Проверьте обязательные переменные
grep -E "DB_USER|DB_PASSWORD|DB_NAME|DOMAIN|BASE_URL" /home/plgames/boards_plane/.env
```

**Минимальный рабочий .env:**
```bash
# Обязательные переменные
NODE_ENV=production
DOMAIN=uwow-guide.online
BASE_URL=https://uwow-guide.online

# База данных
DB_USER=plgames
DB_PASSWORD=secure_password_here
DB_NAME=plgames

# Опциональные (можно оставить пустыми)
AFFINE_COPILOT_ENABLED=false
```

**Если .env неправильный, исправьте его:**
```bash
nano /home/plgames/boards_plane/.env
# Или
vi /home/plgames/boards_plane/.env
```

После изменения .env:
```bash
docker compose -f docker-compose.prod.yml down
docker compose -f docker-compose.prod.yml up -d
```

### Решение 6: Проверка Docker network

```bash
# Проверьте что network существует
docker network ls | grep plgames

# Проверьте что контейнеры подключены к network
docker network inspect boards_plane_plgames-network

# Должны быть все 4 контейнера: backend, frontend, postgres, redis
```

**Если network отсутствует:**
```bash
docker network create boards_plane_plgames-network
docker compose -f docker-compose.prod.yml up -d
```

---

## 🎯 ШАГ 3: Проверка что всё работает

### 3.1. Проверьте статус контейнеров

```bash
docker compose -f docker-compose.prod.yml ps
```

**Все должны быть Up:**
```
NAME                          STATUS              PORTS
boards_plane-backend-1        Up (healthy)        0.0.0.0:3010->3010/tcp ✅
boards_plane-frontend-1       Up                  0.0.0.0:8080->80/tcp   ✅
boards_plane-postgres-1       Up (healthy)        5432/tcp               ✅
boards_plane-redis-1          Up                  6379/tcp               ✅
```

### 3.2. Проверьте что backend отвечает

```bash
# Проверьте GraphQL endpoint
curl -I http://localhost:3010/graphql

# Должно быть 400 или 200
```

**Ожидаемый результат:**
```
HTTP/1.1 400 Bad Request
# или
HTTP/1.1 200 OK
```

### 3.3. Проверьте что сайт доступен

```bash
# На сервере
curl -I http://localhost:8080

# Снаружи
curl -I https://uwow-guide.online
```

**Ожидаемый результат:**
```
HTTP/2 200 OK
```

**Если 502 Bad Gateway:**
- Backend не запущен (вернитесь к Решению 1)
- Caddy настроен неправильно

### 3.4. Проверьте логи на ошибки

```bash
# Backend должен показывать "successfully started"
docker compose -f docker-compose.prod.yml logs backend | grep "successfully started"

# Не должно быть критических ошибок
docker compose -f docker-compose.prod.yml logs backend | grep -E "ERROR|FATAL"
```

---

## 📋 Чеклист для AI-ассистента

При развертывании проверяйте ПО ПОРЯДКУ:

### Перед запуском:
- [ ] Git репозиторий склонирован в /home/plgames/boards_plane
- [ ] Файл .env создан и содержит все обязательные переменные
- [ ] Файл .env имеет права 600 (`chmod 600 .env`)
- [ ] Docker и Docker Compose установлены

### При первом запуске:
- [ ] `docker compose -f docker-compose.prod.yml build --no-cache` выполнен
- [ ] Сборка завершилась БЕЗ ошибок (проверьте последние строки)
- [ ] `docker compose -f docker-compose.prod.yml up -d` выполнен
- [ ] Подождали 60 секунд для инициализации PostgreSQL

### Проверка запуска:
- [ ] `docker compose -f docker-compose.prod.yml ps` показывает все контейнеры Up
- [ ] Backend контейнер не в статусе "Restarting"
- [ ] `docker compose -f docker-compose.prod.yml logs backend` показывает "successfully started"
- [ ] `curl http://localhost:3010/graphql` отвечает (не Connection refused)

### Выполнение миграций:
- [ ] `docker compose -f docker-compose.prod.yml exec backend sh -c "npx prisma migrate deploy"` выполнен
- [ ] Вывод показывает "All migrations have been successfully applied"
- [ ] Нет ошибок P3009 (failed migrations)

### Финальная проверка:
- [ ] Сайт https://uwow-guide.online отвечает 200 OK
- [ ] Не показывает 502 Bad Gateway
- [ ] GraphQL Playground открывается http://uwow-guide.online:3010/graphql

---

## 🚨 Если ничего не помогло

### Соберите диагностическую информацию:

```bash
cd /home/plgames/boards_plane

# 1. Статус контейнеров
docker compose -f docker-compose.prod.yml ps > status.txt

# 2. Логи всех сервисов
docker compose -f docker-compose.prod.yml logs > all_logs.txt

# 3. Логи backend (последние 200 строк)
docker compose -f docker-compose.prod.yml logs backend --tail=200 > backend_logs.txt

# 4. Конфигурация docker-compose
docker compose -f docker-compose.prod.yml config > compose_config.txt

# 5. .env файл (БЕЗ ПАРОЛЕЙ!)
grep -v PASSWORD .env > env_safe.txt

# 6. Версии
docker --version > versions.txt
docker compose version >> versions.txt
uname -a >> versions.txt

# 7. Сеть
docker network inspect boards_plane_plgames-network > network.txt

# 8. Проверка портов
netstat -tlnp | grep -E "3010|8080|5432|6379" > ports.txt
```

**Отправьте пользователю файлы:**
- status.txt
- backend_logs.txt
- compose_config.txt
- versions.txt

---

## 🎓 Типичные ошибки AI-ассистентов

### ❌ Ошибка 1: Запуск без сборки

**Неправильно:**
```bash
docker compose up -d  # ❌ Образы не собраны!
```

**Правильно:**
```bash
docker compose -f docker-compose.prod.yml build
docker compose -f docker-compose.prod.yml up -d
```

### ❌ Ошибка 2: Не дождались инициализации PostgreSQL

**Неправильно:**
```bash
docker compose up -d
docker compose exec backend npx prisma migrate deploy  # ❌ PostgreSQL еще не готов!
```

**Правильно:**
```bash
docker compose up -d
sleep 30  # Дождаться инициализации PostgreSQL
docker compose exec backend npx prisma migrate deploy
```

### ❌ Ошибка 3: Забыли про healthcheck

**Проблема:**
Backend запускается раньше, чем PostgreSQL готов принимать подключения.

**Решение:**
В docker-compose.prod.yml уже есть:
```yaml
depends_on:
  postgres:
    condition: service_healthy  # ✅ Ждем пока PostgreSQL станет healthy
```

Но healthcheck занимает 25-30 секунд (5 попыток * 5 секунд).

### ❌ Ошибка 4: Не проверили логи

**Проблема:**
AI сразу говорит "сервер запущен", но не проверил логи.

**Правильно:**
```bash
docker compose up -d
sleep 10
docker compose logs backend | grep "successfully started"
# Если нет "successfully started" - сервер НЕ запущен!
```

---

## 📞 Краткая инструкция для быстрого исправления

**Если backend не запускается:**

```bash
cd /home/plgames/boards_plane

# 1. Остановить всё
docker compose -f docker-compose.prod.yml down

# 2. Пересобрать backend
docker compose -f docker-compose.prod.yml build --no-cache backend

# 3. Запустить
docker compose -f docker-compose.prod.yml up -d

# 4. Подождать 60 секунд
sleep 60

# 5. Проверить логи
docker compose -f docker-compose.prod.yml logs backend --tail=50

# 6. Выполнить миграции
docker compose -f docker-compose.prod.yml exec backend sh -c "npx prisma migrate deploy"

# 7. Проверить что работает
curl http://localhost:3010/graphql
```

**Если получили 200 или 400 - backend работает! ✅**

**Если Connection refused - повторите с начала или используйте docker-compose.simple.yml**

---

**Последнее обновление:** 2024-12-02
**Версия:** 1.0.1
