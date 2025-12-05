# Building PLGames Web

> **Warning**:
>
> This document is not guaranteed to be up-to-date.
> If you find any outdated information, please feel free to open an issue or submit a PR.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Setup Environment](#setup-environment)
- [Start Development Server](#start-development-server)
- [Testing](#testing)

## Prerequisites

PLGames relies on both **Node.js** and **Rust** toolchains.

### Install Node.js

The project targets Node.js 22.x (see `.nvmrc`).

#### Option 1: Manual install

Install the latest [Node.js 22.x build](https://nodejs.org/en/download).

#### Option 2: Node version manager

Install [fnm](https://github.com/Schniz/fnm) (or your preferred manager) and run:

```sh
fnm use
```

### Install Rust Tools

Follow https://www.rust-lang.org/tools/install to install `rustup` and the stable toolchain.

### Setup Node.js Environment

PLGames uses Yarn 4.9+ (via Corepack). Enable it once:

```sh
corepack enable
corepack prepare yarn@stable --activate
```

```sh
corepack yarn install --immutable
```

### Clone repository

#### Linux & MacOS

```sh
git clone https://github.com/PLGamesHQ/plgames.git
```

#### Windows

The repo contains symbolic links. Enable Developer Mode and run PowerShell as administrator before cloning.

References:
- [Security Policy Settings for Creating Symbolic Links](https://learn.microsoft.com/en-us/windows/security/threat-protection/security-policy-settings/create-symbolic-links)
- [Enable Developer Mode on Windows](https://learn.microsoft.com/en-us/windows/apps/get-started/enable-your-device-for-development)

```sh
# Enable symbolic links
git config --global core.symlinks true
git clone https://github.com/PLGamesHQ/plgames.git
```

### Build Native Dependencies

Run the following script to build the Blocksuite native layer inside [`packages/frontend/native`](../packages/frontend/native) via [NAPI.rs](https://napi.rs). The first build can take several minutes.

```sh
corepack yarn plgames @affine/native build
```

### Build Server Dependencies

```sh
corepack yarn plgames @affine/server-native build
```

## Testing

Adding test cases is strongly encouraged when you contribute new features and bug fixes.

We use [Playwright](https://playwright.dev/) for E2E test, and [vitest](https://vitest.dev/) for unit test.
To test locally, please make sure browser binaries are already installed via `npx playwright install`.

Start server before tests by following [`docs/developing-server.md`](./developing-server.md) first.

### Unit Test

```sh
yarn test
```

### E2E Test

```shell
# e2e suites:
# - affine-local
# - affine-migration
# - affine-prototype
corepack yarn workspace @affine-test/affine-local e2e
```
