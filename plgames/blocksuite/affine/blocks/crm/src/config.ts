import { BlockViewType, type ExtensionType } from '@blocksuite/block-std';
import { literal } from 'lit/static-html.js';

import { CrmBlock } from './crm-block.js';

export const CrmBlockSpec: ExtensionType[] = [
  CrmBlock,
  BlockViewType.display({
    view: literal`affine-crm`,
    block: CrmBlock,
  }),
];