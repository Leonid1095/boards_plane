import { z } from 'zod';

import { BRAND } from '@affine/env/brand';

export const appSchemes = z.enum([
  'affine',
  'affine-canary',
  'affine-beta',
  'affine-internal',
  'affine-dev',
]);

export type Scheme = z.infer<typeof appSchemes>;
export type Channel = 'stable' | 'canary' | 'beta' | 'internal';

export const schemeToChannel = {
  affine: 'stable',
  'affine-canary': 'canary',
  'affine-beta': 'beta',
  'affine-internal': 'internal',
  'affine-dev': 'canary', // dev does not have a dedicated app. use canary as the placeholder.
} as Record<Scheme, Channel>;

export const channelToScheme = {
  stable: 'affine',
  canary: BUILD_CONFIG.debug ? 'affine-dev' : 'affine-canary',
  beta: 'affine-beta',
  internal: 'affine-internal',
} as Record<Channel, Scheme>;

export const appIconMap = {
  stable: '/imgs/app-icon-stable.ico',
  canary: '/imgs/app-icon-canary.ico',
  beta: '/imgs/app-icon-beta.ico',
  internal: '/imgs/app-icon-internal.ico',
} satisfies Record<Channel, string>;

const BASE_APP_NAME = BRAND.productName;
export const appNames = {
  stable: BASE_APP_NAME,
  canary: `${BASE_APP_NAME} Canary`,
  beta: `${BASE_APP_NAME} Beta`,
  internal: `${BASE_APP_NAME} Internal`,
} satisfies Record<Channel, string>;

export const appSchemaUrl = z.custom<string>(
  (url: string) => {
    try {
      return appSchemes.safeParse(new URL(url).protocol.replace(':', ''))
        .success;
    } catch {
      return false;
    }
  },
  { message: 'Invalid URL or protocol' }
);
