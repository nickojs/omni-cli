# Modules Documentation

This directory contains modular business logic scripts for the FM Manager project, organized by functional domain.

## Module Structure

### 📁 `config/` (Sub-module Package)
Configuration and JSON parsing functionality, split into focused sub-modules.

**Sub-modules:**
- `index.sh` - Main entry point and module loader
- `json-parser.sh` - JSON parsing and validation utilities
- `loader.sh` - Configuration loading and user interaction
- `setup.sh` - Setup orchestration and wizard invocation
- `validation.sh` - Configuration validation logic

### 🖥️ `tmux/` (Sub-module Package)
Tmux session and pane management, organized into logical sub-modules.

**Sub-modules:**
- `index.sh` - Main entry point and module loader
- `session.sh` - Session creation and management
- `pane.sh` - Pane operations and utilities
- `project.sh` - Project-specific tmux operations
- `utils.sh` - Utility functions for tmux operations

### 📊 `project/` (Sub-module Package)
Project status display and management functionality.

**Sub-modules:**
- `index.sh` - Main entry point and module loader
- `display.sh` - Project status display and formatting
- `info.sh` - Project information retrieval
- `status.sh` - Project status checking and monitoring
- `validation.sh` - Project configuration validation

### 🎛️ `menu/` (Sub-module Package)
Interactive menu system and user input handling.

**Sub-modules:**
- `index.sh` - Main entry point and module loader
- `display.sh` - Menu display and formatting
- `actions.sh` - Menu action handlers
- `commands.sh` - Command processing and validation
- `wizard.sh` - Menu-integrated wizard functionality

### 🧙‍♂️ `wizard.sh` (Monolithic Module)
Complete project setup wizard functionality in a single file.
Dev note: Too delicate to split into minor files. Trust me, I've tried.


## Adding New Modules

### Adding a module
1. Create `modules/domain-name/` directory
2. Create `modules/domain-name/index.sh` as entry point
3. Create individual `.sh` files for specific functionality
4. Follow the existing pattern for exports and documentation
5. Add import to main `modules/index.sh`
6. Update this README with module documentation
7. Add verification to `modules_loaded()` function
