# 📋 PLGames Production Deployment Checklist

Use this checklist before deploying to production.

## ✅ Pre-Deployment Checks

### 1. Server Requirements
- [ ] Server has minimum 4GB RAM (8GB recommended)
- [ ] Server has minimum 20GB disk space
- [ ] Server has external IP address
- [ ] Domain name configured (optional but recommended)
- [ ] SSH access configured
- [ ] Firewall rules allow ports 80, 443, 22

### 2. Repository Setup
- [ ] Repository cloned to `/home/plg/boards_plane` or custom directory
- [ ] Submodules updated: `git submodule update --init --recursive`
- [ ] Deploy script is executable: `chmod +x deploy_production.sh`
- [ ] Current branch is correct (main/master)

### 3. Environment Configuration
- [ ] Copy `.env.example` to `.env` if customizing before deployment
- [ ] Set `DOMAIN` variable in .env or export before deployment
- [ ] Generate secure passwords for database
- [ ] Review and configure optional features

## 🔧 Configuration Checklist

### Required Configuration
```bash
# .env file (auto-generated but verify after first run)
- [ ] DOMAIN is set correctly
- [ ] DATABASE_URL is configured
- [ ] DB_PASSWORD is secure (auto-generated)
- [ ] NODE_ENV=production
```

### Optional Configuration
```bash
# AI Features (OpenRouter)
- [ ] AFFINE_COPILOT_ENABLED=true
- [ ] AFFINE_COPILOT_OPENROUTER_API_KEY set
- [ ] AFFINE_COPILOT_OPENROUTER_MODEL selected

# OAuth (Yandex)
- [ ] OIDC_CLIENT_ID configured
- [ ] OIDC_CLIENT_SECRET configured
- [ ] OAuth app created at oauth.yandex.ru

# Email (SMTP)
- [ ] MAILER_HOST configured
- [ ] MAILER_USER configured
- [ ] MAILER_PASSWORD configured
```

## 🚀 Deployment Steps

### Step 1: Initial Deployment
```bash
- [ ] Run: sudo ./deploy_production.sh
- [ ] Wait for completion (15-30 minutes)
- [ ] Verify all containers are running
- [ ] Check logs for errors
```

### Step 2: Database Migration
```bash
- [ ] Migrations ran successfully (auto-executed by script)
- [ ] Database schema created
- [ ] CRM tables exist (crm_projects, crm_issues, etc.)
```

### Step 3: Service Verification
```bash
- [ ] Frontend accessible at http://SERVER_IP:8080
- [ ] Backend API responds at http://SERVER_IP:3010/api
- [ ] GraphQL playground at http://SERVER_IP:3010/graphql
- [ ] PostgreSQL container running
- [ ] Redis container running
```

## 🌐 HTTPS Setup (Recommended)

### Option A: Nginx + Let's Encrypt
```bash
- [ ] Nginx installed
- [ ] Nginx config created
- [ ] Config tested: sudo nginx -t
- [ ] Certbot installed
- [ ] SSL certificate obtained
- [ ] HTTPS accessible
```

### Option B: Caddy (Auto-HTTPS)
```bash
- [ ] Caddy installed
- [ ] Caddyfile created
- [ ] Caddy restarted
- [ ] Auto-HTTPS working
```

## 🔒 Security Checklist

### System Security
- [ ] UFW firewall enabled
- [ ] Only necessary ports open (80, 443, 22)
- [ ] SSH key authentication configured
- [ ] Sudo password set
- [ ] Automatic security updates enabled

### Application Security
- [ ] .env file permissions: chmod 600
- [ ] Database password changed from default
- [ ] SESSION_SECRET generated (if using)
- [ ] JWT_SECRET generated (if using)
- [ ] CORS configured properly
- [ ] Rate limiting enabled

### Backup Strategy
- [ ] Database backup script created
- [ ] Backup schedule configured (daily recommended)
- [ ] Backup storage location secured
- [ ] Restore procedure tested

## 📊 Monitoring & Maintenance

### Health Checks
```bash
- [ ] All Docker containers status: Up
- [ ] Disk space sufficient (check df -h)
- [ ] Memory usage normal (check free -m)
- [ ] CPU usage normal (check top)
```

### Logs Review
```bash
- [ ] Backend logs clean (no critical errors)
- [ ] Frontend logs clean
- [ ] Postgres logs clean
- [ ] Nginx/Caddy logs clean (if using)
```

### Regular Maintenance Tasks
- [ ] Weekly: Review logs for errors
- [ ] Weekly: Check disk space
- [ ] Monthly: Update system packages
- [ ] Monthly: Test backup restore
- [ ] Quarterly: Review security updates

## 🇷🇺 Russia-Specific Checks

### Network Optimization
- [ ] Docker mirrors configured (auto by script)
- [ ] NPM mirrors working (if needed)
- [ ] Region detected correctly by script
- [ ] Alternative registries accessible

### Performance
- [ ] Page load time acceptable
- [ ] API response time <2 seconds
- [ ] GraphQL queries fast
- [ ] WebSocket connections stable

## 📱 User Acceptance Testing

### Basic Functionality
- [ ] User can register/login
- [ ] OAuth login works (if configured)
- [ ] User can create workspace
- [ ] User can create project
- [ ] User can create issue
- [ ] User can comment on issue
- [ ] User can log time on issue
- [ ] Real-time updates work

### CRM Features
- [ ] Create CRM project
- [ ] Create issues with all types (Task, Bug, Story, Epic)
- [ ] Set issue status, priority, assignee
- [ ] Create and manage sprints
- [ ] Add comments to issues
- [ ] Log time on issues
- [ ] View project statistics

### AI Features (if enabled)
- [ ] AI assistant responds
- [ ] AI content generation works
- [ ] API key valid and has credits

## 🔄 Post-Deployment

### Documentation
- [ ] Update internal docs with server details
- [ ] Share access URLs with team
- [ ] Document admin credentials securely
- [ ] Create user guide for team

### Communication
- [ ] Notify team of deployment
- [ ] Schedule training session (if needed)
- [ ] Share support contact information
- [ ] Set up feedback channel

### Monitoring Setup
- [ ] Set up uptime monitoring (e.g., UptimeRobot)
- [ ] Configure error alerts
- [ ] Set up performance monitoring
- [ ] Enable analytics (if desired)

## 🆘 Emergency Contacts

```
Server Provider: _______________
Domain Registrar: _______________
SSL Provider: _______________
Database Admin: _______________
System Admin: _______________
```

## 📞 Rollback Procedure

If deployment fails:

```bash
# Stop all services
docker compose -f docker-compose.prod.yml down

# Restore from backup
docker compose -f docker-compose.prod.yml exec -T postgres psql -U plgames plgames < backup.sql

# Restart services
docker compose -f docker-compose.prod.yml up -d

# Check logs
docker compose -f docker-compose.prod.yml logs -f
```

## ✅ Final Sign-Off

- [ ] All critical items checked
- [ ] System accessible and functional
- [ ] Team notified
- [ ] Backups configured
- [ ] Monitoring in place
- [ ] Documentation updated

**Deployed by:** _______________
**Date:** _______________
**Time:** _______________
**Server:** _______________
**Domain:** _______________

---

**Deployment Status:** [ ] Success  [ ] Failed  [ ] Partial

**Notes:**
_____________________________________________
_____________________________________________
_____________________________________________
