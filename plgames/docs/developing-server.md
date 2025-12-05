This document covers running the PLGames backend (`@affine/server`) locally with Docker.

> **Warning**
>
> This document is community-maintained. Please submit a PR if you spot outdated steps.

## Development stack

The API depends on:

- PostgreSQL 16 (with the `pgvector` extension)
- Redis
- Mailhog (SMTP sandbox)

Start the stack:

```sh
cp ./.docker/dev/compose.yml.example ./.docker/dev/compose.yml
cp ./.docker/dev/.env.example ./.docker/dev/.env

docker compose -f ./.docker/dev/compose.yml up -d
```

> The default image is `pgvector/pgvector:pg16`. Change the tag if you use a different Postgres major version.

## Build native dependencies

```sh
# build sync/native bindings
corepack yarn plgames @affine/server-native build

# optional reader worker
corepack yarn plgames @affine/reader build
```

## Prepare environment variables

```sh
cp packages/backend/server/.env.example packages/backend/server/.env

# rerun after migrations change
corepack yarn plgames server init
```

## Start the API

```sh
corepack yarn plgames server dev
```

When the server boots it provisions demo accounts:

| Tier   | Email                      | Password | Members |
| ------ | -------------------------- | -------- | ------- |
| Dev    | dev@plgames.local        | dev      | 3       |
| Pro    | pro@plgames.local        | pro      | 10      |
| Team   | team@plgames.local       | team     | 10      |

## Start the frontend

```sh
corepack yarn dev
```

Open `http://localhost:8080` and sign in with the demo credentials above.

## Bonus commands

### Prisma Studio

```sh
# http://localhost:5555
corepack yarn plgames server prisma studio
```

### Database seed helpers

```sh
corepack yarn plgames server seed -h
```
