#!/bin/bash

# Quick rebuild script for fm-manager package

# Get version info from PKGBUILD safely
if [ ! -f "PKGBUILD" ]; then
    echo "Error: PKGBUILD file not found!" >&2
    exit 1
fi

# Parse PKGBUILD variables safely without eval
pkgname=$(grep -E '^pkgname=' PKGBUILD | cut -d'=' -f2 | tr -d '"' | head -n1)
pkgver=$(grep -E '^pkgver=' PKGBUILD | cut -d'=' -f2 | tr -d '"' | head -n1)
pkgrel=$(grep -E '^pkgrel=' PKGBUILD | cut -d'=' -f2 | tr -d '"' | head -n1)

# Validate extracted values
if [ -z "$pkgname" ] || [ -z "$pkgver" ] || [ -z "$pkgrel" ]; then
    echo "Error: Could not extract required package information from PKGBUILD" >&2
    echo "Missing: ${pkgname:+}${pkgname:-pkgname} ${pkgver:+}${pkgver:-pkgver} ${pkgrel:+}${pkgrel:-pkgrel}" >&2
    exit 1
fi

# Sanitize values - only allow alphanumeric, dots, hyphens, underscores
if ! [[ "$pkgname" =~ ^[a-zA-Z0-9._-]+$ ]] || ! [[ "$pkgver" =~ ^[a-zA-Z0-9._-]+$ ]] || ! [[ "$pkgrel" =~ ^[0-9]+$ ]]; then
    echo "Error: Package information contains invalid characters" >&2
    echo "pkgname: '$pkgname', pkgver: '$pkgver', pkgrel: '$pkgrel'" >&2
    exit 1
fi

echo "Building $pkgname version $pkgver-$pkgrel"

echo "Cleaning up existing build files..."
rm -rf pkg/
rm -rf src/
rm -f "${pkgname}"-*.pkg.tar.zst 2>/dev/null || true
rm -f "${pkgname}"-*.tar.gz 2>/dev/null || true

echo "Creating source tarball..."
cd ..
tar -czf "build/${pkgname}-${pkgver}.tar.gz" --exclude='.git' --exclude='build' --exclude='rebuild-package.sh' .

echo "Building package..."
cd build
makepkg -f

if [ $? -eq 0 ]; then
    echo "Package built successfully!"
    read -p "Do you want to install the package? (Y/n): " answer
    answer=${answer:-y}
    if [[ "$answer" =~ ^[Yy]$ ]]; then
        echo "Installing package..."
        sudo pacman -U "${pkgname}-${pkgver}-${pkgrel}-any.pkg.tar.zst"
    else
        echo "Skipping installation."
    fi
else
    echo "Package build failed!"
    exit 1
fi
