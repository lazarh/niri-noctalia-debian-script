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

Run the script to install all components automatically:

```bash
chmod +x install.sh
./install.sh
```

### Interactive Mode

Use the `--ask-step` flag to get prompted before each installation step:

```bash
./install.sh --ask-step
```

This allows you to skip specific components if already installed or not needed.

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
