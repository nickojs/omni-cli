#!/bin/bash

# ========================================
# Enhanced Mock Project Generator
# ========================================
# Generates realistic test projects with safety limits
# Usage: mockup.sh <folders> [projects-per-folder]

# Bash safety settings
set -euo pipefail
IFS=$'\n\t'

# Constants
readonly MAX_PROJECTS_PER_FOLDER=5
readonly MAX_FOLDERS=3
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly CONFIG_DIR="$SCRIPT_DIR/../config"

# Realistic project names
readonly MOCK_PROJECTS=(
    "frontend-app"
    "backend-api"
    "mobile-client"
    "admin-dashboard"
    "payment-service"
    "user-service"
    "notification-service"
    "analytics-engine"
    "file-processor"
    "email-worker"
    "blog-cms"
    "e-commerce-shop"
    "inventory-manager"
    "chat-service"
    "video-streamer"
)

# Folder category names
readonly MOCK_FOLDERS=(
    "microservices"
    "web-apps"
    "mobile-projects"
    "data-services"
    "client-work"
    "experiments"
    "legacy-systems"
)

# Cleanup on error (only for critical failures)
cleanup_on_error() {
    echo "❌ Critical error occurred during mockup generation"
    echo "🧹 Cleaning up partial state..."
    # Clean up any partial state if needed
    rm -f "$SCRIPT_DIR"/*.json.tmp 2>/dev/null || true
    exit 1
}

# Utility functions
sanitize_name() {
    local name="$1"
    # Remove special chars, keep alphanumeric, hyphens, underscores
    # Convert to lowercase for consistency
    echo "$name" | tr -cd '[:alnum:]-_' | tr '[:upper:]' '[:lower:]'
}

# Function to convert name to title case (e.g., "my-project" -> "My Project")
to_title_case() {
    local name="$1"
    echo "$name" | sed 's/-/ /g' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) substr($i,2)} 1'
}

# Function to get random project name
get_project_name() {
    local index="$1"
    local total_projects=${#MOCK_PROJECTS[@]}

    if [ "$index" -le "$total_projects" ]; then
        echo "${MOCK_PROJECTS[$((index - 1))]}"
    else
        # Fallback to numbered project if we exceed array
        echo "project-$index"
    fi
}

# Function to get random folder name
get_folder_name() {
    local index="$1"
    local total_folders=${#MOCK_FOLDERS[@]}

    if [ "$index" -le "$total_folders" ]; then
        echo "${MOCK_FOLDERS[$((index - 1))]}"
    else
        # Fallback to numbered folder if we exceed array
        echo "folder-$index"
    fi
}

# Function to generate JSON for a specific folder using jq
generate_folder_json() {
    local folder_name="$1"
    local folder_display="$2"
    local -n projects_ref=$3
    local temp_file="$SCRIPT_DIR/temp_$folder_name.json"

    # Start with empty JSON array
    echo "[]" > "$temp_file"

    # Add each project to the JSON array
    for project_data in "${projects_ref[@]}"; do
        IFS='|' read -r proj_name proj_display proj_path <<< "$project_data"

        # Use jq to safely add project to array
        jq --arg displayName "$proj_display" \
           --arg projectName "$proj_name" \
           --arg relativePath "$proj_path" \
           --arg startupCmd "./start.sh" \
           --arg shutdownCmd "" \
           --arg folderPath "test-area/$folder_name" \
           '. += [{
               "displayName": $displayName,
               "projectName": $projectName,
               "relativePath": $relativePath,
               "startupCmd": $startupCmd,
               "shutdownCmd": $shutdownCmd,
               "folderPath": $folderPath
           }]' \
           "$temp_file" > "$temp_file.new" && mv "$temp_file.new" "$temp_file"
    done

    # Move temp file to final location
    local final_file="$SCRIPT_DIR/testing_data__$folder_name.json"
    mv "$temp_file" "$final_file"

    echo "📝 Generated: testing_data__$folder_name.json (${#projects_ref[@]} projects)"
}

# Function to generate .workspaces.json
generate_workspaces_config() {
    local -n folder_names_ref=$1
    local workspaces_file="$SCRIPT_DIR/testing_data__.workspaces.json"

    echo "🏗️  Generating workspaces configuration..."

    # Build arrays for activeConfig, availableConfigs, and workspacePaths
    local active_config_array="[]"
    local available_configs_array="[]"
    local workspace_paths_obj="{}"

    for folder_name in "${folder_names_ref[@]}"; do
        local workspace_file="config/testing_data__$folder_name.json"
        local projects_folder="test-area/$folder_name"

        # Add to activeConfig (all workspaces active by default for testing)
        active_config_array=$(echo "$active_config_array" | jq --arg ws "$workspace_file" '. += [$ws]')

        # Add to availableConfigs
        available_configs_array=$(echo "$available_configs_array" | jq --arg ws "$workspace_file" '. += [$ws]')

        # Add to workspacePaths
        workspace_paths_obj=$(echo "$workspace_paths_obj" | jq --arg key "$workspace_file" --arg val "$projects_folder" '. + {($key): $val}')
    done

    # Create the final workspaces config
    jq -n \
        --argjson activeConfig "$active_config_array" \
        --argjson availableConfigs "$available_configs_array" \
        --argjson workspacePaths "$workspace_paths_obj" \
        '{
            "activeConfig": $activeConfig,
            "availableConfigs": $availableConfigs,
            "workspacePaths": $workspacePaths
        }' > "$workspaces_file"

    echo "✅ Generated: testing_data__.workspaces.json"
    echo "   Active workspaces: ${#folder_names_ref[@]}"
}

# Function to clean up test projects
clean_projects() {
    echo "🧹 Cleaning up test projects..."
    echo "📍 Script directory: $SCRIPT_DIR"

    # Check what would be deleted
    local has_legacy_projects=false
    local has_folder_projects=false
    local has_configs=false
    local has_workspaces_config=false
    local found_items=()

    # Check for legacy project-* folders (backward compatibility)
    if ls "$SCRIPT_DIR"/project-* >/dev/null 2>&1; then
        echo "🗑️  Found legacy project folders:"
        echo "$(ls -d "$SCRIPT_DIR"/project-* 2>/dev/null | xargs basename -a)"
        has_legacy_projects=true
        found_items+=("legacy project folders")
    fi

    # Check for new folder structure (microservices/, web-apps/, etc.)
    local folder_dirs=()
    for folder_name in "${MOCK_FOLDERS[@]}"; do
        if [ -d "$SCRIPT_DIR/$folder_name" ]; then
            folder_dirs+=("$folder_name")
            has_folder_projects=true
        fi
    done

    if [ "$has_folder_projects" = true ]; then
        echo "🗑️  Found project folders:"
        printf '  %s\n' "${folder_dirs[@]}"
        found_items+=("project folders")
    fi

    # Check for JSON configurations
    local config_files=()
    if ls "$SCRIPT_DIR"/testing_data__*.json >/dev/null 2>&1; then
        mapfile -t config_files < <(ls "$SCRIPT_DIR"/testing_data__*.json 2>/dev/null | xargs basename -a)
        echo "🗑️  Found configuration files:"
        printf '  %s\n' "${config_files[@]}"
        has_configs=true
        found_items+=("configuration files")
    fi

    # Check for workspaces config
    if [ -f "$SCRIPT_DIR/testing_data__.workspaces.json" ]; then
        echo "🗑️  Found workspaces configuration"
        has_workspaces_config=true
        found_items+=("workspaces configuration")
    fi

    # Check for temporary files
    if ls "$SCRIPT_DIR"/temp_*.json >/dev/null 2>&1; then
        echo "🗑️  Found temporary files:"
        ls "$SCRIPT_DIR"/temp_*.json 2>/dev/null | xargs basename -a
        found_items+=("temporary files")
    fi

    if [ ${#found_items[@]} -eq 0 ]; then
        echo "📂 Nothing to clean - no test projects or configs found"
        return
    fi

    # Ask for confirmation
    local items_text
    if [ ${#found_items[@]} -eq 1 ]; then
        items_text="${found_items[0]}"
    else
        # Join array elements with ", " and replace last ", " with " and "
        items_text=$(IFS=", "; echo "${found_items[*]}" | sed 's/, \([^,]*\)$/ and \1/')
    fi

    # Skip confirmation if running non-interactively or if FORCE_CLEANUP is set
    if [[ -t 0 ]] && [[ -z "${FORCE_CLEANUP:-}" ]]; then
        echo -n "❓ Are you sure you want to delete these $items_text? [y/N]: "
        read -r confirmation

        if [[ ! "$confirmation" =~ ^[Yy]$ ]]; then
            echo "❌ Cleanup cancelled"
            return
        fi
    else
        echo "🤖 Auto-cleanup enabled - proceeding with deletion"
    fi

    # Perform the deletion
    if [ "$has_legacy_projects" = true ]; then
        rm -rf "$SCRIPT_DIR"/project-* 2>/dev/null
        echo "✅ Removed legacy project folders"
    fi

    if [ "$has_folder_projects" = true ]; then
        for folder_name in "${folder_dirs[@]}"; do
            rm -rf "$SCRIPT_DIR/$folder_name"
            echo "✅ Removed folder: $folder_name"
        done
    fi

    if [ "$has_configs" = true ]; then
        rm -f "$SCRIPT_DIR"/testing_data__*.json 2>/dev/null
        echo "✅ Removed configuration files"
    fi

    if [ "$has_workspaces_config" = true ]; then
        rm -f "$SCRIPT_DIR/testing_data__.workspaces.json"
        echo "✅ Removed workspaces configuration"
    fi

    # Clean up any temporary files
    rm -f "$SCRIPT_DIR"/temp_*.json 2>/dev/null

    echo "🎉 Cleanup complete!"
}

# Function to show usage
show_usage() {
    echo "Usage: $0 <folders> [projects-per-folder] | clean"
    echo ""
    echo "Arguments:"
    echo "  folders            Number of folders to create (1-${MAX_FOLDERS})"
    echo "  projects-per-folder Number of projects in each folder (1-${MAX_PROJECTS_PER_FOLDER}, default: 3)"
    echo "  clean              Clean up all test projects and configurations"
    echo ""
    echo "Examples:"
    echo "  $0 2         # Generate 2 folders with 3 projects each (total: 6 projects)"
    echo "  $0 2 5       # Generate 2 folders with 5 projects each (total: 10 projects)"
    echo "  $0 clean     # Clean up test projects"
    echo ""
    echo "Safety Limits:"
    echo "  • Maximum ${MAX_PROJECTS_PER_FOLDER} projects per folder"
    echo "  • Maximum ${MAX_FOLDERS} folders total"
}

# Function to validate inputs
validate_inputs() {
    local folders="$1"
    local projects_per_folder="$2"

    # Validate folders argument
    if ! [[ "$folders" =~ ^[1-9][0-9]*$ ]]; then
        echo "❌ Error: Folders must be a positive integer"
        show_usage
        exit 1
    fi

    # Validate projects per folder argument
    if ! [[ "$projects_per_folder" =~ ^[1-9][0-9]*$ ]]; then
        echo "❌ Error: Projects per folder must be a positive integer"
        show_usage
        exit 1
    fi

    # Check safety limits
    if [ "$folders" -gt "$MAX_FOLDERS" ]; then
        echo "❌ Error: Maximum $MAX_FOLDERS folders allowed (requested: $folders)"
        show_usage
        exit 1
    fi

    if [ "$projects_per_folder" -gt "$MAX_PROJECTS_PER_FOLDER" ]; then
        echo "❌ Error: Maximum $MAX_PROJECTS_PER_FOLDER projects per folder (requested: $projects_per_folder)"
        show_usage
        exit 1
    fi

    echo "✅ Input validation passed: $folders folders with $projects_per_folder projects each"
}

# Handle clean flag
if [ "${1:-}" = "clean" ]; then
    clean_projects
    exit 0
fi

# Check if any arguments provided
if [ $# -eq 0 ]; then
    echo "❌ Error: No arguments provided"
    show_usage
    exit 1
fi

# Parse and validate arguments
NUM_FOLDERS="$1"
PROJECTS_PER_FOLDER="${2:-3}"
NUM_PROJECTS=$((NUM_FOLDERS * PROJECTS_PER_FOLDER))

validate_inputs "$NUM_FOLDERS" "$PROJECTS_PER_FOLDER"

echo "🎭 Generating $NUM_FOLDERS folders with $PROJECTS_PER_FOLDER projects each (total: $NUM_PROJECTS projects)..."

# Function to create project directory and script
create_project() {
    local folder_name="$1"
    local project_name="$2"
    local project_display_name="$3"
    local project_dir="$4"

    echo "  📁 Creating $project_name in $folder_name..."

    # Create directory with proper permissions
    if ! mkdir -p "$project_dir"; then
        echo "❌ Failed to create directory: $project_dir"
        exit 1
    fi

    # Create startup script with realistic content
    cat > "$project_dir/start.sh" << EOF
#!/bin/bash
echo "$project_display_name is running..."
sleep 999999
EOF

    # Set executable permissions
    chmod +x "$project_dir/start.sh"
}

# Clean up existing test projects first
clean_projects
echo "📍 Script directory: $SCRIPT_DIR"

# Array to collect all folder names for workspaces config
declare -a all_folder_names=()

# Generate projects in folders
project_counter=1
for folder_idx in $(seq 1 "$NUM_FOLDERS"); do
    # Get folder name from array or fallback
    folder_name=$(get_folder_name "$folder_idx")
    folder_name=$(sanitize_name "$folder_name")
    folder_dir="$SCRIPT_DIR/$folder_name"

    # Add to all folders array
    all_folder_names+=("$folder_name")

    echo "📂 Creating folder: $folder_name ($PROJECTS_PER_FOLDER projects)"
    mkdir -p "$folder_dir"

    # Array to collect project data for this folder's JSON
    declare -a folder_projects=()

    for project_in_folder_idx in $(seq 1 "$PROJECTS_PER_FOLDER"); do
        # Get project name from array
        project_name=$(get_project_name "$project_counter")
        project_name=$(sanitize_name "$project_name")

        # Create display name (Folder Name - Project Name)
        folder_display=$(to_title_case "$(get_folder_name "$folder_idx")")
        project_display=$(to_title_case "$(get_project_name "$project_counter")")
        project_display_name="$folder_display - $project_display"

        project_dir="$folder_dir/$project_name"
        project_relative_path="test-area/$folder_name/$project_name"

        create_project "$folder_name" "$project_name" "$project_display_name" "$project_dir"

        # Add project data to folder's project list (format: name|display|path)
        folder_projects+=("$project_name|$project_display_name|$project_relative_path")

        ((project_counter++))
    done

    # Generate JSON configuration for this folder
    generate_folder_json "$folder_name" "$folder_display" folder_projects
    echo ""
done

# Generate workspaces configuration
echo ""
generate_workspaces_config all_folder_names

echo ""
echo "✅ Generated $NUM_PROJECTS projects in $NUM_FOLDERS folder(s) successfully!"
echo "📄 Created $NUM_FOLDERS workspace configuration files:"
for folder_name in "${all_folder_names[@]}"; do
    echo "  • testing_data__$folder_name.json"
done
echo "📄 Created workspaces config: testing_data__.workspaces.json"
echo "🎯 Use masquerade script to apply these test configurations"
