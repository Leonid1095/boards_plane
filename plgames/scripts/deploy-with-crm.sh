#!/usr/bin/env bash
set -euo pipefail

# Simple wrapper to deploy PLGames with CRM enabled using deploy-prod.sh

prompt() {
  local message="$1"
  local default="$2"
  local var
  read -r -p "${message} [${default}]: " var
  echo "${var:-$default}"
}

echo ""
echo "PLGames CRM deployment helper"
echo "------------------------------"

DOMAIN="${PLG_DOMAIN:-}"
if [[ -z "${DOMAIN}" ]]; then
  DOMAIN=$(prompt "Enter domain (leave blank for local host/IP)" "${PLG_LOCAL_HOST:-localhost}")
fi

ADMIN_EMAIL="${PLG_ADMIN_EMAIL:-admin@${DOMAIN:-localhost}}"
ADMIN_EMAIL=$(prompt "Admin email" "${ADMIN_EMAIL}")

DB_PASSWORD="${PLG_DB_PASSWORD:-}"
if [[ -z "${DB_PASSWORD}" ]]; then
  DB_PASSWORD=$(openssl rand -hex 16)
  echo "Generated DB password: ${DB_PASSWORD}"
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo ""
echo "Running deploy-prod.sh with:"
echo "  DOMAIN=${DOMAIN}"
echo "  ADMIN_EMAIL=${ADMIN_EMAIL}"
echo ""

sudo PLG_DOMAIN="${DOMAIN}" \
  PLG_ADMIN_EMAIL="${ADMIN_EMAIL}" \
  PLG_DB_PASSWORD="${DB_PASSWORD}" \
  bash "${SCRIPT_DIR}/deploy-prod.sh"
