#!/bin/bash
# Prepare Ubuntu server for PLGames build (8GB RAM)
# Run with: sudo bash prepare-server.sh

set -e

echo "🔧 Подготовка сервера для сборки PLGames..."
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "❌ Запустите с sudo: sudo bash prepare-server.sh"
    exit 1
fi

# Check current memory
echo "📊 Текущая конфигурация памяти:"
free -h

TOTAL_RAM=$(free -g | awk '/^Mem:/{print $2}')
SWAP_SIZE=$(free -g | awk '/^Swap:/{print $2}')

echo ""
echo "RAM: ${TOTAL_RAM}GB"
echo "SWAP: ${SWAP_SIZE}GB"

# If swap is less than 4GB, create/increase it
if [ "$SWAP_SIZE" -lt 4 ]; then
    echo ""
    echo "⚠️  SWAP меньше 4GB, создаем swap файл на 4GB..."

    # Check if swapfile already exists
    if [ -f /swapfile ]; then
        echo "Отключаем существующий swap..."
        swapoff /swapfile 2>/dev/null || true
        rm -f /swapfile
    fi

    # Create 4GB swap file
    echo "Создаем swap файл 4GB (это займет ~2 минуты)..."
    dd if=/dev/zero of=/swapfile bs=1M count=4096 status=progress

    chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile

    # Make it permanent
    if ! grep -q '/swapfile' /etc/fstab; then
        echo '/swapfile none swap sw 0 0' >> /etc/fstab
    fi

    echo "✅ Swap создан и активирован"
else
    echo "✅ SWAP уже достаточный (${SWAP_SIZE}GB)"
fi

# Adjust swappiness for better performance during build
echo ""
echo "⚙️  Настройка swappiness для оптимизации сборки..."
sysctl vm.swappiness=10
if ! grep -q 'vm.swappiness' /etc/sysctl.conf; then
    echo 'vm.swappiness=10' >> /etc/sysctl.conf
fi

echo ""
echo "📊 Финальная конфигурация:"
free -h

echo ""
echo "✅ Сервер подготовлен для сборки!"
echo ""
echo "Следующие шаги:"
echo "  1. cd ~/plane"
echo "  2. git pull origin main"
echo "  3. bash build.sh"
