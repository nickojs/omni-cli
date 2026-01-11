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
    printf "${BOLD}%-4s %-14s %-22s %-22s %s${NC}\n" "#" "private key" "public key" "encrypted passphrase"

    local counter=1
    for secret_info in "${secrets_ref[@]}"; do
        IFS=':' read -r id private_key public_key encrypted_passphrase <<< "$secret_info"

        # Display filenames only
        local display_private=$(basename "$private_key")
        local display_public=$(basename "$public_key")
        local display_passphrase=$(basename "$encrypted_passphrase")

        # Truncate if too long
        [ ${#display_private} -gt 32 ] && display_private="${display_private:0:26}..."
        [ ${#display_public} -gt 32 ] && display_public="${display_public:0:26}..."
        [ ${#display_passphrase} -gt 32 ] && display_passphrase="${display_passphrase:0:26}..."

        printf "${BRIGHT_CYAN}%-4s${NC} ${BRIGHT_WHITE}%-14s${NC} ${DIM}%-22s %-22s %s${NC}\n" \
            "$counter" "$display_private" "$display_public" "$display_passphrase"
        counter=$((counter + 1))
    done
    echo ""
}

# Display empty state (no secrets configured)
display_secrets_empty() {
    echo ""
    echo -e "${DIM}No secrets configured.${NC}"
    echo ""
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

# Display vaults as cards
# Parameters: vaults_array_ref
display_vaults_table() {
    local -n vaults_ref=$1

    print_header "Vaults"
    echo ""

    local counter=1
    for vault_info in "${vaults_ref[@]}"; do
        IFS=':' read -r name cipher_dir mount_point secret_id <<< "$vault_info"

        # Get status icon
        local status_icon="${DIM}○${NC}"
        if get_vault_status "$mount_point"; then
            status_icon="${BRIGHT_GREEN}●${NC}"
        fi

        # Get secret's .age filename
        local secret_display="-"
        local secret_data
        if secret_data=$(get_secret_by_id "$secret_id"); then
            IFS=':' read -r _ _ _ encrypted_passphrase <<< "$secret_data"
            secret_display=$(basename "$encrypted_passphrase")
        fi

        # Display paths with ~ for home
        local display_cipher="${cipher_dir/#$HOME/\~}"
        local display_mount="${mount_point/#$HOME/\~}"

        # Card display
        printf "${BRIGHT_CYAN}%s${NC}  ${BRIGHT_WHITE}%s${NC}  %b\n" \
            "$counter" "$name" "$status_icon"
        printf "   ${DIM}cipher:${NC}  %s\n" "$display_cipher"
        printf "   ${DIM}mount:${NC}   %s\n" "$display_mount"
        printf "   ${DIM}secret:${NC}  %s\n" "$secret_display"
        echo ""

        counter=$((counter + 1))
    done
}

# Display vaults empty state
display_vaults_empty() {
    print_header "Vaults"
    echo ""
    echo -e "${DIM}No vaults configured.${NC}"
    echo ""
}
