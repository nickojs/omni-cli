# FM Manager - Modular Architecture

A modular project manager with tmux integration, built using bash modules similar to JavaScript ES6 modules.

## 🏗️ Architecture Overview

The project is organized into two main module systems:

```
fm-manager/
├── startup.sh              # Main entry point
├── config/                 # Configuration directory
│   └── projects_output.json # Project configuration
├── styles/                 # Styling and UI modules
│   ├── index.sh            # Styles entry point
│   ├── colors.sh           # Color definitions
│   ├── animations.sh       # Loading animations
│   ├── ui.sh              # UI components
│   └── README.md          # Styles documentation
└── modules/               # Business logic modules
    ├── index.sh           # Modules entry point
    ├── config.sh          # Configuration management
    ├── tmux.sh           # Tmux session management
    ├── project.sh        # Project status & management
    ├── menu.sh           # Interactive menu system
    ├── wizard.sh         # Project setup wizard
    └── README.md         # Modules documentation
```

## 🎨 Styles Modules

**Purpose**: Handle all visual presentation and terminal styling.

- **colors.sh**: Terminal color codes and text styling
- **animations.sh**: Loading spinners and progress bars
- **ui.sh**: Headers, separators, message functions, and layouts

## 🔧 Business Logic Modules

**Purpose**: Handle application functionality and business rules.

- **config.sh**: JSON parsing and configuration management
- **tmux.sh**: Tmux session and pane operations
- **project.sh**: Project status display and validation
- **menu.sh**: Interactive user interface and input handling

## 🚀 Usage

### Running the Application
```bash
./startup.sh
```

### Module System Benefits

1. **Separation of Concerns**: Styles vs business logic
2. **Maintainability**: Easy to update specific functionality
3. **Reusability**: Import only what you need
4. **Testability**: Test modules independently
5. **Scalability**: Easy to add new modules
6. **Collaboration**: Multiple developers can work on different modules

### Example: Using Individual Modules
```bash
#!/bin/bash

# Import just colors and project management
source "styles/colors.sh"
source "modules/project.sh"

# Use specific functionality
print_color "$BRIGHT_GREEN" "Hello World!"
list_project_statuses
```

### Example: Using Everything
```bash
#!/bin/bash

# Import all styles and modules
source "styles/index.sh"
source "modules/index.sh"

# Full application functionality available
print_header "My App"
load_config
show_project_menu_tmux
```

## 🧪 Module Testing

Test individual modules:
```bash
# Test styles
source styles/index.sh
styles_loaded

# Test modules
source modules/index.sh  
modules_loaded
```

## 📚 Documentation

- [Styles Documentation](styles/README.md) - Complete guide to styling modules
- [Modules Documentation](modules/README.md) - Complete guide to business logic modules

## 🔄 Module Loading Order

The modules are loaded in dependency order:

1. **Styles**: colors → animations → ui
2. **Modules**: config → tmux → project → menu

## 🛠️ Development Guidelines

### Adding New Style Components
1. Add to appropriate styles module or create new one
2. Follow color variable naming conventions
3. Update styles/index.sh to import
4. Document in styles/README.md

### Adding New Business Logic
1. Identify functional domain (config, tmux, project, menu)
2. Add to existing module or create new one
3. Follow dependency hierarchy
4. Update modules/index.sh to import
5. Document in modules/README.md

### Module Design Principles
- **Single Responsibility**: One module, one concern
- **Clear Dependencies**: Explicit and minimal dependencies
- **Error Handling**: Each module handles its own errors
- **Documentation**: Clear function documentation and examples

## 🔍 Debugging

Debug specific modules:
```bash
# Debug config loading
bash -x modules/config.sh

# Debug tmux operations  
bash -x modules/tmux.sh

# Check syntax
bash -n startup.sh
bash -n styles/index.sh
bash -n modules/index.sh
```

This modular architecture makes the FM Manager maintainable, testable, and easy to extend while keeping the main startup.sh file clean and focused.
