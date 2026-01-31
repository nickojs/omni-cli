#!/bin/bash

# ========================================
# UI Components Module
# ========================================
# This module provides UI components like headers, separators, and message functions
# Usage: source libs/omni-ui-kit/ui.sh

# Ensure colors are available
if [[ -z "$BRIGHT_CYAN" ]]; then
    source "$(dirname "${BASH_SOURCE[0]}")/colors.sh"
fi

# Function to get terminal width
get_terminal_width() {
    local width
    if command -v tput &> /dev/null; then
        width=$(tput cols 2>/dev/null) || width=80
    else
        width=${COLUMNS:-80}
    fi
    # Ensure minimum width and maximum width for readability
    if [ "$width" -lt 60 ]; then
        width=60
    elif [ "$width" -gt 120 ]; then
        width=120
    fi
    echo "$width"
}

# Function to print a clean header (minimal styling)
print_header() {
    local title="$1"

    echo ""
    echo -e "${BRIGHT_WHITE}${BOLD}${title}${NC}"
    echo -e "${BRIGHT_CYAN}$(printf '─%.0s' $(seq 1 ${#title}))${NC}"
}

# Function to print a clean separator
print_separator() {
    local color="${1:-$DIM}"
    echo -e "${color}$(printf '%.0s─' $(seq 1 40))${NC}"
}

# Function to print success message
print_success() {
    print_color "$BRIGHT_GREEN" "[success] $*"
}

# Function to print error message
print_error() {
    print_color "$BRIGHT_RED" "[error] $*"
}

# Function to print warning message
print_warning() {
    print_color "$BRIGHT_YELLOW" "[warning] $*"
}

# Function to print info message
print_info() {
    print_color "$BRIGHT_WHITE" "[info] $*"
}

# Function to print step message
print_step() {
    print_color "$BLUE" "→ $*"
}

# Function to print a boxed warning header
print_warning_box() {
    echo -e "${BRIGHT_RED}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BRIGHT_RED}║                        ⚠️  WARNING  ⚠️                        ║${NC}"
    echo -e "${BRIGHT_RED}╚═══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# Function to prompt user to press Enter to continue
# Parameters: optional custom message
wait_for_enter() {
    local message="${1:-Press Enter to continue...}"
    echo ""
    echo -ne "${WHITE}${message}${NC}"
    read -r
}
