#!/bin/bash
# Test PKGBUILD locally - clean build and install

set -e

echo "========================================="
echo "PKGBUILD Local Test Script"
echo "========================================="
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Get package name from PKGBUILD
PKGNAME=$(grep -Po '^pkgname=\K.*' PKGBUILD)
PKGVER=$(grep -Po '^pkgver=\K.*' PKGBUILD)
PKGREL=$(grep -Po '^pkgrel=\K.*' PKGBUILD)

echo -e "${YELLOW}Package:${NC} $PKGNAME"
echo -e "${YELLOW}Version:${NC} $PKGVER-$PKGREL"
echo ""

# Step 1: Clean previous build artifacts
echo -e "${YELLOW}[1/5]${NC} Cleaning previous build artifacts..."
rm -rf src/ pkg/ *.pkg.tar.zst

# Step 2: Check if package is already installed
if pacman -Qi "$PKGNAME" &>/dev/null; then
    echo -e "${YELLOW}[2/5]${NC} Package already installed. Removing..."
    sudo pacman -Rns --noconfirm "$PKGNAME" || {
        echo -e "${RED}Failed to remove existing package${NC}"
        exit 1
    }
else
    echo -e "${YELLOW}[2/5]${NC} Package not currently installed"
fi

# Step 3: Build the package
echo -e "${YELLOW}[3/5]${NC} Building package..."
makepkg -f || {
    echo -e "${RED}Build failed${NC}"
    exit 1
}

# Step 4: Install the package
echo -e "${YELLOW}[4/5]${NC} Installing package..."
PACKAGE_FILE="${PKGNAME}-${PKGVER}-${PKGREL}-any.pkg.tar.zst"
if [ ! -f "$PACKAGE_FILE" ]; then
    # Try to find the built package
    PACKAGE_FILE=$(ls "${PKGNAME}"-*.pkg.tar.zst 2>/dev/null | head -n1)
fi

if [ -f "$PACKAGE_FILE" ]; then
    sudo pacman -U --noconfirm "$PACKAGE_FILE" || {
        echo -e "${RED}Installation failed${NC}"
        exit 1
    }
else
    echo -e "${RED}Package file not found${NC}"
    exit 1
fi

# Step 5: Verify installation
echo -e "${YELLOW}[5/5]${NC} Verifying installation..."
if pacman -Qi "$PKGNAME" &>/dev/null; then
    echo ""
    echo -e "${GREEN}=========================================${NC}"
    echo -e "${GREEN}✓ Package installed successfully!${NC}"
    echo -e "${GREEN}=========================================${NC}"
    echo ""
    echo "Installed files:"
    pacman -Ql "$PKGNAME" | head -20
    echo ""
    echo "Run 'omni-cli' to test the application"
else
    echo -e "${RED}Verification failed - package not installed${NC}"
    exit 1
fi
