# Menu Module

This directory contains the refactored menu management module, split into logical components for better maintainability.

## Structure

- **`index.sh`** - Main entry point that imports all menu modules
- **`display.sh`** - Menu display and UI functionality
- **`commands.sh`** - Command routing and processing
- **`actions.sh`** - Action handlers (start, kill, quit, refresh, etc.)
- **`wizard.sh`** - Wizard-related menu functions

## Usage

Instead of sourcing the old `menu.sh` file directly, now source the index:

```bash
source modules/menu/index.sh
```

## Functions Available

All original functions from `menu.sh` are still available:

### Display Functions
- `show_project_menu_tmux()` - Main interactive menu loop
- `show_help()` - Display help menu

### Command Processing
- `handle_menu_choice()` - Route and process user input

### Action Handlers
- `handle_start_command()` - Start a project
- `handle_kill_command()` - Kill a running project
- `handle_quit_command()` - Quit the application
- `handle_refresh_command()` - Refresh project status

### Wizard Functions
- `handle_wizard_command()` - Re-run setup wizard

## Menu Flow

1. **Display** → Shows the interactive menu with project list and commands
2. **Commands** → Processes user input and routes to appropriate handlers
3. **Actions** → Executes the requested action (start, kill, etc.)
4. **Wizard** → Handles configuration management through wizard

## Migration

The original `menu.sh` has been split into these modules to improve:
- **Maintainability** - Easier to find and modify specific functionality
- **Testing** - Individual components can be tested in isolation
- **Readability** - Logical separation of concerns
- **Extensibility** - New menu features can be added as separate modules
