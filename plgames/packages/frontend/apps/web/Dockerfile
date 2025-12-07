FROM node:22-bookworm AS builder

WORKDIR /app

RUN apt-get update && apt-get install -y \
    python3 \
    make \
    g++ \
    gcc \
    git \
    curl \
    ca-certificates \
    openssl \
    libssl-dev \
    libc6-dev \
    pkg-config \
    libvips-dev \
    libvips-tools \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Install Rust for native modules
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"

RUN corepack enable

# Prisma environment variables
ENV PRISMA_ENGINES_CHECKSUM_IGNORE_MISSING=1
ENV PRISMA_CLI_BINARY_TARGETS=native,debian-openssl-3.0.x
ENV PRISMA_QUERY_ENGINE_BINARY=debian-openssl-3.0.x
ENV PRISMA_ENGINES_MIRROR=https://binaries.prisma.sh

COPY . .

# Install dependencies WITHOUT running postinstall (skip init & husky in Docker)
RUN yarn install --immutable --mode=skip-build 2>/dev/null || yarn install --ignore-scripts

# Build frontend
RUN yarn plgames @affine/web build

FROM caddy:2-alpine AS runner

COPY --from=builder /app/packages/frontend/apps/web/dist /usr/share/caddy
COPY --from=builder /app/packages/frontend/apps/web/package.json /usr/share/caddy/package.json
COPY ./packages/frontend/apps/web/Caddyfile /etc/caddy/Caddyfile

EXPOSE 80

CMD ["caddy", "run", "--config", "/etc/caddy/Caddyfile", "--adapter", "caddyfile"]
