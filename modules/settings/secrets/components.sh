#!/bin/bash

# ========================================
# Secrets Components Module
# ========================================
# UI display components for secrets
# Usage: source modules/settings/secrets/components.sh

# Display secrets table
# Parameters: secrets_array_ref
display_secrets_table() {
    local -n secrets_ref=$1

    echo ""
    printf "  ${DIM}%-14s %-28s %s${NC}\n" "Name" "Private Key" "Public Key"

    local counter=1
    for secret_info in "${secrets_ref[@]}"; do
        IFS=':' read -r name private_key public_key <<< "$secret_info"

        # Display paths with ~ for home
        local display_private="${private_key/#$HOME/\~}"
        local display_public="${public_key/#$HOME/\~}"

        # Truncate if too long
        [ ${#display_private} -gt 26 ] && display_private="${display_private:0:23}..."
        [ ${#display_public} -gt 26 ] && display_public="${display_public:0:23}..."

        printf "${BRIGHT_CYAN}%s${NC} ${BRIGHT_WHITE}%-14s${NC} ${DIM}%-28s %s${NC}\n" \
            "$counter" "$name" "$display_private" "$display_public"
        counter=$((counter + 1))
    done
    echo ""
}

# Display help copy
display_secrets_help() {
    echo ""
    echo -e "${DIM}This tool uses ${NC}${BOLD}user-generated ${NC}${BRIGHT_CYAN}age${NC}${DIM} keypairs to manage ${NC}${BRIGHT_CYAN}gocryptfs${NC}${DIM} volumes (aka vaults).${NC}"
    echo ""
    echo -e "${DIM}You need to provide an identity file (${NC}${ITALIC}.age${NC}${DIM}) and its corresponding ${NC}${ITALIC}keypairs${NC}${DIM} to add a secret.${NC}"
    echo -e "${DIM}Secrets are then used to create, mount and unmount ${NC}${ITALIC}vaults${NC}${DIM}. You can also provide your own vaults.${NC}"
    echo ""
    echo -e "${DIM}Optional auto-detect identity files: use your keypair name as prefix of your .age file(s), separated by underscore.${NC}"
    echo -e "${DIM}This will only work if your public and private key shares the same file name.${NC}"
    echo ""
    echo -e "  ${BRIGHT_CYAN}mykey${NC}${DIM} - public/private key file name${NC}"
    echo -e "  ${BRIGHT_CYAN}mykey${NC}${DIM}_${NC}${BOLD}anyfilename.age${NC}${DIM} - automatically detected, assigned to that keypair${NC}"
    echo ""
    echo -e "${BRIGHT_CYAN}age${NC} — simple, modern file encryption tool (${BRIGHT_CYAN}https://github.com/FiloSottile/age${NC})"
    echo -e "${BRIGHT_CYAN}gocryptfs${NC} — encrypted overlay filesystem (${BRIGHT_CYAN}https://github.com/rfjakob/gocryptfs${NC})"
    echo ""
}

# Show help screen
show_secrets_help_screen() {
    clear
    print_header "Secrets"
    display_secrets_help
    wait_for_enter
}

# Display empty state (no secrets configured)
display_secrets_empty() {
    echo ""
    echo -e "${BOLD}No secrets configured.${NC}"
    echo ""
    display_secrets_help
}

# Display file list screen
# Parameters: folder_path, files_array_ref, selection_prompt
display_file_list_screen() {
    local folder_path="$1"
    local -n files_ref=$2
    local selection_prompt="$3"
    local display_path="${folder_path/#$HOME/\~}"

    printf '\033[?25l'
    clear
    print_header "Secrets"

    echo ""
    echo -e "${DIM}Scanning: ${NC}${BRIGHT_WHITE}${display_path}${NC}"
    echo ""
    echo -e "${BRIGHT_WHITE}Files:${NC}"

    if [ ${#files_ref[@]} -eq 0 ]; then
        echo -e "${DIM}No files found in this directory.${NC}"
    else
        for i in "${!files_ref[@]}"; do
            local num=$((i + 1))
            local filename="${files_ref[i]}"
            local file_color="${BRIGHT_WHITE}"
            [[ "$filename" == *.pub ]] && file_color="${BRIGHT_BLUE}"
            printf "${BRIGHT_CYAN}%2s${NC}  ${file_color}%s${NC}\n" "$num" "$filename"
        done
    fi
    echo ""

    echo -e "${BRIGHT_PURPLE}b${NC} back"
    echo ""

    printf '\033[?25h'
    echo -ne "${selection_prompt} ${BRIGHT_CYAN}>${NC} "
}
