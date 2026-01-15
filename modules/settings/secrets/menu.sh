#!/bin/bash

# ========================================
# Secrets Menu Module
# ========================================
# Main menu screen and entry point for secrets
# Usage: source modules/settings/secrets/menu.sh

# Default secrets screen
# Returns: 0 = stay, 1 = back to settings, 2 = add secret, 3 = show help, 4 = add vault
show_secrets_default_screen() {
    local -a secrets=()
    local -a vaults=()
    load_secrets secrets
    load_vaults vaults
    local secret_count=${#secrets[@]}
    local vault_count=${#vaults[@]}

    printf '\033[?25l'
    clear
    print_header "Secrets"

    # Display secrets section
    if [ "$secret_count" -eq 0 ]; then
        display_secrets_empty
    else
        display_secrets_table secrets
    fi

    # Display vaults section
    if [ "$vault_count" -eq 0 ]; then
        display_vaults_empty
    else
        display_vaults_table vaults
    fi

    # Build menu commands
    local menu_items="${BRIGHT_GREEN}a${NC} add secret"

    # Only show vault commands if secrets exist
    if [ "$secret_count" -gt 0 ]; then
        menu_items+="    ${BRIGHT_GREEN}v${NC} add vault"
    fi

    # Mount/unmount commands
    if [ "$vault_count" -gt 0 ]; then
        if [ "$vault_count" -eq 1 ]; then
            menu_items+="    ${BRIGHT_CYAN}m1${NC} mount    ${BRIGHT_CYAN}u1${NC} unmount"
        else
            menu_items+="    ${BRIGHT_CYAN}m1-m${vault_count}${NC} mount    ${BRIGHT_CYAN}u1-u${vault_count}${NC} unmount"
        fi
    fi

    # Switch/reassign secret commands
    if [ "$vault_count" -gt 0 ] && [ "$secret_count" -gt 0 ]; then
        if [ "$vault_count" -eq 1 ]; then
            menu_items+="    ${BRIGHT_YELLOW}s1${NC} switch secret"
        else
            menu_items+="    ${BRIGHT_YELLOW}s1-s${vault_count}${NC} switch secret"
        fi
    fi

    # Delete secret commands
    if [ "$secret_count" -gt 0 ]; then
        if [ "$secret_count" -eq 1 ]; then
            menu_items+="    ${BRIGHT_RED}d1${NC} delete secret"
        else
            menu_items+="    ${BRIGHT_RED}d1-d${secret_count}${NC} delete secret"
        fi
    fi

    # Remove vault commands
    if [ "$vault_count" -gt 0 ]; then
        if [ "$vault_count" -eq 1 ]; then
            menu_items+="    ${BRIGHT_RED}r1${NC} remove vault"
        else
            menu_items+="    ${BRIGHT_RED}r1-r${vault_count}${NC} remove vault"
        fi
    fi

    menu_items+="    ${BRIGHT_PURPLE}h${NC} help    ${BRIGHT_PURPLE}b${NC} back"

    echo ""
    echo -e "$menu_items"
    echo ""

    printf '\033[?25h'
    echo -ne "${BRIGHT_CYAN}>${NC} "
    local choice
    read_with_instant_back choice

    case "$choice" in
        [Bb]) return 1 ;;
        [Hh]) return 3 ;;
        [Aa])
            show_add_secret_flow
            return 0
            ;;
        [Vv])
            if [ "$secret_count" -gt 0 ]; then
                return 4
            fi
            return 0
            ;;
    esac

    # Handle mount commands (m1, m2, etc.)
    if [[ "$choice" =~ ^[Mm]([0-9]+)$ ]]; then
        local mount_num="${BASH_REMATCH[1]}"
        if [ "$mount_num" -ge 1 ] && [ "$mount_num" -le "$vault_count" ]; then
            local mount_index=$((mount_num - 1))
            if ! mount_vault "$mount_index"; then
                wait_for_enter
            fi
        fi
        return 0
    fi

    # Handle unmount commands (u1, u2, etc.)
    if [[ "$choice" =~ ^[Uu]([0-9]+)$ ]]; then
        local unmount_num="${BASH_REMATCH[1]}"
        if [ "$unmount_num" -ge 1 ] && [ "$unmount_num" -le "$vault_count" ]; then
            local unmount_index=$((unmount_num - 1))
            if ! unmount_vault "$unmount_index"; then
                wait_for_enter
            fi
        fi
        return 0
    fi

    # Handle switch secret commands (s1, s2, etc.)
    if [[ "$choice" =~ ^[Ss]([0-9]+)$ ]]; then
        local switch_num="${BASH_REMATCH[1]}"
        if [ "$switch_num" -ge 1 ] && [ "$switch_num" -le "$vault_count" ]; then
            local switch_index=$((switch_num - 1))
            if ! reassign_vault_secret "$switch_index"; then
                wait_for_enter
            fi
        fi
        return 0
    fi

    # Handle delete commands (d1, d2, etc.) - for secrets
    if [[ "$choice" =~ ^[Dd]([0-9]+)$ ]]; then
        local delete_num="${BASH_REMATCH[1]}"
        if [ "$delete_num" -ge 1 ] && [ "$delete_num" -le "$secret_count" ]; then
            local delete_index=$((delete_num - 1))
            local secret_info="${secrets[$delete_index]}"
            IFS=':' read -r _ private_key _ _ <<< "$secret_info"
            local secret_name=$(basename "$private_key")

            # Confirmation prompt
            echo -ne "${BRIGHT_YELLOW}Delete secret '$secret_name'? (y/n):${NC} "
            local confirm
            read_with_instant_back confirm
            if [[ "$confirm" =~ ^[Yy]$ ]]; then
                delete_secret "$delete_index"
            fi
        fi
        return 0
    fi

    # Handle remove commands (r1, r2, etc.) - for vaults
    if [[ "$choice" =~ ^[Rr]([0-9]+)$ ]]; then
        local remove_num="${BASH_REMATCH[1]}"
        if [ "$remove_num" -ge 1 ] && [ "$remove_num" -le "$vault_count" ]; then
            local remove_index=$((remove_num - 1))
            local vault_info="${vaults[$remove_index]}"
            IFS=':' read -r name _ mount_point _ <<< "$vault_info"

            # Check if mounted
            if get_vault_status "$mount_point"; then
                echo -e "${BRIGHT_RED}Cannot remove mounted vault '$name'. Unmount first.${NC}"
                wait_for_enter
            else
                # Confirmation prompt
                echo -ne "${BRIGHT_YELLOW}Remove vault '$name'? (y/n):${NC} "
                local confirm
                read_with_instant_back confirm
                if [[ "$confirm" =~ ^[Yy]$ ]]; then
                    delete_vault "$remove_index"
                fi
            fi
        fi
        return 0
    fi

    return 0
}

# Main secrets menu entry point
show_secrets_menu() {
    while true; do
        local result
        show_secrets_default_screen
        result=$?

        case $result in
            1) return 0 ;;  # Back to settings
            3)              # Show help screen
                display_secrets_help
                ;;
            4)              # Add vault
                show_add_vault_screen
                ;;
        esac
    done
}
