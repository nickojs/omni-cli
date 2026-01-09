#!/bin/bash

# ========================================
# Secrets Add Module
# ========================================
# Handles adding new secrets
# Usage: source modules/settings/secrets/add.sh

# Get files in a directory recursively
# Parameters: directory_path, array_name_ref
# Returns: populates array with relative paths (skips hidden files/dirs)
get_files_in_directory() {
    local dir_path="$1"
    local -n result_array=$2

    result_array=()

    if [ ! -d "$dir_path" ]; then
        return 1
    fi

    while IFS= read -r -d '' file; do
        local relative_path="${file#$dir_path/}"
        local filename=$(basename "$file")

        # Skip hidden files (basename check only, not full path)
        if [[ ! "$filename" =~ ^\. ]]; then
            result_array+=("$relative_path")
        fi
    done < <(find "$dir_path" -mindepth 1 -type f -print0 | sort -z)

    return 0
}

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

# Find identity files matching pattern {path/keyname}_*.age
# Parameters: private_key_path, files_array_ref, results_array_ref
# Populates results_array with matching files
find_identity_files() {
    local private_key_path="$1"
    local -n files_ref=$2
    local -n results_ref=$3
    results_ref=()

    # Pattern includes directory if present (e.g., "scenario1/testkey_")
    local pattern="${private_key_path}_"
    for file in "${files_ref[@]}"; do
        if [[ "$file" == ${pattern}*.age ]]; then
            results_ref+=("$file")
        fi
    done
}

# Filter files by extension
# Parameters: extension, files_array_ref, results_array_ref
filter_files_by_extension() {
    local extension="$1"
    local -n files_ref=$2
    local -n results_ref=$3
    results_ref=()

    for file in "${files_ref[@]}"; do
        if [[ "$file" == *"$extension" ]]; then
            results_ref+=("$file")
        fi
    done
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

    # Try to auto-detect identity file (use full path for pattern matching)
    local -a identity_matches=()
    find_identity_files "$private_key" files identity_matches
    local match_count=${#identity_matches[@]}
    local identity_file=""

    if [ "$match_count" -eq 1 ]; then
        # Exactly one match - auto-select
        identity_file="${identity_matches[0]}"
    else
        # No match or multiple matches - filter to .age files and prompt
        local -a age_files=()
        filter_files_by_extension ".age" files age_files
        local age_count=${#age_files[@]}

        if [ "$age_count" -eq 0 ]; then
            print_error "No .age identity files found in this directory"
            sleep 1
            return 0
        fi

        while true; do
            display_file_list_screen "$folder_path" age_files "${BRIGHT_WHITE}Select identity file (ESC to cancel):${NC}"

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

            if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "$age_count" ]; then
                identity_file="${age_files[$((choice - 1))]}"
                break
            fi
        done
    fi

    # Build full paths
    local private_key_path="${folder_path}/${private_key}"
    local public_key_path="${folder_path}/${public_key}"
    local identity_file_path="${folder_path}/${identity_file}"

    # Save secret
    save_secret "$secret_name" "$private_key_path" "$public_key_path" "$identity_file_path"

    return 0
}
