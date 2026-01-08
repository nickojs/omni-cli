#!/bin/bash

# ========================================
# Secrets Add Module
# ========================================
# Handles adding new secrets
# Usage: source modules/settings/secrets/add.sh

# Prompt for secrets folder path
# Sets SECRETS_FOLDER on success
# Returns: 0 = success, 1 = cancelled/error
prompt_secrets_folder() {
    echo ""
    echo -ne "${BRIGHT_WHITE}Path to secrets folder:${NC} "
    local folder_input
    read -r folder_input

    # Empty input = cancel
    if [ -z "$folder_input" ]; then
        return 1
    fi

    # Expand ~ and resolve path
    folder_input="${folder_input/#\~/$HOME}"

    local resolved_path
    if ! resolved_path=$(realpath "$folder_input" 2>/dev/null); then
        print_error "Invalid path: $folder_input"
        sleep 1
        return 1
    fi

    if [ ! -d "$resolved_path" ]; then
        print_error "Directory does not exist: $folder_input"
        sleep 1
        return 1
    fi

    SECRETS_FOLDER="$resolved_path"
    return 0
}

# Check if a file exists in array
# Parameters: filename, array_ref
# Returns: 0 if found, 1 if not
file_in_array() {
    local needle="$1"
    local -n haystack=$2

    for item in "${haystack[@]}"; do
        [[ "$item" == "$needle" ]] && return 0
    done
    return 1
}

# File list screen with private/public key selection
# Parameters: folder_path
# Returns: 0 = back to default
show_secrets_file_list_screen() {
    local folder_path="$1"

    local -a files=()
    get_files_in_directory "$folder_path" files
    local file_count=${#files[@]}

    # No files - show message and wait for back
    if [ "$file_count" -eq 0 ]; then
        display_file_list_screen "$folder_path" files ""
        local choice
        read_with_instant_back choice
        return 0
    fi

    # Select private key
    local private_key=""
    while true; do
        display_file_list_screen "$folder_path" files "${BRIGHT_WHITE}Select private key (ESC to cancel):${NC}"

        local choice
        read_with_esc_cancel choice
        local result=$?

        # ESC pressed
        if [ $result -eq 2 ]; then
            return 0
        fi

        if [[ $choice =~ ^[Bb]$ ]]; then
            return 0
        fi

        if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "$file_count" ]; then
            private_key="${files[$((choice - 1))]}"
            break
        fi
    done

    # Try to auto-detect matching public key
    local expected_pub="${private_key}.pub"
    local public_key=""

    if file_in_array "$expected_pub" files; then
        # Found matching .pub file - auto-select
        public_key="$expected_pub"
    else
        # No match - manual selection
        while true; do
            display_file_list_screen "$folder_path" files "${BRIGHT_WHITE}Select public key (ESC to cancel):${NC}"

            local choice
            read_with_esc_cancel choice
            local result=$?

            # ESC pressed
            if [ $result -eq 2 ]; then
                return 0
            fi

            if [[ $choice =~ ^[Bb]$ ]]; then
                return 0
            fi

            if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "$file_count" ]; then
                public_key="${files[$((choice - 1))]}"
                break
            fi
        done
    fi

    # Derive name from private key filename
    local secret_name=$(basename "$private_key")

    # Build full paths
    local private_key_path="${folder_path}/${private_key}"
    local public_key_path="${folder_path}/${public_key}"

    # Save secret
    save_secret "$secret_name" "$private_key_path" "$public_key_path"

    return 0
}
