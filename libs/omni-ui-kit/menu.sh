#!/bin/bash

# ========================================
# Shared Menu UI Component
# ========================================
# Provides reusable functions for building menu command lines
# Usage: source libs/omni-ui-kit/menu.sh

# Semantic color constants for menu actions
MENU_COLOR_ADD="$BRIGHT_GREEN"      # add, start, create
MENU_COLOR_OPEN="$BRIGHT_YELLOW"    # terminal, switch, open
MENU_COLOR_ACTION="$BRIGHT_CYAN"    # restart, mount
MENU_COLOR_DELETE="$BRIGHT_RED"     # kill, delete, remove
MENU_COLOR_NAV="$BRIGHT_PURPLE"     # back, help, quit, settings
MENU_COLOR_EDIT="$BRIGHT_BLUE"      # edit, toggle

# Standard spacing between menu commands
MENU_SPACING="    "

# Build a single menu command string
# Parameters:
#   $1 - key (e.g., "s", "h", "q")
#   $2 - label (e.g., "settings", "help", "quit")
#   $3 - color (e.g., "$MENU_COLOR_NAV")
# Returns: formatted command via echo (e.g., "${color}key${NC} label")
menu_cmd() {
    local key="$1"
    local label="$2"
    local color="$3"
    echo "${color}${key}${NC} ${label}"
}

# Build a numbered menu command string
# Parameters:
#   $1 - prefix (e.g., "c", "r", "k", "" for no prefix)
#   $2 - count (number of items)
#   $3 - label (e.g., "terminal", "restart", "start")
#   $4 - color (e.g., "$MENU_COLOR_OPEN")
# Returns: empty if count=0, "c1 label" if count=1, "c1-c5 label" if count=5
menu_num_cmd() {
    local prefix="$1"
    local count="$2"
    local label="$3"
    local color="$4"

    [ "$count" -eq 0 ] && return

    if [ "$count" -eq 1 ]; then
        echo "${color}${prefix}1${NC} ${label}"
    else
        echo "${color}${prefix}1-${prefix}${count}${NC} ${label}"
    fi
}

# Join non-empty menu commands with standard spacing
# Parameters: cmd1 cmd2 cmd3 ...
# Returns: joined string via echo
menu_join() {
    local result=""
    for cmd in "$@"; do
        [ -z "$cmd" ] && continue
        [ -n "$result" ] && result+="$MENU_SPACING"
        result+="$cmd"
    done
    echo "$result"
}

# Output a complete menu line (joins and echoes with -e)
# Parameters: cmd1 cmd2 cmd3 ...
# Outputs directly to stdout with echo -e
menu_line() {
    echo -e "$(menu_join "$@")"
}
