import { Module } from '@nestjs/common';

import { CrmIssueModel, CrmProjectModel } from '../../models';
import { PermissionModule } from '../permission';
import {
  CrmCommentResolver,
  CrmIssueResolver,
  CrmProjectResolver,
  CrmSprintResolver,
  CrmTimeLogResolver,
} from './crm.resolver';
import { CrmService } from './crm.service';

@Module({
  imports: [PermissionModule],
  providers: [
    CrmService,
    CrmProjectModel,
    CrmIssueModel,
    CrmProjectResolver,
    CrmIssueResolver,
    CrmSprintResolver,
    CrmCommentResolver,
    CrmTimeLogResolver,
  ],
  exports: [CrmService],
})
export class CrmModule {}
