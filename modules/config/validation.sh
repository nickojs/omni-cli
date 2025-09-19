#!/bin/bash

# ========================================
# Configuration Validation Module
# ========================================
# This module handles configuration validation
# Usage: source modules/config/validation.sh

# Function to validate configuration format
validate_config() {
    local json_file="$JSON_CONFIG_FILE"
    
    if [ ! -f "$json_file" ]; then
        return 1
    fi
    
    # Basic JSON validation - check for required fields
    if ! grep -q '"displayName"' "$json_file" || \
       ! grep -q '"projectName"' "$json_file" || \
       ! grep -q '"startupCmd"' "$json_file"; then
        return 1
    fi
    
    return 0
}
