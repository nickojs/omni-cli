# FM Manager

A powerful terminal-based project manager with tmux integration and modular architecture. FM Manager helps you organize, monitor, and manage multiple projects from a single, intuitive interface.

## ✨ Features

- **🚀 Project Management**: Create, configure, and monitor multiple projects
- **📱 Tmux Integration**: Seamless tmux session management with smart pane layouts
- **🎨 Beautiful UI**: Rich terminal interface with colors, animations, and responsive layouts
- **⚙️ Interactive Setup**: Guided project wizard for easy configuration
- **�🔧 Modular Design**: Clean architecture with reusable components
- **📊 Status Monitoring**: Real-time project status tracking and validation
- **🏠 Flexible Deployment**: Run locally for development or install system-wide

## 📋 Requirements

### System Dependencies
- **bash** (4.0+)
- **tmux** (2.0+)
- **jq** (for JSON processing)
- **git** (optional, for version control integration)

### Platform Support
- Linux (all distributions)
- macOS (with Homebrew)
- WSL2 (Windows Subsystem for Linux)

## 🚀 Quick Start

### Option 1: Run Locally (Development)

1. **Clone and setup:**
   ```bash
   git clone <repository-url>
   cd fm-manager
   chmod +x startup.sh
   ```

2. **Install dependencies:**
   ```bash
   # Ubuntu/Debian
   sudo apt update && sudo apt install bash tmux jq

   # Arch Linux
   sudo pacman -S bash tmux jq

   # macOS
   brew install bash tmux jq
   ```

3. **Run the application:**
   ```bash
   ./startup.sh
   ```

4. **Test individual modules:**
    ```bash
        # Test styles
        source styles/index.sh && styles_loaded

        # Test core modules
        source modules/index.sh && modules_loaded
    ```

### Option 2: System Installation (Production)

1. **Build the package:**
   ```bash
   cd build/
   ./rebuild.package.sh
   ```
   Note: this will also install the package in your system.

2. **Run from anywhere:**
    ```bash
    fm-manager
    ```
    Note: It's a good idea to run this in your root folder where other Projects are installed.

## 📁 Project Structure

```
fm-manager/
├── startup.sh              # Main entry point
├── .env                    # Environment configuration
├── config/                 # Configuration files
│   └── projects_output.json # Project definitions
├── styles/                 # UI and styling modules
│   ├── index.sh            # Styles entry point
│   ├── colors.sh           # Color definitions
│   ├── animations.sh       # Loading animations
│   └── ui.sh              # UI components
└── modules/               # Core functionality modules
    ├── index.sh           # Modules entry point
    ├── config.sh          # Configuration management
    ├── tmux.sh           # Tmux session management
    ├── project.sh        # Project operations
    ├── menu.sh           # Interactive menus
    └── wizard.sh         # Setup wizard
```

## ⚙️ Configuration

### Environment Variables (.env)
```bash
SESSION_NAME=fm-session
JSON_CONFIG_FILE=projects_output.json
```

### Project Configuration (projects_output.json)
The application automatically creates and manages project configurations through the interactive wizard. Projects are stored in:
- **Local development**: `./config/projects_output.json`
- **System installation**: `~/.cache/fm-manager/projects_output.json`


## � Troubleshooting

### Common Issues

1. **Tmux not found:**
   ```bash
   # Install tmux
   sudo apt install tmux  # Ubuntu/Debian
   sudo pacman -S tmux    # Arch Linux
   brew install tmux      # macOS
   ```

2. **Permission denied:**
   ```bash
   chmod +x startup.sh
   ```
   You may need to chmod other scripts as well. *Do your jumps.*

3. **JSON parsing errors:**
   ```bash
   # Install jq if missing
   sudo apt install jq
   ```

## 🧪 Testing

For development testing, use the included test environment:

### Generate Mock Projects
```bash
# Generate 5 test projects (default: 3)
./test-area/mockup.sh 5

# Clean up test projects with confirmation
./test-area/mockup.sh clean
```

### Test with Mock Configuration
```bash
# Switch to test configuration (backs up original, replaces with mock projects)
./test-area/masquerade.sh enable

# Run fm-manager to test functionality safely
./startup.sh

# Test starting/stopping projects without affecting real ones

# Restore original configuration (restores backup)
./test-area/masquerade.sh restore
```

The masquerade script safely swaps your `config/projects_output.json` with the generated mock configuration, backing up the original. Mock projects are simple hanging processes (`echo + sleep 999999`) perfect for testing process management, kill functionality, and UI behavior without interfering with actual projects.

## 📚 Documentation

- [Styles Documentation](styles/README.md) - Complete styling guide
- [Modules Documentation](modules/README.md) - Core functionality guide
- [Testing Guide](modules/test/) - Testing and validation

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Follow the modular architecture principles
4. Add tests for new functionality
5. Submit a pull request

### Development Guidelines

- **Single Responsibility**: One module, one purpose
- **Clear Dependencies**: Explicit and minimal
- **Error Handling**: Graceful failure handling
- **Documentation**: Clear function documentation

## 📓 License

This project is licensed under the NIC License.

## 🎉 Credits

Built with ❤️ using claude sonnet 4, thank god.
