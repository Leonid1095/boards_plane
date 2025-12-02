# 🔧 PLGames Board - Исправление развертывания

**Для:** AI-ассистента или администратора сервера
**Проблема:** Frontend не собирается из-за сложной структуры проекта
**Решение:** Запустить только backend + базы данных

---

## 🚨 Проблема

При выполнении `docker compose -f docker-compose.prod.yml up -d` возникает ошибка:

```
ERROR: Cannot locate specified Dockerfile: packages/frontend/apps/web/Dockerfile
```

**Причина:**
- Frontend требует полной сборки всего monorepo
- Yarn workspace команды могут не работать
- Процесс сборки очень долгий (20-40 минут)

---

## ✅ Решение: Использовать упрощенную версию

### Вариант 1: Только Backend (рекомендуется для начала)

Используйте `docker-compose.simple.yml` - без frontend, только backend + БД.

**Команда:**
```bash
cd /home/plgames/boards_plane  # или где у вас проект

# Запустить упрощенную версию
docker compose -f docker-compose.simple.yml up -d

# Проверить что запустилось
docker compose -f docker-compose.simple.yml ps

# Посмотреть логи
docker compose -f docker-compose.simple.yml logs -f backend
```

**Что будет работать:**
- ✅ Backend GraphQL API на порту 3010
- ✅ PostgreSQL база данных
- ✅ Redis кэш
- ✅ CRM система (Projects, Issues, Sprints, Comments, Time Logs)
- ✅ AI через OpenRouter (если настроен API ключ)

**Что НЕ будет работать:**
- ❌ Frontend веб-интерфейс (нужно собирать отдельно)

### Вариант 2: Собрать Frontend отдельно

Если нужен полный веб-интерфейс:

```bash
cd /home/plgames/boards_plane/plgames

# Установить зависимости (может занять 10-20 минут)
yarn install

# Собрать frontend (может занять 10-20 минут)
yarn workspace @affine/web build

# Результат будет в:
# plgames/packages/frontend/apps/web/dist/
```

Затем настройте веб-сервер (Caddy/Nginx) чтобы раздавать static файлы из dist/.

### Вариант 3: Исправить docker-compose.prod.yml

Если хотите собрать через Docker:

**Файл:** `docker-compose.prod.yml`

Измените секцию frontend:

```yaml
frontend:
  build:
    context: ./plgames
    dockerfile: packages/frontend/apps/web/Dockerfile
    args:
      - NODE_ENV=production
  restart: unless-stopped
  ports:
    - "8080:80"
  depends_on:
    - backend
  networks:
    - plgames-network  # ДОБАВИТЬ ЭТУ СТРОКУ
```

Затем попробуйте собрать:

```bash
docker compose -f docker-compose.prod.yml build frontend

# Если успешно, запустите
docker compose -f docker-compose.prod.yml up -d
```

**Внимание:** Сборка может занять 30-60 минут и требует:
- Минимум 4GB RAM
- 10GB свободного места на диске

---

## 📊 Проверка что backend работает

После запуска `docker-compose.simple.yml`:

### 1. Проверьте статус контейнеров:

```bash
docker compose -f docker-compose.simple.yml ps
```

**Ожидаемый результат:**
```
NAME                    STATUS              PORTS
boards_plane-backend-1  Up (healthy)        0.0.0.0:3010->3010/tcp
boards_plane-postgres-1 Up (healthy)        5432/tcp
boards_plane-redis-1    Up                  6379/tcp
```

### 2. Проверьте логи backend:

```bash
docker compose -f docker-compose.simple.yml logs backend | tail -50
```

**Ожидаемый результат:**
```
[Nest] ... INFO [NestApplication] Nest application successfully started
[Nest] ... INFO Server is running on http://0.0.0.0:3010
```

### 3. Проверьте GraphQL API:

```bash
# Проверьте что API отвечает
curl -I http://localhost:3010/graphql
```

**Ожидаемый результат:**
```
HTTP/1.1 400 Bad Request
```
или
```
HTTP/1.1 200 OK
```

(400 - это нормально для GET запроса к GraphQL)

### 4. Выполните миграцию базы данных:

```bash
docker compose -f docker-compose.simple.yml exec backend sh -c "npx prisma migrate deploy"
```

**Ожидаемый результат:**
```
✓ All migrations have been successfully applied
```

---

## 🎯 Использование системы без Frontend UI

Backend работает, можно использовать через GraphQL API!

### Откройте GraphQL Playground:

```
http://YOUR_SERVER_IP:3010/graphql
```

### Пример: Создать проект

```graphql
mutation {
  createCrmProject(input: {
    name: "Тестовый проект"
    key: "TEST"
    description: "Проверка работы CRM"
    workspaceId: "получите-workspace-id-через-api"
  }) {
    id
    name
    key
  }
}
```

### Пример: Создать задачу

```graphql
mutation {
  createCrmIssue(input: {
    title: "Моя первая задача"
    description: "Тестирование CRM системы"
    projectId: "id-проекта-из-предыдущего-запроса"
    reporterId: "ваш-user-id"
    type: TASK
    priority: MEDIUM
    dueDate: "2024-12-10T17:00:00Z"
  }) {
    id
    title
    dueDate
  }
}
```

### Пример: Получить все проекты

```graphql
query {
  crmProjectsByWorkspace(workspaceId: "ваш-workspace-id") {
    id
    name
    key
    issuesCount
  }
}
```

---

## 📋 Для AI-ассистента: Пошаговая инструкция

Если вы AI-ассистент, выполните:

### ШАГ 1: Проверьте что проект скачан

```bash
cd /home/plgames/boards_plane || cd /opt/plgames || cd ~/boards_plane
pwd
ls -la
```

Должны быть: `docker-compose.simple.yml`, `.env`, папка `plgames/`

### ШАГ 2: Проверьте .env файл

```bash
cat .env | grep -E "DB_USER|DB_PASSWORD|DOMAIN"
```

Должны быть заполнены: `DB_USER`, `DB_PASSWORD`, `DB_NAME`

### ШАГ 3: Запустите упрощенную версию

```bash
docker compose -f docker-compose.simple.yml up -d
```

### ШАГ 4: Дождитесь запуска (2-3 минуты)

```bash
sleep 180
docker compose -f docker-compose.simple.yml ps
```

### ШАГ 5: Проверьте что backend запустился

```bash
docker compose -f docker-compose.simple.yml logs backend | grep "successfully started"
```

Должно быть: `Nest application successfully started`

### ШАГ 6: Выполните миграцию БД

```bash
docker compose -f docker-compose.simple.yml exec backend sh -c "npx prisma migrate deploy"
```

### ШАГ 7: Проверьте API

```bash
curl -I http://localhost:3010/graphql
```

### ШАГ 8: Сообщите пользователю

```
✅ PLGames Board backend успешно запущен!

Доступ к API:
  Backend: http://YOUR_SERVER_IP:3010
  GraphQL Playground: http://YOUR_SERVER_IP:3010/graphql

Статус:
  Backend: Running ✅
  PostgreSQL: Running ✅
  Redis: Running ✅
  Frontend: Not deployed (нужна отдельная сборка)

CRM система полностью работает через GraphQL API!

Можно создавать проекты, задачи, спринты, комментарии через API.
Для веб-интерфейса нужно собрать frontend отдельно.
```

---

## 🔧 Если нужен Frontend

### Вариант A: Использовать существующий UI от AFFiNE

Backend PLGames Board совместим с AFFiNE frontend.

1. Скачайте готовую сборку AFFiNE frontend
2. Настройте Caddy/Nginx для раздачи static файлов
3. Укажите в конфиге адрес вашего backend

### Вариант B: Собрать свой Frontend (4-6 недель разработки)

См. [ROADMAP.md](ROADMAP.md) - Phase 1, v1.3.0

---

## 📞 Если ничего не помогло

Соберите информацию:

```bash
# Версия Docker
docker --version

# Логи backend
docker compose -f docker-compose.simple.yml logs backend > backend_logs.txt

# Статус контейнеров
docker compose -f docker-compose.simple.yml ps > status.txt

# Системная информация
free -h > system_info.txt
df -h >> system_info.txt
```

Отправьте пользователю файлы: `backend_logs.txt`, `status.txt`, `system_info.txt`

---

**Последнее обновление:** 2024-12-02
**Версия:** 1.0.1
