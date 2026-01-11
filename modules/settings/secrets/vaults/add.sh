#!/bin/bash

# ========================================
# Vault Add Module
# ========================================
# Add vault flow
# Usage: source modules/settings/secrets/vaults/add.sh

# Add vault screen
show_add_vault_screen() {
    local -a secrets=()
    load_secrets secrets
    local secret_count=${#secrets[@]}

    if [ "$secret_count" -eq 0 ]; then
        return
    fi

    printf '\033[?25h'
    clear
    print_header "Vaults"
    echo ""

    # 1. Vault name
    echo -ne "${BRIGHT_WHITE}Vault name:${NC} "
    local vault_name
    read -r vault_name
    if [ -z "$vault_name" ]; then
        return
    fi

    # 2. Cipher dir base
    echo -ne "${BRIGHT_WHITE}Cipher dir base (e.g., ~/.vaults):${NC} "
    local cipher_base
    read -r cipher_base
    if [ -z "$cipher_base" ]; then
        return
    fi
    # Expand ~
    cipher_base="${cipher_base/#\~/$HOME}"
    local cipher_dir="$cipher_base/$vault_name"

    # 3. Mount point base
    echo -ne "${BRIGHT_WHITE}Mount point base (e.g., ~/mnt):${NC} "
    local mount_base
    read -r mount_base
    if [ -z "$mount_base" ]; then
        return
    fi
    # Expand ~
    mount_base="${mount_base/#\~/$HOME}"
    local mount_point="$mount_base/$vault_name"

    # 4. Select secret
    echo ""
    echo -e "${BRIGHT_WHITE}Select secret:${NC}"
    local counter=1
    for secret_info in "${secrets[@]}"; do
        IFS=':' read -r id private_key _ encrypted_passphrase <<< "$secret_info"
        local display_age=$(basename "$encrypted_passphrase")
        printf "${BRIGHT_CYAN}%2s${NC}  %s\n" "$counter" "$display_age"
        counter=$((counter + 1))
    done
    echo ""
    echo -ne "${BRIGHT_WHITE}Secret number:${NC} "
    local secret_num
    read -r secret_num

    if ! [[ "$secret_num" =~ ^[0-9]+$ ]] || [ "$secret_num" -lt 1 ] || [ "$secret_num" -gt "$secret_count" ]; then
        return
    fi

    local secret_index=$((secret_num - 1))
    local selected_secret="${secrets[$secret_index]}"
    IFS=':' read -r secret_id _ _ _ <<< "$selected_secret"

    # 5. New or existing?
    echo ""
    echo -e "${BRIGHT_WHITE}Is this a new vault or existing?${NC}"
    echo -e "${BRIGHT_CYAN}1${NC}  New (initialize with gocryptfs)"
    echo -e "${BRIGHT_CYAN}2${NC}  Existing (already initialized)"
    echo ""
    echo -ne "${BRIGHT_WHITE}Choice:${NC} "
    local vault_type
    read -r vault_type

    if [ "$vault_type" = "1" ]; then
        # Initialize new vault
        echo ""
        echo -e "${DIM}Initializing vault...${NC}"
        if ! init_vault "$cipher_dir" "$secret_id"; then
            echo -e "${BRIGHT_RED}Failed to initialize vault${NC}"
            wait_for_enter
            return
        fi
        echo -e "${BRIGHT_GREEN}Vault initialized${NC}"
    elif [ "$vault_type" = "2" ]; then
        # Check if cipher dir exists
        if [ ! -d "$cipher_dir" ] || [ ! -f "$cipher_dir/gocryptfs.conf" ]; then
            echo ""
            echo -e "${BRIGHT_RED}No gocryptfs vault found at $cipher_dir${NC}"
            wait_for_enter
            return
        fi
    else
        return
    fi

    # Save vault config
    if save_vault "$vault_name" "$cipher_dir" "$mount_point" "$secret_id"; then
        echo -e "${BRIGHT_GREEN}Vault added${NC}"
    else
        echo -e "${BRIGHT_RED}Failed to save vault${NC}"
    fi

    wait_for_enter
}
