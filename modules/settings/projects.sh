#!/bin/bash

# ========================================
# Projects Management Module
# ========================================
# This module handles multiple project configuration management
# Usage: source modules/settings/projects.sh

# Function to get config directory based on environment
get_config_directory() {
    if [ -d "config" ] && [ -f "startup.sh" ]; then
        # Development environment
        echo "config"
    else
        # Production environment
        local cache_dir="$HOME/.cache/fm-manager"
        mkdir -p "$cache_dir"
        echo "$cache_dir"
    fi
}

# Function to list available configuration files
list_config_files() {
    local config_dir="$1"
    find "$config_dir" -name "*.json" -type f ! -name ".*" 2>/dev/null | sort
}

# Function to get project count from config file
get_config_project_count() {
    local config_file="$1"
    if [ -f "$config_file" ] && command -v jq >/dev/null 2>&1; then
        local count
        count=$(jq '. | length' "$config_file" 2>/dev/null)
        if [[ "$count" =~ ^[0-9]+$ ]]; then
            echo "$count"
        else
            echo "0"
        fi
    else
        echo "0"
    fi
}

# Function to get config file display name
get_config_display_name() {
    local config_file="$1"
    local filename=$(basename "$config_file" .json)

    # Convert underscores and hyphens to spaces, capitalize words
    echo "$filename" | sed 's/[_-]/ /g' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) substr($i,2)} 1'
}

# Function to show projects management screen
show_projects_management_screen() {
    while true; do
        clear
        print_header "Project Configuration"

        # List available configuration files
        local config_files
        mapfile -t config_files < <(list_config_files "$(get_config_directory)")

        if [ ${#config_files[@]} -eq 0 ]; then
            print_warning "No configuration files found"
        else
            # Display configs
            for i in "${!config_files[@]}"; do
                local config_file="${config_files[i]}"
                local display_name=$(get_config_display_name "$config_file")
                local project_count=$(get_config_project_count "$config_file")
                local number="${BRIGHT_CYAN}$((i + 1))${NC}"

                if [[ "$config_file" == *"$(basename "$JSON_CONFIG_FILE")" ]]; then
                    local status="${BRIGHT_GREEN}●${NC} ${BRIGHT_GREEN}running${NC}"
                else
                    local status="${DIM}○${NC} ${DIM}stopped${NC}"
                fi

                echo -e "  ${number}  ${BRIGHT_WHITE}${display_name}${NC}  ${status}  ${DIM}${project_count} projects${NC}"
            done
        fi

        echo ""
        echo -e "${BRIGHT_GREEN}[c]${NC} change config │ ${BRIGHT_PURPLE}[b]${NC} back to settings"
        echo ""
        echo -ne "${BRIGHT_CYAN}>${NC} "

        IFS= read -r -n1 -s choice

        case "${choice,,}" in
            "c")
                show_config_selector
                ;;
            "b")
                break
                ;;
        esac
    done
}

# Function to show config selector
show_config_selector() {
    local config_files
    mapfile -t config_files < <(list_config_files "$(get_config_directory)")

    if [ ${#config_files[@]} -eq 0 ]; then
        print_error "No configuration files found"
        echo -ne "${BRIGHT_YELLOW}Press Enter to continue...${NC}"
        read -r
        return
    fi

    local selection=1

    while true; do
        clear
        print_header "Select Configuration"
        echo ""

        for i in "${!config_files[@]}"; do
            local config_file="${config_files[i]}"
            local display_name=$(get_config_display_name "$config_file")
            local project_count=$(get_config_project_count "$config_file")

            if [[ "$config_file" == *"$(basename "$JSON_CONFIG_FILE")" ]]; then
                local status="${BRIGHT_GREEN}●${NC} ${BRIGHT_GREEN}running${NC}"
            else
                local status="${DIM}○${NC} ${DIM}stopped${NC}"
            fi

            if [ "$((i + 1))" -eq "$selection" ]; then
                echo -e "${BRIGHT_YELLOW}▶${NC} ${BOLD}${BRIGHT_CYAN}$((i + 1))${NC}  ${BOLD}${BRIGHT_WHITE}${display_name}${NC}  ${BOLD}${status}${NC}  ${BOLD}${BRIGHT_WHITE}${project_count} projects${NC}"
            else
                echo -e "  ${BRIGHT_CYAN}$((i + 1))${NC}  ${BRIGHT_WHITE}${display_name}${NC}  ${status}  ${DIM}${project_count} projects${NC}"
            fi
        done

        echo ""
        echo -e "${BRIGHT_YELLOW}[w]${NC}/${BRIGHT_YELLOW}[s]${NC} navigate │ ${BRIGHT_GREEN}[Enter]${NC} select │ ${BRIGHT_RED}[b]${NC} back"
        echo ""
        echo -ne "${BRIGHT_CYAN}>${NC} "

        IFS= read -r -n1 -s choice

        case "${choice,,}" in
            "w")
                selection=$((selection > 1 ? selection - 1 : ${#config_files[@]}))
                ;;
            "s")
                selection=$((selection < ${#config_files[@]} ? selection + 1 : 1))
                ;;
            $'\n'|$'\r'|'')
                local selected_config="${config_files[$((selection - 1))]}"
                switch_to_config "$selected_config"
                return
                ;;
            "b"|"q")
                return
                ;;
        esac
    done
}

# Function to switch to selected configuration
switch_to_config() {
    local selected_config="$1"
    local config_name=$(basename "$selected_config")

    print_info "Switching to configuration: $config_name"

    # Update the JSON_CONFIG_FILE variable to point to the selected config
    export JSON_CONFIG_FILE="$selected_config"

    # Reload the projects array from the new configuration
    if [ -f "$selected_config" ]; then
        # Source the config loader to reload projects
        source "modules/config/loader.sh"
        load_config

        # Update the bulk_project_config tracker
        update_bulk_config_tracker "$selected_config"

        echo -e "${BRIGHT_GREEN}✓${NC} Configuration switched successfully!"
        echo -e "${DIM}Active config: $(basename "$selected_config")${NC}"
        echo -e "${DIM}Projects loaded: ${#projects[@]}${NC}"
    else
        print_error "Configuration file not found: $selected_config"
    fi

    echo ""
    echo -ne "${BRIGHT_YELLOW}Press Enter to continue...${NC}"
    read -r
}

# Function to update bulk config tracker
update_bulk_config_tracker() {
    local active_config="$1"
    local config_dir
    config_dir=$(get_config_directory)
    local bulk_config_file="$config_dir/.bulk_project_config.json"

    # Get all available configs (excluding hidden files)
    local config_files
    mapfile -t config_files < <(list_config_files "$config_dir")

    # Build available configs array
    local available_configs_json="[]"
    for config_file in "${config_files[@]}"; do
        local config_name=$(basename "$config_file" .json)
        available_configs_json=$(echo "$available_configs_json" | jq --arg name "$config_name" '. += [$name]')
    done

    # Get display name for active config
    local active_config_name=$(basename "$active_config" .json)
    local display_name=$(echo "$active_config_name" | sed 's/[_-]/ /g' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) substr($i,2)} 1')

    # Get projects root directory from the active config
    local projects_path=""
    if [ -f "$active_config" ]; then
        # Temporarily set JSON_CONFIG_FILE to get the projects root
        local old_config="$JSON_CONFIG_FILE"
        JSON_CONFIG_FILE="$active_config"

        # Source the utils to get projects root function
        if [ -f "modules/settings/utils.sh" ]; then
            source "modules/settings/utils.sh"
            projects_path=$(get_projects_root_directory 2>/dev/null || echo "")
        fi

        # Restore original config
        JSON_CONFIG_FILE="$old_config"

        # Convert relative path to absolute
        if [ -n "$projects_path" ] && [ "$projects_path" != "." ]; then
            projects_path=$(cd "$(dirname "$active_config")" && realpath "$projects_path" 2>/dev/null || echo "$projects_path")
        fi
    fi

    # Create/update the bulk config file
    if command -v jq >/dev/null 2>&1; then
        jq -n \
            --arg activeConfig "$active_config_name.json" \
            --arg displayName "$display_name" \
            --arg projectsPath "${projects_path:-}" \
            --argjson availableConfigs "$available_configs_json" \
            '{
                "activeConfig": $activeConfig,
                "displayName": $displayName,
                "projectsPath": $projectsPath,
                "availableConfigs": $availableConfigs
            }' > "$bulk_config_file"
    fi
}