#!/bin/bash

CONFIG_FILE="config/projects_output.json"
BACKUP_FILE="config/projects_output.json.backup"
TEST_CONFIG="test-area/projects_output__test_area.json"

case "$1" in
    "enable"|"on")
        if [ ! -f "$BACKUP_FILE" ]; then
            echo "📦 Backing up original config..."
            cp "$CONFIG_FILE" "$BACKUP_FILE"
        else
            echo "⚠️  Backup already exists, skipping..."
        fi

        echo "🎭 Enabling test masquerade..."
        cp "$TEST_CONFIG" "$CONFIG_FILE"
        echo "✅ Test configuration is now active"
        echo "   Use: ./test-area/masquerade.sh restore"
        ;;

    "disable"|"off"|"restore")
        if [ -f "$BACKUP_FILE" ]; then
            echo "🔄 Restoring original configuration..."
            mv "$BACKUP_FILE" "$CONFIG_FILE"
            echo "✅ Original configuration restored"
        else
            echo "❌ No backup found to restore from"
            exit 1
        fi
        ;;

    *)
        echo "Usage: $0 {enable|disable|restore}"
        echo ""
        echo "  enable   - Switch to test configuration"
        echo "  disable  - Restore original configuration"
        echo "  restore  - Same as disable"
        exit 1
        ;;
esac