# Niri + Quickshell + Noctalia Installation Script

Automated installation script for setting up Niri compositor, Quickshell, and Noctalia shell on Debian 13.

## Overview

This script provides a complete installation workflow for:
- **Niri**: A scrollable-tiling Wayland compositor
- **Quickshell**: A QtQuick-based Wayland shell toolkit
- **Noctalia**: A desktop shell for Quickshell

## Prerequisites

- Debian 13 (Trixie)
- Root/sudo access
- Internet connection

## Usage

### Basic Installation

Run the script to install all core components automatically:

```bash
chmod +x install.sh
./install.sh
```

### Interactive Menu

Use the `--menu` flag to select which components to install:

```bash
./install.sh --menu
```

This shows an interactive menu where you can choose:
- Core components (1-5): System dependencies, Pacstall, Niri, Quickshell, Noctalia
- Optional components (6-11): VS Code, Oh My Zsh, document viewers, office tools, network fixes, GNOME removal

### Interactive Mode

Use the `--ask-step` flag to get prompted before each installation step:

```bash
./install.sh --ask-step
```

This allows you to skip specific components if already installed or not needed.

### Command-Line Options

Install specific optional components directly:

```bash
# Install VS Code with Wayland support
./install.sh --install-vscode

# Install Oh My Zsh
./install.sh --install-omz

# Install document viewers (zathura, loupe)
./install.sh --install-docs

# Install office tools (patat, gnumeric, abiword)
./install.sh --install-office

# Apply network & hardware fixes
./install.sh --apply-fixes

# Remove GNOME/GDM3 (WARNING: removes desktop environment)
./install.sh --remove-gnome

# Combine multiple options
./install.sh --install-vscode --install-omz --apply-fixes
```

For a full list of options, run:

```bash
./install.sh --help
```

## Installation Steps

The script performs the following steps:

### [1/5] System Dependencies
Installs all required build tools and libraries:
- Build essentials (cmake, ninja-build, gcc, etc.)
- Qt6 development packages (base, declarative, wayland with private headers)
- Wayland libraries (protocols, client, scanner)
- Graphics libraries (libdrm, libgbm, EGL)
- Additional dependencies (PAM, polkit, jemalloc, CLI11)
- GitHub CLI (gh)

**Post-install actions:**
- Prompts for system reboot (due to systemd-resolved)
- Checks GitHub authentication status and offers login

### [2/5] Pacstall Package Manager
Installs Pacstall, a community-driven package manager for Debian.

### [3/5] Niri Compositor
Installs the Niri Wayland compositor via Pacstall.

### [4/5] Quickshell
Builds and installs Quickshell from source:
- Clones from official repository
- Builds with CMake/Ninja
- Crash handler disabled (no google-breakpad dependency)
- Verifies installation

### [5/5] Noctalia Shell Configuration
Clones the Noctalia shell configuration to `~/.config/quickshell/noctalia-shell`.

### Post-Installation

If a `config.kdl` file exists in the same directory as the script, you'll be prompted to apply it as the Niri configuration.

## Optional Components

### Visual Studio Code (`--install-vscode`)
- Adds Microsoft apt repository
- Installs VS Code
- Configures Wayland support via desktop file modification
- Adds shell alias for Wayland flag

### Oh My Zsh (`--install-omz`)
- Installs zsh package
- Offers to change default shell to zsh
- Installs Oh My Zsh framework

### Document Viewers (`--install-docs`)
- Installs zathura (PDF viewer)
- Installs zathura-pdf-poppler (PDF backend)
- Installs loupe (image viewer)

### Office Tools (`--install-office`)
- Installs patat (terminal-based presentation tool)
- Installs gnumeric (spreadsheet application)
- Installs abiword (word processor)

### Network & Hardware Fixes (`--apply-fixes`)
- Installs NetworkManager, bluez, brightnessctl, upower
- Installs pipewire audio libraries
- Installs firmware packages (iwlwifi, realtek, etc.)
- Installs wlsunset (screen color temperature)
- Installs nwg-look (GTK theme switcher)
- Adds user to netdev, bluetooth, and video groups
- Updates NetworkManager configuration to managed mode
- Comments out wlan0 entries in `/etc/network/interfaces`
- Backs up configuration files before modifying

### Remove GNOME/GDM3 (`--remove-gnome`)
- **WARNING**: This removes your desktop environment
- Stops GDM3 service
- Purges GNOME packages (gnome-core, gnome-shell, gdm3, etc.)
- Runs autoremove to clean up dependencies
- Sets system to boot to multi-user target (console mode)
- Requires typing "yes" to confirm

## Configuration

### Niri Configuration

Place a `config.kdl` file next to the install script to have it automatically copied to `~/.config/niri/config.kdl` during installation.

### GitHub Authentication

The script checks if GitHub CLI is authenticated. This is useful for:
- Cloning private repositories
- Avoiding rate limits
- Contributing to projects

If not authenticated, you'll be prompted to run `gh auth login`.

## Starting Niri

After installation completes, you can start Niri with:

```bash
niri
```

Or add it as a session option in your display manager.

## Dependencies Installed

### Build Tools
- cmake, ninja-build, build-essential
- pkg-config, spirv-tools

### Qt6 Packages
- qt6-base-dev, qt6-base-private-dev
- qt6-declarative-dev, qt6-declarative-private-dev
- qt6-wayland-dev, qt6-wayland-private-dev
- qt6-shadertools-dev

### System Libraries
- libwayland-dev, wayland-protocols
- libdrm-dev, libgbm-dev, libegl1-mesa-dev
- libpolkit-agent-1-dev
- libpam0g-dev
- libjemalloc-dev
- libcli11-dev

### Utilities
- gh (GitHub CLI)
- systemd-resolved

## Troubleshooting

### Reboot Required
If you experience DNS resolution issues after installation, reboot your system to properly initialize systemd-resolved.

### GitHub Authentication
If you skip GitHub authentication and later need it:
```bash
gh auth login
```

### Build Failures
If Quickshell build fails due to missing dependencies, ensure all Qt6 private development packages are installed:
```bash
sudo apt install qt6-base-private-dev qt6-declarative-private-dev qt6-wayland-private-dev
```

### Quickshell Not Found
After installation, if `quickshell` is not found, ensure the installation directory is in your PATH, or log out and back in.

## Repository Structure

```
.
├── install.sh          # Main installation script
├── config.kdl          # Optional Niri configuration
└── README.md           # This file
```

## License

This installation script is provided as-is. Individual components (Niri, Quickshell, Noctalia) have their own licenses.

## Credits

- **Niri**: [YaLTeR/niri](https://github.com/YaLTeR/niri)
- **Quickshell**: [outfoxxed/quickshell](https://git.outfoxxed.me/quickshell/quickshell)
- **Noctalia**: [outfoxxed/noctalia-shell](https://github.com/outfoxxed/noctalia-shell)

