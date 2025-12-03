# 🚀 Быстрое исправление на сервере

## Для тех, кто уже пытался установить и получил ошибки

### 📋 Что сделано:

✅ Исправлены все пути в docker-compose файлах
✅ Исправлен Dockerfile для frontend
✅ Создан новый установщик с поддержкой обновления
✅ Создан скрипт управления сервисами

---

## 🔧 Быстрое исправление (2 минуты)

### Вариант 1: У вас есть git на сервере

```bash
cd /opt/plgames
git pull origin main
chmod +x install-fixed.sh restart.sh
bash restart.sh rebuild
```

### Вариант 2: Ручное обновление файлов

```bash
cd /opt/plgames

# Скачать исправленные файлы из репозитория
wget https://raw.githubusercontent.com/Leonid1095/boards_plane/main/docker-compose.yml -O docker-compose.yml
wget https://raw.githubusercontent.com/Leonid1095/boards_plane/main/docker-compose.prod.yml -O docker-compose.prod.yml
wget https://raw.githubusercontent.com/Leonid1095/boards_plane/main/restart.sh -O restart.sh
wget https://raw.githubusercontent.com/Leonid1095/boards_plane/main/install-fixed.sh -O install-fixed.sh

# Обновить Dockerfile для frontend
wget https://raw.githubusercontent.com/Leonid1095/boards_plane/main/plgames/packages/frontend/apps/web/Dockerfile \
  -O plgames/packages/frontend/apps/web/Dockerfile

# Дать права на выполнение
chmod +x restart.sh install-fixed.sh

# Пересобрать
bash restart.sh rebuild
```

### Вариант 3: Чистая установка (если ничего не помогло)

```bash
# Удалить старую установку
docker compose down -v
cd ..
rm -rf /opt/plgames

# Запустить новый установщик
mkdir -p /opt/plgames
cd /opt/plgames
curl -fsSL https://raw.githubusercontent.com/Leonid1095/boards_plane/main/install-fixed.sh | bash
```

---

## 📊 Проверка после исправления

```bash
# 1. Проверить статус
bash restart.sh status

# Вы должны увидеть:
# ✓ PostgreSQL: работает
# ✓ Backend: работает
# ✓ Frontend: работает

# 2. Проверить логи (если что-то не работает)
bash restart.sh logs

# 3. Проверить конкретный сервис
bash restart.sh logs backend
bash restart.sh logs frontend
```

---

## ❓ Что делать если всё равно ошибки

### Ошибка: "Invalid package.json"

```bash
# Проверить что файл существует
ls -la plgames/package.json

# Если не существует - переклонировать plgames
cd /opt/plgames
rm -rf plgames
git clone https://github.com/toeverything/AFFiNE.git plgames
```

### Ошибка: "No space left on device"

```bash
# Очистить Docker
docker system prune -af
docker volume prune -f

# Проверить место
df -h
```

### Ошибка: "Cannot connect to Docker daemon"

```bash
# Перезапустить Docker
sudo systemctl restart docker

# Проверить статус
sudo systemctl status docker
```

### Ошибка: Backend или Frontend не запускается

```bash
# Остановить всё
bash restart.sh stop

# Полная очистка и пересборка
docker system prune -af
bash restart.sh rebuild

# Если не помогло - посмотреть детальные логи
docker compose logs backend --tail=100
docker compose logs frontend --tail=100
```

---

## 🎯 Ожидаемый результат

После выполнения исправлений:

✅ `docker compose ps` - все сервисы в статусе "running"
✅ `curl http://localhost:3010/api/healthz` - ответ 200 OK
✅ `curl http://localhost:8080` - frontend доступен
✅ PostgreSQL и Redis работают стабильно

---

## 📞 Нужна помощь?

1. Запустите диагностику:
```bash
bash restart.sh status > status.log
bash restart.sh logs > logs.log
```

2. Отправьте файлы `status.log` и `logs.log`

---

## 🔍 Основные команды управления

```bash
bash restart.sh status    # Статус всех сервисов
bash restart.sh restart   # Перезапуск
bash restart.sh rebuild   # Полная пересборка
bash restart.sh logs      # Показать логи
bash restart.sh stop      # Остановить всё
bash restart.sh start     # Запустить
bash restart.sh cleanup   # Полная очистка
```

---

**Дата**: 2024-12-03
**Готово к использованию**: ✅ Да
