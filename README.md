# FM Manager

A powerful terminal-based project manager with tmux integration and workspace organization. FM Manager helps you organize, monitor, and manage multiple projects from a single, intuitive interface.

## ✨ Features

- **🚀 Workspace Management**: Organize projects by location or category
- **📱 Tmux Integration**: Seamless tmux session management with smart pane layouts
- **🎨 Beautiful UI**: Rich terminal interface with colors and responsive layouts
- **⚙️ Interactive Settings**: Add, edit, and manage workspaces and projects
- **🔧 Modular Design**: Clean architecture with reusable components
- **📊 Status Monitoring**: Real-time project status tracking
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
   ./rebuild-package.sh
   ```
   Note: This will also install the package in your system.

2. **Run from anywhere:**
    ```bash
    fm-manager
    ```

## 📁 Project Structure

```
fm-manager/
├── startup.sh              # Main entry point
├── config/                 # Configuration files
│   ├── .workspaces.json    # Workspace definitions
│   └── *.json              # Individual workspace configs
├── styles/                 # UI and styling modules
│   ├── index.sh            # Styles entry point
│   ├── colors.sh           # Color definitions
│   ├── animations.sh       # Loading animations
│   └── ui.sh               # UI components
└── modules/                # Core functionality modules
    ├── index.sh            # Modules entry point
    ├── config/             # Configuration management
    ├── tmux/               # Tmux session management
    ├── navigator/          # Filesystem navigation
    ├── menu/               # Interactive menus
    └── settings/           # Settings and workspace management
        ├── workspaces/     # Workspace operations
        └── projects/       # Project operations
```

## ⚙️ Configuration

### Workspace System
The application uses a workspace-based configuration system:
- **`.workspaces.json`**: Defines active workspaces and their locations
- **Workspace configs**: Individual JSON files for each workspace's projects

Configuration storage:
- **Local development**: `./config/`
- **System installation**: `~/.cache/fm-manager/`

## 🔧 Troubleshooting

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

3. **JSON parsing errors:**
   ```bash
   # Install jq if missing
   sudo apt install jq
   ```

## 🧪 Testing

For development testing, use the included test environment:

### Generate Mock Projects
```bash
# Generate 2 folders with 3 projects each (total: 6 projects)
./test-area/mockup.sh 2 3

# Generate 2 folders with 5 projects each (total: 10 projects)
./test-area/mockup.sh 2 5

# Clean up test projects
./test-area/mockup.sh clean
```

### Test with Mock Configuration
```bash
# Switch to test configuration (backs up original configs)
./test-area/masquerade.sh enable

# Run fm-manager to test functionality safely
./startup.sh

# Test starting/stopping projects without affecting real ones

# Restore original configuration
./test-area/masquerade.sh restore
```

The masquerade script safely swaps your configs with generated mock workspaces, backing up the originals. Mock projects are simple processes (`echo + sleep 999999`) perfect for testing without interfering with actual projects.

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
