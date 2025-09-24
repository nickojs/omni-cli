#!/bin/bash

# Function to generate JSON content
generate_json() {
    local num_projects=$1
    local json_content="["

    for i in $(seq 1 $num_projects); do
        json_content+="\n  {"
        json_content+="\n    \"displayName\": \"Test Project $i\","
        json_content+="\n    \"projectName\": \"project-$i\","
        json_content+="\n    \"relativePath\": \"test-area/project-$i\","
        json_content+="\n    \"startupCmd\": \"./start.sh\""
        json_content+="\n  }"

        if [ $i -lt $num_projects ]; then
            json_content+=","
        fi
    done

    json_content+="\n]"
    echo -e "$json_content"
}

# Function to clean up test projects
clean_projects() {
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    echo "🧹 Cleaning up test projects..."
    echo "📍 Script directory: $SCRIPT_DIR"

    # Check what would be deleted
    local has_projects=false
    local has_json=false

    if ls "$SCRIPT_DIR"/project-* >/dev/null 2>&1; then
        echo "🗑️  Found project folders:"
        echo "$(ls -d "$SCRIPT_DIR"/project-* | xargs basename -a)"
        has_projects=true
    fi

    if [ -f "$SCRIPT_DIR/projects_output__test_area.json" ]; then
        echo "🗑️  Found JSON config: projects_output__test_area.json"
        has_json=true
    fi

    if [ "$has_projects" = false ] && [ "$has_json" = false ]; then
        echo "📂 Nothing to clean - no test projects or config found"
        return
    fi

    # Ask for confirmation
    echo -n "❓ Are you sure you want to delete these files? [y/N]: "
    read -r confirmation

    if [[ ! "$confirmation" =~ ^[Yy]$ ]]; then
        echo "❌ Cleanup cancelled"
        return
    fi

    # Perform the deletion
    if [ "$has_projects" = true ]; then
        rm -rf "$SCRIPT_DIR"/project-*
        echo "✅ Removed project folders"
    fi

    if [ "$has_json" = true ]; then
        rm -f "$SCRIPT_DIR/projects_output__test_area.json"
        echo "✅ Removed JSON config"
    fi

    echo "🎉 Cleanup complete!"
}

# Handle clean flag
if [ "$1" = "clean" ]; then
    clean_projects
    exit 0
fi

# Default to 3 projects if no argument provided
NUM_PROJECTS=${1:-3}

# Validate input
if ! [[ "$NUM_PROJECTS" =~ ^[1-9][0-9]*$ ]]; then
    echo "❌ Error: Please provide a positive number or 'clean'"
    echo "Usage: $0 <number-of-projects|clean>"
    echo "Examples:"
    echo "  $0 5      # Generate 5 projects"
    echo "  $0 clean  # Clean up test projects"
    exit 1
fi

echo "🎭 Generating $NUM_PROJECTS mock projects..."

# Clean up existing test projects first
clean_projects

# Generate project directories and scripts
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo "📍 Script directory: $SCRIPT_DIR"

for i in $(seq 1 $NUM_PROJECTS); do
    project_name="project-$i"
    project_dir="$SCRIPT_DIR/$project_name"

    echo "📁 Creating $project_name..."
    mkdir -p "$project_dir"

    # Create simple hanging script
    cat > "$project_dir/start.sh" << 'EOF'
#!/bin/bash
echo "Project $i is running..."
sleep 999999
EOF

    # Fix variable interpolation in the script
    sed -i "s/\$i/$i/g" "$project_dir/start.sh"
    chmod +x "$project_dir/start.sh"
done

# Generate JSON configuration using function
echo "📝 Generating configuration JSON..."
generate_json "$NUM_PROJECTS" > "$SCRIPT_DIR/projects_output__test_area.json"

echo "✅ Generated $NUM_PROJECTS mock projects successfully!"
echo "🎯 Use: ./test-area/masquerade.sh enable"