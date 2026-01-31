#!/bin/bash
# Test PKGBUILD using local files (no git clone, fast iteration)
# Usage: ./test-area/build/local.sh

set -e

cd "$(dirname "${BASH_SOURCE[0]}")/../.."

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

PKGNAME=$(grep -Po '^pkgname=\K.*' PKGBUILD)
PKGVER=$(grep -Po '^pkgver=\K.*' PKGBUILD)
PKGREL=$(grep -Po '^pkgrel=\K.*' PKGBUILD)

echo "========================================="
echo " PKGBUILD Test (local)"
echo "========================================="
echo -e "${YELLOW}Package:${NC} $PKGNAME $PKGVER-$PKGREL"
echo ""

# Clean
echo -e "${YELLOW}[1/5]${NC} Cleaning..."
rm -rf src/ pkg/ "$PKGNAME/" *.pkg.tar.zst

# Copy local files into src/ (mimics git clone)
echo -e "${YELLOW}[2/5]${NC} Copying local files to src/$PKGNAME/..."
mkdir -p "src/$PKGNAME"
cp -r modules styles .env startup.sh LICENSE "src/$PKGNAME/"

# Remove old package if installed
if pacman -Qi "$PKGNAME" &>/dev/null; then
    echo -e "${YELLOW}[3/5]${NC} Removing installed package..."
    sudo pacman -Rns --noconfirm "$PKGNAME"
else
    echo -e "${YELLOW}[3/5]${NC} Package not currently installed"
fi

# Build (-e = use existing src/, -f = force)
echo -e "${YELLOW}[4/5]${NC} Building..."
makepkg -ef

# Install
echo -e "${YELLOW}[5/5]${NC} Installing..."
sudo pacman -U --noconfirm "${PKGNAME}"-*.pkg.tar.zst

echo ""
echo -e "${GREEN}Done! Run 'omni-cli' to test.${NC}"
pacman -Ql "$PKGNAME" | head -20
