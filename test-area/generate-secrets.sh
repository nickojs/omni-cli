#!/bin/bash

# ========================================
# Test Secrets Generator
# ========================================
# Generates age keypairs and encrypted files to test secrets flow
# Usage: generate-secrets.sh [clean]

# Bash safety settings
set -euo pipefail
IFS=$'\n\t'

# Constants
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
readonly SECRETS_DIR="$PROJECT_ROOT/.secrets"

# Check for age-keygen
check_dependencies() {
    if ! command -v age-keygen >/dev/null 2>&1; then
        echo "age-keygen not found. Install age first:"
        echo "  https://github.com/FiloSottile/age"
        exit 1
    fi
    if ! command -v age >/dev/null 2>&1; then
        echo "age not found. Install age first:"
        echo "  https://github.com/FiloSottile/age"
        exit 1
    fi
}

# Generate a keypair
# Parameters: output_dir, key_name
generate_keypair() {
    local output_dir="$1"
    local key_name="$2"
    local private_key="$output_dir/$key_name"
    local public_key="$output_dir/$key_name.pub"

    # Generate keypair
    age-keygen -o "$private_key" 2>/dev/null

    # Extract public key from comment in private key file
    grep "# public key:" "$private_key" | awk '{print $4}' > "$public_key"

    echo "    Generated: $key_name, $key_name.pub"
}

# Generate an encrypted .age file
# Parameters: output_dir, public_key_file, age_filename, passphrase
generate_age_file() {
    local output_dir="$1"
    local public_key_file="$2"
    local age_filename="$3"
    local passphrase="$4"
    local age_file="$output_dir/$age_filename"

    local recipient
    recipient=$(cat "$public_key_file")
    echo "$passphrase" | age -r "$recipient" > "$age_file"

    echo "    Generated: $age_filename"
}

# Generate a test scenario
# Parameters: scenario_name, description, private_key_name, public_key_name, age_files (comma-separated)
generate_scenario() {
    local scenario_name="$1"
    local description="$2"
    local private_key_name="$3"
    local public_key_name="$4"
    local age_files="$5"

    local scenario_dir="$SECRETS_DIR/$scenario_name"
    echo "$scenario_name: $description"

    mkdir -p "$scenario_dir"

    # Generate keypair
    generate_keypair "$scenario_dir" "$private_key_name"

    # Rename public key to break auto-detect pattern (tests manual selection)
    if [ "$public_key_name" != "$private_key_name" ]; then
        mv "$scenario_dir/$private_key_name.pub" "$scenario_dir/$public_key_name.pub"
        echo "    Renamed: $private_key_name.pub -> $public_key_name.pub"
    fi

    # Generate .age files
    local public_key_file="$scenario_dir/$public_key_name.pub"
    IFS=',' read -ra age_array <<< "$age_files"
    for age_name in "${age_array[@]}"; do
        generate_age_file "$scenario_dir" "$public_key_file" "$age_name" "passphrase-$age_name"
    done

    echo ""
}

# Clean up generated secrets
clean_secrets() {
    echo "Cleaning up test secrets..."

    if [ -d "$SECRETS_DIR" ]; then
        rm -rf "$SECRETS_DIR"
        echo "Removed: $SECRETS_DIR"
    else
        echo "Nothing to clean - .secrets/ does not exist"
    fi
}

# Show usage
show_usage() {
    echo "Usage: $0 [clean]"
    echo ""
    echo "Commands:"
    echo "  (no args)  Generate test secrets in .secrets/"
    echo "  clean      Remove .secrets/ folder"
    echo ""
    echo "Test Scenarios:"
    echo "  scenario1/ - Matching names, single .age file (tests auto-detect)"
    echo "  scenario2/ - Matching names, multiple .age files (tests prompt)"
    echo "  scenario3/ - Dissonant names (tests full manual selection)"
}

# Main
main() {
    if [ "${1:-}" = "clean" ]; then
        clean_secrets
        exit 0
    fi

    if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
        show_usage
        exit 0
    fi

    check_dependencies

    # Clean first if exists
    if [ -d "$SECRETS_DIR" ]; then
        echo "Cleaning existing .secrets/..."
        rm -rf "$SECRETS_DIR"
    fi

    echo "Generating test secrets in .secrets/..."
    echo ""

    mkdir -p "$SECRETS_DIR"

    # Scenario 1: Auto-detect (single .age match)
    generate_scenario "scenario1" "Auto-detect (single .age match)" \
        "testkey" "testkey" "testkey_passphrase.age"

    # Scenario 2: Multiple matches (prompts user)
    generate_scenario "scenario2" "Multiple matches (prompts user)" \
        "multikey" "multikey" "multikey_work.age,multikey_home.age,multikey_backup.age"

    # Scenario 3: Dissonant names (full manual)
    generate_scenario "scenario3" "Dissonant names (full manual)" \
        "my_private_key" "the_public_key" "random_passphrase.age,another_file.age"

    echo "Done! Test secrets created in: $SECRETS_DIR"
    echo ""
    echo "Test each scenario in the secrets UI:"
    echo "  scenario1/ - should auto-select testkey_passphrase.age"
    echo "  scenario2/ - should prompt with 3 .age options"
    echo "  scenario3/ - should prompt for public key, then encrypted passphrase"
}

main "$@"
