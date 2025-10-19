#!/bin/bash

# ========================================
# Masquerade Script - Test Mode Manager
# ========================================
# Handles switching between real and test configurations
# Usage: ./test-area/masquerade.sh {enable|restore}

# Bash safety settings
set -euo pipefail

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Navigate to project root (parent of test-area)
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

CONFIG_DIR="$PROJECT_ROOT/config"
BACKUP_DIR="$CONFIG_DIR/.bkp"
TEST_AREA="$PROJECT_ROOT/test-area"

# Function to show usage
show_usage() {
    echo "Usage: $0 {enable|restore}"
    echo ""
    echo "Commands:"
    echo "  enable   - Replace real configs with test configurations"
    echo "  restore  - Restore original configurations"
    echo ""
    echo "Test configurations will be sourced from: $TEST_AREA/"
    echo "  • testing_data__*.json workspace files"
    echo "  • testing_data__.workspaces.json"
}

# Function to enable masquerade mode
enable_masquerade() {
    echo "🎭 Enabling test masquerade mode..."

    # Check if already in test mode
    if [ -d "$BACKUP_DIR" ]; then
        echo "⚠️  Test mode already active. Use 'restore' first."
        exit 1
    fi

    # Check if test workspaces config exists
    if [ ! -f "$TEST_AREA/testing_data__.workspaces.json" ]; then
        echo "❌ No test workspaces config found: $TEST_AREA/testing_data__.workspaces.json"
        echo "   Run: ./test-area/mockup.sh <folders> [projects-per-folder]"
        exit 1
    fi

    # STEP 1: Backup existing files - move ALL files from CONFIG_DIR to .bkp
    echo "📦 Step 1: Backing up existing configurations..."
    mkdir -p "$BACKUP_DIR"

    local backed_up_count=0
    # First, move all files (not .bkp)
    for config_file in "$CONFIG_DIR"/*; do
        # Skip if glob didn't match anything
        [ -e "$config_file" ] || continue

        # Skip the backup directory itself
        if [ "$(basename "$config_file")" = ".bkp" ]; then
            continue
        fi

        mv "$config_file" "$BACKUP_DIR/"
        backed_up_count=$((backed_up_count + 1))
    done

    if [ $backed_up_count -gt 0 ]; then
        echo "   ✓ Backed up $backed_up_count files to $BACKUP_DIR"
    else
        echo "   No files to backup"
    fi

    # STEP 2: Copy test JSON files to CONFIG_DIR
    echo "📂 Step 2: Copying test configurations..."

    # Copy all JSON files from test-area to CONFIG_DIR
    local copied_json_count=0
    for test_json in "$TEST_AREA"/testing_data__*.json; do
        [ -f "$test_json" ] || continue
        cp "$test_json" "$CONFIG_DIR/"
        copied_json_count=$((copied_json_count + 1))
        echo "   ✓ Copied: $(basename "$test_json")"
    done

    echo "   Copied $copied_json_count JSON files"

    # STEP 3: Rename testing_data__.workspaces.json -> .workspaces.json
    echo "🔧 Step 3: Renaming workspaces configuration..."
    if [ -f "$CONFIG_DIR/testing_data__.workspaces.json" ]; then
        mv "$CONFIG_DIR/testing_data__.workspaces.json" "$CONFIG_DIR/.workspaces.json"
        echo "   ✓ Renamed: testing_data__.workspaces.json → .workspaces.json"
    else
        echo "   ⚠️  Warning: testing_data__.workspaces.json not found in CONFIG_DIR"
    fi

    echo ""
    echo "✅ Test masquerade enabled successfully!"
    echo "📄 Summary:"
    echo "   • Backed up $backed_up_count files"
    echo "   • Copied $copied_json_count JSON configs"
    echo ""
    echo "🔄 To restore original configs: ./test-area/masquerade.sh restore"
}

# Function to restore original mode
restore_masquerade() {
    echo "🔄 Restoring original configurations..."

    # Check if backup exists
    if [ ! -d "$BACKUP_DIR" ]; then
        echo "❌ No backup found. Not in test mode?"
        exit 1
    fi

    # Remove all test configuration files from config/
    echo "🗑️  Removing test configurations..."
    local removed_count=0

    # Remove all files from CONFIG_DIR (except .bkp)
    for config_file in "$CONFIG_DIR"/*; do
        [ -e "$config_file" ] || continue

        # Skip the backup directory itself
        if [ "$(basename "$config_file")" = ".bkp" ]; then
            continue
        fi

        rm -rf "$config_file"
        removed_count=$((removed_count + 1))
    done
    echo "   Removed $removed_count files"

    # Restore .workspaces.json if it was backed up
    if [ -f "$BACKUP_DIR/.workspaces.json" ]; then
        echo "📂 Restoring original .workspaces.json..."
        mv "$BACKUP_DIR/.workspaces.json" "$CONFIG_DIR/.workspaces.json"
    fi

    # Restore all remaining files from backup
    echo "📂 Restoring original files..."
    local restored_count=0
    for backup_file in "$BACKUP_DIR"/*; do
        [ -e "$backup_file" ] || continue

        mv "$backup_file" "$CONFIG_DIR/"
        restored_count=$((restored_count + 1))
    done

    if [ $restored_count -gt 0 ]; then
        echo "   Restored $restored_count files"
    else
        echo "   No files to restore"
    fi

    # Remove backup directory
    rmdir "$BACKUP_DIR" 2>/dev/null || {
        echo "⚠️  Warning: Could not remove backup directory (may not be empty)"
        echo "   Check: $BACKUP_DIR"
    }

    echo ""
    echo "✅ Original configurations restored successfully!"
}

# Main script
case "${1:-}" in
    "enable"|"on")
        enable_masquerade
        ;;

    "disable"|"off"|"restore")
        restore_masquerade
        ;;

    *)
        show_usage
        exit 1
        ;;
esac
