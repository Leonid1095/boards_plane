#!/bin/bash
set -e

# Define project root
PROJECT_ROOT="/opt/plgames"

# Navigate to project root
cd "$PROJECT_ROOT"

echo "🚀 Starting PLGames Server Setup..."

# 1. Install dependencies
echo "📦 Installing dependencies..."
corepack yarn install

# 2. Build the server
echo "hammer_and_wrench: Building server..."
# We use the monorepo tool to build the server package specifically
corepack yarn plgames build -p server

# 3. Start the server
echo "✅ Build successful. Starting server..."
# Using the built file in dist
export NODE_ENV=production

# Check if dist/main.js exists
if [ -f "packages/backend/server/dist/main.js" ]; then
    node packages/backend/server/dist/main.js
else
    echo "❌ Error: packages/backend/server/dist/main.js not found after build."
    exit 1
fi
