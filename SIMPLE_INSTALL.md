# PLGames Board - Простая установка

## 🚀 Установка за 1 команду

### На чистом сервере Ubuntu/Debian:

```bash
curl -fsSL https://raw.githubusercontent.com/Leonid1095/boards_plane/main/install.sh | sudo bash
```

**Вот и всё!** Скрипт сделает всё сам:
1. ✅ Установит Docker (если нет)
2. ✅ Скачает проект
3. ✅ Настроит конфигурацию (спросит домен и AI ключ)
4. ✅ Соберет и запустит все сервисы
5. ✅ Настроит базу данных
6. ✅ Проверит что всё работает

**Время:** 15-20 минут

---

## 🎯 Что получишь после установки

### Доступ к системе:
- **Сайт:** https://ваш-домен.com (или http://IP:8080)
- **GraphQL API:** http://ваш-домен.com:3010/graphql
- **Backend API:** http://ваш-домен.com:3010/api

### Учетные данные:
Скрипт покажет все пароли в конце установки.

Сохрани их в надежное место!

---

## 📋 Управление системой

### Статус сервисов:
```bash
docker compose ps
```

### Логи:
```bash
# Все сервисы
docker compose logs -f

# Только backend
docker compose logs -f backend

# Только ошибки
docker compose logs backend | grep ERROR
```

### Перезапуск:
```bash
docker compose restart
```

### Остановка:
```bash
docker compose down
```

### Обновление:
```bash
cd /opt/plgames
git pull
docker compose up -d --build
```

---

## 🔧 Где находятся файлы

| Что | Где |
|-----|-----|
| Проект | `/opt/plgames/` |
| Конфигурация | `/opt/plgames/.env` |
| База данных | Docker volume `plgames_postgres_data` |
| Файлы | Docker volume `plgames_storage_data` |

---

## ⚙️ Настройка

### Включить AI (после установки):

1. Открой `.env`:
```bash
nano /opt/plgames/.env
```

2. Измени:
```env
AFFINE_COPILOT_ENABLED=true
AFFINE_COPILOT_OPENROUTER_API_KEY=твой_ключ
```

3. Перезапусти:
```bash
cd /opt/plgames
docker compose restart backend
```

### Настроить Yandex OAuth:

1. Создай приложение: https://oauth.yandex.ru/client/new
2. Добавь в `.env`:
```env
OIDC_CLIENT_ID=твой_client_id
OIDC_CLIENT_SECRET=твой_secret
```
3. Перезапусти backend

### Изменить домен:

1. Отредактируй `.env`:
```bash
nano /opt/plgames/.env
```

2. Измени:
```env
DOMAIN=новый-домен.com
BASE_URL=https://новый-домен.com
```

3. Перезапусти:
```bash
docker compose down
docker compose up -d
```

---

## 🆘 Проблемы?

### Backend не запускается (502 ошибка):

```bash
# Посмотри логи
docker compose logs backend --tail=50

# Пересобери
docker compose down
docker compose build --no-cache backend
docker compose up -d

# Выполни миграции
docker compose exec backend npx prisma migrate deploy
```

### PostgreSQL не готов:

```bash
# Проверь статус
docker compose exec postgres pg_isready -U plgames

# Перезапусти
docker compose restart postgres
sleep 10
docker compose restart backend
```

### Нет места на диске:

```bash
# Очисти старые образы
docker system prune -a

# Очисти старые логи
docker compose logs --tail=0 backend
```

---

## 📚 Дополнительная документация

Если нужны подробности:
- **[README.md](README.md)** - Полное описание проекта
- **[INSTALL_RU.md](INSTALL_RU.md)** - Детальная инструкция (русский)
- **[DEPLOYMENT_TROUBLESHOOTING.md](DEPLOYMENT_TROUBLESHOOTING.md)** - Устранение проблем

Но скорее всего они не понадобятся - `install.sh` делает всё сам! 😉

---

## 💡 Для продвинутых пользователей

### Ручная установка (если не доверяешь скриптам):

```bash
# 1. Установи Docker
curl -fsSL https://get.docker.com | sh

# 2. Клонируй проект
git clone --recurse-submodules https://github.com/Leonid1095/boards_plane.git /opt/plgames
cd /opt/plgames

# 3. Создай .env
cp .env.example .env
nano .env  # Отредактируй

# 4. Запусти
docker compose up -d

# 5. Миграции
sleep 30
docker compose exec backend npx prisma migrate deploy
```

### Использовать свой Docker Compose:

Файл `docker-compose.yml` - универсальный, работает везде.

Можешь скопировать его и изменить под себя.

---

**Последнее обновление:** 2024-12-02
**Версия:** 1.1.0
