#!/bin/bash

# ========================================
# Fetch Project Module
# ========================================
# This module provides functionality to clone Git repositories
# and integrate them with the project manager
# Usage: source modules/fetch-project or call directly

# Get the directory where this script is located
# Check environment: packaged vs development
if [[ -n "$BASE_DIR" ]]; then
    # Package environment - BASE_DIR is set by startup.sh
    FETCH_MODULE_DIR="$BASE_DIR/modules/menu"
else
    # Development environment - use relative path
    FETCH_MODULE_DIR="$(dirname "${BASH_SOURCE[0]}")"
fi

# Ensure styles are available if running standalone
if [[ -z "$BRIGHT_CYAN" ]]; then
    source "$FETCH_MODULE_DIR/../styles/index.sh" 2>/dev/null || {
        # Fallback color definitions if styles not available
        BRIGHT_CYAN='\033[1;36m'
        BRIGHT_GREEN='\033[1;32m'
        BRIGHT_RED='\033[1;31m'
        BRIGHT_YELLOW='\033[1;33m'
        BRIGHT_WHITE='\033[1;37m'
        NC='\033[0m'
    }
fi

# Source required modules for configuration management (only needed for standalone execution)
if [[ -z "$(type -t load_projects_from_json)" ]]; then
    source "$FETCH_MODULE_DIR/../config/json-parser.sh" 2>/dev/null || true
fi

if [[ -z "$(type -t add_single_project_config)" ]]; then
    source "$FETCH_MODULE_DIR/../wizard.sh" 2>/dev/null || true
fi

# Function to fetch a project from Git repository
fetch_project_standalone() {
    print_header "GIT REPOSITORY CLONER"
    print_info "This tool will clone a Git repository to the directory where you ran this script."
    echo ""
    print_step "Current directory: $(pwd)"
    echo ""

    # Get the GitHub URL from user
    echo -ne "${BRIGHT_CYAN}Enter the Git repository URL: ${NC}"
    read -r github_url

    # Validate URL is not empty
    if [ -z "$github_url" ]; then
        print_error "No URL provided. Exiting..."
        exit 1
    fi

    echo ""
    print_step "Repository URL: $github_url"
    print_step "Clone destination: $(pwd)"
    echo ""

    # Ask for confirmation before cloning
    echo -ne "${BRIGHT_YELLOW}Proceed with cloning? ${BOLD}(y/N)${NC}: "
    read -r confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        print_info "Cancelled."
        exit 0
    fi

    echo ""
    print_step "Starting clone process..."
    echo ""

    # Clone the repository
    if git clone "$github_url"; then
        echo ""
        print_success "Repository cloned successfully!"
        
        # Extract repository name from URL for helpful message
        repo_name=$(basename "$github_url" .git)
        print_info "You can now navigate to the repository with: cd $repo_name"
        
        # If fm-manager is available, suggest adding to project manager
        if command -v fm-manager &> /dev/null; then
            echo ""
            print_info "💡 Tip: You can add this project to fm-manager by running:"
            echo -e "   ${BRIGHT_CYAN}fm-manager${NC} and using the wizard (w) command"
        fi
    else
        echo ""
        print_error "Failed to clone repository."
        echo ""
        print_warning "Please check:"
        echo -e "  ${NC}• The URL is correct"
        echo -e "  ${NC}• You have internet connection"  
        echo -e "  ${NC}• You have access to the repository (if private)"
        echo -e "  ${NC}• Git is installed on your system"
        exit 1
    fi
}

# Function to fetch project with integration to project manager
fetch_project_integrated() {
    local dest_dir="$1"
    local github_url="$2"
    local show_header="${3:-true}"
    
    if [ "$show_header" = "true" ]; then
        print_header "FETCH PROJECT FROM GIT"
        echo ""
    fi
    
    # Validate inputs
    if [ -z "$github_url" ]; then
        print_error "Repository URL is required"
        return 1
    fi
    
    if [ -z "$dest_dir" ]; then
        dest_dir="$(pwd)"
    fi
    
    # Create destination directory if it doesn't exist
    if [ ! -d "$dest_dir" ]; then
        print_step "Creating destination directory: $dest_dir"
        mkdir -p "$dest_dir" || {
            print_error "Failed to create directory: $dest_dir"
            return 1
        }
    fi
    
    # Change to destination directory
    cd "$dest_dir" || {
        print_error "Failed to navigate to $dest_dir"
        return 1
    }
    
    print_step "Cloning to: $dest_dir"
    print_step "Repository: $github_url"
    echo ""
    
    # Clone the repository
    if git clone "$github_url"; then
        echo ""
        print_success "Repository cloned successfully!"
        
        # Extract repository name from URL
        repo_name=$(basename "$github_url" .git)
        print_info "Project location: ${dest_dir%/}/$repo_name"
        
        return 0
    else
        echo ""
        print_error "Failed to clone repository."
        return 1
    fi
}

# Function for menu integration - interactive but with return instead of exit
fetch_project_menu() {
    print_header "FETCH PROJECT FROM GIT"
    echo ""

    # Get the GitHub URL from user
    echo -ne "${BRIGHT_CYAN}Enter the Git repository URL: ${NC}"
    read -r github_url

    # Validate URL is not empty
    if [ -z "$github_url" ]; then
        print_error "No URL provided. Returning to menu..."
        sleep 2
        return 1
    fi

    echo ""
    print_step "Repository URL: $github_url"
    
    # Ask for destination directory (default to current)
    echo -ne "${BRIGHT_CYAN}Enter destination directory (leave empty for current): ${NC}"
    read -r dest_dir
    
    if [ -z "$dest_dir" ]; then
        dest_dir="$(pwd)"
    fi
    
    # Expand relative paths
    if [[ "$dest_dir" == "~"* ]]; then
        dest_dir="${dest_dir/#~/$HOME}"
    elif [[ "$dest_dir" != /* ]]; then
        dest_dir="$(pwd)/$dest_dir"
    fi
    
    print_step "Clone destination: $dest_dir"
    echo ""

    # Ask for confirmation before cloning
    echo -ne "${BRIGHT_YELLOW}Proceed with cloning? ${BOLD}(y/N)${NC}: "
    read -r confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        print_info "Cancelled. Returning to menu..."
        sleep 2
        return 0
    fi

    echo ""
    
    # Use the integrated function to do the actual cloning
    if fetch_project_integrated "$dest_dir" "$github_url" true; then
        echo ""
        # Extract repository name from URL
        repo_name=$(basename "$github_url" .git)
        
        # Offer to automatically configure the project
        echo -ne "${BRIGHT_CYAN}Do you want to add this project to fm-manager configuration? ${BOLD}(y/N)${NC}: "
        read -r configure_project
        
        if [[ $configure_project =~ ^[Yy]$ ]]; then
            echo ""
            
            # Call the single project configuration function from wizard.sh
            if type add_single_project_config >/dev/null 2>&1; then
                # Set up the projects directory relative path
                local relative_dest_dir
                if [[ "$dest_dir" = /* ]]; then
                    # Convert absolute path to relative
                    relative_dest_dir=$(realpath --relative-to="." "$dest_dir")
                else
                    relative_dest_dir="$dest_dir"
                fi
                
                # Call the function to add the project
                add_single_project_config "$repo_name" "$relative_dest_dir"
                
                # Reload the configuration in the current session (only if function is available)
                if type load_projects_from_json >/dev/null 2>&1 && load_projects_from_json; then
                    echo ""
                    print_success "Configuration reloaded! Project is now available in the menu."
                else
                    print_warning "Configuration added but could not reload automatically. Please restart fm-manager to see the new project."
                fi
            else
                print_error "Configuration function not available. Please use the wizard (w) command instead."
            fi
        else
            print_info "💡 You can add this project later using the wizard (w) command"
        fi
        
        echo ""
        echo -ne "${BRIGHT_YELLOW}Press Enter to continue...${NC}"
        read -r
        return 0
    else
        echo ""
        echo -ne "${BRIGHT_YELLOW}Press Enter to continue...${NC}"
        read -r
        return 1
    fi
}

# Main function for standalone execution
main() {
    fetch_project_standalone
}

# Only run main if script is executed directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi