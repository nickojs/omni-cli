# Project Module

This directory contains the refactored project management module, split into logical components for better maintainability.

## Structure

- **`index.sh`** - Main entry point that imports all project modules
- **`display.sh`** - Project display and status formatting
- **`info.sh`** - Project information retrieval functions
- **`status.sh`** - Status checking and counting functions
- **`validation.sh`** - Project configuration validation

## Usage

Instead of sourcing the old `project.sh` file directly, now source the index:

```bash
source modules/project/index.sh
```

## Functions Available

All original functions from `project.sh` are still available:

### Display Functions
- `display_project_status()` - Display project status with colors
- `list_project_statuses()` - List all project statuses with summary

### Information Functions
- `get_project_info()` - Get project info by index
- `find_project_by_name()` - Find project index by display name

### Status Functions
- `validate_project_folder()` - Check if project folder exists
- `count_running_projects()` - Count currently running projects

### Validation Functions
- `validate_project_config()` - Validate project configuration format

## Module Dependencies

The modules are loaded in dependency order:
1. **Validation** → Basic configuration validation
2. **Status** → Status checking and counting
3. **Info** → Information retrieval operations
4. **Display** → Display formatting (depends on status functions)

## Migration

The original `project.sh` has been split into these modules to improve:
- **Maintainability** - Easier to find and modify specific functionality
- **Testing** - Individual components can be tested in isolation
- **Readability** - Logical separation of concerns
- **Extensibility** - New project features can be added as separate modules

## Data Dependencies

These functions depend on the global `projects` array that is managed by the config module.
