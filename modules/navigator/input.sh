#!/bin/bash

# ========================================
# Filesystem Navigator Input Handling
# ========================================
# Key handling for navigation
# Usage: source modules/navigator/input.sh

# Function to handle browsing keys
# Return codes:
#   0 = continue (full redraw)
#   1 = selection made
#   2 = back/cancel
#   4 = navigate to parent
#   5 = navigate into directory
#   6 = partial update (selection change)
#   7 = partial page update
#   8 = no-op (skip redraw)
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
            return 8  # No action needed, skip redraw
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
                        if [ "$NAV_SINGLE_MARK_MODE" = "true" ]; then
                            # Single mark mode: replace previous mark
                            MARKED_FILES=("$abs_path")
                        else
                            # Multi mark mode: append to array
                            MARKED_FILES+=("$abs_path")
                        fi
                    fi
                    # Partial page update to show mark change and update counter
                    return 7
                fi
            fi
            return 8  # Not a file, skip redraw
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
        h|H)
            # Show help screen
            display_navigator_help
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
            # Silently ignore invalid keys - no redraw
            return 8
            ;;
    esac
}
