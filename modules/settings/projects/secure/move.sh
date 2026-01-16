#!/bin/bash

# ========================================
# Secure Files - Move from Vault
# ========================================
# Confirm and execute moving files from vault back to project
# Usage: source modules/settings/projects/secure/move.sh

# Show confirmation screen for moving files from vault back to project
# Parameters: project_name, project_path
# Uses: MARKED_FILES array from navigator
# Returns: 0 if confirmed, 1 if cancelled
confirm_move_from_vault() {
    local project_name="$1"
    local project_path="$2"
    local vault_project_dir="${SELECTED_VAULT_MOUNT}/${project_name}"

    clear
    print_header "CONFIRM MOVE FROM VAULT"
    echo ""
    print_warning_box
    echo ""
    echo -e "${BOLD}This operation will${NC}"
    echo -e "  1. Move files from vault '${SELECTED_VAULT_NAME}' back to project"
    echo -e "  2. ${BRIGHT_RED}Delete${NC} symlinks from the project directory"
    echo -e "  3. Restore original files in their place"
    echo ""
    echo -e "${BOLD}Files to restore (${#MARKED_FILES[@]}):${NC}"
    echo ""

    for file in "${MARKED_FILES[@]}"; do
        local relative_path="${file#$vault_project_dir/}"
        if [ -d "$file" ]; then
            echo -e "  ${BRIGHT_CYAN}📁${NC} ${relative_path}"
        else
            echo -e "  ${BRIGHT_WHITE}📄${NC} ${relative_path}"
        fi
    done

    echo ""
    echo -e "${BOLD}Source:${NC}"
    echo -e "  ${DIM}${SELECTED_VAULT_MOUNT}/${project_name}${NC}"
    echo ""
    echo -e "${BOLD}Destination:${NC}"
    echo -e "  ${DIM}${project_path}${NC}"
    echo ""
    echo -ne "${BOLD}Type 'yes' to confirm: ${NC}"

    local confirm
    read confirm

    if [ "$confirm" = "yes" ]; then
        return 0
    fi
    return 1
}

# Execute the move from vault operation
# Parameters: project_name, project_path
# Uses: MARKED_FILES, SELECTED_VAULT_MOUNT
# Returns: 0 on success
execute_move_from_vault() {
    local project_name="$1"
    local project_path="$2"
    local vault_project_dir="${SELECTED_VAULT_MOUNT}/${project_name}"

    echo ""
    echo -e "${DIM}Restoring files from vault...${NC}"
    echo ""

    local success_count=0
    local fail_count=0

    for vault_file in "${MARKED_FILES[@]}"; do
        # Calculate relative path from vault project root
        local relative_path="${vault_file#$vault_project_dir/}"

        # Target path in project
        local project_target="${project_path}/${relative_path}"
        local project_target_dir=$(dirname "$project_target")

        # Check if symlink exists at target location
        if [ -L "$project_target" ]; then
            # Remove the symlink
            if ! rm "$project_target" 2>/dev/null; then
                echo -e "  ${BRIGHT_RED}✗${NC} Failed to remove symlink: ${relative_path}"
                fail_count=$((fail_count + 1))
                continue
            fi
        elif [ -e "$project_target" ]; then
            # File exists but is not a symlink - don't overwrite
            echo -e "  ${BRIGHT_RED}✗${NC} File exists (not a symlink): ${relative_path}"
            fail_count=$((fail_count + 1))
            continue
        fi

        # Ensure target directory exists in project
        if ! mkdir -p "$project_target_dir" 2>/dev/null; then
            echo -e "  ${BRIGHT_RED}✗${NC} Failed to create directory: ${relative_path}"
            fail_count=$((fail_count + 1))
            continue
        fi

        # Move file from vault back to project
        if ! mv "$vault_file" "$project_target" 2>/dev/null; then
            echo -e "  ${BRIGHT_RED}✗${NC} Failed to move: ${relative_path}"
            fail_count=$((fail_count + 1))
            continue
        fi

        echo -e "  ${BRIGHT_GREEN}✓${NC} ${relative_path}"
        success_count=$((success_count + 1))
    done

    echo ""
    if [ $fail_count -eq 0 ]; then
        echo -e "${BRIGHT_GREEN}Successfully restored ${success_count} item(s).${NC}"
    else
        echo -e "${BRIGHT_YELLOW}Restored ${success_count} item(s), ${fail_count} failed.${NC}"
    fi
    echo ""
    wait_for_enter
    return 0
}
