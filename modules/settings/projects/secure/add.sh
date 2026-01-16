#!/bin/bash

# ========================================
# Secure Files - Add to Vault
# ========================================
# Confirm and execute adding files to vault
# Usage: source modules/settings/projects/secure/add.sh

# Show confirmation screen for securing files
# Parameters: project_name, project_path
# Uses: MARKED_FILES array from navigator
# Returns: 0 if confirmed, 1 if cancelled
confirm_secure_files() {
    local project_name="$1"
    local project_path="$2"

    clear
    print_header "CONFIRM SECURE FILES"
    echo ""
    echo -e "${DIM}(Dev note: currently just supporting files)${NC}"
    echo ""
    print_warning_box
    echo -e "${BOLD}This operation will${NC}"
    echo -e "  ${NC}1. Move the following files/folders to vault '${SELECTED_VAULT_NAME}'${NC}"
    echo -e "  2. ${BRIGHT_RED}Delete${NC} them from the project directory${NC}"
    echo -e "  3. Create symlinks in their place${NC}"
    echo ""
    echo -e "${BOLD}Moving to the vault is ${BRIGHT_RED}destructive${NC}: the original file/folder ${BOLD}will be deleted${NC}."
    echo -e "This is ${BOLD}required${NC} so the symlink becomes the ${BOLD}only path${NC} to the data, preventing duplicate copies and confusion."
    echo ""
    echo -e "${ITALIC}The file/folder is restored either when a vault is removed from the config, or via user choice${NC}"
    echo ""
    echo ""
    echo -e "${BOLD}Files to secure (${#MARKED_FILES[@]}):${NC}"
    echo ""

    for file in "${MARKED_FILES[@]}"; do
        local relative_path="${file#$project_path/}"
        local display_path="${file/#$HOME/\~}"
        if [ -d "$file" ]; then
            echo -e "  ${BRIGHT_CYAN}📁${NC} ${relative_path}"
        else
            echo -e "  ${BRIGHT_WHITE}📄${NC} ${relative_path}"
        fi
    done

    echo ""
    echo -e "${BOLD}Destination:${NC}"
    echo -e "  ${DIM}${SELECTED_VAULT_MOUNT}/${project_name}${NC}"
    echo ""
    echo -e "${DIM}Note: If files are git-tracked, git will detect a type change${NC} ${BRIGHT_CYAN}(https://git-scm.com/docs/git-status#_output)${NC}."
    echo -e "${DIM}This feature works best with untracked files like .env or secrets.${NC}"
    echo ""
    echo -ne "${BRIGHT_RED}Type 'yes' to confirm: ${NC}"

    local confirm
    read confirm

    if [ "$confirm" = "yes" ]; then
        return 0
    fi
    return 1
}

# Execute the securing operation
# Parameters: project_name, project_path
# Uses: MARKED_FILES, SELECTED_VAULT_MOUNT
# Returns: 0 on success
execute_secure_files() {
    local project_name="$1"
    local project_path="$2"
    local vault_project_dir="${SELECTED_VAULT_MOUNT}/${project_name}"

    echo ""
    echo -e "${DIM}Securing files...${NC}"
    echo ""

    local success_count=0
    local fail_count=0

    for original_path in "${MARKED_FILES[@]}"; do
        # Calculate relative path from project root
        local relative_path="${original_path#$project_path/}"

        # Target path in vault
        local vault_target="${vault_project_dir}/${relative_path}"
        local vault_target_dir=$(dirname "$vault_target")

        # Ensure target directory exists in vault
        if ! mkdir -p "$vault_target_dir" 2>/dev/null; then
            echo -e "  ${BRIGHT_RED}✗${NC} Failed to create directory in vault: ${relative_path}"
            fail_count=$((fail_count + 1))
            continue
        fi

        # Move file/folder to vault
        if ! mv "$original_path" "$vault_target" 2>/dev/null; then
            echo -e "  ${BRIGHT_RED}✗${NC} Failed to move: ${relative_path}"
            fail_count=$((fail_count + 1))
            continue
        fi

        # Create symlink at original location
        if ! ln -s "$vault_target" "$original_path" 2>/dev/null; then
            echo -e "  ${BRIGHT_RED}✗${NC} Failed to create symlink: ${relative_path}"
            echo -e "      ${DIM}File was moved to vault but symlink failed!${NC}"
            fail_count=$((fail_count + 1))
            continue
        fi

        echo -e "  ${BRIGHT_GREEN}✓${NC} ${relative_path}"
        success_count=$((success_count + 1))
    done

    echo ""
    if [ $fail_count -eq 0 ]; then
        echo -e "${BRIGHT_GREEN}Successfully secured ${success_count} item(s).${NC}"
    else
        echo -e "${BRIGHT_YELLOW}Secured ${success_count} item(s), ${fail_count} failed.${NC}"
    fi
    echo ""
    wait_for_enter
    return 0
}
