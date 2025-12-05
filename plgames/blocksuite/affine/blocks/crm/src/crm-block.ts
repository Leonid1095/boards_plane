import { CaptionedBlockComponent } from '@blocksuite/affine-components/caption';
import {
  menu,
  popMenu,
  popupTargetFromElement,
} from '@blocksuite/affine-components/context-menu';
import { toast } from '@blocksuite/affine-components/toast';
import type { BlockModel } from '@blocksuite/std';
import { BlockSelection } from '@blocksuite/std';
import { Slice } from '@blocksuite/store';
import { html, nothing } from 'lit';

import {
  CommentIcon,
  CopyIcon,
  DeleteIcon,
  MoreHorizontalIcon,
} from '@blocksuite/icons/lit';

// Define CRM block model interface
export interface CrmBlockModel extends BlockModel {
  props: {
    title: string;
    projectId?: string;
  };
}

export class CrmBlockComponent extends CaptionedBlockComponent<CrmBlockModel> {
  private readonly clickCrmOps = (e: MouseEvent) => {
    const options = {
      items: [
        menu.input({
          initialValue: this.model.props.title || 'CRM Board',
          placeholder: 'CRM Board title',
          onChange: text => {
            this.model.props.title = text;
          },
        }),
        menu.action({
          prefix: CommentIcon(),
          name: 'Comment',
          select: () => {
            // Add comment functionality
            toast(this.host, 'Comments coming soon!');
          },
        }),
        menu.action({
          prefix: CopyIcon(),
          name: 'Copy',
          select: () => {
            const slice = Slice.fromModels(this.store, [this.model]);
            this.std.clipboard
              .copySlice(slice)
              .then(() => {
                toast(this.host, 'Copied to clipboard');
              })
              .catch(console.error);
          },
        }),
        menu.action({
          prefix: DeleteIcon(),
          class: {
            'delete-item': true,
          },
          name: 'Delete CRM Board',
          select: () => {
            this.model.children.slice().forEach(block => {
              this.store.deleteBlock(block);
            });
            this.store.deleteBlock(this.model);
          },
        }),
      ],
    };

    popMenu(popupTargetFromElement(e.currentTarget as HTMLElement), {
      options,
    });
  };

  private renderCrmOps() {
    return html` <div
      data-testid="crm-ops"
      style="display: flex; align-items: center; justify-content: center; width: 24px; height: 24px; cursor: pointer; border-radius: 4px; hover: background-color: var(--affine-hover-color);"
      @click="${this.clickCrmOps}"
    >
      ${MoreHorizontalIcon()}
    </div>`;
  }

  private renderCrmContent() {
    return html`
      <div style="padding: 16px; border: 1px solid var(--affine-border-color); border-radius: 8px; background: var(--affine-white);">
        <div style="display: flex; align-items: center; gap: 8px; margin-bottom: 16px;">
          <h3 style="margin: 0; font-size: 18px; font-weight: 600;">
            ${this.model.props.title || 'CRM Board'}
          </h3>
          ${this.renderCrmOps()}
        </div>

        <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(300px, 1fr)); gap: 16px;">
          <!-- Backlog Column -->
          <div style="border: 1px solid var(--affine-border-color); border-radius: 6px; padding: 12px;">
            <h4 style="margin: 0 0 12px 0; font-size: 14px; font-weight: 600; color: var(--affine-text-secondary);">Backlog</h4>
            <div style="min-height: 100px; background: var(--affine-hover-color); border-radius: 4px; padding: 8px;">
              <p style="margin: 0; font-size: 12px; color: var(--affine-text-secondary);">Drop issues here</p>
            </div>
          </div>

          <!-- Todo Column -->
          <div style="border: 1px solid var(--affine-border-color); border-radius: 6px; padding: 12px;">
            <h4 style="margin: 0 0 12px 0; font-size: 14px; font-weight: 600; color: var(--affine-text-secondary);">To Do</h4>
            <div style="min-height: 100px; background: var(--affine-hover-color); border-radius: 4px; padding: 8px;">
              <p style="margin: 0; font-size: 12px; color: var(--affine-text-secondary);">Ready to work on</p>
            </div>
          </div>

          <!-- In Progress Column -->
          <div style="border: 1px solid var(--affine-border-color); border-radius: 6px; padding: 12px;">
            <h4 style="margin: 0 0 12px 0; font-size: 14px; font-weight: 600; color: var(--affine-text-secondary);">In Progress</h4>
            <div style="min-height: 100px; background: var(--affine-hover-color); border-radius: 4px; padding: 8px;">
              <p style="margin: 0; font-size: 12px; color: var(--affine-text-secondary);">Currently working</p>
            </div>
          </div>

          <!-- Done Column -->
          <div style="border: 1px solid var(--affine-border-color); border-radius: 6px; padding: 12px;">
            <h4 style="margin: 0 0 12px 0; font-size: 14px; font-weight: 600; color: var(--affine-text-secondary);">Done</h4>
            <div style="min-height: 100px; background: var(--affine-hover-color); border-radius: 4px; padding: 8px;">
              <p style="margin: 0; font-size: 12px; color: var(--affine-text-secondary);">Completed tasks</p>
            </div>
          </div>
        </div>

        <div style="margin-top: 16px; padding: 12px; background: var(--affine-hover-color); border-radius: 6px;">
          <p style="margin: 0; font-size: 14px; color: var(--affine-text-secondary);">
            🚧 CRM MVP: Basic kanban board structure. Full functionality coming in future updates.
          </p>
        </div>
      </div>
    `;
  }

  override renderBlock() {
    return html`
      <div contenteditable="false">
        ${this.renderCrmContent()}
      </div>
    `;
  }

  override accessor useZeroWidth = true;
}

declare global {
  interface HTMLElementTagNameMap {
    'affine-crm': CrmBlockComponent;
  }
}