# Styles Module Documentation

This directory contains modular styling scripts for the FM Manager project, organized similar to JavaScript ES6 modules.

## Module Structure

### 📁 `colors.sh`
Contains all color definitions and the base `print_color()` function.

**Exports:**
- Basic colors: `RED`, `GREEN`, `YELLOW`, `BLUE`, `PURPLE`, `CYAN`, `WHITE`
- Text styling: `BOLD`, `DIM`, `UNDERLINE`, `BLINK`, `REVERSE`, `NC`
- Bright colors: `BRIGHT_RED`, `BRIGHT_GREEN`, etc.
- Background colors: `BG_RED`, `BG_GREEN`, etc.
- Function: `print_color()`

### 🎬 `animations.sh`
Provides loading animations and visual effects.

**Exports:**
- `show_loading(message, duration)` - Spinning loader with dots
- `show_spinner(message, duration)` - Simple character spinner
- `show_progress(message, steps, duration)` - Progress bar animation

### 🎨 `ui.sh`
UI components like headers, separators, and message functions.

**Exports:**
- `print_header(title)` - Fancy bordered header
- `print_separator(char, color)` - Horizontal separator line
- `print_success(message)` - Success message with green styling
- `print_error(message)` - Error message with red styling
- `print_warning(message)` - Warning message with yellow styling
- `print_info(message)` - Info message with blue styling
- `print_box(title, width, border_char, top_char)` - Text in a box
- `print_divider(text)` - Divider with centered text

### 📋 `index.sh`
Main entry point that imports all modules.

**Exports:**
- All functions and variables from above modules
- `styles_loaded()` - Verification function

## Usage

### Import All Styles (Recommended)
```bash
#!/bin/bash
source "path/to/styles/index.sh"

# Now use any styling function
print_header "My App"
show_loading "Starting up" 2
print_success "Ready!"
```

### Import Individual Modules
```bash
#!/bin/bash
source "path/to/styles/colors.sh"
source "path/to/styles/ui.sh"

print_color "$BRIGHT_GREEN" "Hello World!"
print_header "Just UI and Colors"
```

### Verify Styles Loaded
```bash
source "styles/index.sh"
styles_loaded
```

## Benefits of Modular Approach

1. **Separation of Concerns**: Each module has a specific responsibility
2. **Reusability**: Import only what you need
3. **Maintainability**: Easy to update specific styling aspects
4. **Scalability**: Easy to add new styling modules
5. **Testing**: Each module can be tested independently

## Adding New Modules

To add a new styling module:

1. Create `styles/your-module.sh`
2. Follow the pattern of checking for dependencies
3. Export functions and variables
4. Add import to `styles/index.sh`
5. Document in this README

Example template:
```bash
#!/bin/bash
# Ensure dependencies are available
if [[ -z "$BRIGHT_BLUE" ]]; then
    source "$(dirname "${BASH_SOURCE[0]}")/colors.sh"
fi

# Your functions here
my_custom_function() {
    echo -e "${BRIGHT_BLUE}Custom styling${NC}"
}
```
