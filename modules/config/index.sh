#!/bin/bash

# ========================================
# Configuration Module Index
# ========================================
# Main entry point for all configuration modules
# This file imports and makes available all config functions
# Usage: source modules/config/index.sh

# Get the directory where this script is located
CONFIG_DIR="$(dirname "${BASH_SOURCE[0]}")"

# Import all configuration modules in dependency order
source "$CONFIG_DIR/json.sh"     # JSON parsing and data loading
source "$CONFIG_DIR/validation.sh"      # Configuration validation
source "$CONFIG_DIR/setup.sh"          # Setup functions
source "$CONFIG_DIR/loader.sh"         # Main configuration loading logic

# Export a function to verify config modules are loaded
config_modules_loaded() {
    echo "✓ Configuration modules loaded successfully"
    echo "  - JSON Parser: $(type load_projects_from_json &>/dev/null && echo "✓" || echo "✗")"
    echo "  - Validation: $(type validate_config &>/dev/null && echo "✓" || echo "✗")"
    echo "  - Setup: $(type check_and_setup_config &>/dev/null && echo "✓" || echo "✗")"
    echo "  - Loader: $(type load_config &>/dev/null && echo "✓" || echo "✗")"
}

# Function to initialize configuration modules
init_config() {
    # Any initialization logic for config modules can go here
    return 0
}
