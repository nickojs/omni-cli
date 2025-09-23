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

# Safety check: ensure we're in the build directory with PKGBUILD file
if [ ! -f "PKGBUILD" ]; then
    echo "Error: PKGBUILD not found in current directory!" >&2
    echo "This script must be run from the build directory containing PKGBUILD." >&2
    exit 1
fi

# Safety check: ensure we're in a directory that looks like a build environment
if [ ! -d "../modules" ] || [ ! -f "../startup.sh" ]; then
    echo "Error: Directory structure doesn't match expected fm-manager build environment!" >&2
    echo "This script must be run from the fm-manager/build directory." >&2
    exit 1
fi

# Now safely remove build artifacts
if [ -d "pkg" ]; then
    rm -rf pkg/
fi

if [ -d "src" ]; then
    rm -rf src/
fi

rm -f "${pkgname}"-*.pkg.tar.zst 2>/dev/null || true
rm -f "${pkgname}"-*.tar.gz 2>/dev/null || true

echo "Creating source tarball..."
cd ..
tar -czf "build/${pkgname}-${pkgver}.tar.gz" --exclude='.git' --exclude='build' --exclude='rebuild-package.sh' .

echo "Updating checksums in PKGBUILD..."
cd build
# Use standard updpkgsums command to generate checksums
updpkgsums
echo "Checksums updated successfully"

echo "Building package..."
makepkg -f

if [ $? -eq 0 ]; then
    echo "Package built successfully!"
    read -p "Do you want to install the package? (Y/n): " answer
    answer=${answer:-y}
    if [[ "$answer" =~ ^[Yy]$ ]]; then
        echo "Installing package..."

        # Verify package file exists before installation
        if [ ! -f "${pkgname}-${pkgver}-${pkgrel}-any.pkg.tar.zst" ]; then
            echo "Error: Package file '${pkgname}-${pkgver}-${pkgrel}-any.pkg.tar.zst' not found!" >&2
            echo "Build may have failed or package filename is unexpected." >&2
            exit 1
        fi

        # Additional safety: ensure filename doesn't contain path traversal
        if [[ "${pkgname}-${pkgver}-${pkgrel}-any.pkg.tar.zst" == *"/"* ]] || [[ "${pkgname}-${pkgver}-${pkgrel}-any.pkg.tar.zst" == *".."* ]]; then
            echo "Error: Package filename contains invalid path characters!" >&2
            exit 1
        fi

        # Install with explicit path to prevent any ambiguity
        sudo pacman -U "./${pkgname}-${pkgver}-${pkgrel}-any.pkg.tar.zst"
    else
        echo "Skipping installation."
    fi
else
    echo "Package build failed!"
    exit 1
fi

echo "Restoring PKGBUILD to original state..."
git checkout PKGBUILD
echo "PKGBUILD restored"
