# PLGames CRM MVP Summary

## Overview

- Fully branded PLGames workspace with CRM built-in (projects, issues, sprints).
- Kanban-first UX with quick status changes and backlog grooming.
- AI helpers available through Copilot/OpenRouter providers.
- Paywall disabled for self-hosted installs.

## Scope (MVP)

- Data models: `CrmProject`, `CrmIssue`, `CrmSprint`, `CrmComment`, `CrmTimeLog`.
- Prisma-backed storage, CRUD services, and API exposure.
- Frontend CRM block (board and detail drawer) aligned with PLGames styling.
- i18n branding post-processor ensures no legacy names leak to users.

## Stack map

- Frontend: `packages/frontend/core/src/modules/crm-block/` and CRM-related i18n.
- Backend: `packages/backend/server/src/models/crm-*.ts`, `schema.prisma`, Copilot plugins.
- Scripts: `scripts/test-crm-basic.mjs`, `scripts/deploy-with-crm.sh`.

## Usage

```bash
corepack yarn install
corepack yarn plgames init
corepack yarn plgames server dev   # backend
corepack yarn dev                  # frontend
node scripts/test-crm-basic.mjs    # quick sanity check
```

## Feature checklist

- Projects with keys, leads, and workspace binding.
- Issues with status, priority, type, assignee/reporter, due date, story points, custom fields.
- Sprints with goals and date ranges.
- Comments and time logging.
- Kanban drag-and-drop and backlog view.

## Next steps (nice-to-have)

- Workflow automation and custom status sets.
- Reports: burndown, velocity, SLA dashboards.
- Webhooks and import/export integrations.
- Mobile polish for board interactions.
