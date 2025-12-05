FROM node:22-alpine AS builder

WORKDIR /app

RUN apk add --no-cache python3 make g++ git
RUN corepack enable

COPY . .

RUN yarn install
RUN yarn plgames @affine/web build

FROM caddy:2-alpine AS runner

COPY --from=builder /app/packages/frontend/apps/web/dist /usr/share/caddy
COPY --from=builder /app/packages/frontend/apps/web/package.json /usr/share/caddy/package.json
COPY ./packages/frontend/apps/web/Caddyfile /etc/caddy/Caddyfile

EXPOSE 80

CMD ["caddy", "run", "--config", "/etc/caddy/Caddyfile", "--adapter", "caddyfile"]
