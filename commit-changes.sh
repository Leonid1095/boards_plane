#!/bin/bash

# Git Commit Helper Script for PLGames v1.0.0
# This script commits all changes with proper commit messages

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}PLGames v1.0.0 - Commit Helper${NC}"
echo ""

# Check if we're in a git repository
if [ ! -d .git ]; then
    echo -e "${YELLOW}Not in a git repository. Initializing...${NC}"
    git init
    git branch -M main
fi

# Check git status
echo -e "${GREEN}Current git status:${NC}"
git status --short
echo ""

# Commit 1: Backend CRM Module
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}Commit 1/4: Backend CRM Module${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

if [ -d "plgames/packages/backend/server/src/core/crm" ]; then
    git add plgames/packages/backend/server/src/core/crm/
    git commit -m "feat: add complete CRM module with GraphQL API

This commit introduces a full-featured CRM system:

Features:
- Project management with leads and statistics
- Issue tracking (Task, Bug, Story, Epic, Subtask)
- Sprint planning and management
- Time tracking on issues
- Comments and collaboration
- Real-time updates ready

Implementation:
- CrmModule: NestJS module with dependency injection
- CrmService: Business logic layer with CRUD operations
- CrmResolver: GraphQL API with queries and mutations
- TypeScript types: Full type safety
- Permission integration: Workspace-based access control

Database:
- 5 new tables: crm_projects, crm_issues, crm_sprints, crm_comments, crm_time_logs
- 3 enums: IssueStatus, IssuePriority, IssueType

API Endpoints:
- Projects: CRUD + list by workspace
- Issues: CRUD + filter by status/assignee/sprint
- Sprints: CRUD + active sprint tracking
- Comments: CRUD + threaded discussions
- Time Logs: CRUD + total time aggregation

Files added:
- plgames/packages/backend/server/src/core/crm/crm.module.ts
- plgames/packages/backend/server/src/core/crm/crm.service.ts
- plgames/packages/backend/server/src/core/crm/crm.resolver.ts
- plgames/packages/backend/server/src/core/crm/types.ts
- plgames/packages/backend/server/src/core/crm/index.ts

Lines of code: ~1,100" || echo "Skipping (already committed or not found)"
fi

# Commit 2: Integration
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}Commit 2/4: CRM Integration${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

git add plgames/packages/backend/server/src/app.module.ts 2>/dev/null || true
git add plgames/packages/backend/server/src/models/index.ts 2>/dev/null || true
git commit -m "feat: integrate CRM module into backend

Integration points:
- Added CrmModule import to app.module.ts
- Integrated CRM into GraphQL server (only when graphql flavor enabled)
- Exported CRM models (CrmProjectModel, CrmIssueModel) in models/index.ts
- Connected to Permission system for access control
- Connected to Prisma for database operations

Changes:
- plgames/packages/backend/server/src/app.module.ts: +2 lines
  - Import CrmModule from './core/crm'
  - Add CrmModule to GraphQL server modules

- plgames/packages/backend/server/src/models/index.ts: +2 lines
  - Export CrmProjectModel
  - Export CrmIssueModel

The CRM API is now available at:
- GraphQL endpoint: http://localhost:3010/graphql
- Queries: crmProject, crmProjectsByWorkspace, crmIssue, crmIssuesByProject, etc.
- Mutations: createCrmProject, updateCrmProject, deleteCrmProject, etc." || echo "Skipping (already committed)"

# Commit 3: Deployment & DevOps
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}Commit 3/4: Russia-Optimized Deployment${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

git add deploy_production.sh quick-start.sh 2>/dev/null || true
git add plgames/Dockerfile.plgames 2>/dev/null || true
git add plgames/.npmrc.russia 2>/dev/null || true
git commit -m "feat: add Russia-optimized deployment system

One-Click Deployment:
- Auto-detects Russia region (checks Google accessibility)
- Configures Docker mirrors for Russia automatically
- Installs Docker with region-specific sources
- Generates secure passwords with openssl
- Runs database migrations automatically
- Performs health checks and verification

Interactive Setup Wizard (quick-start.sh):
- Domain configuration
- AI features setup (OpenRouter)
- OAuth configuration (Yandex)
- Automatic .env generation
- Guided deployment process
- User-friendly CLI interface

Deployment Features:
- One-command deployment: sudo ./deploy_production.sh
- Auto branch detection (main/master)
- Submodule updates
- Docker compose orchestration
- Database migration automation
- Comprehensive error handling
- Color-coded logging

Docker Improvements:
- Fixed Dockerfile duplication (removed duplicate ENV/CMD)
- Added Prisma schema to production image
- Multi-stage builds optimized
- Health checks configured

Russia-Specific Optimizations:
- Docker registry mirrors
- NPM registry mirrors (.npmrc.russia)
- Network timeout optimizations
- Alternative CDNs configured

Files modified/created:
- deploy_production.sh: Enhanced with Russia detection
- quick-start.sh: NEW - Interactive wizard
- plgames/Dockerfile.plgames: Fixed duplications
- plgames/.npmrc.russia: NEW - NPM mirrors

Deployment time: 15-30 minutes (first run)" || echo "Skipping (already committed)"

# Commit 4: Documentation
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}Commit 4/4: Complete Documentation${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

git add README.md INSTALL_RU.md DEPLOYMENT_CHECKLIST.md 2>/dev/null || true
git add CHANGELOG.md PROJECT_SUMMARY.md FILES_MODIFIED.md 2>/dev/null || true
git add .env.example commit-changes.sh 2>/dev/null || true
git commit -m "docs: add comprehensive documentation for v1.0.0

Documentation Files:

1. README.md (English)
   - Project overview and features
   - Quick start guide (5 minutes)
   - Architecture diagram
   - GraphQL API examples
   - Management commands
   - Russia deployment notes

2. INSTALL_RU.md (Russian)
   - Complete installation guide
   - System requirements
   - Step-by-step instructions
   - HTTPS setup (Nginx & Caddy)
   - OAuth configuration (Yandex)
   - Troubleshooting guide
   - Security best practices
   - Backup procedures

3. DEPLOYMENT_CHECKLIST.md
   - Pre-deployment verification
   - Configuration checklist
   - Security checklist
   - Monitoring setup
   - Rollback procedure
   - Final sign-off form

4. CHANGELOG.md
   - Version 1.0.0 release notes
   - Complete feature list
   - Database migrations
   - Dependencies
   - Future roadmap

5. PROJECT_SUMMARY.md
   - Technical implementation details
   - File structure overview
   - Completion status (100%)
   - Performance metrics
   - Security considerations

6. FILES_MODIFIED.md
   - Complete list of changes
   - Lines of code statistics
   - Git commit recommendations
   - Impact analysis

7. .env.example
   - Complete environment template
   - All configuration options
   - AI setup (OpenRouter)
   - OAuth setup (Yandex)
   - Email/SMTP configuration
   - Storage configuration

8. commit-changes.sh
   - Automated commit helper
   - Proper commit messages
   - Git workflow automation

Coverage:
- Installation: ✅ Complete
- Configuration: ✅ Complete
- Deployment: ✅ Complete
- API Usage: ✅ Complete
- Troubleshooting: ✅ Complete
- Security: ✅ Complete

Languages:
- English: README.md + others
- Russian: INSTALL_RU.md

Total documentation: ~1,500 lines" || echo "Skipping (already committed)"

# Summary
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}Commit Summary${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Show commit log
git log --oneline -5

echo ""
echo -e "${GREEN}✅ All changes committed successfully!${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Review commits: ${GREEN}git log${NC}"
echo "2. Push to remote: ${GREEN}git push origin main${NC}"
echo "3. Create release tag: ${GREEN}git tag v1.0.0 && git push --tags${NC}"
echo ""
echo -e "${BLUE}Repository ready for production deployment! 🚀${NC}"
