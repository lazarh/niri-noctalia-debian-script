# Niri + Noctalia Installation Script

Automated installation script for setting up Niri compositor and Noctalia shell on Debian-based systems.

## Overview

This script provides a complete installation workflow for:
- **Niri**: A scrollable-tiling Wayland compositor
- **Noctalia**: A native Wayland desktop shell (v5) — bars, launcher, lock screen, notifications, wallpaper, and more, built directly on Wayland with no Qt or GTK dependency
- **Noctalia Greeter**: A minimal login greeter for greetd that matches Noctalia Shell's visual language

## Prerequisites

- **Debian 13 (Trixie)** or later (minimal installation recommended)
- Root/sudo access
- Internet connection
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
- Core components (1-4): System dependencies, Niri, Noctalia, Noctalia Greeter
- Upgrade options (U1, U2, U3, UA): Upgrade individual components or all at once
- Optional components (5-15): VS Code, Oh My Zsh, document viewers, office tools, network fixes, GNOME removal, wallpaper changer, wayland-session desktop entry, Yazi file manager, 0xProto Nerd Font, Neovim

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
./install.sh --upgrade noctalia       # Upgrade only Noctalia
./install.sh --upgrade greeter        # Upgrade only Noctalia Greeter
./install.sh --upgrade all            # Upgrade all components (Niri + Noctalia + Greeter)

# Install Noctalia Greeter
./install.sh --install-noctalia-greeter

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
- Build essentials (cmake, ninja-build, gcc, git, curl, meson, etc.)
- Wayland libraries (protocols, client, scanner, EGL)
- Noctalia v5 dependencies (sdbus-c++, pipewire, polkit, pam, pango, cairo, harfbuzz, freetype, fontconfig, xkbcommon, glib, rsvg, curl, qalculate, xml2, webp, epoxy, jemalloc, webp)
- Display info library (libdisplay-info, for Niri)
- Wayland desktop tools (alacritty, fuzzel, waybar, xdg-desktop-portal-gtk, xwayland, nwg-look)
- **Rust toolchain** (installed via rustup if not already present)
- **just** build tool (installed via `cargo install just`, required by Noctalia)

### [2/4] Niri Compositor
Builds and installs the Niri Wayland compositor from source:
- Clones from [YaLTeR/niri](https://github.com/YaLTeR/niri)
- Builds with Cargo in release mode
- Installs binary and session files

### [3/4] Noctalia
Builds and installs Noctalia v5 from source:
- Clones from [noctalia-dev/noctalia](https://github.com/noctalia-dev/noctalia)
- Builds with `just configure release` + `just build release`
- Installs binary and assets via `sudo just install release`
- Verifies installation

### [4/4] Noctalia Greeter
Builds and installs Noctalia Greeter from source — a login greeter for greetd matching Noctalia's visual language:
- Clones from [noctalia-dev/noctalia-greeter](https://github.com/noctalia-dev/noctalia-greeter)
- Builds with `just configure-release` + `just build-release`
- Installs binary and assets via `sudo meson install -C build-release`
- Runs `setup_greeter_system.sh` to configure greetd, create log directories, and write initial greeter config
- greetd service is enabled automatically

### Post-Installation

The Niri step automatically copies `config.kdl` (if present next to the script) to `~/.config/niri/config.kdl`. If Niri was installed and `config.kdl` exists, you'll also be prompted again to apply or skip it.

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
- Uses `noctalia msg wallpaper-set` to change the wallpaper
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
./install.sh --upgrade noctalia       # Rebuilds Noctalia from latest source
./install.sh --upgrade greeter        # Rebuilds Noctalia Greeter from latest source

# Upgrade everything at once
./install.sh --upgrade all            # Updates all components
```

**Note**: When using `--upgrade`, only the specified components are updated. Other installation options are ignored.

## Configuration

### Niri Configuration

Place a `config.kdl` file next to the install script to have it automatically copied to `~/.config/niri/config.kdl` during installation.

The bundled `config.kdl` is pre-configured to start Noctalia automatically and includes keybindings for common actions via Noctalia IPC:

| Keybind | Action |
|---------|--------|
| `Mod+D` | Toggle launcher |
| `Super+Alt+K` | Lock screen |
| `Super+Alt+L` | Lock and suspend |
| `Super+Alt+V` | Show clipboard |

### Noctalia Configuration

Noctalia stores its configuration at `~/.config/noctalia/config.toml`. A starter config with all defaults is available in the [noctalia repository](https://github.com/noctalia-dev/noctalia/blob/main/example.toml).

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
- cmake, ninja-build, build-essential, meson
- pkg-config
- Rust toolchain (via rustup)
- just (via `cargo install just`)

### System Libraries
- libwayland-dev, wayland-protocols, libegl1-mesa-dev
- libwlroots-0.20-dev, libegl-dev, libgles-dev (wlroots compositor libraries, for Noctalia Greeter)
- libsdbus-c++-dev (D-Bus IPC)
- libpipewire-0.3-dev (audio)
- libpolkit-agent-1-dev, libpam0g-dev (authentication)
- libjemalloc-dev (memory allocator)
- libpango1.0-dev, libcairo2-dev, libharfbuzz-dev, libfreetype-dev, libfontconfig1-dev (text/rendering)
- librsvg2-dev, libwebp-dev, libepoxy-dev (images/GL)
- libxkbcommon-dev, libglib2.0-dev (input/platform)
- libcurl4-gnutls-dev, libqalculate-dev, libxml2-dev (network/data)
- libdisplay-info3, libdisplay-info-dev (monitor info, for Niri)

### Wayland Desktop Tools
- alacritty, fuzzel, waybar
- xdg-desktop-portal-gtk, xwayland
- nwg-look (GTK theme switcher)
- swayidle (idle/lock trigger)
- greetd (login greeter daemon, for Noctalia Greeter)

## Troubleshooting

### `just: command not found` during build
The script sources `~/.cargo/env` automatically. If you encounter this outside the script, run:
```bash
source ~/.cargo/env
```

### Noctalia build fails with missing dependency
Run the system dependencies step first (`[1]` in the menu or `./install.sh` default) to ensure all build libraries are installed.

## Repository Structure

```
.
├── install.sh          # Main installation script
├── config.kdl          # Niri configuration (pre-configured for Noctalia)
├── tests/              # Test scripts (bash-based assertions)
│   ├── run_tests.sh
│   ├── test_help_output.sh
│   ├── test_menu_source.sh
│   └── test_greeter_source.sh
└── README.md           # This file
```

## License

This installation script is provided as-is. Individual components (Niri, Noctalia) have their own licenses.

## Credits

- **Niri**: [YaLTeR/niri](https://github.com/YaLTeR/niri)
- **Noctalia**: [noctalia-dev/noctalia](https://github.com/noctalia-dev/noctalia)
- **Noctalia Greeter**: [noctalia-dev/noctalia-greeter](https://github.com/noctalia-dev/noctalia-greeter)
- **Yazi**: [sxyazi/yazi](https://github.com/sxyazi/yazi)

