#!/bin/bash

# ========================================
# Settings Commands Module
# ========================================
# This module handles settings menu command routing and processing
# Usage: source modules/settings/commands.sh

# Function to handle settings menu choices
handle_settings_choice() {
    local choice="$1"

    # Handle back command
    if [[ $choice =~ ^[Bb]$ ]]; then
        return 1  # Return to previous menu
    fi

    # Handle help command
    if [[ $choice =~ ^[Hh]$ ]]; then
        show_settings_help
        return 0
    fi

    # Handle add workspace command
    if [[ $choice =~ ^[Aa]$ ]]; then
        show_add_workspace_screen
        return 0
    fi

    # Invalid command
    print_error "Invalid command. Use a (add workspace), b (back) or h (help)"
    echo -ne "${BRIGHT_YELLOW}Press Enter to continue...${NC}"
    read -r
    return 0
}

# Function to show add workspace screen - launches filesystem navigator
show_add_workspace_screen() {
    # Call the filesystem navigator to select a directory
    show_path_selector

    # Check if a directory was selected
    if [ -n "$SELECTED_PROJECTS_DIR" ]; then
        # Store the selected directory
        local projects_folder="$SELECTED_PROJECTS_DIR"

        # Prompt for workspace name
        clear
        print_header "Create Workspace"
        echo ""
        print_success "Directory selected: $projects_folder"
        echo ""

        # Get default name from directory basename
        local default_name=$(basename "$projects_folder")

        # Prompt for workspace name
        echo -e "${BRIGHT_WHITE}Enter name for this workspace:${NC}"
        echo -ne "${DIM}(press Enter to use '$default_name')${NC} ${BLUE}❯${NC} "
        read -r workspace_name

        # Use default if empty
        if [ -z "$workspace_name" ]; then
            workspace_name="$default_name"
        fi

        # Validate workspace name (alphanumeric, dash, underscore only)
        if ! [[ "$workspace_name" =~ ^[a-zA-Z0-9_-]+$ ]]; then
            print_error "Invalid workspace name. Use only letters, numbers, dashes, and underscores."
            echo -ne "${BRIGHT_YELLOW}Press Enter to continue...${NC}"
            read -r
            unset SELECTED_PROJECTS_DIR
            return 1
        fi

        # Create workspace
        if create_workspace "$workspace_name" "$projects_folder"; then
            clear
            print_header "Workspace Created"
            echo ""
            print_success "Workspace '$workspace_name' created successfully!"
            echo ""
            print_info "Projects folder: $projects_folder"
            print_info "You can now add projects to this workspace."
            echo ""
            echo -ne "${BRIGHT_YELLOW}Press Enter to continue...${NC}"
            read -r
        else
            print_error "Failed to create workspace."
            echo -ne "${BRIGHT_YELLOW}Press Enter to continue...${NC}"
            read -r
        fi

        # Clear the selection for next time
        unset SELECTED_PROJECTS_DIR
    fi
}

# Function to create a new workspace
# Parameters: workspace_name, projects_folder
# Returns: 0 if successful, 1 if error
create_workspace() {
    local workspace_name="$1"
    local projects_folder="$2"

    # Get config directory
    local config_dir=$(get_config_directory)

    # Ensure config directory exists
    if [ ! -d "$config_dir" ]; then
        mkdir -p "$config_dir" 2>/dev/null || return 1
    fi

    # Create workspace file path
    local workspace_file="$config_dir/${workspace_name}.json"

    # Check if workspace file already exists
    if [ -f "$workspace_file" ]; then
        print_error "Workspace '$workspace_name' already exists!"
        return 1
    fi

    # Create empty workspace file (empty JSON array)
    if ! echo '[]' > "$workspace_file" 2>/dev/null; then
        print_error "Failed to create workspace file: $workspace_file"
        return 1
    fi

    # Activate the workspace (registers and activates in one step)
    if ! activate_workspace "$workspace_file" "$projects_folder"; then
        print_error "Failed to register workspace in configuration"
        # Clean up the workspace file we just created
        rm -f "$workspace_file" 2>/dev/null
        return 1
    fi

    return 0
}
