# Android

AFFiNE Android app.

## Setup

- set CARGO_HOME to your system environment
- add

  `rust.cargoCommand={replace_with_your_own_cargo_home_absolute_path}/bin/cargo`

  `rust.rustcCommand={replace_with_your_own_cargo_home_absolute_path}/bin/rustc`

  to App/local.properties

## Build

- yarn install
- BUILD_TYPE=canary PUBLIC_PATH="/" yarn plgames @affine/android build
- yarn plgames @affine/android cap sync
- yarn plgames @affine/android cap open android
