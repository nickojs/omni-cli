#!/bin/bash
# Project Setup Wizard
# Generates project configuration for the tmux project manager

# Get the directory where this script is located
WIZARD_DIR="$(dirname "${BASH_SOURCE[0]}")"

# Import required modules
source "$WIZARD_DIR/../../styles/index.sh"
source "$WIZARD_DIR/../config/json.sh"

# Function to scan directory and list projects
scan_projects_directory() {
    local projects_dir=$1
    local -a project_folders=()
    
    print_step "Scanning directory: $projects_dir"
    
    if [ ! -d "$projects_dir" ]; then
        print_error "Directory '$projects_dir' does not exist!"
        return 1
    fi
    
    # Find all subdirectories
    while IFS= read -r -d '' dir; do
        local folder_name=$(basename "$dir")
        
        # Skip hidden directories and the current project folder (fm-manager)
        if [[ ! "$folder_name" =~ ^\. ]] && [[ "$folder_name" != "fm-manager" ]]; then
            project_folders+=("$folder_name")
        fi
    done < <(find "$projects_dir" -mindepth 1 -maxdepth 1 -type d -print0 | sort -z)
    
    if [ ${#project_folders[@]} -eq 0 ]; then
        print_error "No project folders found in '$projects_dir'"
        return 1
    fi
    
    echo ""
    print_color "$BRIGHT_YELLOW" "Found ${#project_folders[@]} project folders:"
    for i in "${!project_folders[@]}"; do
        echo "$((i + 1)). ${project_folders[i]}"
    done
    
    # Store the array globally for use in main function
    FOUND_PROJECTS=("${project_folders[@]}")
    PROJECTS_DIR="$projects_dir"
    return 0
}

# Function to generate the projects array for the main script
generate_config() {
    local -a project_configs=()
    
    print_header "PROJECT CONFIGURATION"
    echo "For each project folder, you'll need to provide:"
    echo "1. Display name (how it appears in the menu)"
    echo "2. Startup command (command to run the project)"
    echo ""
    print_color "$BRIGHT_YELLOW" "Press Enter to skip configuration for any project"
    echo ""
    
    for folder in "${FOUND_PROJECTS[@]}"; do
        echo ""
        print_color "$CYAN" "$folder config:"
        echo "Folder path: ${PROJECTS_DIR%/}/$folder"
        
        
        # Ask if user wants to skip this project
        read -p "Enter display name for this project (or press Enter to skip): " display_name
        if [ -z "$display_name" ]; then
            print_color "$BRIGHT_YELLOW" "Skipping $folder"
            continue
        fi
        
        # Get startup command
        read -p "Enter startup command (e.g., 'npm start', 'yarn dev'): " startup_cmd
        if [ -z "$startup_cmd" ]; then
            startup_cmd="echo 'No startup command configured'"
        fi
        
        local config="$display_name:$folder:$startup_cmd"
        project_configs+=("$config")
    done
    
    # Check if no projects were configured
    if [ ${#project_configs[@]} -eq 0 ]; then
        echo ""
        print_color "$BRIGHT_YELLOW" "No projects were configured. Configuration skipped."
        echo "You can run this setup again anytime to configure your projects."
        return 0
    fi
    
    # Generate the JSON configuration file
    write_json_config project_configs "$PROJECTS_DIR"
}

# Main wizard function
main() {
    print_header "PROJECT SETUP WIZARD"
    
    # Check if configuration file already exists
    if [ -f "$JSON_CONFIG_FILE" ]; then
        print_error "Configuration file already exists: $JSON_CONFIG_FILE"
        echo "Remove the existing file if you want to recreate the configuration."
        exit 1
    fi
    
    echo "This wizard will help you configure projects for the tmux project manager."
    echo ""
    
    # Get projects directory
    local projects_dir=""
    while [ -z "$projects_dir" ]; do
        read -p "Enter the relative path to your projects folder: " projects_dir
        
        if [ -z "$projects_dir" ]; then
            print_error "Please enter a valid path"
            continue
        fi
        
        # Convert to relative path if absolute path was provided
        if [[ "$projects_dir" = /* ]]; then
            projects_dir=$(realpath --relative-to="." "$projects_dir")
            print_step "Converted to relative path: $projects_dir"
        fi
        
        # Scan the directory
        if ! scan_projects_directory "$projects_dir"; then
            projects_dir=""
            continue
        fi
        
        break
    done
    
    
    # Ask user which projects to configure
    echo ""
    read -p "Do you want to configure all found projects? (y/n): " configure_all
    
    if [[ ! $configure_all =~ ^[Yy]$ ]]; then
        echo ""
        print_step "Select projects to configure (enter numbers separated by spaces):"
        read -p "Projects to configure: " selected_numbers
        
        # Parse selected numbers
        local -a selected_projects=()
        for num in $selected_numbers; do
            if [[ $num =~ ^[0-9]+$ ]] && [ "$num" -ge 1 ] && [ "$num" -le "${#FOUND_PROJECTS[@]}" ]; then
                local index=$((num - 1))
                selected_projects+=("${FOUND_PROJECTS[index]}")
            else
                print_error "Invalid selection: $num"
            fi
        done
        
        if [ ${#selected_projects[@]} -eq 0 ]; then
            print_error "No valid projects selected. Exiting."
            exit 1
        fi
        
        FOUND_PROJECTS=("${selected_projects[@]}")
    fi
    
    # Generate configuration
    generate_config

    # Only show setup complete if configuration was actually created with content
    if [ -f "$JSON_CONFIG_FILE" ] && [ -s "$JSON_CONFIG_FILE" ]; then
        # Double check that it's not just an empty array
        json_content=$(cat "$JSON_CONFIG_FILE" | tr -d '[:space:]')
        if [ "$json_content" != "[]" ]; then
            echo ""
            print_header "SETUP COMPLETE!"
            print_success "Your project configuration is ready!"
            echo ""
            print_color "$BRIGHT_YELLOW" "Next steps:"
            echo "1. Your main script will automatically read this JSON configuration"
            echo "2. Run your main tmux script - it will parse the $JSON_CONFIG_FILE file"
            echo ""
            print_color "$BLUE" "Happy coding! 🚀"
        fi
    fi
}

