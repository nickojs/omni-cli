#!/bin/bash

# ========================================
# Project File Securing Module
# ========================================
# Move files from project to vault and symlink back
# Usage: source modules/settings/projects/secure.sh

# Global for selected vault info
declare -g SELECTED_VAULT_NAME=""
declare -g SELECTED_VAULT_MOUNT=""

# Cache for vault lookups (populated by init_vault_lookup)
declare -gA VAULT_MOUNT_MAP=()    # mount_point -> vault_name
declare -ga VAULT_MOUNT_LIST=()   # ordered list of mount points

# Show vault selection screen
# Returns: 0 if vault selected (sets SELECTED_VAULT_*), 1 if cancelled/no vaults
select_vault_screen() {
    local -a vaults=()
    load_vaults vaults

    if [ ${#vaults[@]} -eq 0 ]; then
        clear
        print_header "SECURE FILES"
        echo ""
        echo -e "${DIM}No vaults configured. Add a vault in Settings > Secrets first.${NC}"
        echo ""
        wait_for_enter
        return 1
    fi

    # Check if any vaults are mounted
    local has_mounted=false
    for vault_info in "${vaults[@]}"; do
        IFS=':' read -r name _ mount_point _ <<< "$vault_info"
        if get_vault_status "$mount_point"; then
            has_mounted=true
            break
        fi
    done

    if [ "$has_mounted" = false ]; then
        clear
        print_header "SECURE FILES"
        echo ""
        echo -e "${DIM}No vaults are currently mounted. Mount a vault first.${NC}"
        echo ""
        wait_for_enter
        return 1
    fi

    while true; do
        clear
        print_header "SELECT VAULT"
        echo ""
        echo -e "${DIM}Select a mounted vault to store secured files:${NC}"
        echo ""

        local counter=1
        local -a mounted_indices=()
        for i in "${!vaults[@]}"; do
            local vault_info="${vaults[$i]}"
            IFS=':' read -r name _ mount_point _ <<< "$vault_info"

            if get_vault_status "$mount_point"; then
                echo -e "  ${BRIGHT_CYAN}${counter}${NC}  ${BRIGHT_GREEN}●${NC} ${BRIGHT_WHITE}${name}${NC}"
                echo -e "      ${DIM}${mount_point}${NC}"
                mounted_indices+=("$i")
                counter=$((counter + 1))
            else
                echo -e "      ${DIM}○ ${name} (not mounted)${NC}"
            fi
        done

        echo ""
        echo -e "${BRIGHT_RED}b${NC} back"
        echo ""
        echo -ne "${BRIGHT_CYAN}>${NC} "

        local choice
        read choice

        if [[ "$choice" =~ ^[Bb]$ ]]; then
            return 1
        fi

        if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "${#mounted_indices[@]}" ]; then
            local selected_idx="${mounted_indices[$((choice - 1))]}"
            local vault_info="${vaults[$selected_idx]}"
            IFS=':' read -r SELECTED_VAULT_NAME _ SELECTED_VAULT_MOUNT _ <<< "$vault_info"
            return 0
        fi
    done
}

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
    echo -e "${BRIGHT_YELLOW}WARNING: This operation will:${NC}"
    echo -e "  ${DIM}1. Move the following files/folders to vault '${SELECTED_VAULT_NAME}'${NC}"
    echo -e "  ${DIM}2. Delete them from the project directory${NC}"
    echo -e "  ${DIM}3. Create symlinks in their place${NC}"
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
    echo -e "  ${DIM}${SELECTED_VAULT_MOUNT}/${project_name}/...${NC}"
    echo ""
    echo -e "${BRIGHT_RED}This action cannot be easily undone.${NC}"
    echo ""
    echo -ne "${BRIGHT_YELLOW}Type 'yes' to confirm: ${NC}"

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

# Main flow orchestrator
# Parameters: project_display_name, project_path
show_secure_files_flow() {
    local project_display_name="$1"
    local project_path="$2"
    local project_name=$(basename "$project_path")

    # Step 1: Select vault
    if ! select_vault_screen; then
        return 1
    fi

    # Step 2: Browse and mark files
    show_interactive_browser "files" "$project_path" "$project_path"

    # Check if any files were marked
    if [ ${#MARKED_FILES[@]} -eq 0 ]; then
        echo ""
        print_warning "No files selected."
        sleep 1
        return 1
    fi

    # Step 3: Confirm
    if ! confirm_secure_files "$project_name" "$project_path"; then
        echo ""
        print_warning "Operation cancelled."
        sleep 1
        return 1
    fi

    # Step 4: Execute
    execute_secure_files "$project_name" "$project_path"

    return 0
}
