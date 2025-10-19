#!/bin/bash

# ========================================
# UI Components Module
# ========================================
# This module provides UI components like headers, separators, and message functions
# Usage: source styles/ui.sh

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

    echo -e "${BRIGHT_WHITE}${BOLD}${title}${NC}"
    echo -e "${BRIGHT_CYAN}$(printf '─%.0s' $(seq 1 ${#title}))${NC}"
}

# Function to print a section header (for grouping content)
print_section_header() {
    local title="$1"
    local width=$(get_terminal_width)

    # Lightweight section divider inspired by lazygit
    echo -e "${CYAN}───${NC} ${BRIGHT_WHITE}${title}${NC} ${CYAN}$(printf '─%.0s' $(seq 1 $((width - ${#title} - 6))))${NC}"
}

# Function to print a clean separator
print_separator() {
    local color="${1:-$DIM}"
    echo -e "${color}$(printf '%.0s─' $(seq 1 40))${NC}"
}

# Function to print success message
print_success() {
    print_color "$BRIGHT_GREEN" "✓ $*"
}

# Function to print error message
print_error() {
    print_color "$BRIGHT_RED" "✗ $*"
}

# Function to print warning message
print_warning() {
    print_color "$BRIGHT_YELLOW" "⚠ $*"
}

# Function to print info message
print_info() {
    print_color "$BRIGHT_BLUE" "ℹ $*"
}

# Function to print step message
print_step() {
    print_color "$BLUE" "→ $*"
}

# Function to print a clean box around text
print_box() {
    local title="$1"

    echo -e "${BRIGHT_WHITE}${BOLD}${title}${NC}"
}

# Function for a simple divider with text
print_divider() {
    local text="$1"

    echo -e "${DIM}${text}${NC}"
}

# Function to create a clean border line
print_border() {
    local color="${1:-$DIM}"
    echo -e "${color}$(printf '%.0s─' $(seq 1 40))${NC}"
}

# Function to print centered text (simplified)
print_centered() {
    local text="$1"
    local color="${2:-$BRIGHT_WHITE}"

    echo -e "${color}${text}${NC}"
}

# Function to print simple text (no borders)
print_bordered_text() {
    local text="$1"
    local text_color="${2:-$BRIGHT_WHITE}"

    echo -e "${text_color}${text}${NC}"
}

# Function to create a clean status panel with title and content
print_status_panel() {
    local title="$1"
    local content="$2"

    echo ""
    echo -e "${BRIGHT_WHITE}${BOLD}${title}${NC}"
    echo -e "${BRIGHT_CYAN}$(printf '─%.0s' $(seq 1 ${#title}))${NC}"
    echo ""
    echo -e "${BRIGHT_WHITE}${content}${NC}"
    echo ""
}
