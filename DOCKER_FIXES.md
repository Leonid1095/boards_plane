# Docker Configuration Fixes

## Critical Issues Fixed

### 1. **Missing Frontend Dockerfile**
**Problem:**
- `docker-compose.yml` and `docker-compose.prod.yml` referenced `packages/frontend/apps/web/Dockerfile` which didn't exist
- This caused `lstat: no such file or directory` errors during Docker build

**Solution:**
- Created `plgames/packages/frontend/apps/web/Dockerfile`
- Multi-stage build: Node.js builder → Nginx production server
- Includes proper build commands: `yarn plgames build -p web`
- Configured Nginx to serve static files and proxy API requests to backend

### 2. **Incorrect Dockerfile Path References**
**Problem:**
- Paths in docker-compose files used `./packages/...` which is incorrect when context is `./plgames`
- Docker couldn't locate the Dockerfile during build

**Solution:**
- Fixed in `docker-compose.yml`:
  ```yaml
  dockerfile: packages/frontend/apps/web/Dockerfile  # Removed leading ./
  ```
- Fixed in `docker-compose.prod.yml`:
  ```yaml
  dockerfile: packages/frontend/apps/web/Dockerfile  # Removed leading ./
  ```

### 3. **Backend Dockerfile (Dockerfile.plgames)**
**Status:** ✅ Already correct
- Properly located at `plgames/Dockerfile.plgames`
- Multi-stage build with all necessary dependencies
- Includes Rust for native module compilation
- Builds backend server: `yarn plgames build -p server`

## Docker Compose Structure

### Files:
1. **docker-compose.yml** - Development/Universal configuration
2. **docker-compose.prod.yml** - Production configuration
3. **docker-compose.simple.yml** - Backend-only (no frontend)

### Services:
- **backend**: PLGames API server (port 3010)
  - Built from `plgames/Dockerfile.plgames`
  - Includes health checks
  - Connected to PostgreSQL + Redis

- **frontend**: Web interface (port 8080)
  - Built from `plgames/packages/frontend/apps/web/Dockerfile`
  - Nginx serving static files
  - Proxies `/api` requests to backend

- **postgres**: PostgreSQL 16 with pgvector
  - Port 5432
  - Health checks configured

- **redis**: Redis cache
  - Alpine image for small footprint
  - Persistent storage

## Build Process

### Backend Build:
```dockerfile
1. Install Node.js 22 + system dependencies
2. Install Rust (for native modules)
3. Enable corepack (for Yarn)
4. Copy project files (packages, blocksuite, tools, etc.)
5. Run: yarn install
6. Run: yarn plgames build -p server
7. Copy built files to slim production image
```

### Frontend Build:
```dockerfile
1. Install Node.js 22 + system dependencies
2. Install Rust (for native modules)
3. Enable corepack (for Yarn)
4. Copy project files
5. Run: yarn install
6. Run: yarn plgames build -p web
7. Copy dist files to Nginx Alpine image
8. Configure Nginx for SPA routing + API proxy
```

## Testing the Fix

### Test Backend Only:
```bash
docker compose -f docker-compose.simple.yml up --build
```

### Test Full Stack:
```bash
docker compose up --build
```

### Test Production Config:
```bash
docker compose -f docker-compose.prod.yml up --build
```

## Common Issues and Solutions

### Issue: "package.json not found"
**Cause:** Missing package.json in plgames directory
**Solution:** Ensure plgames repository is properly cloned with all files

### Issue: "yarn install failed"
**Cause:** Network issues or missing dependencies
**Solution:**
- Check internet connection
- For Russia: Use `.npmrc.russia` for registry mirrors
- Increase Docker build timeout

### Issue: "Frontend not accessible"
**Cause:** Nginx configuration or build path issues
**Solution:**
- Check if `plgames/packages/frontend/apps/web/dist` exists after build
- Verify Nginx is running: `docker compose logs frontend`
- Check port mapping: 8080:80

## Verification Checklist

- ✅ Backend Dockerfile exists: `plgames/Dockerfile.plgames`
- ✅ Frontend Dockerfile exists: `plgames/packages/frontend/apps/web/Dockerfile`
- ✅ docker-compose.yml paths corrected
- ✅ docker-compose.prod.yml paths corrected
- ✅ All required files present in plgames directory
- ✅ Health checks configured for all services
- ✅ Volume mounts for data persistence
- ✅ Network configuration for inter-service communication

## Next Steps

1. **Commit Changes:**
   ```bash
   git add .
   git commit -m "fix: correct Docker configuration and add missing frontend Dockerfile"
   git push
   ```

2. **Test Deployment:**
   ```bash
   ./install-fixed.sh
   ```

3. **Monitor Services:**
   ```bash
   docker compose ps
   docker compose logs -f
   ```

## Summary of Changes

| File | Change | Status |
|------|--------|--------|
| `plgames/packages/frontend/apps/web/Dockerfile` | Created | ✅ New |
| `docker-compose.yml` | Fixed path | ✅ Modified |
| `docker-compose.prod.yml` | Fixed path | ✅ Modified |
| `plgames/Dockerfile.plgames` | No change needed | ✅ OK |

**All critical Docker configuration issues have been resolved!**
