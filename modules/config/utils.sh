#!/bin/bash

# ========================================
# Configuration Utilities Module
# ========================================
# Common utility functions for configuration management
# This module is loaded first to provide shared utilities
# Usage: source modules/config/utils.sh

# Function to get the config directory path
# Returns: config directory path via echo
# Uses IS_INSTALLED and BASE_DIR variables set in startup.sh
get_config_directory() {
    if [ "$IS_INSTALLED" = true ]; then
        echo "$HOME/.cache/fm-manager"
    else
        echo "$BASE_DIR/config"
    fi
}
