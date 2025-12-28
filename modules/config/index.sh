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
source "$CONFIG_DIR/json.sh"            # JSON parsing and data loading
source "$CONFIG_DIR/setup.sh"          # Setup functions

# Export a function to verify config modules are loaded
config_modules_loaded() {
# TODO CLAUDE: needs to recalculate this based on new config (see lines 13~16)
}
