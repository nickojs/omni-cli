#!/bin/bash

# Test script for responsive styling
source "$(dirname "$0")/styles/index.sh"

echo "Testing responsive styling functions..."
echo ""

# Test terminal width detection
echo "Current terminal width: $(get_terminal_width)"
echo ""

# Test header
print_header "RESPONSIVE STYLING TEST"

# Test separator
print_separator

# Test divider with text
print_divider "DIVIDER TEST"

# Test box
print_box "This is a test box"

# Test centered text
print_centered "This text should be centered"

# Test bordered text
print_bordered_text "This text has borders on both sides"

# Test border line
print_border "═"

# Test with different terminal widths (simulate)
echo ""
print_divider "SIMULATING DIFFERENT WIDTHS"

# Override terminal width function temporarily for testing
get_terminal_width() { echo 80; }
print_header "80 COLUMN HEADER"

get_terminal_width() { echo 120; }
print_header "120 COLUMN HEADER"

get_terminal_width() { echo 60; }
print_header "60 COLUMN HEADER"

echo ""
echo "Styling test complete!"
