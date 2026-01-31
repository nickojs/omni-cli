#!/bin/bash

# ========================================
# Animations Module
# ========================================
# This module provides loading animations and visual effects
# Usage: source libs/omni-ui-kit/animations.sh

# Ensure colors are available
if [[ -z "$BRIGHT_PURPLE" ]]; then
    source "$(dirname "${BASH_SOURCE[0]}")/colors.sh"
fi

# Function to print a fancy loading animation
show_loading() {
    local msg="$1"
    local duration=${2:-2}
    local frames=("⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏")
    local frame_count=${#frames[@]}
    local iterations=$((duration * 10))
    
    for ((i=0; i<iterations; i++)); do
        local frame=${frames[$((i % frame_count))]}
        echo -ne "\r${BRIGHT_PURPLE}${frame} ${msg}${NC}"
        sleep 0.1
    done
    echo -ne "\r${BRIGHT_GREEN}[DONE] ${msg}${NC}\n"
}

