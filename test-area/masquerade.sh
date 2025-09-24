#!/bin/bash

# ========================================
# Enhanced Masquerade Script
# ========================================
# Handles multiple test configurations with bulk_project_config marker

CONFIG_DIR="config"
BACKUP_DIR="$CONFIG_DIR/.bkp"
MARKER_FILE="$CONFIG_DIR/.bulk_project_config.json"
TEST_AREA="test-area"

# Function to show usage
show_usage() {
    echo "Usage: $0 {enable|restore}"
    echo ""
    echo "  enable   - Replace configs with test configurations"
    echo "  restore  - Restore original configurations"
    echo ""
    echo "Test configurations will be sourced from: $TEST_AREA/testing_data__*.json"
}

# Function to enable masquerade mode
enable_masquerade() {
    echo "🎭 Enabling test masquerade..."

    # Check if already in test mode
    if [ -d "$BACKUP_DIR" ]; then
        echo "⚠️  Test mode already active. Use 'restore' first."
        exit 1
    fi

    # Check if test configs exist
    if ! ls "$TEST_AREA"/testing_data__*.json >/dev/null 2>&1; then
        echo "❌ No test configurations found in $TEST_AREA/"
        echo "   Run ./test-area/mockup.sh to generate test configs"
        exit 1
    fi

    # Create backup directory
    echo "📦 Creating backup directory..."
    mkdir -p "$BACKUP_DIR"

    # Backup all existing JSON configs (except bulk_project_config.json and projects_output.json)
    echo "💾 Backing up original configurations..."
    if ls "$CONFIG_DIR"/*.json >/dev/null 2>&1; then
        # Move all JSON files except .bulk_project_config.json and projects_output.json (keep for compatibility)
        find "$CONFIG_DIR" -name "*.json" ! -name ".bulk_project_config.json" ! -name "projects_output.json" -exec mv {} "$BACKUP_DIR/" \;
        if ls "$BACKUP_DIR"/*.json >/dev/null 2>&1; then
            echo "   Backed up: $(ls "$BACKUP_DIR"/*.json | xargs basename -a)"
        fi
        echo "   Kept for compatibility: projects_output.json"
    fi

    # Copy test configurations to config directory
    echo "📂 Installing test configurations..."
    local test_configs=()
    for test_config in "$TEST_AREA"/testing_data__*.json; do
        if [ -f "$test_config" ]; then
            cp "$test_config" "$CONFIG_DIR/"
            test_configs+=($(basename "$test_config"))
        fi
    done

    # Create bulk_project_config tracker
    echo "🏷️  Creating bulk_project_config tracker..."

    # Build available configs array using jq (include test configs + projects_output for compatibility)
    local available_configs_json='["projects_output"]'
    for config in "${test_configs[@]}"; do
        local config_name=$(basename "$config" .json | sed 's/testing_data__//')
        available_configs_json=$(echo "$available_configs_json" | jq --arg name "$config_name" '. += [$name]')
    done

    # Create proper JSON using jq
    local active_config=$(basename "${test_configs[0]}" .json | sed 's/testing_data__//')
    local display_name=$(echo "$active_config" | sed 's/-/ /g' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) substr($i,2)} 1')

    jq -n \
        --arg activeConfig "$active_config.json" \
        --arg displayName "$display_name" \
        --argjson availableConfigs "$available_configs_json" \
        '{
            "activeConfig": $activeConfig,
            "displayName": $displayName,
            "availableConfigs": $availableConfigs
        }' > "$MARKER_FILE"

    echo "✅ Test masquerade enabled successfully!"
    echo "📄 Active test configurations:"
    printf '   • %s\n' "${test_configs[@]}"
    echo "🔄 Use: ./test-area/masquerade.sh restore"
}

# Function to restore original mode
restore_masquerade() {
    echo "🔄 Restoring original configurations..."

    # Check if backup exists
    if [ ! -d "$BACKUP_DIR" ]; then
        echo "❌ No backup found. Not in test mode?"
        exit 1
    fi

    # Remove test configurations
    echo "🗑️  Removing test configurations..."
    rm -f "$CONFIG_DIR"/testing_data__*.json

    # Restore original configurations
    echo "📂 Restoring original configurations..."
    if ls "$BACKUP_DIR"/*.json >/dev/null 2>&1; then
        mv "$BACKUP_DIR"/*.json "$CONFIG_DIR/"
        echo "   Restored: $(ls "$CONFIG_DIR"/*.json | xargs basename -a)"
    fi

    # Remove backup directory
    rmdir "$BACKUP_DIR"

    # Update bulk_project_config tracker
    echo "🏷️  Updating bulk_project_config tracker..."

    # Get restored configs (excluding .bulk_project_config.json itself)
    local restored_configs=()
    if ls "$CONFIG_DIR"/*.json >/dev/null 2>&1; then
        mapfile -t restored_configs < <(ls "$CONFIG_DIR"/*.json | grep -v ".bulk_project_config.json" | xargs basename -a)
    fi

    # Build configs array using jq
    local available_configs_json="[]"
    for config in "${restored_configs[@]}"; do
        local config_name=$(basename "$config" .json)
        available_configs_json=$(echo "$available_configs_json" | jq --arg name "$config_name" '. += [$name]')
    done

    # Create proper JSON using jq
    local active_config=$(basename "${restored_configs[0]}" .json)
    local display_name=$(echo "$active_config" | sed 's/_/ /g' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) substr($i,2)} 1')

    jq -n \
        --arg activeConfig "$active_config.json" \
        --arg displayName "$display_name" \
        --argjson availableConfigs "$available_configs_json" \
        '{
            "activeConfig": $activeConfig,
            "displayName": $displayName,
            "availableConfigs": $availableConfigs
        }' > "$MARKER_FILE"

    echo "✅ Original configurations restored successfully!"
}

case "$1" in
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