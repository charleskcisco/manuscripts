#!/usr/bin/env bash
# app-setup.sh — Install system dependencies and set up Manuscripts.
# Run once on a fresh device, then run device-setup.sh.

set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== Manuscripts App Setup ==="
echo ""

# System update
echo "Updating system packages..."
sudo apt update
sudo apt upgrade -y

# System packages
echo "Installing required packages..."
sudo apt install -y \
    micro ranger \
    pandoc libreoffice \
    cups cups-client lpr \
    git cage foot \
    fonts-jetbrains-mono \
    python3 python3-pip python3-venv

# Python venv + Manuscripts dependencies
echo "Setting up Python environment..."
if [ ! -d "${SCRIPT_DIR}/.venv" ]; then
    echo "  Creating virtual environment..."
    python3 -m venv "${SCRIPT_DIR}/.venv"
fi

echo "  Installing Python dependencies..."
"${SCRIPT_DIR}/.venv/bin/pip" install --quiet \
    prompt_toolkit pygments aiohttp zeroconf

echo ""
echo "All done. Run Manuscripts with: ./run.sh"
echo ""
echo "Rebooting in 5 seconds to apply updates (Ctrl+C to cancel)..."
sleep 5
sudo reboot now
