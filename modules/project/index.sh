#!/bin/bash

# ========================================
# Project Module Index
# ========================================
# Main entry point for all project modules
# This file imports and makes available all project functions
# Usage: source modules/project/index.sh

# Get the directory where this script is located
PROJECT_DIR="$(dirname "${BASH_SOURCE[0]}")"

# Import all project modules in dependency order
source "$PROJECT_DIR/validation.sh"    # Project configuration validation
source "$PROJECT_DIR/status.sh"        # Status checking and counting
source "$PROJECT_DIR/info.sh"          # Project information retrieval
source "$PROJECT_DIR/display.sh"       # Display and status formatting

# Export a function to verify project modules are loaded
project_modules_loaded() {
    echo "✓ Project modules loaded successfully"
    echo "  - Display: $(type display_project_status &>/dev/null && echo "✓" || echo "✗")"
    echo "  - Info: $(type get_project_info &>/dev/null && echo "✓" || echo "✗")"
    echo "  - Status: $(type count_running_projects &>/dev/null && echo "✓" || echo "✗")"
    echo "  - Validation: $(type validate_project_config &>/dev/null && echo "✓" || echo "✗")"
}

# Function to initialize project modules
init_project() {
    # Any initialization logic for project modules can go here
    return 0
}
