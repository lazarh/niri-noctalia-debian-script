# Niri + Quickshell + Noctalia Installation Script

Automated installation script for setting up Niri compositor, Quickshell, and Noctalia shell on Debian-based systems.

## Overview

This script provides a complete installation workflow for:
- **Niri**: A scrollable-tiling Wayland compositor
- **Quickshell**: A QtQuick-based Wayland shell toolkit
- **Noctalia**: A desktop shell for Quickshell

## Prerequisites

- **Debian 13 (Trixie)** or **Debian Forky** (minimal installation recommended)
- Root/sudo access
- Internet connection
- **At least 16GB of free space in /tmp** (required for Quickshell build)
  - The Quickshell compilation process requires significant temporary space
  - If /tmp has less than 16GB, the build will likely fail with out-of-space errors
  - You can check available space with: `df -h /tmp`
- **Minimal Debian installation without graphical environment** (recommended)
  - This script is designed to run on a fresh, minimal Debian installation
  - It will install all necessary components to create a complete Wayland desktop environment
  - If you have an existing desktop environment (GNOME, KDE, etc.), you may want to remove it first using `--remove-gnome` or manually

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
- Core components (1-4): System dependencies, Niri, Quickshell, Noctalia
- Upgrade options (U1-UA): Upgrade individual components or all at once
- Optional components (5-13): VS Code, Oh My Zsh, document viewers, office tools, network fixes, GNOME removal, wallpaper changer, wayland-session desktop entry, Yazi file manager

### Interactive Mode

Use the `--ask-step` flag to get prompted before each installation step:

```bash
./install.sh --ask-step
```

This allows you to skip specific components if already installed or not needed.

### Command-Line Options

Install specific optional components directly:

```bash
# Upgrade components
./install.sh --upgrade niri           # Upgrade only Niri
./install.sh --upgrade quickshell     # Upgrade only Quickshell
./install.sh --upgrade noctalia       # Upgrade only Noctalia configuration
./install.sh --upgrade all            # Upgrade all components

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

# Install random wallpaper changer (systemd timer)
./install.sh --install-wallpaper

# Install wayland-session desktop entry for display managers (NOT installed by default)
./install.sh --install-desktop-entry

# Install Yazi terminal file manager (builds from source)
./install.sh --install-yazi

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

### [1/4] System Dependencies
Installs all required build tools and libraries:
- Build essentials (cmake, ninja-build, clang, libclang-dev, gcc, git, curl, etc.)
- Qt6 development packages (base, declarative, wayland with private headers, gtk platform theme)
- Wayland libraries (protocols, client, scanner)
- Graphics libraries (libdrm, libgbm, EGL)
- Additional dependencies (PAM, polkit, jemalloc, CLI11, libseat, libpipewire, libpango, libdisplay-info)
- Wayland desktop tools (alacritty, fuzzel, waybar, xdg-desktop-portal-gtk, xwayland, nwg-look)
- **Rust toolchain** (installed via rustup if not already present)



### [2/4] Niri Compositor
Builds and installs the Niri Wayland compositor from source:
- Clones from the official repository
- Builds with Cargo in release mode
- Installs binary and session files

### [3/4] Quickshell
Builds and installs Quickshell from source:
- Clones from official repository
- Builds with CMake/Ninja
- Crash handler disabled (no google-breakpad dependency)
- Verifies installation

### [4/4] Noctalia Shell Configuration
Clones the Noctalia shell configuration to `~/.config/quickshell/noctalia-shell`.

### Post-Installation

The Noctalia step automatically copies `config.kdl` (if present next to the script) to `~/.config/niri/config.kdl`. If Niri was installed and `config.kdl` exists, you'll also be prompted again to apply or skip it.

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

### Random Wallpaper Changer (`--install-wallpaper`)
- Creates a script at `~/.local/bin/noctalia-random-wallpaper.sh`
- Sets up systemd service and timer files
- Automatically rotates wallpaper every 30 minutes
- Uses Noctalia IPC to change wallpaper
- Timer starts on boot and runs continuously

### Wayland Session Desktop Entry (`--install-desktop-entry`)
- **NOT installed by default** - must be explicitly requested
- Creates `/usr/share/wayland-sessions/niri.desktop`
- Allows selecting Niri from display manager login screen (GDM, SDDM, LightDM, etc.)
- Useful if you have an existing graphical environment and want to add Niri as a session option
- Not needed for minimal installations that boot directly to console

### Yazi Terminal File Manager (`--install-yazi`)
- Installs apt prerequisites: `ffmpeg`, `7zip`, `jq`, `poppler-utils`, `fd-find`, `ripgrep`, `fzf`, `zoxide`, `imagemagick`
- Clones [sxyazi/yazi](https://github.com/sxyazi/yazi) and builds from source with Cargo
- Installs `yazi` and `ya` binaries to `/usr/local/bin/`
- Requires Rust toolchain (install core components first, or have Rust already)

### Remove GNOME/GDM3 (`--remove-gnome`)
- **WARNING**: This removes your desktop environment
- Stops GDM3 service
- Purges GNOME packages (gnome-core, gnome-shell, gdm3, etc.)
- Runs autoremove to clean up dependencies
- Sets system to boot to multi-user target (console mode)
- Requires typing "yes" to confirm

## Upgrading Components

The script includes an upgrade mode to update already-installed components:

```bash
# Upgrade individual components
./install.sh --upgrade niri           # Rebuilds Niri from latest source
./install.sh --upgrade quickshell     # Rebuilds Quickshell from latest source
./install.sh --upgrade noctalia       # Pulls latest Noctalia configuration

# Upgrade everything at once
./install.sh --upgrade all            # Updates all three components
```

**Note**: When using `--upgrade`, only the specified components are updated. Other installation options are ignored.

## Configuration

### Niri Configuration

Place a `config.kdl` file next to the install script to have it automatically copied to `~/.config/niri/config.kdl` during installation.

## Starting Niri

After installation completes, you have two options:

### Option 1: Start from Console (Default)
```bash
niri
```

### Option 2: Select from Display Manager
If you have a display manager (GDM, SDDM, LightDM, etc.) and want to select Niri from the login screen:

1. Install the wayland-session desktop entry:
   ```bash
   ./install.sh --install-desktop-entry
   ```

2. Log out and select "Niri" from the session menu at your login screen

**Note**: The desktop entry is **not installed by default**. It's only needed if you're using a display manager and want Niri as a selectable session option.

## Dependencies Installed

### Build Tools
- cmake, ninja-build, build-essential
- clang, libclang-dev (required by bindgen for FFI binding generation)
- pkg-config, spirv-tools
- Rust toolchain (via rustup)

### Qt6 Packages
- qt6-base-dev, qt6-base-private-dev
- qt6-declarative-dev, qt6-declarative-private-dev
- qt6-wayland-dev, qt6-wayland-private-dev
- qt6-shadertools-dev
- qt6-gtk-platformtheme

### System Libraries
- libwayland-dev, wayland-protocols
- libdrm-dev, libgbm-dev, libegl1-mesa-dev
- libpolkit-agent-1-dev
- libpam0g-dev
- libjemalloc-dev
- libcli11-dev
- libseat-dev
- libpipewire-0.3-dev
- libpango1.0-dev
- libdisplay-info3, libdisplay-info-dev (downloaded from Debian repos)

### Wayland Desktop Tools
- alacritty, fuzzel, waybar
- xdg-desktop-portal-gtk, xwayland
- nwg-look (GTK theme switcher)

## Troubleshooting

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
- **Noctalia**: [noctalia-dev/noctalia-shell](https://github.com/noctalia-dev/noctalia-shell)
- **Yazi**: [sxyazi/yazi](https://github.com/sxyazi/yazi)

