#!/bin/bash

# ========================================
# Color Definitions Module
# ========================================
# This module exports all color constants for terminal styling
# Usage: source libs/omni-ui-kit/colors.sh

# Basic colors
export RED=$'\033[0;31m'
export GREEN=$'\033[0;32m'
export BLUE=$'\033[0;34m'
export WHITE=$'\033[0;37m'

# Text styling
export BOLD=$'\033[1m'
export ITALIC=$'\033[3m'
export DIM=$'\033[2m'
export NC=$'\033[0m' # No Color

# Bright/Bold colors
export BRIGHT_RED=$'\033[1;31m'
export BRIGHT_GREEN=$'\033[1;32m'
export BRIGHT_YELLOW=$'\033[1;33m'
export BRIGHT_BLUE=$'\033[1;34m'
export BRIGHT_PURPLE=$'\033[1;35m'
export BRIGHT_CYAN=$'\033[1;36m'
export BRIGHT_WHITE=$'\033[1;37m'

# Function to print colored text
print_color() {
    local color=$1
    shift
    echo -e "${color}$*${NC}"
}
