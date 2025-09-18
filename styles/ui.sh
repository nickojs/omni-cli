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

# Function to print a fancy header (simplified with just top/bottom borders)
print_header() {
    local title="$1"
    local width=$(get_terminal_width)
    local padding=$(( (width - ${#title} - 2) / 2 ))
    
    echo ""
    # Top border
    echo -e "${BRIGHT_CYAN}$(printf '━%.0s' $(seq 1 $width))${NC}"
    # Title with proper centering
    local left_pad=$(( (width - ${#title}) / 2 ))
    local right_pad=$(( width - ${#title} - left_pad ))
    echo -e "${BRIGHT_WHITE}$(printf "%*s" $left_pad "")${title}$(printf "%*s" $right_pad "")${NC}"
    # Bottom border
    echo -e "${BRIGHT_CYAN}$(printf '━%.0s' $(seq 1 $width))${NC}"
    echo ""
}

# Function to print a fancy separator
print_separator() {
    local char="${1:-━}"
    local color="${2:-$BRIGHT_BLUE}"
    local width=$(get_terminal_width)
    echo -e "${color}$(printf "%.0s${char}" $(seq 1 $width))${NC}"
}

# Function to print success message
print_success() {
    print_color "$BRIGHT_GREEN" "[SUCCESS] $*"
}

# Function to print error message
print_error() {
    print_color "$BRIGHT_RED" "[ERROR] $*"
}

# Function to print warning message
print_warning() {
    print_color "$BRIGHT_YELLOW" "[WARNING] $*"
}

# Function to print info message
print_info() {
    print_color "$BRIGHT_BLUE" "[INFO] $*"
}

# Function to print step message
print_step() {
    print_color "$BLUE" "→ $*"
}

# Function to print a fancy box around text
print_box() {
    local title="$1"
    local width=${2:-$(get_terminal_width)}
    local border_char="${3:-┃}"
    local top_char="${4:-━}"
    
    echo ""
    # Top border
    echo -e "${BRIGHT_CYAN}┏$(printf "${top_char}%.0s" $(seq 1 $((width-2))))┓${NC}"
    # Title with proper centering
    local title_length=${#title}
    local content_width=$((width - 4))  # Account for border chars and spaces
    local left_pad=$(( (content_width - title_length) / 2 ))
    local right_pad=$(( content_width - title_length - left_pad ))
    echo -e "${BRIGHT_CYAN}${border_char}${NC} ${BRIGHT_WHITE}$(printf "%*s" $left_pad "")${title}$(printf "%*s" $right_pad "")${NC} ${BRIGHT_CYAN}${border_char}${NC}"
    # Bottom border
    echo -e "${BRIGHT_CYAN}┗$(printf "${top_char}%.0s" $(seq 1 $((width-2))))┛${NC}"
    echo ""
}

# Function for a simple divider with text
print_divider() {
    local text="$1"
    local total_width=$(get_terminal_width)
    local text_length=${#text}
    local dash_count=$(( (total_width - text_length - 2) / 2 ))
    
    printf "${BRIGHT_BLUE}"
    printf "%.0s─" $(seq 1 $dash_count)
    printf " ${BRIGHT_WHITE}%s${BRIGHT_BLUE} " "$text"
    printf "%.0s─" $(seq 1 $dash_count)
    # Handle odd numbers
    if (( (total_width - text_length) % 2 == 1 )); then
        printf "─"
    fi
    printf "${NC}\n"
}

# Function to create a full-width border line
print_border() {
    local char="${1:-─}"
    local color="${2:-$BRIGHT_CYAN}"
    local width=$(get_terminal_width)
    echo -e "${color}$(printf "%.0s${char}" $(seq 1 $width))${NC}"
}

# Function to print text with padding to center it
print_centered() {
    local text="$1"
    local color="${2:-$BRIGHT_WHITE}"
    local width=$(get_terminal_width)
    local text_length=${#text}
    local left_pad=$(( (width - text_length) / 2 ))
    local right_pad=$(( width - text_length - left_pad ))
    
    echo -e "${color}$(printf "%*s" $left_pad "")${text}$(printf "%*s" $right_pad "")${NC}"
}

# Function to print text with left and right borders
print_bordered_text() {
    local text="$1"
    local border_char="${2:-┃}"
    local text_color="${3:-$BRIGHT_WHITE}"
    local border_color="${4:-$BRIGHT_CYAN}"
    local width=$(get_terminal_width)
    local content_width=$((width - 4))  # Account for borders and spaces
    local text_length=${#text}
    
    if [ "$text_length" -gt "$content_width" ]; then
        # Truncate text if too long
        text="${text:0:$content_width}"
        text_length=$content_width
    fi
    
    local right_pad=$(( content_width - text_length ))
    echo -e "${border_color}${border_char}${NC} ${text_color}${text}$(printf "%*s" $right_pad "")${NC} ${border_color}${border_char}${NC}"
}

# Function to create a status panel with title and content
print_status_panel() {
    local title="$1"
    local content="$2"
    local width=$(get_terminal_width)
    
    echo ""
    # Top border with title
    echo -e "${BRIGHT_CYAN}┏━━━ ${BRIGHT_WHITE}${title}${BRIGHT_CYAN} $(printf "%.0s━" $(seq 1 $((width - ${#title} - 8))))┓${NC}"
    
    # Content lines
    echo "$content" | while IFS= read -r line; do
        if [ -n "$line" ]; then
            print_bordered_text "$line" "┃"
        else
            print_bordered_text "" "┃"
        fi
    done
    
    # Bottom border
    echo -e "${BRIGHT_CYAN}┗$(printf "%.0s━" $(seq 1 $((width - 2))))┛${NC}"
    echo ""
}
