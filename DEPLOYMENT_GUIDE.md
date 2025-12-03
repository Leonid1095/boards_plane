# 🚀 Руководство по развертыванию PLGames Board

## 📋 Содержание

1. [Быстрый старт](#быстрый-старт)
2. [Требования](#требования)
3. [Установка](#установка)
4. [Управление сервисами](#управление-сервисами)
5. [Решение проблем](#решение-проблем)

---

## ⚡ Быстрый старт

### На чистом сервере (новая установка):

```bash
# 1. Клонировать репозиторий
git clone https://github.com/Leonid1095/boards_plane.git /opt/plgames
cd /opt/plgames

# 2. Запустить установку
bash install-fixed.sh
```

### На сервере с существующей установкой (обновление):

```bash
# 1. Перейти в директорию
cd /opt/plgames

# 2. Обновить код
git pull origin main

# 3. Пересобрать сервисы
bash restart.sh rebuild
```

---

## 💻 Требования

### Минимальные требования:

- **ОС**: Ubuntu 20.04+ / Debian 11+
- **RAM**: 4 GB (рекомендуется 8 GB)
- **Диск**: 20 GB свободного места
- **Docker**: 20.10+
- **Docker Compose**: 2.0+

### Проверка требований:

```bash
# Версия ОС
cat /etc/os-release

# Свободное место
df -h

# Docker
docker --version
docker compose version
```

---

## 📦 Установка

### Вариант 1: Автоматическая установка (рекомендуется)

```bash
# Скачать и запустить установщик
curl -fsSL https://raw.githubusercontent.com/Leonid1095/boards_plane/main/install-fixed.sh | bash
```

### Вариант 2: Ручная установка

```bash
# 1. Клонировать репозиторий
git clone https://github.com/Leonid1095/boards_plane.git /opt/plgames
cd /opt/plgames

# 2. Создать .env файл
cp .env.example .env
nano .env  # Отредактировать параметры

# 3. Собрать и запустить
docker compose build --no-cache
docker compose up -d

# 4. Проверить статус
bash restart.sh status
```

---

## 🎛️ Управление сервисами

### Основные команды:

```bash
# Показать статус всех сервисов + health check
bash restart.sh status

# Перезапустить сервисы
bash restart.sh restart

# Полная пересборка образов
bash restart.sh rebuild

# Запустить остановленные сервисы
bash restart.sh start

# Остановить все сервисы
bash restart.sh stop

# Показать логи
bash restart.sh logs

# Логи конкретного сервиса
bash restart.sh logs backend
bash restart.sh logs frontend
bash restart.sh logs postgres

# Полная очистка (удалить все данные)
bash restart.sh cleanup
```

### Docker Compose команды:

```bash
# Статус контейнеров
docker compose ps

# Логи в реальном времени
docker compose logs -f

# Перезапуск конкретного сервиса
docker compose restart backend

# Масштабирование
docker compose up -d --scale backend=2

# Остановка и удаление
docker compose down
docker compose down -v  # С удалением volumes
```

---

## 🔧 Конфигурация

### Основные параметры (.env):

```bash
# Домен и порты
DOMAIN=your-domain.com          # Ваш домен или IP
BASE_URL=http://your-domain.com:8080
FRONTEND_PORT=8080              # Порт frontend
BACKEND_PORT=3010               # Порт backend

# База данных
DB_USER=plgames
DB_PASSWORD=your-secure-password
DB_NAME=plgames
POSTGRES_PORT=5432

# AI (OpenRouter) - опционально
AFFINE_COPILOT_ENABLED=true
AFFINE_COPILOT_OPENROUTER_API_KEY=your-api-key
AFFINE_COPILOT_OPENROUTER_MODEL=meta-llama/llama-3.1-70b-instruct

# OAuth (Yandex) - опционально
OIDC_CLIENT_ID=your-client-id
OIDC_CLIENT_SECRET=your-client-secret
```

### Изменение конфигурации:

```bash
# 1. Отредактировать .env
nano .env

# 2. Перезапустить сервисы
bash restart.sh restart
```

---

## 🔍 Проверка работоспособности

### Health checks:

```bash
# PostgreSQL
docker compose exec postgres pg_isready

# Backend API
curl http://localhost:3010/api/healthz

# Frontend
curl http://localhost:8080

# Полная проверка
bash restart.sh status
```

### Ожидаемый результат:

```
ℹ  Статус сервисов (docker-compose.yml):

NAME                    IMAGE                   STATUS      PORTS
plgames-backend-1       plgames-backend        Up          0.0.0.0:3010->3010/tcp
plgames-frontend-1      plgames-frontend       Up          0.0.0.0:8080->80/tcp
plgames-postgres-1      pgvector/pgvector:pg16 Up (healthy) 0.0.0.0:5432->5432/tcp
plgames-redis-1         redis:alpine           Up          6379/tcp

ℹ  Проверка здоровья:
✓ PostgreSQL: работает
✓ Backend: работает
✓ Frontend: работает
```

---

## 🐛 Решение проблем

### Проблема: "Invalid package.json"

**Симптом**: Ошибка при сборке backend
**Решение**:
```bash
# Проверить что файл существует
ls -la plgames/package.json

# Переклонировать если отсутствует
cd /opt/plgames
rm -rf plgames
git clone https://github.com/toeverything/AFFiNE.git plgames
```

### Проблема: "No space left on device"

**Симптом**: Не хватает места для сборки
**Решение**:
```bash
# Очистить Docker
docker system prune -af
docker volume prune -f

# Проверить место
df -h
```

### Проблема: Порт уже занят

**Симптом**: "Port already in use"
**Решение**:
```bash
# Найти процесс на порту
sudo lsof -i :3010
sudo lsof -i :8080

# Изменить порт в .env
nano .env
# Изменить FRONTEND_PORT или BACKEND_PORT

# Перезапустить
bash restart.sh restart
```

### Проблема: Backend не запускается

**Симптом**: Backend container постоянно перезапускается
**Решение**:
```bash
# Посмотреть логи
bash restart.sh logs backend

# Проверить подключение к БД
docker compose exec backend sh -c "npx prisma db push"

# Пересобрать без кэша
docker compose build --no-cache backend
docker compose up -d backend
```

### Проблема: Frontend показывает ошибку

**Симптом**: 502 Bad Gateway или ошибки в консоли
**Решение**:
```bash
# Проверить что backend работает
curl http://localhost:3010/api/healthz

# Проверить логи frontend
bash restart.sh logs frontend

# Проверить Caddyfile
cat plgames/packages/frontend/apps/web/Caddyfile

# Пересобрать frontend
docker compose build --no-cache frontend
docker compose up -d frontend
```

---

## 📊 Мониторинг

### Просмотр ресурсов:

```bash
# Использование ресурсов контейнерами
docker stats

# Размер образов
docker images

# Размер volumes
docker system df -v
```

### Логи:

```bash
# Все сервисы (в реальном времени)
bash restart.sh logs

# Последние 100 строк backend
docker compose logs backend --tail=100

# Логи с временными метками
docker compose logs -t backend

# Следить за логами
docker compose logs -f --tail=50 backend
```

---

## 🔄 Обновление

### Обновление кода:

```bash
cd /opt/plgames

# Сохранить изменения если есть
git stash

# Обновить
git pull origin main

# Восстановить изменения
git stash pop

# Пересобрать
bash restart.sh rebuild
```

### Обновление Docker образов:

```bash
# Обновить базовые образы
docker compose pull postgres redis

# Пересобрать свои образы
bash restart.sh rebuild
```

---

## 🔒 Безопасность

### Рекомендации:

1. **Изменить пароли по умолчанию**
```bash
nano .env
# Изменить DB_PASSWORD на надежный пароль
```

2. **Настроить firewall**
```bash
# Открыть только нужные порты
sudo ufw allow 8080/tcp
sudo ufw allow 3010/tcp
sudo ufw enable
```

3. **Использовать HTTPS**
```bash
# Настроить SSL сертификаты через Caddy
# или использовать reverse proxy (nginx/traefik)
```

4. **Регулярные бэкапы**
```bash
# Бэкап базы данных
docker compose exec postgres pg_dump -U plgames plgames > backup.sql

# Бэкап volumes
docker run --rm -v plgames_postgres_data:/data -v $(pwd):/backup \
  alpine tar czf /backup/postgres_data.tar.gz /data
```

---

## 📚 Дополнительные ресурсы

- **Полная документация по исправлениям**: [FIXES_DOCUMENTATION.md](FIXES_DOCUMENTATION.md)
- **Быстрое исправление на сервере**: [SERVER_QUICK_FIX.md](SERVER_QUICK_FIX.md)
- **Основной README**: [README.md](README.md)

---

## 💬 Поддержка

При возникновении проблем:

1. Проверьте [FIXES_DOCUMENTATION.md](FIXES_DOCUMENTATION.md)
2. Запустите диагностику: `bash restart.sh status`
3. Соберите логи: `bash restart.sh logs > logs.txt`
4. Создайте issue на GitHub с логами

---

**Дата последнего обновления**: 2024-12-03
**Версия**: 1.0
