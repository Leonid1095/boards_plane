# iOS

AFFiNE iOS app.

## Build

- `yarn install`
- `BUILD_TYPE=canary PUBLIC_PATH="/" yarn plgames @affine/ios build`
- `yarn plgames @affine/ios cap sync`
- `yarn plgames @affine/ios cap open ios`

## Live Reload

> Capacitor doc: https://capacitorjs.com/docs/guides/live-reload#using-with-framework-clis

- `yarn install`
- `yarn dev`
  - select `ios` for the "Distribution" option
- `yarn plgames @affine/ios sync:dev`
- `yarn plgames @affine/ios cap open ios`
