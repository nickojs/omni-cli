#!/bin/bash

# ========================================
# Vaults Storage Module
# ========================================
# Handles JSON storage for vaults
# Usage: source modules/settings/secrets/vaults_storage.sh

# Get path to vaults JSON file
get_vaults_file() {
    local config_dir=$(get_config_directory)
    echo "$config_dir/.vaults.json"
}

# Ensure vaults file exists
ensure_vaults_file() {
    local vaults_file=$(get_vaults_file)
    if [ ! -f "$vaults_file" ]; then
        echo "[]" > "$vaults_file"
    fi
}

# Load vaults into array
# Parameters: array_name_ref
# Returns: name:cipherDir:mountPoint:secretId
load_vaults() {
    local -n result_array=$1
    result_array=()

    local vaults_file=$(get_vaults_file)
    if [ ! -f "$vaults_file" ]; then
        return 0
    fi

    if ! command -v jq >/dev/null 2>&1; then
        return 1
    fi

    while IFS= read -r line; do
        [ -n "$line" ] && result_array+=("$line")
    done < <(jq -r '.[] | "\(.name):\(.cipherDir):\(.mountPoint):\(.secretId)"' "$vaults_file" 2>/dev/null)
}

# Save a new vault
# Parameters: name, cipher_dir, mount_point, secret_id
save_vault() {
    local name="$1"
    local cipher_dir="$2"
    local mount_point="$3"
    local secret_id="$4"

    ensure_vaults_file
    local vaults_file=$(get_vaults_file)

    local temp_file=$(mktemp)
    if jq --arg name "$name" \
          --arg cipherDir "$cipher_dir" \
          --arg mountPoint "$mount_point" \
          --arg secretId "$secret_id" \
          '. += [{"name": $name, "cipherDir": $cipherDir, "mountPoint": $mountPoint, "secretId": $secretId}]' \
          "$vaults_file" > "$temp_file" 2>/dev/null; then
        mv "$temp_file" "$vaults_file"
        return 0
    fi
    rm -f "$temp_file"
    return 1
}

# Restore all files from a vault back to their original project locations
# Parameters: vault_mount_point, vault_name (for display)
# Returns: 0 on success
restore_all_vault_files() {
    local vault_mount="$1"
    local vault_name="$2"

    # Check if vault directory exists and has content
    if [ ! -d "$vault_mount" ]; then
        return 0
    fi

    echo ""
    echo -e "${DIM}Restoring files from vault '$vault_name'...${NC}"
    echo ""

    local restored_count=0
    local failed_count=0

    # Find all project directories in the vault
    for project_dir in "$vault_mount"/*/ ; do
        [ ! -d "$project_dir" ] && continue

        local project_name=$(basename "$project_dir")

        # Try to find the corresponding project in workspaces
        # Load all projects and look for matching name
        local -a all_projects=()
        load_projects_from_json

        local project_path=""
        for proj_info in "${projects[@]}"; do
            IFS=':' read -r _ path _ _ <<< "$proj_info"
            if [ "$(basename "$path")" = "$project_name" ]; then
                project_path="$path"
                break
            fi
        done

        # If project not found in workspaces, skip it
        if [ -z "$project_path" ]; then
            echo -e "  ${BRIGHT_YELLOW}⚠${NC}  Project '$project_name' not found in workspaces, skipping"
            continue
        fi

        # Restore all files from this project's vault directory
        while IFS= read -r -d '' vault_file; do
            # Get relative path from vault project directory
            local relative_path="${vault_file#$project_dir}"
            local project_target="$project_path/$relative_path"

            # Check if symlink exists at target location
            if [ -L "$project_target" ]; then
                # Remove the symlink
                if ! rm "$project_target" 2>/dev/null; then
                    echo -e "  ${BRIGHT_RED}✗${NC} Failed to remove symlink: $relative_path"
                    failed_count=$((failed_count + 1))
                    continue
                fi
            elif [ -e "$project_target" ]; then
                # File exists but is not a symlink - don't overwrite
                echo -e "  ${BRIGHT_YELLOW}⚠${NC}  File exists (not a symlink): $relative_path"
                failed_count=$((failed_count + 1))
                continue
            fi

            # Ensure target directory exists
            local project_target_dir=$(dirname "$project_target")
            if ! mkdir -p "$project_target_dir" 2>/dev/null; then
                echo -e "  ${BRIGHT_RED}✗${NC} Failed to create directory: $relative_path"
                failed_count=$((failed_count + 1))
                continue
            fi

            # Move file from vault back to project
            if ! mv "$vault_file" "$project_target" 2>/dev/null; then
                echo -e "  ${BRIGHT_RED}✗${NC} Failed to restore: $relative_path"
                failed_count=$((failed_count + 1))
                continue
            fi

            echo -e "  ${BRIGHT_GREEN}✓${NC} $project_name/$relative_path"
            restored_count=$((restored_count + 1))
        done < <(find "$project_dir" -type f -print0)
    done

    echo ""
    if [ $failed_count -eq 0 ] && [ $restored_count -gt 0 ]; then
        echo -e "${BRIGHT_GREEN}Successfully restored $restored_count file(s).${NC}"
    elif [ $restored_count -eq 0 ]; then
        echo -e "${DIM}No files to restore.${NC}"
    else
        echo -e "${BRIGHT_YELLOW}Restored $restored_count file(s), $failed_count failed.${NC}"
    fi
    echo ""

    return 0
}

# Delete a vault by index (0-based)
# Parameters: index
delete_vault() {
    local index="$1"

    # Get vault info before deletion
    local -a vaults=()
    load_vaults vaults

    if [ "$index" -ge "${#vaults[@]}" ]; then
        return 1
    fi

    local vault_info="${vaults[$index]}"
    IFS=':' read -r name _ mount_point _ <<< "$vault_info"

    # Restore all files from vault before deletion
    restore_all_vault_files "$mount_point" "$name"
    wait_for_enter

    local vaults_file=$(get_vaults_file)
    if [ ! -f "$vaults_file" ]; then
        return 1
    fi

    local temp_file=$(mktemp)
    if jq --argjson idx "$index" 'del(.[$idx])' "$vaults_file" > "$temp_file" 2>/dev/null; then
        mv "$temp_file" "$vaults_file"
        return 0
    fi
    rm -f "$temp_file"
    return 1
}

# Update vault's secret assignment
# Parameters: vault_index (0-based), new_secret_id
# Returns: 0 on success, 1 on failure
update_vault_secret() {
    local vault_index="$1"
    local new_secret_id="$2"

    local vaults_file=$(get_vaults_file)
    if [ ! -f "$vaults_file" ]; then
        return 1
    fi

    # Verify the new secret exists
    if ! get_secret_by_id "$new_secret_id" >/dev/null 2>&1; then
        echo "Secret ID not found: $new_secret_id"
        return 1
    fi

    local temp_file=$(mktemp)
    if jq --argjson idx "$vault_index" \
          --arg secretId "$new_secret_id" \
          '.[$idx].secretId = $secretId' \
          "$vaults_file" > "$temp_file" 2>/dev/null; then
        mv "$temp_file" "$vaults_file"
        return 0
    fi
    rm -f "$temp_file"
    return 1
}

# Get secret by UUID
# Parameters: secret_id
# Returns: id:privateKey:publicKey:encryptedPassphrase (echoes to stdout)
get_secret_by_id() {
    local secret_id="$1"

    local secrets_file=$(get_secrets_file)
    if [ ! -f "$secrets_file" ]; then
        return 1
    fi

    local result
    result=$(jq -r --arg id "$secret_id" '.[] | select(.id == $id) | "\(.id):\(.privateKey):\(.publicKey):\(.encryptedPassphrase)"' "$secrets_file" 2>/dev/null)

    if [ -n "$result" ]; then
        echo "$result"
        return 0
    fi
    return 1
}

# Get vault mount status
# Parameters: mount_point
# Returns: 0 if mounted, 1 if not
get_vault_status() {
    local mount_point="$1"

    if mountpoint -q "$mount_point" 2>/dev/null; then
        return 0
    fi
    return 1
}
