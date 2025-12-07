# Исправление сборки Docker для PLGames

## Проблема

При сборке Docker-контейнера возникали ошибки:

1. **@prisma/engines** - не могли скомпилироваться из-за отсутствия необходимых нативных библиотек
2. **sharp** - библиотека обработки изображений требовала дополнительные зависимости
3. **@affine/server** - сбой при сборке из-за проблем с Prisma

## Решение

### 1. Обновлен Dockerfile.plgames

#### Изменения в builder stage:

**Добавлены системные зависимости:**
- `libvips-dev`, `libvips-tools` - для Sharp (обработка изображений)
- `libc6-dev`, `pkg-config` - для сборки нативных модулей
- `build-essential` - полный набор инструментов сборки

**Настроены переменные окружения Prisma:**
```bash
ENV PRISMA_ENGINES_CHECKSUM_IGNORE_MISSING=1
ENV PRISMA_CLI_BINARY_TARGETS=native,debian-openssl-3.0.x
ENV PRISMA_QUERY_ENGINE_BINARY=debian-openssl-3.0.x
ENV PRISMA_ENGINES_MIRROR=https://binaries.prisma.sh
```

**Оптимизирована установка зависимостей:**
```bash
RUN yarn install --inline-builds
```

#### Изменения в runtime stage:

**Добавлены runtime библиотеки:**
- `libvips42` - runtime для Sharp
- `libssl3` - для Prisma engines
- `libc6` - базовые C библиотеки

**Копирование Prisma клиента:**
```dockerfile
COPY --from=builder /app/node_modules/.prisma ./node_modules/.prisma
COPY --from=builder /app/node_modules/@prisma ./node_modules/@prisma
```

**Настройка Prisma runtime:**
```bash
ENV PRISMA_QUERY_ENGINE_LIBRARY=/app/node_modules/.prisma/client/libquery_engine-debian-openssl-3.0.x.so.node
ENV PRISMA_ENGINES_CHECKSUM_IGNORE_MISSING=1
```

### 2. Создан .dockerignore

Для оптимизации размера контекста сборки и ускорения процесса.

## Команды для сборки

### Локальная сборка

```bash
cd plgames
docker build -f Dockerfile.plgames -t plgames-server:latest .
```

### Запуск контейнера

```bash
docker run -d \
  --name plgames-server \
  -p 3010:3010 \
  -e DATABASE_URL="postgresql://user:password@host:5432/dbname" \
  -e NODE_ENV=production \
  plgames-server:latest
```

### С docker-compose

```yaml
version: '3.8'

services:
  plgames-server:
    build:
      context: ./plgames
      dockerfile: Dockerfile.plgames
    ports:
      - "3010:3010"
    environment:
      - DATABASE_URL=postgresql://user:password@postgres:5432/plgames
      - NODE_ENV=production
      - PRISMA_QUERY_ENGINE_LIBRARY=/app/node_modules/.prisma/client/libquery_engine-debian-openssl-3.0.x.so.node
    depends_on:
      - postgres

  postgres:
    image: postgres:15-alpine
    environment:
      - POSTGRES_USER=user
      - POSTGRES_PASSWORD=password
      - POSTGRES_DB=plgames
    volumes:
      - postgres_data:/var/lib/postgresql/data

volumes:
  postgres_data:
```

## Проверка сборки

После сборки проверьте:

```bash
# Проверка размера образа
docker images plgames-server:latest

# Проверка логов при запуске
docker logs plgames-server

# Проверка работы Prisma
docker exec plgames-server node -e "console.log(require('@prisma/client'))"
```

## Решение возможных проблем

### Ошибка "Prisma engine not found"

Убедитесь, что переменная `PRISMA_QUERY_ENGINE_LIBRARY` указывает на правильный путь:

```bash
docker exec plgames-server ls -la /app/node_modules/.prisma/client/
```

### Ошибка "Sharp installation failed"

Проверьте наличие libvips в runtime образе:

```bash
docker exec plgames-server dpkg -l | grep libvips
```

### Медленная сборка

1. Используйте BuildKit для параллельной сборки:
   ```bash
   DOCKER_BUILDKIT=1 docker build -f Dockerfile.plgames -t plgames-server:latest .
   ```

2. Используйте кэширование слоев:
   ```bash
   docker build --cache-from plgames-server:latest -f Dockerfile.plgames -t plgames-server:latest .
   ```

## Технические детали

### Почему это работает

1. **Prisma требует нативные binary файлы** для query engine, которые должны соответствовать целевой платформе (Debian + OpenSSL 3.0.x)

2. **Sharp использует libvips** - нативную библиотеку для обработки изображений, которая должна быть установлена как на этапе сборки, так и runtime

3. **Yarn inline-builds** обеспечивает правильную компиляцию нативных модулей внутри Docker-окружения

### Совместимость

- Node.js: 22.x
- Debian: Bookworm (12)
- OpenSSL: 3.0.x
- Prisma: 5.19.1+
- Sharp: 0.33.5

## Changelog

### 2024-12-06
- Исправлена сборка @prisma/engines
- Добавлена поддержка Sharp
- Оптимизирован Dockerfile
- Создан .dockerignore
- Добавлена документация
