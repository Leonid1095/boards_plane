# Анализ проблем установки PLGames Board

## Основная проблема

**Ваш проект НЕ может установиться за 5 минут как оригинальный AFFiNE, потому что:**

### 1. Это НЕ AFFiNE проект

Ваш репозиторий: `https://github.com/Leonid1095/boards_plane.git`
- Это форк **Plane** (система управления проектами), а не AFFiNE
- Вы ПЕРЕИМЕНОВАЛИ его в PLGames и пытаетесь использовать как AFFiNE
- Проект использует структуру Plane, но с зависимостями AFFiNE

### 2. Конфликт зависимостей

В вашем `package.json` (plgames):
```json
{
  "name": "@plgames/monorepo",
  "version": "0.25.2"
}
```

Но внутри используются пакеты AFFiNE:
- `@affine/server`
- `@affine/reader`
- `@affine/graphql`
- И другие `@affine/*` пакеты

### 3. Проблема с Docker образами

#### Ваш Dockerfile.plgames (старый):
```dockerfile
FROM node:22-bookworm AS builder
# ... попытка собрать все как AFFiNE
RUN yarn plgames build -p server  # ← эта команда НЕ существует в Plane!
```

#### Другие Dockerfile в проекте:
**packages/backend/server/Dockerfile** - использует Alpine:
```dockerfile
FROM node:22-alpine AS builder
```

**Alpine НЕ совместим с Prisma!**
- Alpine использует `musl libc`
- Prisma компилируется для `glibc` (Debian/Ubuntu)
- Prisma engines ЛОМАЮТСЯ на Alpine

### 4. Структурная несовместимость

```
plgames/
├── package.json          ← Ссылается на @plgames/monorepo
├── packages/
│   ├── backend/server/   ← Содержит @affine/server
│   ├── frontend/         ← Структура из Plane
│   └── ...
├── Dockerfile.plgames    ← Пытается собрать как AFFiNE
└── docker-compose.yml    ← Использует Dockerfile.plgames
```

## Почему оригинальный AFFiNE работает за 5 минут

### 1. Правильная структура проекта
```
AFFiNE/
├── .docker/
│   ├── Dockerfile        ← Официальный, протестированный
│   └── docker-compose.yml
├── packages/
│   └── backend/server/   ← Правильная структура @affine/server
└── package.json          ← Корректные зависимости
```

### 2. Используют Debian, НЕ Alpine
```dockerfile
FROM node:20-bookworm AS builder
```

### 3. Правильные переменные окружения
```dockerfile
ENV PRISMA_QUERY_ENGINE_BINARY=debian-openssl-3.0.x
```

### 4. Оптимизированная сборка
- Используют buildkit
- Кэширование слоев
- Правильный порядок COPY

## Основные проблемы вашего проекта

### Проблема 1: Неправильная база образа в некоторых Dockerfile

**Файл:** `plgames/packages/backend/server/Dockerfile`

```dockerfile
FROM node:22-alpine AS builder  # ← ОШИБКА!
```

**Alpine не подходит для:**
- Prisma (требует glibc)
- Sharp (требует libvips с glibc)
- Нативные модули Node.js

### Проблема 2: Отсутствие нативных зависимостей

Старый `Dockerfile.plgames` не содержал:
- `libvips-dev` для Sharp
- `libc6-dev` для Prisma
- Правильных `PRISMA_*` переменных окружения

### Проблема 3: Yarn команды

```bash
yarn plgames build -p server
```

Эта команда работает только если:
1. Настроен `affine.ts` CLI
2. Все workspace зависимости установлены
3. Prisma клиент сгенерирован

### Проблема 4: Конфликт версий

```json
// plgames/packages/backend/server/package.json
"@prisma/client": "^5.19.1"

// vs root package.json
"prisma": "5.22.0"  // ← Несовместимые версии!
```

### Проблема 5: Неправильный docker-compose.yml

```yaml
services:
  backend:
    build:
      context: ./plgames
      dockerfile: Dockerfile.plgames  # ← Собирает ВСЁ, не только backend
```

Правильно было бы:
```yaml
services:
  backend:
    build:
      context: ./plgames
      dockerfile: packages/backend/server/Dockerfile
```

## Что было исправлено

### 1. Обновлен Dockerfile.plgames

✅ Использует Debian Bookworm вместо Alpine
✅ Добавлены все необходимые системные зависимости
✅ Настроены переменные окружения Prisma
✅ Правильное копирование Prisma клиента в runtime

### 2. Создан .dockerignore

✅ Исключает ненужные файлы
✅ Ускоряет сборку

### 3. Добавлена документация

✅ DOCKER_BUILD_FIX.md - инструкция по сборке
✅ PROBLEM_ANALYSIS.md - этот файл

## Рекомендации для решения

### Краткосрочные решения (1-2 дня)

1. **Используйте исправленный Dockerfile.plgames**
   ```bash
   cd plgames
   docker build -f Dockerfile.plgames -t plgames-server:latest .
   ```

2. **Обновите версии Prisma до одной везде**
   ```bash
   # В root и в packages/backend/server
   "@prisma/client": "5.22.0"
   "prisma": "5.22.0"
   ```

3. **Исправьте Alpine Dockerfile**
   ```bash
   # packages/backend/server/Dockerfile
   FROM node:22-bookworm AS builder  # вместо alpine
   ```

### Среднесрочные решения (1 неделя)

1. **Определитесь с архитектурой**
   - Либо полностью используйте структуру AFFiNE
   - Либо адаптируйте под Plane
   - Не смешивайте их!

2. **Разделите Dockerfile**
   - Отдельный для backend
   - Отдельный для frontend
   - Не один монолитный

3. **Используйте multi-stage builds правильно**
   ```dockerfile
   # Stage 1: Builder
   FROM node:22-bookworm AS builder
   # ... build

   # Stage 2: Dependencies
   FROM node:22-bookworm AS deps
   # ... install only prod deps

   # Stage 3: Runtime
   FROM node:22-bookworm-slim
   COPY --from=deps /app/node_modules ./node_modules
   COPY --from=builder /app/dist ./dist
   ```

### Долгосрочные решения (1 месяц)

1. **Синхронизируйтесь с upstream**
   ```bash
   git remote add upstream https://github.com/toeverything/AFFiNE.git
   git fetch upstream
   git merge upstream/canary
   ```

2. **Используйте официальные Docker образы AFFiNE**
   - Они уже оптимизированы
   - Поддерживаются командой

3. **Настройте CI/CD**
   - GitHub Actions для автоматической сборки
   - Тесты перед деплоем

## Почему месяц не получалось

### 1. Неправильный подход
Вы пытались собрать гибрид Plane + AFFiNE, который не может работать из коробки

### 2. Alpine vs Debian
Использование Alpine для Prisma гарантирует провал

### 3. Отсутствие системных зависимостей
Sharp, Prisma, другие нативные модули требуют специфичные библиотеки

### 4. Неправильные переменные окружения
Prisma не знал, какие binary использовать

### 5. Версионные конфликты
Разные версии Prisma в разных частях проекта

## Следующие шаги

### Немедленно (сегодня)

1. Используйте исправленный Dockerfile.plgames
2. Запустите сборку:
   ```bash
   cd /opt/plgames  # или ваша директория
   docker compose build --no-cache
   docker compose up -d
   ```

3. Проверьте логи:
   ```bash
   docker compose logs -f backend
   ```

### На этой неделе

1. Обновите все Dockerfile на Debian
2. Синхронизируйте версии Prisma
3. Проверьте workspace зависимости

### В следующем месяце

1. Решите: AFFiNE или Plane?
2. Настройте автоматическую сборку
3. Документируйте изменения

## Сравнение: Ваш проект vs AFFiNE

| Параметр | Ваш проект | AFFiNE оригинал |
|----------|------------|-----------------|
| Репозиторий | boards_plane | AFFiNE |
| Имя пакета | @plgames/monorepo | @affine/monorepo |
| Структура | Plane + AFFiNE | Чистый AFFiNE |
| Docker base | Alpine (старый) | Debian Bookworm |
| Prisma версии | 5.19.1 и 5.22.0 | Единая версия |
| Время сборки | Не работало | 5-10 минут |
| Системные зависимости | Отсутствовали | Полный набор |

## Заключение

Ваш проект не мог собраться месяц, потому что:

1. **Это не AFFiNE** - это гибрид Plane + AFFiNE
2. **Alpine несовместим** с Prisma и Sharp
3. **Отсутствовали зависимости** для нативных модулей
4. **Конфликты версий** Prisma
5. **Неправильная структура** сборки

**Теперь исправлено:**
- ✅ Используется Debian Bookworm
- ✅ Добавлены все системные зависимости
- ✅ Настроены переменные Prisma
- ✅ Создан .dockerignore
- ✅ Добавлена документация

**Попробуйте сейчас:**
```bash
cd plgames
docker build -f Dockerfile.plgames -t plgames-server:latest .
```

Если ошибки остались, проверьте логи:
```bash
docker build -f Dockerfile.plgames -t plgames-server:latest . 2>&1 | tee build.log
```

И пришлите мне `build.log` для дальнейшей диагностики.
