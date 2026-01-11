#!/bin/bash

# ========================================
# Vault Operations Module
# ========================================
# Mount, unmount, and init operations for gocryptfs vaults
# Usage: source modules/settings/secrets/vaults_ops.sh

# Mount a vault
# Parameters: vault_index (0-based)
# Returns: 0 on success, 1 on failure
mount_vault() {
    local vault_index="$1"

    local -a vaults=()
    load_vaults vaults

    if [ "$vault_index" -lt 0 ] || [ "$vault_index" -ge "${#vaults[@]}" ]; then
        echo "Invalid vault index"
        return 1
    fi

    local vault_info="${vaults[$vault_index]}"
    IFS=':' read -r name cipher_dir mount_point secret_id <<< "$vault_info"

    # Check if already mounted
    if get_vault_status "$mount_point"; then
        echo "Vault '$name' is already mounted"
        return 1
    fi

    # Get secret data
    local secret_data
    if ! secret_data=$(get_secret_by_id "$secret_id"); then
        echo "Secret not found for vault '$name'"
        return 1
    fi

    IFS=':' read -r _ private_key _ encrypted_passphrase <<< "$secret_data"

    # Ensure mount point exists
    if [ ! -d "$mount_point" ]; then
        mkdir -p "$mount_point"
    fi

    # Mount using piped passphrase
    if age -d -i "$private_key" "$encrypted_passphrase" 2>/dev/null | gocryptfs -q "$cipher_dir" "$mount_point" 2>/dev/null; then
        return 0
    fi

    echo "Failed to mount vault '$name'"
    return 1
}

# Unmount a vault
# Parameters: vault_index (0-based)
# Returns: 0 on success, 1 on failure
unmount_vault() {
    local vault_index="$1"

    local -a vaults=()
    load_vaults vaults

    if [ "$vault_index" -lt 0 ] || [ "$vault_index" -ge "${#vaults[@]}" ]; then
        echo "Invalid vault index"
        return 1
    fi

    local vault_info="${vaults[$vault_index]}"
    IFS=':' read -r name _ mount_point _ <<< "$vault_info"

    # Check if mounted
    if ! get_vault_status "$mount_point"; then
        echo "Vault '$name' is not mounted"
        return 1
    fi

    # Unmount
    if fusermount -u "$mount_point"; then
        return 0
    fi

    return 1
}

# Initialize a new vault (gocryptfs -init)
# Parameters: cipher_dir, secret_id
# Returns: 0 on success, 1 on failure
init_vault() {
    local cipher_dir="$1"
    local secret_id="$2"

    # Get secret data
    local secret_data
    if ! secret_data=$(get_secret_by_id "$secret_id"); then
        echo "Secret not found"
        return 1
    fi

    IFS=':' read -r _ private_key _ encrypted_passphrase <<< "$secret_data"

    # Ensure cipher dir exists
    if [ ! -d "$cipher_dir" ]; then
        mkdir -p "$cipher_dir"
    fi

    # Check if already initialized
    if [ -f "$cipher_dir/gocryptfs.conf" ]; then
        echo "Vault already initialized at '$cipher_dir'"
        return 1
    fi

    # Initialize using piped passphrase
    if age -d -i "$private_key" "$encrypted_passphrase" 2>/dev/null | gocryptfs -init -q "$cipher_dir" 2>/dev/null; then
        return 0
    fi

    echo "Failed to initialize vault"
    return 1
}
