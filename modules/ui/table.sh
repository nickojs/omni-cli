#!/bin/bash

# ========================================
# Shared Table UI Component
# ========================================
# Provides reusable table rendering for workspace/project displays
# Usage: source modules/ui/table.sh

# Format workspace filename into display name (title case)
# Parameters:
#   $1 - workspace_file path
# Returns: formatted display name via echo
format_workspace_display_name() {
    local workspace_file="$1"
    local workspace_name=$(basename "$workspace_file" .json)
    echo "$workspace_name" | sed 's/[_-]/ /g' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) substr($i,2)} 1'
}

# Get workspace files from config directory
# Parameters:
#   $1 - mode: "active" (only active workspaces) or "all" (all workspaces)
#   $2 - nameref to array to populate
# Usage: get_workspace_files "active" workspace_files
get_workspace_files() {
    local mode="$1"
    local -n result_array=$2

    result_array=()
    local config_dir=$(get_config_directory)
    local workspaces_file="$config_dir/.workspaces.json"

    if [ ! -f "$workspaces_file" ] || ! command -v jq >/dev/null 2>&1; then
        return 1
    fi

    if [ "$mode" = "active" ]; then
        # Get only active workspaces
        while IFS= read -r active_workspace; do
            local full_path="$config_dir/$active_workspace"
            if [ -f "$full_path" ]; then
                result_array+=("$full_path")
            fi
        done < <(jq -r '.activeConfig[]? // empty' "$workspaces_file" 2>/dev/null)
    else
        # Get all available workspaces
        local available=()
        if get_available_workspaces available; then
            for ws in "${available[@]}"; do
                result_array+=("$config_dir/$ws")
            done
        fi
    fi

    [ ${#result_array[@]} -gt 0 ]
}

# Get assigned vaults for a project
# Parameters:
#   $1 - workspace_file path
#   $2 - relative_path of project
# Returns: comma-separated vault names via echo
get_project_vaults() {
    local workspace_file="$1"
    local relative_path="$2"

    if [ -f "$workspace_file" ] && command -v jq >/dev/null 2>&1; then
        jq -r --arg path "$relative_path" \
            '.[] | select(.relativePath == $path) | .assignedVaults[]? // empty' \
            "$workspace_file" 2>/dev/null | tr '\n' ',' | sed 's/,$//'
    fi
}

# Truncate value to max length with ellipsis
# Parameters:
#   $1 - value
#   $2 - max length
# Returns: truncated value via echo
truncate_value() {
    local value="$1"
    local max_len="$2"

    if [ ${#value} -gt "$max_len" ]; then
        printf "%.${max_len}s..." "${value:0:$((max_len - 3))}"
    else
        echo "$value"
    fi
}

# Format column with fixed width
# Parameters:
#   $1 - value
#   $2 - width
# Returns: formatted value via echo
format_column() {
    local value="$1"
    local width="$2"
    printf "%-${width}s" "$value"
}

# Render workspace header
# Parameters:
#   $1 - mode: "menu" or "settings"
#   $2 - display_name
#   $3 - counter (for settings mode)
#   $4 - status_icon (for settings mode, optional)
#   $5 - status_text (for settings mode, optional)
render_workspace_header() {
    local mode="$1"
    local display_name="$2"
    local counter="$3"
    local status_icon="$4"
    local status_text="$5"

    if [ "$mode" = "menu" ]; then
        printf " ${BRIGHT_CYAN}%s${NC}\n" "$display_name"
    else
        printf " %s ${BRIGHT_CYAN}%s${NC} ${BOLD}%-25s${NC} %s" \
            "$status_icon" "Workspace #$counter" "\"${display_name:0:45}\""
    fi
    echo ""
    echo ""
}

# Render table header row
# Parameters:
#   $1 - mode: "menu" or "settings"
# Outputs directly to stdout
render_table_header() {
    local mode="$1"

    if [ "$mode" = "menu" ]; then
        local h_counter=$(format_column "#" 3)
        local h_name=$(format_column "Name" 34)
        local h_status=$(format_column "Status" 16)
        local h_vaults="Vaults"
        echo -e "  ${BRIGHT_WHITE}${h_counter}${h_name}${h_status}${h_vaults}${NC}"
    else
        local h_name=$(format_column "Project name" 24)
        local h_folder=$(format_column "Folder name" 24)
        local h_startup=$(format_column "Startup cmd" 20)
        local h_shutdown=$(format_column "Shutdown cmd" 20)
        local h_vaults=$(format_column "Vaults" 20)
        printf "  ${BRIGHT_WHITE}%s %s %s %s %s\n${NC}" \
            "$h_name" "$h_folder" "$h_startup" "$h_shutdown" "$h_vaults"
    fi
    echo ""
}

# Render project row for menu mode
# Parameters:
#   $1 - counter
#   $2 - project_name
#   $3 - status_text
#   $4 - status_color
#   $5 - vaults
render_menu_project_row() {
    local counter="$1"
    local project_name="$2"
    local status_text="$3"
    local status_color="$4"
    local vaults="$5"

    local col_counter=$(format_column "$counter" 3)
    local col_name=$(format_column "${project_name:0:34}" 34)
    local col_status=$(format_column "$status_text" 16)
    local col_vaults="${vaults:-}"

    echo -e "  ${BRIGHT_CYAN}${col_counter}${NC}${BRIGHT_WHITE}${col_name}${NC}${status_color}${col_status}${NC}${DIM}${col_vaults}${NC}"
}

# Render project row for settings mode
# Parameters:
#   $1 - project_name
#   $2 - folder_name
#   $3 - startup_cmd
#   $4 - shutdown_cmd
#   $5 - vaults
render_settings_project_row() {
    local project_name="$1"
    local folder_name="$2"
    local startup_cmd="$3"
    local shutdown_cmd="$4"
    local vaults="$5"

    # Truncate long values
    folder_name=$(truncate_value "$folder_name" 24)
    startup_cmd=$(truncate_value "$startup_cmd" 20)
    shutdown_cmd=$(truncate_value "$shutdown_cmd" 20)
    vaults=$(truncate_value "$vaults" 20)

    # Format columns
    local col_name=$(format_column "$project_name" 24)
    local col_folder=$(format_column "$folder_name" 24)
    local col_startup=$(format_column "$startup_cmd" 20)
    local col_shutdown=$(format_column "$shutdown_cmd" 22)
    local col_vaults=$(format_column "${vaults:-}" 20)

    printf "  ${DIM}%s %s %s %s %s${NC}\n" \
        "$col_name" "$col_folder" "$col_startup" "$col_shutdown" "$col_vaults"
}

# Get project status for menu display
# Parameters:
#   $1 - project_display_name
#   $2 - folder_path
# Returns via echo: "status_text|status_color"
get_project_status() {
    local project_name="$1"
    local folder_path="$2"

    local status_text=""
    local status_color=""

    if is_project_running "$project_name"; then
        if is_project_stopping "$project_name"; then
            status_text="stopping"
            status_color="${BRIGHT_YELLOW}"
        else
            status_text="running"
            status_color="${GREEN}"
        fi
    else
        clear_project_stopping "$project_name"
        if [ -d "$folder_path" ]; then
            status_text="stopped"
            status_color="${DIM}"
        else
            status_text="not found"
            status_color="${RED}"
        fi
    fi

    echo "${status_text}|${status_color}"
}

# Get workspace active status
# Parameters:
#   $1 - workspace_file path
# Returns via echo: "icon|text"
get_workspace_status() {
    local workspace_file="$1"

    if is_workspace_active "$workspace_file"; then
        echo "${BRIGHT_GREEN}●${NC}|${DIM}active${NC}"
    else
        echo "${DIM}○${NC}|${DIM}inactive${NC}"
    fi
}
