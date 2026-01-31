#!/bin/bash
# Test PKGBUILD from git (clones from GitHub, tests real build pipeline)
# Usage: ./test-area/build/remote.sh
# Requires changes pushed to the branch specified in PKGBUILD

set -e

cd "$(dirname "${BASH_SOURCE[0]}")/../.."

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

PKGNAME=$(grep -Po '^pkgname=\K.*' PKGBUILD)
PKGVER=$(grep -Po '^pkgver=\K.*' PKGBUILD)
PKGREL=$(grep -Po '^pkgrel=\K.*' PKGBUILD)
SOURCE=$(grep -Po '^source=\(\K[^)]+' PKGBUILD)

echo "========================================="
echo " PKGBUILD Test (remote)"
echo "========================================="
echo -e "${YELLOW}Package:${NC} $PKGNAME $PKGVER-$PKGREL"
echo -e "${YELLOW}Source:${NC} $SOURCE"
echo ""

# Clean
echo -e "${YELLOW}[1/4]${NC} Cleaning..."
rm -rf src/ pkg/ "$PKGNAME/" *.pkg.tar.zst

# Remove old package if installed
if pacman -Qi "$PKGNAME" &>/dev/null; then
    echo -e "${YELLOW}[2/4]${NC} Removing installed package..."
    sudo pacman -Rns --noconfirm "$PKGNAME"
else
    echo -e "${YELLOW}[2/4]${NC} Package not currently installed"
fi

# Build (full pipeline: clone + package)
echo -e "${YELLOW}[3/4]${NC} Building from git..."
makepkg -sf

# Install
echo -e "${YELLOW}[4/4]${NC} Installing..."
sudo pacman -U --noconfirm "${PKGNAME}"-*.pkg.tar.zst

echo ""
echo -e "${GREEN}Done! Run 'omni-cli' to test.${NC}"
pacman -Ql "$PKGNAME" | head -20
