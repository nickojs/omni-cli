# Settings Module

This module provides settings and configuration management functionality for the FM Manager project.

## Files

- **index.sh** - Main entry point, loads all settings module components
- **display.sh** - Settings menu display and UI
- **commands.sh** - Command handling for settings menu navigation
- **config-display.sh** - Configuration display in human-readable format

## Features

### Current Features
- **List Configuration** - Display current project configuration in human-readable format
- Settings menu navigation with help system
- Fallback support for systems without `jq` installed

### Planned Features
- Edit existing project configurations
- Add new projects to configuration
- Remove projects from configuration
- Reset configuration to defaults
- Backup and restore configurations

## Usage

The settings module is accessed through the main menu by pressing `s`. This opens a sub-menu with various configuration management options.

### Settings Menu Options

1. **List current configuration** - Shows all configured projects with their details
2. **Edit configuration** *(coming soon)* - Modify existing project settings
3. **Reset configuration** *(coming soon)* - Reset all configurations

### Navigation Commands

- `b` - Go back to main menu
- `h` - Show help
- `q` - Quit application

## Dependencies

- **Optional**: `jq` for enhanced JSON parsing and formatting
- **Required**: Basic bash utilities (cat, read, etc.)

## Implementation Notes

- Uses `jq` when available for better JSON parsing and display formatting
- Falls back to raw JSON display when `jq` is not installed
- Integrates with existing color and styling system
- Follows the same patterns as other modules for consistency
