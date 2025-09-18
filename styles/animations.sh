#!/bin/bash

# ========================================
# Animations Module
# ========================================
# This module provides loading animations and visual effects
# Usage: source styles/animations.sh

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

# Function for a simple spinner
show_spinner() {
    local msg="$1"
    local duration=${2:-3}
    local frames=("-" "\\" "|" "/")
    local frame_count=${#frames[@]}
    local iterations=$((duration * 4))
    
    for ((i=0; i<iterations; i++)); do
        local frame=${frames[$((i % frame_count))]}
        echo -ne "\r${BRIGHT_CYAN}${frame} ${msg}${NC}"
        sleep 0.25
    done
    echo -ne "\r${BRIGHT_GREEN}✓ ${msg}${NC}\n"
}

# Function for progress bar simulation
show_progress() {
    local msg="$1"
    local steps=${2:-20}
    local duration=${3:-2}
    local sleep_time=$(echo "scale=3; $duration / $steps" | bc -l 2>/dev/null || echo "0.1")
    
    echo -e "${BRIGHT_BLUE}${msg}${NC}"
    for ((i=0; i<=steps; i++)); do
        local progress=$((i * 100 / steps))
        local filled=$((i * 30 / steps))
        local empty=$((30 - filled))
        
        printf "\r${BRIGHT_WHITE}["
        printf "%${filled}s" | tr ' ' '█'
        printf "%${empty}s" | tr ' ' '░'
        printf "] ${BRIGHT_CYAN}%3d%%${NC}" "$progress"
        
        sleep "$sleep_time"
    done
    echo ""
}
