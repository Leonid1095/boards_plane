# PLGames Monorepo CLI

## Start

```bash
yarn plgames -h
```

### Run build command defined in package.json

```bash
yarn plgames i18n build
# or
yarn build -p i18n
```

### Run dev command defined in package.json

```bash
yarn plgames web dev
# or
yarn dev -p i18n
```

### Clean

```bash
yarn plgames clean --dist --rust
# clean node_modules
yarn plgames clean --node-modules
```

### Init

> Generate files that make the monorepo work properly, the per project codegen will not be included anymore

```bash
yarn plgames init
```

## Tricks

### Define scripts to run a .ts files without `--loader ts-node/esm/transpile-only`

`plgames run` automatically injects the ts-node transpile service (SWC) for scripts.

```json
{
  "name": "@affine/demo",
  "scripts": {
    "dev": "node ./dev.ts"
  }
}
```

```bash
plgames @affine/demo dev
```

or

```json
{
  "name": "@affine/demo",
  "scripts": {
    "dev": "r ./src/index.ts"
  },
  "devDependencies": {
    "@affine-tools/cli": "workspace:*"
  }
}
```

### Short your key presses

```bash
# Add your own alias, e.g. `pg`
yarn pg web build
```

#### by custom shell script

Create file `pg` in the root of the project with the following content:

```bash
#!/usr/bin/env sh
./tools/scripts/bin/runner.js affine.ts $@
```

or on windows:

```cmd
node "./tools/cli/bin/runner.js" affine.ts %*
```

and give it executable permission

```bash
chmod a+x ./pg

# now you can run scripts with simply
./pg web build
```

if you want to go further, but for vscode(or other forks) only, add the following to your `.vscode/settings.json`

```json
{
  "terminal.integrated.env.osx": {
    "PATH": "${env:PATH}:${cwd}"
  },
  "terminal.integrated.env.linux": {
    "PATH": "${env:PATH}:${cwd}"
  },
  "terminal.integrated.env.windows": {
    "PATH": "${env:PATH};${cwd}"
  }
}
```

restart all the integrated terminals and now you get:

```bash
pg web build
```

```

```
