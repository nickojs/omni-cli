#!/bin/bash

# Quick rebuild script for fm-manager package

# Get version info from PKGBUILD
eval $(grep -E '^(pkgname|pkgver|pkgrel)=' PKGBUILD)

echo "Building $pkgname version $pkgver-$pkgrel"

echo "Cleaning up existing build files..."
rm -rf pkg/
rm -rf src/
rm -f ${pkgname}-*.pkg.tar.zst 2>/dev/null || true
rm -f ${pkgname}-*.tar.gz 2>/dev/null || true

echo "Creating source tarball..."
cd ..
tar -czf build/$pkgname-$pkgver.tar.gz --exclude='.git' --exclude='build' --exclude='rebuild-package.sh' .

echo "Building package..."
cd build
makepkg -f

if [ $? -eq 0 ]; then
    echo "Package built successfully!"
    read -p "Do you want to install the package? (Y/n): " answer
    answer=${answer:-y}
    if [[ "$answer" =~ ^[Yy]$ ]]; then
        echo "Installing package..."
        sudo pacman -U $pkgname-$pkgver-$pkgrel-any.pkg.tar.zst
    else
        echo "Skipping installation."
    fi
else
    echo "Package build failed!"
    exit 1
fi
