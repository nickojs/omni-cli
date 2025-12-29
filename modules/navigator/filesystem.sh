#!/bin/bash

# ========================================
# Filesystem Navigator Module
# ========================================
# This module provides interactive filesystem navigation for path selection
# Usage: source modules/navigator/filesystem.sh

# Function to show path selection - goes straight to interactive browser
show_path_selector() {
    show_interactive_browser
}

# Function to show manual path entry (existing behavior)
show_manual_path_entry() {
    clear
    print_header "✏️  MANUAL PATH ENTRY"
    echo ""

    local projects_dir=""
    while [ -z "$projects_dir" ]; do
        read -p "Enter the relative path to your projects folder: " projects_dir

        if [ -z "$projects_dir" ]; then
            print_error "Please enter a valid path"
            continue
        fi

        # Convert to relative path if absolute path was provided
        if [[ "$projects_dir" = /* ]]; then
            projects_dir=$(realpath --relative-to="." "$projects_dir")
            print_step "Converted to relative path: $projects_dir"
        fi

        # Validate the directory
        if [ ! -d "$projects_dir" ]; then
            print_error "Directory '$projects_dir' does not exist!"
            projects_dir=""
            continue
        fi

        break
    done

    export SELECTED_PROJECTS_DIR="$projects_dir"
}

# Function to show interactive filesystem browser
show_interactive_browser() {
    # Start from home directory and immediately enter browsing mode
    local current_dir="$HOME"
    CURRENT_SELECTION=1

    local need_full_redraw=true

    while true; do
        if [ "$need_full_redraw" = true ]; then
            # Show current directory and its contents
            show_directory_listing "$current_dir"

            # In browsing mode - capture single keystrokes
            echo -e "${BRIGHT_YELLOW}↑ w  ↓ s${NC} navigate    ${BRIGHT_CYAN}#${NC} jump    ${BRIGHT_GREEN}enter${NC} open    ${BRIGHT_BLUE}space${NC} select    ${BRIGHT_RED}b${NC} back"
        fi

        IFS= read -r -n1 -s choice

        handle_browsing_key "$choice" "$current_dir"
        local result=$?

        need_full_redraw=true  # Default to full redraw

        if [ $result -eq 1 ]; then
            # Directory selected
            printf '\033[?25h'  # Restore cursor
            break
        elif [ $result -eq 2 ]; then
            # Return requested
            printf '\033[?25h'  # Restore cursor
            return
        elif [ $result -eq 4 ]; then
            # Navigate to parent directory
            current_dir=$(realpath "$current_dir/..")
            CURRENT_SELECTION=1
        elif [ $result -eq 5 ]; then
            # Navigate into selected directory using global array
            local selected_index=$((CURRENT_SELECTION - 1))
            local selected_dir="${NAV_DIRECTORIES[selected_index]}"

            if [ -n "$selected_dir" ] && [ -d "$selected_dir" ]; then
                current_dir=$(realpath "$selected_dir")
                CURRENT_SELECTION=1
            fi
        elif [ $result -eq 6 ]; then
            # Partial update - just redraw changed lines
            update_selection_display "$PREVIOUS_SELECTION" "$CURRENT_SELECTION"
            need_full_redraw=false
        fi
    done
}

# Global variables for navigation state
CURRENT_SELECTION=1
PREVIOUS_SELECTION=1
declare -g -a NAV_DIRECTORIES=()
declare -g -a NAV_DISPLAY_NAMES=()
NAV_LIST_START_LINE=7  # Line where directory list starts (after header + location)

# Function to render a single directory line
# Parameters: index (0-based), is_selected (0 or 1)
render_directory_line() {
    local index="$1"
    local is_selected="$2"
    local counter=$((index + 1))
    local dir_name="${NAV_DISPLAY_NAMES[index]}"
    local icon=""

    # Choose appropriate icon
    if [[ "$dir_name" == ".. (parent directory)" ]]; then
        icon="⬆️ "
    else
        icon="📂 "
    fi

    if [ "$is_selected" -eq 1 ]; then
        # Highlight current selection with background and arrow
        printf "  ${BRIGHT_YELLOW}▶${NC} ${BRIGHT_BLACK}${BRIGHT_YELLOW} %-2s ${NC} ${icon}${BRIGHT_YELLOW}%s${NC}" "$counter" "$dir_name"
    else
        # Normal directory entry
        printf "  ${DIM} ${NC} ${BRIGHT_CYAN}%-2s${NC}  ${icon}${BRIGHT_WHITE}%s${NC}" "$counter" "$dir_name"
    fi
}

# Function to update selection display without full redraw
update_selection_display() {
    local old_sel="$1"
    local new_sel="$2"

    printf '\033[?25l'  # Hide cursor

    # Move to old selection line and redraw as unselected
    local old_line=$((NAV_LIST_START_LINE + old_sel - 1))
    printf '\033[%d;1H\033[K' "$old_line"  # Move to line, clear it
    render_directory_line $((old_sel - 1)) 0

    # Move to new selection line and redraw as selected
    local new_line=$((NAV_LIST_START_LINE + new_sel - 1))
    printf '\033[%d;1H\033[K' "$new_line"  # Move to line, clear it
    render_directory_line $((new_sel - 1)) 1

    # Move cursor below menu line (list + blank + menu + 1)
    local input_line=$((NAV_LIST_START_LINE + ${#NAV_DIRECTORIES[@]} + 2))
    printf '\033[%d;1H' "$input_line"
}

# Function to show directory listing
show_directory_listing() {
    local dir="$1"

    printf '\033[?25l'  # Hide cursor during redraw
    clear
    print_header "DIRECTORY BROWSER"
    echo ""
    local absolute_path=$(realpath "$dir")
    local display_path="${absolute_path/#$HOME/\~}"
    print_color "$BRIGHT_CYAN" "Current location: ${BRIGHT_WHITE}${display_path}${NC}"
    echo ""

    # Clear and populate global arrays
    NAV_DIRECTORIES=()
    NAV_DISPLAY_NAMES=()

    # Add parent directory option (always show unless we're at home directory)
    local current_real_path=$(realpath "$dir")
    if [ "$current_real_path" != "$HOME" ]; then
        NAV_DIRECTORIES+=("$dir/..")
        NAV_DISPLAY_NAMES+=(".. (parent directory)")
    fi

    # Add subdirectories
    while IFS= read -r -d '' subdir; do
        if [ -d "$subdir" ]; then
            local basename_dir=$(basename "$subdir")
            # Skip hidden directories
            if [[ ! "$basename_dir" =~ ^\. ]]; then
                NAV_DIRECTORIES+=("$subdir")
                NAV_DISPLAY_NAMES+=("$basename_dir/")
            fi
        fi
    done < <(find "$dir" -mindepth 1 -maxdepth 1 -type d -print0 2>/dev/null | sort -z)

    if [ ${#NAV_DIRECTORIES[@]} -eq 0 ]; then
        print_warning "No directories found in this location"
        echo ""
        echo -e "${BRIGHT_YELLOW}Press 'Space' to select current directory or 'b' to return${NC}"
        return
    fi

    # Display stylized directory list with icons
    for i in "${!NAV_DIRECTORIES[@]}"; do
        render_directory_line "$i" $([[ $((i + 1)) -eq "$CURRENT_SELECTION" ]] && echo 1 || echo 0)
        echo ""  # newline after each line
    done

    echo ""
}

# Function to handle browsing keys
handle_browsing_key() {
    local key="$1"
    local current_dir="$2"

    # Use global NAV_DIRECTORIES array (populated by show_directory_listing)
    local -n directories=NAV_DIRECTORIES

    case "$key" in
        w|W)
            # Move selection up
            PREVIOUS_SELECTION=$CURRENT_SELECTION
            if [ "$CURRENT_SELECTION" -gt 1 ]; then
                CURRENT_SELECTION=$((CURRENT_SELECTION - 1))
            else
                # Wrap to bottom
                CURRENT_SELECTION=${#directories[@]}
            fi
            return 6  # Partial update
            ;;
        s|S)
            # Move selection down
            PREVIOUS_SELECTION=$CURRENT_SELECTION
            if [ "$CURRENT_SELECTION" -lt "${#directories[@]}" ]; then
                CURRENT_SELECTION=$((CURRENT_SELECTION + 1))
            else
                # Wrap to top
                CURRENT_SELECTION=1
            fi
            return 6  # Partial update
            ;;
        $'\n'|$'\r'|'')
            # Enter key - navigate directly into selected directory/parent
            if [ ${#directories[@]} -gt 0 ] && [ "$CURRENT_SELECTION" -le "${#directories[@]}" ]; then
                local selected_index=$((CURRENT_SELECTION - 1))
                local selected_dir="${directories[selected_index]}"

                # Check if it's parent directory
                if [[ "$selected_dir" == *".." ]]; then
                    # Navigate to parent directory
                    return 4  # Signal navigation to parent
                else
                    # Navigate into directory (continue browsing)
                    return 5  # Signal navigation into directory
                fi
            fi
            return 0
            ;;
        ' ')
            # Space key - select current directory as projects directory
            local absolute_path=$(realpath "$current_dir")
            # Display with tilde, store absolute
            local display_path="${absolute_path/#$HOME/\~}"
            echo ""
            print_success "Selected directory: $display_path"
            export SELECTED_PROJECTS_DIR="$absolute_path"
            return 1  # Signal selection made
            ;;
        b|B)
            # Return without selecting
            return 2
            ;;
        [0-9])
            # Numeric input - collect full number and jump to that index
            local number="$key"
            printf '\033[?25h'  # Show cursor for number input
            echo ""  # Blank line for spacing
            echo -ne "${BRIGHT_CYAN}Go to: ${number}${NC}"

            # Keep reading digits until Enter or non-digit
            while true; do
                local next_char
                IFS= read -r -n1 -s next_char

                if [[ "$next_char" =~ [0-9] ]]; then
                    number="${number}${next_char}"
                    echo -ne "${next_char}"
                elif [[ -z "$next_char" || "$next_char" == $'\n' || "$next_char" == $'\r' ]]; then
                    # Enter pressed - jump to index and enter folder
                    echo ""
                    if [ "$number" -ge 1 ] && [ "$number" -le "${#directories[@]}" ]; then
                        CURRENT_SELECTION=$number
                        # Enter the folder directly
                        local selected_index=$((CURRENT_SELECTION - 1))
                        local selected_dir="${directories[selected_index]}"
                        if [[ "$selected_dir" == *".." ]]; then
                            return 4  # Navigate to parent
                        else
                            return 5  # Navigate into directory
                        fi
                    fi
                    break
                else
                    # Non-digit pressed - cancel
                    echo ""
                    break
                fi
            done
            return 0
            ;;
        *)
            # Silently ignore invalid keys
            return 0
            ;;
    esac
}