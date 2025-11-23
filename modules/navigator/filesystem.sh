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
    # Start from current directory and immediately enter browsing mode
    local current_dir="."
    CURRENT_SELECTION=1

    while true; do
        # Show current directory and its contents
        show_directory_listing "$current_dir"

        # In browsing mode - capture single keystrokes
        echo -e "${BRIGHT_YELLOW}↑ w  ↓ s${NC} navigate    ${BRIGHT_GREEN}enter${NC} open folder    ${BRIGHT_BLUE}space${NC} select here    ${BRIGHT_RED}b${NC} return "
        IFS= read -r -n1 -s choice
        echo ""  # Add newline after key capture

        handle_browsing_key "$choice" "$current_dir"
        local result=$?

        if [ $result -eq 1 ]; then
            # Directory selected
            break
        elif [ $result -eq 2 ]; then
            # Return requested
            return
        elif [ $result -eq 4 ]; then
            # Navigate to parent directory
            current_dir=$(realpath "$current_dir/..")
            CURRENT_SELECTION=1
            sleep 0.3
        elif [ $result -eq 5 ]; then
            # Navigate into selected directory
            # Get the selected directory from current selection
            local selected_dir=""
            local counter=1

            # Check parent directory first (if it exists)
            local current_real_path=$(realpath "$current_dir")
            if [ "$current_real_path" != "/" ]; then
                if [ "$counter" -eq "$CURRENT_SELECTION" ]; then
                    selected_dir=$(realpath "$current_dir/..")
                fi
                counter=$((counter + 1))
            fi

            # Check subdirectories
            if [ -z "$selected_dir" ]; then
                while IFS= read -r -d '' subdir; do
                    if [ -d "$subdir" ]; then
                        local basename_dir=$(basename "$subdir")
                        if [[ ! "$basename_dir" =~ ^\. ]]; then
                            if [ "$counter" -eq "$CURRENT_SELECTION" ]; then
                                selected_dir="$subdir"
                                break
                            fi
                            counter=$((counter + 1))
                        fi
                    fi
                done < <(find "$current_dir" -mindepth 1 -maxdepth 1 -type d -print0 2>/dev/null | sort -z)
            fi

            # Navigate to selected directory
            if [ -n "$selected_dir" ] && [ -d "$selected_dir" ]; then
                current_dir="$selected_dir"
                CURRENT_SELECTION=1
                sleep 0.3
            fi
        fi
    done
}

# Global variable to track current selection
CURRENT_SELECTION=1

# Function to show directory listing
show_directory_listing() {
    local dir="$1"

    clear
    print_header "DIRECTORY BROWSER"
    echo ""
    print_color "$BRIGHT_CYAN" "Current location: ${BRIGHT_WHITE}$(realpath "$dir")${NC}"
    echo ""

    # Get directories in current location
    local -a directories=()
    local -a display_names=()

    # Add parent directory option (always show unless we're at filesystem root)
    local current_real_path=$(realpath "$dir")
    if [ "$current_real_path" != "/" ]; then
        directories+=("$dir/..")
        display_names+=(".. (parent directory)")
    fi

    # Add subdirectories
    while IFS= read -r -d '' subdir; do
        if [ -d "$subdir" ]; then
            local basename_dir=$(basename "$subdir")
            # Skip hidden directories
            if [[ ! "$basename_dir" =~ ^\. ]]; then
                directories+=("$subdir")
                display_names+=("$basename_dir/")
            fi
        fi
    done < <(find "$dir" -mindepth 1 -maxdepth 1 -type d -print0 2>/dev/null | sort -z)

    if [ ${#directories[@]} -eq 0 ]; then
        print_warning "No directories found in this location"
        echo ""
        echo -e "${BRIGHT_YELLOW}Press 'Space' to select current directory or 'b' to return${NC}"
        return
    fi

    # Display stylized directory list with icons
    for i in "${!directories[@]}"; do
        local counter=$((i + 1))
        local dir_name="${display_names[i]}"
        local icon=""

        # Choose appropriate icon
        if [[ "$dir_name" == ".. (parent directory)" ]]; then
            icon="⬆️ "
        else
            icon="📂 "
        fi

        if [ "$counter" -eq "$CURRENT_SELECTION" ]; then
            # Highlight current selection with background and arrow
            printf "  ${BRIGHT_YELLOW}▶${NC} ${BRIGHT_BLACK}${BRIGHT_YELLOW} %-2s ${NC} ${icon}${BRIGHT_YELLOW}%s${NC}\n" "$counter" "$dir_name"
        else
            # Normal directory entry
            printf "  ${DIM} ${NC} ${BRIGHT_CYAN}%-2s${NC}  ${icon}${BRIGHT_WHITE}%s${NC}\n" "$counter" "$dir_name"
        fi
    done

    echo ""
}

# Function to handle browsing keys
handle_browsing_key() {
    local key="$1"
    local current_dir="$2"

    # Get current directory listing for navigation (same logic as display)
    local -a directories=()

    # Add parent directory option (always show unless we're at filesystem root)
    local current_real_path=$(realpath "$current_dir")
    if [ "$current_real_path" != "/" ]; then
        directories+=("$current_dir/..")
    fi

    # Add subdirectories
    while IFS= read -r -d '' subdir; do
        if [ -d "$subdir" ]; then
            local basename_dir=$(basename "$subdir")
            if [[ ! "$basename_dir" =~ ^\. ]]; then
                directories+=("$subdir")
            fi
        fi
    done < <(find "$current_dir" -mindepth 1 -maxdepth 1 -type d -print0 2>/dev/null | sort -z)

    case "$key" in
        w|W)
            # Move selection up
            if [ "$CURRENT_SELECTION" -gt 1 ]; then
                CURRENT_SELECTION=$((CURRENT_SELECTION - 1))
            else
                # Wrap to bottom
                CURRENT_SELECTION=${#directories[@]}
            fi
            return 0
            ;;
        s|S)
            # Move selection down
            if [ "$CURRENT_SELECTION" -lt "${#directories[@]}" ]; then
                CURRENT_SELECTION=$((CURRENT_SELECTION + 1))
            else
                # Wrap to top
                CURRENT_SELECTION=1
            fi
            return 0
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
            local relative_path=$(realpath --relative-to="." "$current_dir")
            echo ""
            print_success "Selected directory: $relative_path"
            export SELECTED_PROJECTS_DIR="$relative_path"
            return 1  # Signal selection made
            ;;
        b|B)
            # Return without selecting
            return 2
            ;;
        *)
            # Silently ignore invalid keys
            return 0
            ;;
    esac
}