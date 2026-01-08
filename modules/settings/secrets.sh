#!/bin/bash

# ========================================
# Secrets Management Module
# ========================================
# Handles secrets management operations
# Usage: source modules/settings/secrets.sh

# Interactive secrets menu
show_secrets_menu() {
    while true; do
        printf '\033[?25l'  # Hide cursor during redraw
        clear
        print_header "Secrets"

        echo ""
        echo -e "${DIM}No secrets configured.${NC}"
        echo ""
        echo -e "${DIM}Secrets are ${NC}${BRIGHT_WHITE}age${NC}${DIM} keypairs. This tool uses them to mount and unmount${NC}"
        echo -e "${DIM}encrypted ${NC}${BRIGHT_WHITE}gocryptfs${NC}${DIM} volumes.${NC}"
        echo ""
        echo -e "${DIM}This tool manages existing keypairs — it does not generate them.${NC}"
        echo -e "${DIM}Create your keypairs with ${NC}${BRIGHT_WHITE}age-keygen${NC}${DIM}: ${NC}${BRIGHT_CYAN}https://github.com/FiloSottile/age${NC}"
        echo ""

        # Show commands (only back works)
        echo -e "${BRIGHT_PURPLE}b${NC} back"
        echo ""

        # Get user input
        printf '\033[?25h'  # Show cursor for input
        echo -ne "${BRIGHT_CYAN}>${NC} "
        read_with_instant_back choice

        # Handle back command
        if [[ $choice =~ ^[Bb]$ ]]; then
            return 0
        fi
    done
}
