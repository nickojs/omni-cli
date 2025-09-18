#!/bin/bash

# Test script to verify modular structure
echo "Testing FM Manager Modular Structure"
echo "===================================="

# Test styles loading
echo "Testing styles modules..."
if source "styles/index.sh" 2>/dev/null; then
    echo "✓ Styles loaded successfully"
    if type print_color &>/dev/null; then
        print_color "$BRIGHT_GREEN" "✓ Colors working"
    fi
    if type show_loading &>/dev/null; then
        echo "✓ Animations available" 
    fi
    if type print_header &>/dev/null; then
        echo "✓ UI components available"
    fi
else
    echo "✗ Failed to load styles"
fi

echo ""
echo "Testing business logic modules..."
if source "modules/index.sh" 2>/dev/null; then
    echo "✓ Modules loaded successfully"
    if type load_config &>/dev/null; then
        echo "✓ Config functions available"
    fi
    if type check_tmux &>/dev/null; then
        echo "✓ Tmux functions available"
    fi
    if type display_project_status &>/dev/null; then
        echo "✓ Project functions available"
    fi
    if type show_project_menu_tmux &>/dev/null; then
        echo "✓ Menu functions available"
    fi
else
    echo "✗ Failed to load modules"
fi

echo ""
echo "Module verification:"
styles_loaded 2>/dev/null || echo "Styles verification not available"
echo ""
modules_loaded 2>/dev/null || echo "Modules verification not available"

echo ""
echo "File structure:"
find . -name "*.sh" | head -10
