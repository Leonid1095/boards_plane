# PLGames CRM

PLGames ships with a lightweight CRM/work management layer that fits tech teams (Jira-like boards with simpler defaults) and sales/support backlogs.

## Concepts

- **Projects**: top-level containers with key (e.g. `APP`), description, lead, workspace binding.
- **Issues**: TASK, BUG, STORY, EPIC, SUBTASK with status (BACKLOG, TODO, IN_PROGRESS, IN_REVIEW, DONE, CANCELLED), priority (LOWEST → HIGHEST), assignee/reporter, story points, due date, and custom fields.
- **Sprints**: name, start/end dates, optional goal, burndown-ready.
- **Comments & time logs**: threaded comments and per-issue time tracking.

## Frontend

- Kanban board with drag-and-drop across status columns (Backlog, To Do, In Progress, Done by default).
- Issue drawer/cards show priority, type, assignee, due date, story points, and custom fields.
- Sprint selector and backlog grooming inside the CRM block (`blocksuite/affine/blocks/crm/`).
- Styling aligns with the main PLGames UI theme; i18n branding is applied at runtime.

## Backend

- Prisma models: `CrmProject`, `CrmIssue`, `CrmSprint`, `CrmComment`, `CrmTimeLog` in `packages/backend/server/schema.prisma`.
- Service layer: `CrmProjectModel` and `CrmIssueModel` expose CRUD and filtered queries.
- API endpoints are wired through the NestJS server; see `packages/backend/server/src/models/` and related GraphQL/resolvers.

## Quick API usage

```ts
// Create project
const project = await models.crmProject.create({
  name: 'My Project',
  key: 'APP',
  description: 'Project description',
  workspaceId: 'workspace-uuid',
  leadId: 'user-uuid',
});

// Create issue
const issue = await models.crmIssue.create({
  title: 'Implement login',
  description: 'User authentication feature',
  status: IssueStatus.TODO,
  priority: IssuePriority.HIGH,
  type: IssueType.TASK,
  projectId: project.id,
  reporterId: 'user-uuid',
  dueDate: new Date().toISOString(),
  storyPoints: 3,
});
```

## Setup and seeding

```bash
# Generate Prisma client
npx prisma generate --schema=packages/backend/server/schema.prisma

# Apply migrations
npx prisma migrate dev

# Start services
yarn plgames server dev
yarn dev
```

## Roadmap

- Advanced workflows: custom statuses, transitions, automations.
- Reports: burndown charts, velocity, SLA dashboards.
- Integrations: webhooks, issue import/export.
- Mobile polish for board interactions.
