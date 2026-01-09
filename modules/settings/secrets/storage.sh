#!/bin/bash

# ========================================
# Secrets Storage Module
# ========================================
# Handles JSON storage for secrets
# Usage: source modules/settings/secrets/storage.sh

# Get path to secrets JSON file
get_secrets_file() {
    local config_dir=$(get_config_directory)
    echo "$config_dir/.secrets.json"
}

# Ensure secrets file exists
ensure_secrets_file() {
    local secrets_file=$(get_secrets_file)
    if [ ! -f "$secrets_file" ]; then
        echo "[]" > "$secrets_file"
    fi
}

# Load secrets into array
# Parameters: array_name_ref
# Usage: load_secrets secrets_array
load_secrets() {
    local -n result_array=$1
    result_array=()

    local secrets_file=$(get_secrets_file)
    if [ ! -f "$secrets_file" ]; then
        return 0
    fi

    if ! command -v jq >/dev/null 2>&1; then
        return 1
    fi

    while IFS= read -r line; do
        [ -n "$line" ] && result_array+=("$line")
    done < <(jq -r '.[] | "\(.name):\(.privateKey):\(.publicKey):\(.identityFile)"' "$secrets_file" 2>/dev/null)
}

# Save a new secret
# Parameters: name, private_key_path, public_key_path, identity_file_path
save_secret() {
    local name="$1"
    local private_key="$2"
    local public_key="$3"
    local identity_file="$4"

    ensure_secrets_file
    local secrets_file=$(get_secrets_file)

    local temp_file=$(mktemp)
    if jq --arg name "$name" \
          --arg privateKey "$private_key" \
          --arg publicKey "$public_key" \
          --arg identityFile "$identity_file" \
          '. += [{"name": $name, "privateKey": $privateKey, "publicKey": $publicKey, "identityFile": $identityFile}]' \
          "$secrets_file" > "$temp_file" 2>/dev/null; then
        mv "$temp_file" "$secrets_file"
        return 0
    fi
    rm -f "$temp_file"
    return 1
}

# Delete a secret by index (0-based)
# Parameters: index
delete_secret() {
    local index="$1"

    local secrets_file=$(get_secrets_file)
    if [ ! -f "$secrets_file" ]; then
        return 1
    fi

    local temp_file=$(mktemp)
    if jq --argjson idx "$index" 'del(.[$idx])' "$secrets_file" > "$temp_file" 2>/dev/null; then
        mv "$temp_file" "$secrets_file"
        return 0
    fi
    rm -f "$temp_file"
    return 1
}
