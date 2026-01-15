#!/bin/bash

# ========================================
# Secrets Add Module
# ========================================
# Handles adding new secrets
# Usage: source modules/settings/secrets/add.sh

# Navigator-based add secret flow
# Returns: 0 on success, 1 on cancel
show_add_secret_flow() {
    clear
    print_header "ADD SECRET"
    echo ""
    echo -e "${DIM}Select your private key file using the navigator${NC}"
    echo -e "${DIM}Navigate with w/s, mark with 'm', confirm with space${NC}"
    echo ""
    wait_for_enter

    # Step 1: Select private key
    show_interactive_browser "files" "$HOME" "/home"

    if [ ${#MARKED_FILES[@]} -eq 0 ]; then
        clear
        print_warning "No private key selected."
        sleep 1
        return 1
    fi

    local private_key_path="${MARKED_FILES[0]}"
    local private_key_dir=$(dirname "$private_key_path")
    local private_key_name=$(basename "$private_key_path")

    # Step 2: Try to auto-detect public key
    local expected_pub="${private_key_path}.pub"
    local public_key_path=""

    if [ -f "$expected_pub" ]; then
        clear
        print_header "ADD SECRET"
        echo ""
        echo -e "${BRIGHT_GREEN}✓${NC} Private key: ${private_key_name}"
        echo -e "${BRIGHT_GREEN}✓${NC} Public key: $(basename "$expected_pub") ${DIM}(auto-detected)${NC}"
        echo ""
        public_key_path="$expected_pub"
    else
        # No auto-detect - prompt for public key
        clear
        print_header "ADD SECRET"
        echo ""
        echo -e "${BRIGHT_GREEN}✓${NC} Private key: ${private_key_name}"
        echo ""
        echo -e "${DIM}Select your public key file${NC}"
        echo ""
        wait_for_enter

        show_interactive_browser "files" "$private_key_dir" "/home"

        if [ ${#MARKED_FILES[@]} -eq 0 ]; then
            clear
            print_warning "No public key selected."
            sleep 1
            return 1
        fi

        public_key_path="${MARKED_FILES[0]}"
    fi

    # Step 3: Try to auto-detect encrypted passphrase
    local private_key_basename=$(basename "$private_key_path")
    local passphrase_pattern="${private_key_dir}/${private_key_basename}_*.age"
    local -a passphrase_matches=($(ls $passphrase_pattern 2>/dev/null))
    local encrypted_passphrase_path=""

    if [ ${#passphrase_matches[@]} -eq 1 ]; then
        # Exactly one match - auto-select
        encrypted_passphrase_path="${passphrase_matches[0]}"
        clear
        print_header "ADD SECRET"
        echo ""
        echo -e "${BRIGHT_GREEN}✓${NC} Private key: ${private_key_name}"
        echo -e "${BRIGHT_GREEN}✓${NC} Public key: $(basename "$public_key_path")"
        echo -e "${BRIGHT_GREEN}✓${NC} Passphrase: $(basename "$encrypted_passphrase_path") ${DIM}(auto-detected)${NC}"
        echo ""
    else
        # No match or multiple matches - prompt
        clear
        print_header "ADD SECRET"
        echo ""
        echo -e "${BRIGHT_GREEN}✓${NC} Private key: ${private_key_name}"
        echo -e "${BRIGHT_GREEN}✓${NC} Public key: $(basename "$public_key_path")"
        echo ""
        echo -e "${DIM}Select your encrypted passphrase file (.age)${NC}"
        echo ""
        wait_for_enter

        show_interactive_browser "files" "$private_key_dir" "/home"

        if [ ${#MARKED_FILES[@]} -eq 0 ]; then
            clear
            print_warning "No passphrase file selected."
            sleep 1
            return 1
        fi

        encrypted_passphrase_path="${MARKED_FILES[0]}"
    fi

    # Step 4: Save the secret
    local secret_name="$private_key_name"
    save_secret "$secret_name" "$private_key_path" "$public_key_path" "$encrypted_passphrase_path"

    clear
    print_header "ADD SECRET"
    echo ""
    echo -e "${BRIGHT_GREEN}✓${NC} Secret added successfully!"
    echo ""
    echo -e "${DIM}Private key:${NC} $(basename "$private_key_path")"
    echo -e "${DIM}Public key:${NC} $(basename "$public_key_path")"
    echo -e "${DIM}Passphrase:${NC} $(basename "$encrypted_passphrase_path")"
    echo ""
    wait_for_enter

    return 0
}

