# Tmux Module

This directory contains the refactored tmux management module, split into logical components for better maintainability.

## Structure

- **`index.sh`** - Main entry point that imports all tmux modules
- **`utils.sh`** - Utility functions (check tmux availability)
- **`session.sh`** - Session management (create, attach, status)
- **`pane.sh`** - Pane management (create, kill, list)
- **`project.sh`** - Project-specific tmux operations

## Usage

Instead of sourcing the old `tmux.sh` file directly, now source the index:

```bash
source modules/tmux/index.sh
```

## Functions Available

All original functions from `tmux.sh` are still available:

### Utility Functions
- `check_tmux()` - Check if tmux is installed and available

### Session Management
- `setup_tmux_session()` - Create or attach to tmux session
- `attach_session()` - Attach to existing session
- `session_status()` - Check session status and pane count

### Pane Management
- `get_project_pane()` - Get pane ID for a specific project
- `kill_project()` - Kill a specific project pane
- `list_project_panes()` - List all project panes
- `kill_all_projects()` - Kill all project panes (except main menu)

### Project Operations
- `is_project_running()` - Check if a project is currently running
- `start_project_in_tmux()` - Start a project in a new tmux pane

## Module Dependencies

The modules are loaded in dependency order:
1. **Utils** → Basic tmux availability check
2. **Session** → Session lifecycle management
3. **Pane** → Pane management operations
4. **Project** → High-level project operations (depends on pane functions)

## Migration

The original `tmux.sh` has been split into these modules to improve:
- **Maintainability** - Easier to find and modify specific functionality
- **Testing** - Individual components can be tested in isolation
- **Readability** - Logical separation of concerns
- **Extensibility** - New tmux features can be added as separate modules

## Global Variables

- `SESSION_NAME` - The tmux session name (defaults to "fm-session")
