#!/bin/bash

# ========================================
# Secure Files Module
# ========================================
# Move files from project to vault and symlink back
# Usage: source modules/settings/projects/secure/index.sh

# Get the directory of this script
SECURE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Global for selected vault info
declare -g SELECTED_VAULT_NAME=""
declare -g SELECTED_VAULT_MOUNT=""

# Cache for vault lookups (populated by init_vault_lookup)
declare -gA VAULT_MOUNT_MAP=()    # mount_point -> vault_name
declare -ga VAULT_MOUNT_LIST=()   # ordered list of mount points

# Source sub-modules
source "$SECURE_DIR/menu.sh"
source "$SECURE_DIR/add.sh"
source "$SECURE_DIR/move.sh"

# Main flow orchestrator
# Parameters: project_display_name, project_path
show_secure_files_flow() {
    local project_display_name="$1"
    local project_path="$2"
    local project_name=$(basename "$project_path")

    # Step 1: Select vault and operation
    select_vault_screen
    local operation=$?

    if [ $operation -eq 1 ]; then
        return 1  # User cancelled
    elif [ $operation -eq 10 ]; then
        # Add to vault operation
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
            wait_for_enter
            return 1
        fi

        # Step 4: Execute
        execute_secure_files "$project_name" "$project_path"
    elif [ $operation -eq 20 ]; then
        # Move from vault operation
        local vault_project_dir="${SELECTED_VAULT_MOUNT}/${project_name}"

        # Check if project directory exists in vault
        if [ ! -d "$vault_project_dir" ]; then
            clear
            print_header "MOVE FROM VAULT"
            echo ""
            echo -e "${DIM}No files found for this project in vault '${SELECTED_VAULT_NAME}'.${NC}"
            echo ""
            wait_for_enter
            return 1
        fi

        # Step 2: Browse vault and mark files to restore
        show_interactive_browser "files" "$vault_project_dir" "$vault_project_dir"

        # Check if any files were marked
        if [ ${#MARKED_FILES[@]} -eq 0 ]; then
            echo ""
            print_warning "No files selected."
            sleep 1
            return 1
        fi

        # Step 3: Confirm
        if ! confirm_move_from_vault "$project_name" "$project_path"; then
            echo ""
            print_warning "Operation cancelled."
            wait_for_enter
            return 1
        fi

        # Step 4: Execute
        execute_move_from_vault "$project_name" "$project_path"
    fi

    return 0
}
