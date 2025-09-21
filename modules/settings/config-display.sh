#!/bin/bash

# ========================================
# Configuration Display Module
# ========================================
# This module handles displaying configuration in human-readable format
# Usage: source modules/settings/config-display.sh

# Function to list current configuration in human-readable format
list_current_config() {
    print_header "CURRENT PROJECT CONFIGURATION"
    
    # Check if configuration file exists
    if [ ! -f "$JSON_CONFIG_FILE" ]; then
        print_error "No configuration file found at: $JSON_CONFIG_FILE"
        echo ""
        print_color "$BRIGHT_YELLOW" "Run the wizard (w) to create your first configuration."
        return 1
    fi
    
    # Check if file is empty
    if [ ! -s "$JSON_CONFIG_FILE" ]; then
        print_error "Configuration file is empty: $JSON_CONFIG_FILE"
        echo ""
        print_color "$BRIGHT_YELLOW" "Run the wizard (w) to create your first configuration."
        return 1
    fi
    
    # Check if jq is available for better JSON parsing
    if command -v jq >/dev/null 2>&1; then
        display_config_with_jq
    else
        display_config_fallback
    fi
}

# Function to display configuration using jq (preferred method)
display_config_with_jq() {
    echo ""
    print_color "$BRIGHT_GREEN" "Configuration file: $JSON_CONFIG_FILE"
    echo ""
    
    # Check if JSON is valid
    if ! jq empty "$JSON_CONFIG_FILE" 2>/dev/null; then
        print_error "Invalid JSON format in configuration file"
        echo ""
        print_color "$BRIGHT_YELLOW" "Raw file contents:"
        echo ""
        cat "$JSON_CONFIG_FILE"
        return 1
    fi
    
    # Get number of projects
    local project_count=$(jq length "$JSON_CONFIG_FILE")
    
    if [ "$project_count" -eq 0 ]; then
        print_color "$BRIGHT_YELLOW" "No projects configured."
        echo ""
        print_color "$BLUE" "Run the wizard (w) to add projects to your configuration."
        return 0
    fi
    
    print_color "$BRIGHT_CYAN" "Found $project_count project(s) configured:"
    echo ""
    
    # Display each project
    local counter=1
    while [ $counter -le $project_count ]; do
        local index=$((counter - 1))
        
        # Extract project data
        local display_name=$(jq -r ".[$index].displayName" "$JSON_CONFIG_FILE")
        local project_name=$(jq -r ".[$index].projectName" "$JSON_CONFIG_FILE")
        local relative_path=$(jq -r ".[$index].relativePath" "$JSON_CONFIG_FILE")
        
        # Display project info with nice formatting
        print_color "$BRIGHT_WHITE" "Project #$counter:"
        echo -e "  ${BRIGHT_YELLOW}Display Name:${NC} $display_name"
        echo -e "  ${BRIGHT_YELLOW}Folder Name:${NC}  $project_name"
        echo -e "  ${BRIGHT_YELLOW}Path:${NC}         $relative_path"
        
        echo ""
        
        counter=$((counter + 1))
    done
    
    # Show summary
    print_separator
    echo -e "${BRIGHT_CYAN}Summary:${NC} $project_count projects configured"
    
}

# Function to display configuration without jq (fallback method)
display_config_fallback() {
    echo ""
    print_color "$BRIGHT_GREEN" "Configuration file: $JSON_CONFIG_FILE"
    echo ""
    print_color "$BRIGHT_YELLOW" "Note: Install 'jq' for better formatted output"
    echo ""
    
    # Show raw JSON with some basic formatting
    print_color "$BRIGHT_CYAN" "Raw configuration:"
    echo ""
    
    # Add line numbers and basic indentation highlighting
    local line_num=1
    while IFS= read -r line; do
        echo -e "${DIM}$line_num:${NC} $line"
        line_num=$((line_num + 1))
    done < "$JSON_CONFIG_FILE"
    
    echo ""
    print_separator
    print_color "$BRIGHT_BLUE" "Tip: Install jq for human-readable configuration display"
}
