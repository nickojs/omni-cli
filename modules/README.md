# Modules Documentation

This directory contains modular business logic scripts for the FM Manager project, organized by functional domain.

## Module Structure

### 📁 `config.sh`
Configuration and JSON parsing functionality.

**Exports:**
- `projects[]` - Global projects array
- `load_projects_from_json()` - Parse projects from JSON config
- `check_and_setup_config()` - Check config exists, run wizard if needed
- `load_config()` - Main config loading function with user interaction
- `validate_config()` - Validate JSON configuration format

### 🖥️ `tmux.sh`
Tmux session and pane management.

**Exports:**
- `SESSION_NAME` - Global session name constant
- `check_tmux()` - Verify tmux is installed
- `setup_tmux_session()` - Create or attach to session
- `get_project_pane(display_name)` - Get pane ID for project
- `is_project_running(display_name)` - Check if project is running
- `kill_project(display_name)` - Kill specific project pane
- `start_project_in_tmux(name, folder, cmd)` - Start project in new pane
- `list_project_panes()` - List all project panes
- `kill_all_projects()` - Kill all project panes except main
- `attach_session()` - Attach to existing session
- `session_status()` - Get session status info

### 📊 `project.sh`
Project status display and management.

**Exports:**
- `display_project_status(index, name, folder, cmd)` - Show colored project status
- `get_project_info(index)` - Get project details by index
- `validate_project_folder(folder)` - Check if project folder exists
- `count_running_projects()` - Count currently running projects
- `list_project_statuses()` - Show summary of all project statuses
- `find_project_by_name(name)` - Find project index by name
- `validate_project_config(project_line)` - Validate project configuration

### 🎛️ `menu.sh`
Interactive menu system and user input handling.

**Exports:**
- `show_project_menu_tmux()` - Main interactive menu loop
- `handle_menu_choice(choice)` - Process user menu input
- `handle_quit_command()` - Handle quit command
- `handle_refresh_command()` - Handle refresh command
- `handle_kill_command(kill_choice)` - Handle kill commands (k1, k2, etc.)
- `handle_start_command(choice)` - Handle start commands (1, 2, etc.)
- `show_help()` - Display help menu

### 📋 `index.sh`
Main entry point that imports all modules.

**Exports:**
- All functions and variables from above modules
- `modules_loaded()` - Verification function
- `init_modules()` - Module initialization

## Dependencies

The modules have the following dependency relationships:

```
config.sh (no dependencies)
    ↓
tmux.sh (uses config for SESSION_NAME)
    ↓
project.sh (uses tmux functions for status)
    ↓
menu.sh (uses all above modules)
```

## Usage

### Import All Modules (Recommended)
```bash
#!/bin/bash
source "path/to/modules/index.sh"

# Now use any module function
load_config
check_tmux
show_project_menu_tmux
```

### Import Individual Modules
```bash
#!/bin/bash
source "path/to/modules/config.sh"
source "path/to/modules/tmux.sh"

load_projects_from_json
setup_tmux_session
```

### Verify Modules Loaded
```bash
source "modules/index.sh"
modules_loaded
```

## Module Design Principles

1. **Single Responsibility**: Each module handles one functional domain
2. **Clear Dependencies**: Dependencies are explicitly documented and minimal
3. **Testability**: Each module can be tested independently
4. **Reusability**: Functions are designed to be reused across contexts
5. **Error Handling**: Each module handles its own error cases

## Benefits of Modular Approach

1. **Maintainability**: Easy to update specific functionality
2. **Readability**: Code is organized by logical concerns
3. **Testing**: Each module can be unit tested
4. **Reusability**: Modules can be reused in other scripts
5. **Debugging**: Easier to isolate and fix issues
6. **Collaboration**: Multiple developers can work on different modules

## Adding New Modules

To add a new module:

1. Create `modules/your-module.sh`
2. Follow the existing pattern for exports and documentation
3. Add dependency checks if needed
4. Add import to `modules/index.sh`
5. Update this README with module documentation
6. Add verification to `modules_loaded()` function

Example template:
```bash
#!/bin/bash

# ========================================
# Your Module Name
# ========================================
# Brief description of what this module does
# Usage: source modules/your-module.sh

# Check dependencies if needed
# if ! type some_required_function &>/dev/null; then
#     echo "Error: Required dependency not loaded"
#     return 1
# fi

# Your functions here
your_function() {
    # Implementation
    return 0
}
```

## Testing Modules

Each module can be tested independently:

```bash
# Test config module
source styles/index.sh
source modules/config.sh
load_projects_from_json && echo "Config module works!"

# Test tmux module  
source modules/tmux.sh
check_tmux && echo "Tmux module works!"
```
