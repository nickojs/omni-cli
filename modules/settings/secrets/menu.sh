#!/bin/bash

# ========================================
# Secrets Menu Module
# ========================================
# Main menu screen and entry point for secrets
# Usage: source modules/settings/secrets/menu.sh

# Default secrets screen
# Returns: 0 = stay, 1 = back to settings, 2 = add secret, 3 = show help
show_secrets_default_screen() {
    local -a secrets=()
    load_secrets secrets
    local secret_count=${#secrets[@]}

    printf '\033[?25l'
    clear
    print_header "Secrets"

    if [ "$secret_count" -eq 0 ]; then
        display_secrets_empty

        echo -e "${BRIGHT_GREEN}a${NC} add secret    ${BRIGHT_PURPLE}b${NC} back"
        echo ""

        printf '\033[?25h'
        echo -ne "${BRIGHT_CYAN}>${NC} "
        local choice
        read_with_instant_back choice

        case "$choice" in
            [Bb]) return 1 ;;
            [Aa])
                if prompt_secrets_folder; then
                    return 2
                fi
                return 0
                ;;
            *) return 0 ;;
        esac
    else
        display_secrets_table secrets

        # Build delete command display
        local delete_cmd=""
        if [ "$secret_count" -eq 1 ]; then
            delete_cmd="${BRIGHT_RED}d1${NC} delete"
        else
            delete_cmd="${BRIGHT_RED}d1-d${secret_count}${NC} delete"
        fi

        echo -e "${BRIGHT_GREEN}a${NC} add secret    ${delete_cmd}    ${BRIGHT_PURPLE}h${NC} help    ${BRIGHT_PURPLE}b${NC} back"
        echo ""

        printf '\033[?25h'
        echo -ne "${BRIGHT_CYAN}>${NC} "
        local choice
        read_with_instant_back choice

        case "$choice" in
            [Bb]) return 1 ;;
            [Hh]) return 3 ;;
            [Aa])
                if prompt_secrets_folder; then
                    return 2
                fi
                return 0
                ;;
        esac

        # Handle delete commands (d1, d2, etc.)
        if [[ "$choice" =~ ^[Dd]([0-9]+)$ ]]; then
            local delete_num="${BASH_REMATCH[1]}"
            if [ "$delete_num" -ge 1 ] && [ "$delete_num" -le "$secret_count" ]; then
                local delete_index=$((delete_num - 1))
                delete_secret "$delete_index"
            fi
            return 0
        fi

        return 0
    fi
}

# Main secrets menu entry point
show_secrets_menu() {
    SECRETS_FOLDER=""

    while true; do
        local result
        show_secrets_default_screen
        result=$?

        case $result in
            1) return 0 ;;  # Back to settings
            2)              # Show file list (add secret)
                show_secrets_file_list_screen "$SECRETS_FOLDER"
                SECRETS_FOLDER=""
                ;;
            3)              # Show help screen
                show_secrets_help_screen
                ;;
        esac
    done
}
