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
- Arch Linux btw
- for macOS, windows, and other OS I recommend praying

## 🚀 Quick Start

### Run Locally

1. **Clone and setup:**
   ```bash
   git clone <repository-url>
   cd fm-manager
   chmod +x startup.sh
   ```

2. **Install dependencies:**
   ```bash
   # Arch Linux
   sudo pacman -S bash tmux jq
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

## 📁 Project Structure

```
fm-manager/
├── startup.sh          # Entry point
├── config/             # Workspace configs (.json)
├── styles/             # UI, colors, animations
└── modules/            
    ├── config/         # Config file management
    ├── tmux/           # Tmux configuration
    ├── navigator/      # Filesystem navigation
    ├── menu/           # Interactive menus
    └── settings/       # Workspace & project configuration
```

```mermaid
flowchart TB
    subgraph MAIN["Main Screen (Project Manager)"]
        TABLE["Table: Workspaces & Projects<br/>(with IDs, based on settings)"]
        RUN["Run Project"]
        STOP["Stop Project"]
        CUSTOM["Custom Command<br/>(opens panel in project folder)"]
        TABLE --> RUN
        TABLE --> STOP
        TABLE --> CUSTOM
    end

    subgraph TMUX["Tmux Navigation"]
        WALK["Walk through<br/>projects panel"]
    end

    subgraph SETTINGS["Settings Menu"]
        MW["Manage Workspace"]
        AW["Add Workspace"]
        TW["Toggle Workspace<br/>(show/hide in main)"]
    end

    subgraph ADD_WS_FLOW["Add Workspace"]
        NAV["Filesystem Navigator"]
        SELECT["Select folder"]
        NAV --> SELECT
    end

    subgraph MANAGE_WS["Manage Workspace"]
        ADD_PROJ["Add Project"]
        EDIT_PROJ["Edit Project"]
        REMOVE_PROJ["Remove Project"]
        REMOVE_WS["Remove Workspace<br/>(if no projects)"]
    end

    subgraph ADD_PROJ_FLOW["Add Project"]
        LIST_PROJS["List workspace's<br/>available projects"]
        CONFIG_PROJ["Configure project"]
        LIST_PROJS --> CONFIG_PROJ
    end

    MAIN <--> SETTINGS
    MAIN -.-> TMUX
    MW --> MANAGE_WS
    AW --> ADD_WS_FLOW
    ADD_PROJ --> ADD_PROJ_FLOW

    %% Styling
    classDef mainScreen fill:#4a9eff,stroke:#2670c2,color:#fff
    classDef settings fill:#ff9f43,stroke:#c77a2e,color:#fff
    classDef manage fill:#26de81,stroke:#1b9e5c,color:#fff
    classDef tmux fill:#a55eea,stroke:#7c3aab,color:#fff
    classDef addWsFlow fill:#45aaf2,stroke:#2d8ed9,color:#fff
    classDef addProjFlow fill:#a55eea,stroke:#7c3aab,color:#fff
    
    class TABLE,RUN,STOP,CUSTOM mainScreen
    class MW,AW,TW settings
    class ADD_PROJ,EDIT_PROJ,REMOVE_PROJ,REMOVE_WS manage
    class WALK tmux
    class NAV,SELECT addWsFlow
    class LIST_PROJS,CONFIG_PROJ addProjFlow
```

## ⚙️ Configuration

### Workspace System
The application uses a workspace-based configuration system:
- **`.workspaces.json`**: Defines active workspaces and their locations
- **Workspace configs**: Individual JSON files for each workspace's projects

Configuration storage:
- **Local development**: `./config/`
- **System installation**: `~/.cache/fm-manager/`

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

1. Clone this and open a Pull Request with a proper branch.
2. Follow the modular architecture principles

### Development Guidelines

- **Single Responsibility**: One module, one purpose
- **Clear Dependencies**: Explicit and minimal
- **Error Handling**: Graceful failure handling
- **Documentation**: Clear function documentation

## 📓 License

This project is licensed under the NIC License.

## 🎉 Credits

Built with ❤️ using claude code CLI, thank god.
