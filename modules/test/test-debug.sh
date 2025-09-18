#!/bin/bash

echo "=== DEBUG TEST SCRIPT ==="
echo "Current working directory: $(pwd)"
echo "Script location: $(dirname "$0")"

# Test the SCRIPT_DIR calculation from wizard.sh
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo "SCRIPT_DIR from wizard logic: $SCRIPT_DIR"

JSON_CONFIG_FILE="$SCRIPT_DIR/config/projects_output.json"
echo "JSON_CONFIG_FILE: $JSON_CONFIG_FILE"

# Check if file exists
if [ -f "$JSON_CONFIG_FILE" ]; then
    echo "✓ Config file EXISTS"
    echo "File size: $(wc -c < "$JSON_CONFIG_FILE") bytes"
    echo "File contents:"
    cat "$JSON_CONFIG_FILE"
else
    echo "✗ Config file does NOT exist"
fi

# Check directory structure
echo ""
echo "=== DIRECTORY STRUCTURE ==="
echo "Contents of current directory:"
ls -la

echo ""
echo "Contents of fm-manager/:"
ls -la ./ 2>/dev/null || echo "fm-manager/ directory not found"

echo ""
echo "Contents of fm-manager/config/:"
ls -la ./config/ 2>/dev/null || echo "fm-manager/config/ directory not found"

echo ""
echo "Contents of fm-manager/modules/:"
ls -la ./modules/ 2>/dev/null || echo "fm-manager/modules/ directory not found"
