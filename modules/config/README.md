# Configuration Module

This directory contains the refactored configuration management module, split into logical components for better maintainability.

## Structure

- **`index.sh`** - Main entry point that imports all config modules
- **`json-parser.sh`** - JSON parsing and data loading functionality
- **`validation.sh`** - Configuration validation functions  
- **`setup.sh`** - Setup wizard and initialization functions
- **`loader.sh`** - Main configuration loading logic

## Usage

Instead of sourcing the old `config.sh` file directly, now source the index:

```bash
source modules/config/index.sh
```

## Functions Available

All original functions from `config.sh` are still available:

- `load_projects_from_json()` - Load projects from JSON config
- `check_and_setup_config()` - Check config and run wizard if needed  
- `load_config()` - Main configuration loading function
- `validate_config()` - Validate configuration format
- `reload_config()` - Reload configuration after changes
- `run_setup_wizard()` - Run the setup wizard

## Migration

The original `config.sh` has been split into these modules to improve:
- **Maintainability** - Easier to find and modify specific functionality
- **Testing** - Individual components can be tested in isolation
- **Readability** - Logical separation of concerns
- **Reusability** - Components can be used independently if needed
