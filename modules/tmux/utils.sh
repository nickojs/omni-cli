#!/bin/bash

# ========================================
# Tmux Utilities Module
# ========================================
# This module handles tmux utility functions
# Usage: source modules/tmux/utils.sh

# Function to check if tmux is available
check_tmux() {
    if ! command -v tmux &> /dev/null; then
        print_error "tmux is not installed. Please install tmux to use this script."
        exit 1
    fi
}
