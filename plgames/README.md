# Boards Plane

Boards Plane - это комплексный хаб для совместной работы, объединяющий документы, бесконечные доски, канбан-доски и многопользовательские ИИ-инструменты в едином рабочем пространстве.

## Основные возможности

- Единое полотно — переключайтесь между структурированными документами, досками и бесконечными холстами.
- Готов к CRM — Канбан-доски, задачи, спринты и управление бэклогом.
- Синхронизация в первую очередь оффлайн — локальные рабочие пространства с опциональным облачным резервным копированием и sharing.
- Нативный ИИ — ИИ Boards Plane для чата, суммаризации и генерации шаблонов.
- Дружелюбный к само-хостингу — Docker-контейнеры Postgres/Redis/Mail для быстрого развертывания.

## Быстрая установка (Ubuntu 24.04+)

```bash
curl -fsSL https://raw.githubusercontent.com/Leonid1095/boards_plane/main/scripts/install-plgames.sh | bash
```

Установщик:
- Устанавливает Node.js 22, Yarn 4.9, Rust, Docker.
- Клонирует/обновляет репозиторий и запускает `corepack yarn plgames init`.
- Собирает нативные модули и запускает Docker Compose стек.
- Запрашивает ваш домен; оставьте пустым для локального доступа и введите IP/hostname позже.

### Ручная установка

```bash
git clone https://github.com/Leonid1095/boards_plane.git
cd plgames
corepack enable
corepack yarn install --immutable
corepack yarn plgames init
corepack yarn dev                    # Web клиент + desktop оболочка
corepack yarn plgames server dev     # Backend API (требует docker compose стек)
```

## Продакшн развертывание

`scripts/deploy-prod.sh` разворачивает полный стек (Node сервер, Docker-контейнеры Postgres/Redis, Caddy HTTPS фронтенд) на Ubuntu 24:

```bash
sudo PLG_DOMAIN=your-domain.com \
     PLG_ADMIN_EMAIL=ops@your-domain.com \
     PLG_DB_PASSWORD='your-strong-pass' \
     bash scripts/deploy-prod.sh
```

Ключевые переменные окружения:

| Переменная         | Описание (по умолчанию)               |
| ------------------ | ------------------------------------- |
| `PLG_DOMAIN`       | Публичный домен (устанавливается явно) |
| `PLG_INSTALL_DIR`  | Директория развертывания (`/opt/plgames`) |
| `PLG_SERVER_PORT`  | Внутренний порт API (`3010`)          |
| `PLG_DB_USER/NAME` | Postgres учетные данные (`plgames`)   |
| `PLG_DB_PASSWORD`  | Postgres пароль (генерируется если пусто) |

Скрипт устанавливает зависимости, клонирует репозиторий, собирает рабочее пространство, запускает Docker сервисы, выполняет миграции, размещает веб-клиент в `/var/www/plgames`, настраивает Caddy для HTTPS и создает systemd unit `plgames-server`.

## CLI и скрипты рабочего пространства

Используйте точку входа PLGames CLI `yarn plgames ...` для команд рабочего пространства.

Примеры:

```
corepack yarn plgames @affine/web dev
corepack yarn plgames @affine/server-native build
corepack yarn plgames server prisma studio
```

`corepack yarn dev` запускает Turbo задачи для всех приложений.

## Управление брендингом

- Источник: `packages/common/env/src/brand.ts`
  - Названия продукта/ИИ/облака
  - URL маркетинга/документации (настраивается через `PLG_BASE_URL`)
  - Email поддержки (настраивается через `PLG_SUPPORT_EMAIL`)
- i18n строки ребрендируются во время выполнения через пост-процессор `branding` i18next (`packages/frontend/i18n/src/post-processors/branding.ts`).

## Рабочий процесс само-хостинга

1. `corepack yarn plgames server init` — применяет миграции и создает демо-аккаунты.
2. `corepack yarn plgames server dev` — запускает NestJS бэкенд.
3. `corepack yarn dev` — запускает React desktop/web оболочку.
4. Демо-логины по умолчанию находятся в `docs/developing-server.md`.

Docker стек (`.docker/dev/compose.yml`) предоставляет PostgreSQL на `localhost:5432`, Redis на `localhost:6379`, и Mailpit на `localhost:8025`.

## Полезная документация

- `docs/CRM.md` — функциональность CRM и доски.
- `docs/developing-server.md` — инструкции по запуску бэкенда.
- `docs/BUILDING.md` — сборка мобильных/desktop целей.
- `tools/cli/README.md` — опции CLI и troubleshooting.

## Поддержка

- Issues: `https://github.com/Leonid1095/boards_plane/issues`

## Лицензия

Boards Plane использует двойную лицензию: MIT для пакетов Blocksuite и AGPL для приложения. Смотрите `LICENSE` и `LICENSE-MIT`.
