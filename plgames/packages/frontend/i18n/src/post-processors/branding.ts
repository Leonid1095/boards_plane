import type { PostProcessorModule } from 'i18next';

import { applyBranding } from '@affine/env/brand';

export const brandingPostProcessor: PostProcessorModule = {
  name: 'branding',
  type: 'postProcessor',
  process(value) {
    return applyBranding(value) as string;
  },
};
