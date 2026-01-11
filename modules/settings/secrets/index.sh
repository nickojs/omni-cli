#!/bin/bash

# ========================================
# Secrets Module Index
# ========================================
# Main entry point for all secrets modules
# This file imports and makes available all secrets functions
# Usage: source modules/settings/secrets/index.sh

# Get the directory where this script is located
SECRETS_DIR="$(dirname "${BASH_SOURCE[0]}")"

# Import all secrets modules in dependency order
source "$SECRETS_DIR/storage.sh"           # JSON storage functions
source "$SECRETS_DIR/vaults/storage.sh"    # Vaults JSON storage functions
source "$SECRETS_DIR/vaults/ops.sh"        # Vault mount/unmount/init
source "$SECRETS_DIR/vaults/add.sh"        # Vault add functionality
source "$SECRETS_DIR/components.sh"        # UI components
source "$SECRETS_DIR/add.sh"               # Add secret functionality
source "$SECRETS_DIR/menu.sh"              # Main menu and entry point
