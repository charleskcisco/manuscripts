#!/usr/bin/env bash
# install-debian.sh — Install dependencies for manuscripts on Debian/Ubuntu.
set -euo pipefail

echo "==> Updating package lists…"
sudo apt-get update

echo "==> Installing Python 3 and pip…"
sudo apt-get install -y python3 python3-pip

echo "==> Installing pandoc…"
sudo apt-get install -y pandoc

echo "==> Installing LibreOffice…"
sudo apt-get install -y libreoffice

echo "==> Installing Microsoft core fonts (Times New Roman)…"
echo ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true \
  | sudo debconf-set-selections
sudo apt-get install -y ttf-mscorefonts-installer

echo "==> Rebuilding font cache…"
sudo fc-cache -f

echo "==> Installing Python dependencies…"
pip3 install --user textual

echo ""
echo "All dependencies installed. Run:  python3 manuscripts.py"
