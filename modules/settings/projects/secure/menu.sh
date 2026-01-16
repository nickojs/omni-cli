#!/bin/bash

# ========================================
# Secure Files - Vault Selection Menu
# ========================================
# Show vault selection screen with add/move options
# Usage: source modules/settings/projects/secure/menu.sh

# Show vault selection screen
# Returns: 10 for add, 20 for move, 1 if cancelled/no vaults
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
        echo -e "${DIM}Select a mounted vault:${NC}"
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

        # Build inline menu based on number of vaults
        local vault_count="${#mounted_indices[@]}"
        if [ $vault_count -eq 1 ]; then
            echo -e "${BRIGHT_GREEN}a1${NC} add to vault    ${BRIGHT_CYAN}m1${NC} move from vault    ${BRIGHT_RED}b${NC} back"
        else
            echo -e "${BRIGHT_GREEN}a1-a${vault_count}${NC} add to vault    ${BRIGHT_CYAN}m1-m${vault_count}${NC} move from vault    ${BRIGHT_RED}b${NC} back"
        fi
        echo ""
        echo -ne "${BRIGHT_CYAN}>${NC} "

        local choice
        read choice

        if [[ "$choice" =~ ^[Bb]$ ]]; then
            return 1
        fi

        # Check for add operation (a1, a2, etc.)
        if [[ "$choice" =~ ^[Aa]([0-9]+)$ ]]; then
            local vault_num="${BASH_REMATCH[1]}"
            if [ "$vault_num" -ge 1 ] && [ "$vault_num" -le "$vault_count" ]; then
                local selected_idx="${mounted_indices[$((vault_num - 1))]}"
                local vault_info="${vaults[$selected_idx]}"
                IFS=':' read -r SELECTED_VAULT_NAME _ SELECTED_VAULT_MOUNT _ <<< "$vault_info"
                return 10  # Return code for "add"
            fi
        fi

        # Check for move operation (m1, m2, etc.)
        if [[ "$choice" =~ ^[Mm]([0-9]+)$ ]]; then
            local vault_num="${BASH_REMATCH[1]}"
            if [ "$vault_num" -ge 1 ] && [ "$vault_num" -le "$vault_count" ]; then
                local selected_idx="${mounted_indices[$((vault_num - 1))]}"
                local vault_info="${vaults[$selected_idx]}"
                IFS=':' read -r SELECTED_VAULT_NAME _ SELECTED_VAULT_MOUNT _ <<< "$vault_info"
                return 20  # Return code for "move"
            fi
        fi
    done
}
