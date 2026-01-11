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
# Parameters: mode (optional) - "directory" (default) or "files"
#             start_dir (optional) - starting directory (default: $HOME)
show_interactive_browser() {
    BROWSER_MODE="${1:-directory}"
    local current_dir="${2:-$HOME}"
    CURRENT_SELECTION=1
    NAV_PAGE=1
    MARKED_FILES=()

    local need_full_redraw=true

    while true; do
        if [ "$need_full_redraw" = true ]; then
            # Show current directory and its contents
            show_directory_listing "$current_dir"

            # In browsing mode - capture single keystrokes
            if [ "$BROWSER_MODE" = "files" ]; then
                echo -e "${BRIGHT_YELLOW}↑ w  ↓ s${NC} navigate    ${BRIGHT_CYAN}[ ]${NC} previous/next page    ${BRIGHT_GREEN}enter${NC} open    ${BRIGHT_PURPLE}m${NC} mark    ${BRIGHT_CYAN}l${NC} list marked    ${BRIGHT_BLUE}space${NC} confirm    ${BRIGHT_RED}b${NC} back"
            else
                echo -e "${BRIGHT_YELLOW}↑ w  ↓ s${NC} navigate    ${BRIGHT_CYAN}[ ]${NC} previous/next page    ${BRIGHT_GREEN}enter${NC} open    ${BRIGHT_BLUE}space${NC} select    ${BRIGHT_RED}b${NC} back"
            fi
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
            NAV_PAGE=1
        elif [ $result -eq 5 ]; then
            # Navigate into selected directory using global array
            local selected_index=$((CURRENT_SELECTION - 1))
            local selected_dir="${NAV_DIRECTORIES[selected_index]}"

            if [ -n "$selected_dir" ] && [ -d "$selected_dir" ]; then
                current_dir=$(realpath "$selected_dir")
                CURRENT_SELECTION=1
                NAV_PAGE=1
            fi
        elif [ $result -eq 6 ]; then
            # Partial update - just redraw changed lines
            update_selection_display "$PREVIOUS_SELECTION" "$CURRENT_SELECTION"
            need_full_redraw=false
        elif [ $result -eq 7 ]; then
            # Partial page update - redraw paginator + list only
            update_page_display
            need_full_redraw=false
        elif [ $result -eq 8 ]; then
            # No-op - skip redraw entirely
            need_full_redraw=false
        fi
    done
}

# Global variables for navigation state
CURRENT_SELECTION=1
PREVIOUS_SELECTION=1
declare -g -a NAV_DIRECTORIES=()
declare -g -a NAV_DISPLAY_NAMES=()
declare -g -a NAV_ITEM_TYPES=()      # "dir" or "file" for each item
declare -g -a MARKED_FILES=()        # Absolute paths of marked files
declare -g BROWSER_MODE="directory"  # "directory" or "files"
declare -g NAV_PAGE=1                # Current page (1-indexed)
declare -g NAV_PAGE_SIZE=15          # Items per page
NAV_LIST_START_LINE=9  # Line where directory list starts (after header + location + page info)

# Check if a file is marked
is_file_marked() {
    local file_path="$1"
    local abs_path=$(realpath "$file_path" 2>/dev/null)
    for marked in "${MARKED_FILES[@]}"; do
        [ "$marked" = "$abs_path" ] && return 0
    done
    return 1
}

# Function to render a single directory line
# Parameters: index (0-based), is_selected (0 or 1)
render_directory_line() {
    local index="$1"
    local is_selected="$2"
    local counter=$((index + 1))
    local item_name="${NAV_DISPLAY_NAMES[index]}"
    local item_type="${NAV_ITEM_TYPES[index]:-dir}"
    local item_path="${NAV_DIRECTORIES[index]}"
    local icon=""
    local mark=""

    # Choose appropriate icon
    if [[ "$item_name" == ".. (parent directory)" ]]; then
        icon="⬆️ "
    elif [ "$item_type" = "file" ]; then
        icon="📄 "
        # Show mark indicator for files in file mode
        if [ "$BROWSER_MODE" = "files" ] && is_file_marked "$item_path"; then
            mark="${BRIGHT_GREEN}●${NC} "
        fi
    else
        icon="📂 "
    fi

    if [ "$is_selected" -eq 1 ]; then
        # Highlight current selection with arrow
        printf "  ${BRIGHT_YELLOW}▶ %-2s${NC}  ${mark}${icon}${BRIGHT_YELLOW}%s${NC}" "$counter" "$item_name"
    else
        # Normal entry
        printf "    ${BRIGHT_CYAN}%-2s${NC}  ${mark}${icon}${BRIGHT_WHITE}%s${NC}" "$counter" "$item_name"
    fi
}

# Function to update selection display without full redraw
update_selection_display() {
    local old_sel="$1"
    local new_sel="$2"

    printf '\033[?25l'  # Hide cursor

    # Calculate page-relative positions (1-indexed within page)
    local page_start=$(( (NAV_PAGE - 1) * NAV_PAGE_SIZE + 1 ))
    local old_page_pos=$((old_sel - page_start + 1))
    local new_page_pos=$((new_sel - page_start + 1))

    # Move to old selection line and redraw as unselected
    local old_line=$((NAV_LIST_START_LINE + old_page_pos - 1))
    printf '\033[%d;1H\033[K' "$old_line"  # Move to line, clear it
    render_directory_line $((old_sel - 1)) 0

    # Move to new selection line and redraw as selected
    local new_line=$((NAV_LIST_START_LINE + new_page_pos - 1))
    printf '\033[%d;1H\033[K' "$new_line"  # Move to line, clear it
    render_directory_line $((new_sel - 1)) 1

    # Move cursor below menu line (fixed height: list + blank + menu + 1)
    local input_line=$((NAV_LIST_START_LINE + NAV_PAGE_SIZE + 2))
    printf '\033[%d;1H' "$input_line"
}

# Function to update page display without full redraw (paginator + list only)
update_page_display() {
    printf '\033[?25l'  # Hide cursor

    local total_items=${#NAV_DIRECTORIES[@]}
    local total_pages=$(( (total_items + NAV_PAGE_SIZE - 1) / NAV_PAGE_SIZE ))
    local start_index=$(( (NAV_PAGE - 1) * NAV_PAGE_SIZE ))
    local end_index=$(( start_index + NAV_PAGE_SIZE - 1 ))
    [ "$end_index" -ge "$total_items" ] && end_index=$((total_items - 1))

    # Move to page indicator line (NAV_LIST_START_LINE - 2)
    local page_line=$((NAV_LIST_START_LINE - 2))
    printf '\033[%d;1H\033[K' "$page_line"

    # Redraw page indicator
    local first_item=$((start_index + 1))
    local last_item=$((end_index + 1))
    local marked_info=""
    if [ "$BROWSER_MODE" = "files" ] && [ ${#MARKED_FILES[@]} -gt 0 ]; then
        marked_info="  ${BRIGHT_GREEN}● ${#MARKED_FILES[@]} files marked${NC}"
    fi
    echo -e "${NC}Page ${NAV_PAGE}/${total_pages}  [${first_item}-${last_item} of ${total_items}]${marked_info}${NC}"

    # Skip blank line (already exists)
    printf '\033[%d;1H' "$NAV_LIST_START_LINE"

    # Redraw all list lines
    local items_on_page=$((end_index - start_index + 1))
    for (( i=start_index; i<=end_index; i++ )); do
        printf '\033[K'  # Clear line
        local is_selected=0
        [[ $((i + 1)) -eq "$CURRENT_SELECTION" ]] && is_selected=1
        render_directory_line "$i" "$is_selected"
        echo ""
    done

    # Clear padding lines
    local padding=$((NAV_PAGE_SIZE - items_on_page))
    for (( p=0; p<padding; p++ )); do
        printf '\033[K\n'
    done

    # Move cursor below menu line
    local input_line=$((NAV_LIST_START_LINE + NAV_PAGE_SIZE + 2))
    printf '\033[%d;1H' "$input_line"
}

# Function to show directory listing
show_directory_listing() {
    local dir="$1"

    printf '\033[?25l'  # Hide cursor during redraw
    clear
    if [ "$BROWSER_MODE" = "files" ]; then
        print_header "FILE BROWSER"
    else
        print_header "DIRECTORY BROWSER"
    fi
    echo ""
    local absolute_path=$(realpath "$dir")
    local display_path="${absolute_path/#$HOME/\~}"
    print_color "$BRIGHT_CYAN" "Current location: ${BRIGHT_WHITE}${display_path}${NC}"
    echo ""

    # Clear and populate global arrays
    NAV_DIRECTORIES=()
    NAV_DISPLAY_NAMES=()
    NAV_ITEM_TYPES=()

    # Add parent directory option (don't go above /home)
    local current_real_path=$(realpath "$dir")
    local can_go_up=false
    [ "$current_real_path" != "/home" ] && can_go_up=true

    if [ "$can_go_up" = true ]; then
        NAV_DIRECTORIES+=("$dir/..")
        NAV_DISPLAY_NAMES+=(".. (parent directory)")
        NAV_ITEM_TYPES+=("dir")
    fi

    if [ "$BROWSER_MODE" = "files" ]; then
        # File mode: show directories first, then files (including hidden)
        while IFS= read -r -d '' item; do
            local basename_item=$(basename "$item")
            if [ -d "$item" ]; then
                NAV_DIRECTORIES+=("$item")
                NAV_DISPLAY_NAMES+=("$basename_item/")
                NAV_ITEM_TYPES+=("dir")
            fi
        done < <(find "$dir" -mindepth 1 -maxdepth 1 -type d -print0 2>/dev/null | sort -z)

        while IFS= read -r -d '' item; do
            local basename_item=$(basename "$item")
            NAV_DIRECTORIES+=("$item")
            NAV_DISPLAY_NAMES+=("$basename_item")
            NAV_ITEM_TYPES+=("file")
        done < <(find "$dir" -mindepth 1 -maxdepth 1 -type f -print0 2>/dev/null | sort -z)
    else
        # Directory mode: only directories, skip hidden
        while IFS= read -r -d '' subdir; do
            if [ -d "$subdir" ]; then
                local basename_dir=$(basename "$subdir")
                if [[ ! "$basename_dir" =~ ^\. ]]; then
                    NAV_DIRECTORIES+=("$subdir")
                    NAV_DISPLAY_NAMES+=("$basename_dir/")
                    NAV_ITEM_TYPES+=("dir")
                fi
            fi
        done < <(find "$dir" -mindepth 1 -maxdepth 1 -type d -print0 2>/dev/null | sort -z)
    fi

    if [ ${#NAV_DIRECTORIES[@]} -eq 0 ]; then
        if [ "$BROWSER_MODE" = "files" ]; then
            print_warning "No items found in this location"
        else
            print_warning "No directories found in this location"
        fi
        echo ""
        echo -e "${BRIGHT_YELLOW}Press 'Space' to select current directory or 'b' to return${NC}"
        return
    fi

    # Pagination calculations
    local total_items=${#NAV_DIRECTORIES[@]}
    local total_pages=$(( (total_items + NAV_PAGE_SIZE - 1) / NAV_PAGE_SIZE ))

    # Clamp page to valid range
    [ "$NAV_PAGE" -lt 1 ] && NAV_PAGE=1
    [ "$NAV_PAGE" -gt "$total_pages" ] && NAV_PAGE=$total_pages

    # Calculate page bounds (0-indexed)
    local start_index=$(( (NAV_PAGE - 1) * NAV_PAGE_SIZE ))
    local end_index=$(( start_index + NAV_PAGE_SIZE - 1 ))
    [ "$end_index" -ge "$total_items" ] && end_index=$((total_items - 1))

    # Show page indicator
    local first_item=$((start_index + 1))
    local last_item=$((end_index + 1))
    local marked_info=""
    if [ "$BROWSER_MODE" = "files" ] && [ ${#MARKED_FILES[@]} -gt 0 ]; then
        marked_info="  ${BRIGHT_GREEN}● ${#MARKED_FILES[@]} files marked${NC}"
    fi
    echo -e "${NC}Page ${NAV_PAGE}/${total_pages}  [${first_item}-${last_item} of ${total_items}]${marked_info}${NC}"
    echo ""

    # Display stylized list with icons (only current page)
    local items_on_page=$((end_index - start_index + 1))
    for (( i=start_index; i<=end_index; i++ )); do
        local is_selected=0
        [[ $((i + 1)) -eq "$CURRENT_SELECTION" ]] && is_selected=1
        render_directory_line "$i" "$is_selected"
        echo ""  # newline after each line
    done

    # Pad with empty lines to maintain fixed height
    local padding=$((NAV_PAGE_SIZE - items_on_page))
    for (( p=0; p<padding; p++ )); do
        echo ""
    done

    echo ""
}

# Function to handle browsing keys
handle_browsing_key() {
    local key="$1"
    local current_dir="$2"

    # Use global NAV_DIRECTORIES array (populated by show_directory_listing)
    local -n directories=NAV_DIRECTORIES

    # Calculate page bounds for navigation
    local total_items=${#directories[@]}
    local total_pages=$(( (total_items + NAV_PAGE_SIZE - 1) / NAV_PAGE_SIZE ))
    local page_start=$(( (NAV_PAGE - 1) * NAV_PAGE_SIZE + 1 ))
    local page_end=$(( NAV_PAGE * NAV_PAGE_SIZE ))
    [ "$page_end" -gt "$total_items" ] && page_end=$total_items

    case "$key" in
        w|W)
            # Move selection up within page
            PREVIOUS_SELECTION=$CURRENT_SELECTION
            if [ "$CURRENT_SELECTION" -gt "$page_start" ]; then
                CURRENT_SELECTION=$((CURRENT_SELECTION - 1))
            else
                # Wrap to bottom of page
                CURRENT_SELECTION=$page_end
            fi
            return 6  # Partial update
            ;;
        s|S)
            # Move selection down within page
            PREVIOUS_SELECTION=$CURRENT_SELECTION
            if [ "$CURRENT_SELECTION" -lt "$page_end" ]; then
                CURRENT_SELECTION=$((CURRENT_SELECTION + 1))
            else
                # Wrap to top of page
                CURRENT_SELECTION=$page_start
            fi
            return 6  # Partial update
            ;;
        '[')
            # Previous page
            if [ "$NAV_PAGE" -gt 1 ]; then
                NAV_PAGE=$((NAV_PAGE - 1))
                # Set selection to first item of new page
                CURRENT_SELECTION=$(( (NAV_PAGE - 1) * NAV_PAGE_SIZE + 1 ))
                return 7  # Partial page redraw
            fi
            # At bounds - do nothing
            return 8
            ;;
        ']')
            # Next page
            if [ "$NAV_PAGE" -lt "$total_pages" ]; then
                NAV_PAGE=$((NAV_PAGE + 1))
                # Set selection to first item of new page
                CURRENT_SELECTION=$(( (NAV_PAGE - 1) * NAV_PAGE_SIZE + 1 ))
                return 7  # Partial page redraw
            fi
            # At bounds - do nothing
            return 8
            ;;
        $'\n'|$'\r'|'')
            # Enter key - navigate directly into selected directory/parent
            if [ ${#directories[@]} -gt 0 ] && [ "$CURRENT_SELECTION" -le "${#directories[@]}" ]; then
                local selected_index=$((CURRENT_SELECTION - 1))
                local selected_item="${directories[selected_index]}"
                local item_type="${NAV_ITEM_TYPES[selected_index]:-dir}"

                # Check if it's parent directory
                if [[ "$selected_item" == *".." ]]; then
                    return 4  # Signal navigation to parent
                elif [ "$item_type" = "dir" ]; then
                    # Navigate into directory (continue browsing)
                    return 5  # Signal navigation into directory
                fi
                # If it's a file, do nothing (enter doesn't open files)
            fi
            return 0
            ;;
        ' ')
            if [ "$BROWSER_MODE" = "files" ]; then
                # File mode: confirm marked files selection
                if [ ${#MARKED_FILES[@]} -gt 0 ]; then
                    echo ""
                    print_success "Selected ${#MARKED_FILES[@]} file(s)"
                    return 1  # Signal selection made
                else
                    echo ""
                    print_warning "No files marked. Use 'm' to mark files."
                    sleep 1
                    return 0
                fi
            else
                # Directory mode: select current directory as projects directory
                local absolute_path=$(realpath "$current_dir")
                local display_path="${absolute_path/#$HOME/\~}"
                echo ""
                print_success "Selected directory: $display_path"
                export SELECTED_PROJECTS_DIR="$absolute_path"
                return 1  # Signal selection made
            fi
            ;;
        m|M)
            # Mark/unmark current file (files mode only)
            if [ "$BROWSER_MODE" = "files" ]; then
                local selected_index=$((CURRENT_SELECTION - 1))
                local item_type="${NAV_ITEM_TYPES[selected_index]:-dir}"
                local item_path="${directories[selected_index]}"

                if [ "$item_type" = "file" ]; then
                    local abs_path=$(realpath "$item_path")
                    if is_file_marked "$item_path"; then
                        # Unmark: remove from array
                        local new_marked=()
                        for m in "${MARKED_FILES[@]}"; do
                            [ "$m" != "$abs_path" ] && new_marked+=("$m")
                        done
                        MARKED_FILES=("${new_marked[@]}")
                    else
                        # Mark: add to array
                        MARKED_FILES+=("$abs_path")
                    fi
                    # Partial page update to show mark change and update counter
                    return 7
                fi
            fi
            return 0
            ;;
        l|L)
            # List marked files (files mode only)
            if [ "$BROWSER_MODE" = "files" ]; then
                printf '\033[?25l'  # Hide cursor
                clear
                print_header "MARKED FILES"
                echo ""
                if [ ${#MARKED_FILES[@]} -eq 0 ]; then
                    echo -e "${DIM}No files marked.${NC}"
                else
                    echo -e "${DIM}${#MARKED_FILES[@]} file(s) marked:${NC}"
                    echo ""
                    for marked_file in "${MARKED_FILES[@]}"; do
                        local display_path="${marked_file/#$HOME/\~}"
                        echo -e "  ${BRIGHT_GREEN}●${NC} ${BRIGHT_WHITE}${display_path}${NC}"
                    done
                fi
                echo ""
                echo -e "${DIM}Press any key to continue...${NC}"
                IFS= read -r -n1 -s
            fi
            return 0
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