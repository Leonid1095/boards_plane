import type { CrmComment, CrmIssue, CrmProject, CrmSprint, CrmTimeLog } from '@prisma/client';

// GraphQL Types
export type CrmProjectWithRelations = CrmProject & {
  lead?: { id: string; name: string; email: string; avatarUrl?: string | null };
  issuesCount?: number;
  issues?: CrmIssueWithRelations[];
};

export type CrmIssueWithRelations = CrmIssue & {
  project?: CrmProject;
  assignee?: { id: string; name: string; email: string; avatarUrl?: string | null };
  reporter?: { id: string; name: string; email: string; avatarUrl?: string | null };
  sprint?: CrmSprint;
  parent?: CrmIssue;
  subtasks?: CrmIssue[];
  comments?: CrmCommentWithRelations[];
  timeLogs?: CrmTimeLogWithRelations[];
  commentsCount?: number;
  timeLogsCount?: number;
};

export type CrmCommentWithRelations = CrmComment & {
  author?: { id: string; name: string; email: string; avatarUrl?: string | null };
};

export type CrmTimeLogWithRelations = CrmTimeLog & {
  user?: { id: string; name: string; email: string; avatarUrl?: string | null };
};

export type CrmSprintWithRelations = CrmSprint & {
  project?: CrmProject;
  issues?: CrmIssue[];
  issuesCount?: number;
};

// Input Types
export interface CreateProjectInput {
  name: string;
  key: string;
  description?: string;
  workspaceId: string;
  leadId?: string;
}

export interface UpdateProjectInput {
  name?: string;
  key?: string;
  description?: string;
  leadId?: string;
}

export interface CreateIssueInput {
  title: string;
  description?: string;
  projectId: string;
  assigneeId?: string;
  reporterId: string;
  sprintId?: string;
  parentId?: string;
  status?: string;
  priority?: string;
  type?: string;
  storyPoints?: number;
  dueDate?: Date;
}

export interface UpdateIssueInput {
  title?: string;
  description?: string;
  assigneeId?: string;
  sprintId?: string;
  status?: string;
  priority?: string;
  type?: string;
  storyPoints?: number;
  dueDate?: Date;
}

export interface CreateSprintInput {
  name: string;
  goal?: string;
  projectId: string;
  startDate: Date;
  endDate: Date;
}

export interface UpdateSprintInput {
  name?: string;
  goal?: string;
  startDate?: Date;
  endDate?: Date;
  isActive?: boolean;
}

export interface CreateCommentInput {
  content: string;
  issueId: string;
  authorId: string;
}

export interface UpdateCommentInput {
  content: string;
}

export interface CreateTimeLogInput {
  issueId: string;
  userId: string;
  timeSpent: number;
  description?: string;
  loggedAt: Date;
}

export interface IssueFilters {
  status?: string;
  assigneeId?: string;
  sprintId?: string;
  type?: string;
  priority?: string;
}
