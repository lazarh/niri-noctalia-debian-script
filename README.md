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
- `x86_64` or `arm64` (architecture-aware steps pick the matching packages; the
  Neovim tarball is only published for these two)
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

With no arguments the script installs the four core components: system
dependencies, Niri, Noctalia and Noctalia Greeter.

### Selecting Components

Passing **any** `--install-*`, `--remove-gnome`, `--apply-fixes` or `--upgrade`
flag switches off the "install everything core" default, so the script installs
only what you asked for:

```bash
./install.sh --install-vscode               # only VS Code, nothing from the core set
./install.sh --apply-fixes                  # only the network/hardware fixes
./install.sh --install-font --install-nvim   # only these two
```

`--ask-step` is orthogonal: it can be combined with the default (all core
components, each behind a prompt) or with individual flags.

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
It can be combined with the default (all four core components, each behind a
prompt) or with individual `--install-*` flags.

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

# Install 0xProto Nerd Font and apply it to alacritty
./install.sh --install-font

# Install Neovim with lazy.nvim and oil.nvim
./install.sh --install-nvim

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
- Display info library (libdisplay-info, for Niri) — taken from apt when the
  release carries a new enough version, otherwise the newest `.deb` is fetched
  from the Debian pool for the detected architecture
- Wayland desktop tools (alacritty, fuzzel, waybar, xdg-desktop-portal-gtk, xwayland, nwg-look)
- Supporting tools used by later steps (`wget`, `python3`)
- **Rust toolchain** (installed via rustup if not already present)
- **just** build tool (installed via `cargo install just`, required by Noctalia;
  skipped when `just` is already on `PATH`)

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

After the core steps finish you are asked whether to apply `config.kdl` (from
next to the script) to `~/.config/niri/config.kdl`. An existing `config.kdl` is
copied to `config.kdl.backup` before being replaced, so declining the prompt
leaves your setup untouched.

### Temporary build directories

Every build happens in a `mktemp -d` directory. All of them are registered with
an `EXIT` trap, so they are removed when the script finishes — including when a
build fails or you press Ctrl-C. Nothing is left behind in `/tmp`, and the
script always returns you to the directory you started it from.

## Optional Components

### Visual Studio Code (`--install-vscode`)
- Adds Microsoft apt repository
- Installs VS Code
- Configures Wayland support via desktop file modification (warns instead of
  failing if the desktop entry cannot be found)
- Adds shell alias for Wayland flag
- The repository signing key is written to a temp file, never into the checkout

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
- Adds the invoking user (honouring `$SUDO_USER`) to netdev, bluetooth, and video groups
- Updates NetworkManager configuration to managed mode
- Comments out wlan0 entries in `/etc/network/interfaces` — only active stanzas,
  so re-running never stacks comments on an already-commented line
- Backs up configuration files before modifying

### Random Wallpaper Changer (`--install-wallpaper`)
- Creates a script at `~/.local/bin/noctalia-random-wallpaper.sh`
- Sets up systemd service and timer files
- Automatically rotates wallpaper every 30 minutes
- Uses `noctalia msg wallpaper-set` to change the wallpaper
- Timer starts on boot and runs continuously
- Safe to re-run: the three files are simply rewritten

### Wayland Session Desktop Entry (`--install-desktop-entry`)
- **NOT installed by default** - must be explicitly requested
- Creates `/usr/share/wayland-sessions/niri.desktop` (creating the directory if
  a minimal install does not have it yet)
- Points `Exec` at the absolute `/usr/local/bin/niri`, since display managers do
  not always run sessions through a login `PATH`
- Allows selecting Niri from display manager login screen (GDM, SDDM, LightDM, etc.)
- Useful if you have an existing graphical environment and want to add Niri as a session option
- Not needed for minimal installations that boot directly to console

### Yazi Terminal File Manager (`--install-yazi`)
- Installs apt prerequisites: `ffmpeg`, `jq`, `poppler-utils`, `fd-find`, `ripgrep`, `fzf`, `zoxide`, `imagemagick`
- Installs `7zip`, falling back to the older `p7zip-full` package name
- Symlinks `fd` to Debian's `fdfind` in `~/.local/bin` so Yazi finds it
- Clones [sxyazi/yazi](https://github.com/sxyazi/yazi) and builds from source with Cargo
- Installs `yazi` and `ya` binaries to `/usr/local/bin/`
- Requires Rust toolchain (install core components first, or have Rust already)

### 0xProto Nerd Font (`--install-font`)
- Downloads `0xProto.zip` and extracts the `.ttf` files into `~/.local/share/fonts/0xProto`
- Rebuilds the font cache with `fc-cache -fv`
- Rewrites the `[font]`/`[font.*]` tables in `~/.config/alacritty/alacritty.toml`,
  leaving every other setting intact; an existing file is copied to
  `alacritty.toml.backup` first
- Safe to re-run: old font tables (including subsections such as
  `[font.bold]`) are removed rather than duplicated

### Neovim (`--install-nvim`)
- Downloads the latest stable Neovim release tarball for the detected
  architecture (`x86_64` or `arm64`) and unpacks it into `/usr/local`
- Creates `~/.config/nvim/init.lua` bootstrapping lazy.nvim and oil.nvim
- An existing `init.lua` is copied to `init.lua.backup` before being replaced
- Plugins are installed on the first launch of `nvim`

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
- just (via `cargo install just`, only when `just` is not already installed)
- wget, python3 (used by later steps)

### System Libraries
- libwayland-dev, wayland-protocols, libegl1-mesa-dev
- libwlroots-0.18-dev on Debian 13 "Trixie", libwlroots-0.20-dev elsewhere
  (wlroots compositor libraries, for Noctalia Greeter — the version is derived
  from `VERSION_CODENAME` in `/etc/os-release`)
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

## Testing

The test suite runs entirely against stubbed system commands, so it is safe to
run on a machine that has nothing installed — it never touches the real system:

```bash
bash tests/run_tests.sh
```

| Test | What it covers |
|------|----------------|
| `test_help_output.sh` | `--help` text and the flags it advertises |
| `test_menu_source.sh` | menu entries and how selections are parsed |
| `test_greeter_source.sh` | greeter-specific code paths present in `install.sh` |
| `test_debian_detection.sh` | codename → wlroots version mapping, including a missing `os-release` |
| `test_shellcheck.sh` | lints `install.sh` and the tests (skipped if shellcheck is absent) |
| `test_sandbox_run.sh` | end-to-end runs of every flag against stubbed commands |
| `test_idempotency.sh` | re-running a step does not duplicate or corrupt its output |

`sandbox_run.sh` and `idempotency.sh` share `tests/lib/sandbox.sh`, which points
`HOME` and `TMPDIR` at a throwaway directory and puts stubs for `sudo`, `apt`,
`git`, `cargo`, `wget` and friends on `PATH`. Its `sudo` stub refuses any path
under `/etc`, `/usr`, `/bin` and `/sbin`, so a mistake in a test cannot modify
the host.

Install the linter to get the full suite:

```bash
sudo apt install shellcheck
```

## Troubleshooting

### `just: command not found` during build
The script sources `~/.cargo/env` automatically. If you encounter this outside the script, run:
```bash
source ~/.cargo/env
```

### Noctalia build fails with missing dependency
Run the system dependencies step first (`[1]` in the menu or `./install.sh` default) to ensure all build libraries are installed.

### `Error: wlroots-0.20 development files not found`
The greeter builds against wlroots, and the required major version differs per
Debian release. Run the system dependencies step (option `1`), or install the
package the error message names yourself.

### `libdisplay-info3 is not available via apt`
Expected on an older release: Debian ships a version too old for Niri. The
script then fetches the newest matching `.deb` straight from the Debian pool for
your architecture. If that also fails, check network access to
`ftp.debian.org`.

### Yazi cannot find `fd`
Debian ships the binary as `fdfind` to avoid a name clash. The script symlinks
`fd` into `~/.local/bin`; make sure that directory is on your `PATH`.

### Neovim fails to install on a non-x86 machine
Only `x86_64` and `arm64` have official Neovim release tarballs. Other
architectures have to be installed from your package manager or built from
source.

### A configuration file was replaced
The script backs up files before overwriting them, next to the original:

| File | Backup |
|------|--------|
| `~/.config/niri/config.kdl` | `config.kdl.backup` |
| `~/.config/alacritty/alacritty.toml` | `alacritty.toml.backup` |
| `~/.config/nvim/init.lua` | `init.lua.backup` |
| `/etc/network/interfaces` | `interfaces.backup` |

## Repository Structure

```
.
├── install.sh          # Main installation script
├── config.kdl          # Niri configuration (pre-configured for Noctalia)
├── tests/              # Test scripts (bash-based assertions)
│   ├── run_tests.sh    # Runs every test below
│   ├── lib/
│   │   └── sandbox.sh  # Shared harness: stubbed PATH + temporary HOME/TMPDIR
│   ├── test_help_output.sh
│   ├── test_menu_source.sh
│   ├── test_greeter_source.sh
│   ├── test_debian_detection.sh
│   ├── test_shellcheck.sh
│   ├── test_sandbox_run.sh
│   └── test_idempotency.sh
└── README.md           # This file
```

## License

This installation script is provided as-is. Individual components (Niri, Noctalia) have their own licenses.

## Credits

- **Niri**: [YaLTeR/niri](https://github.com/YaLTeR/niri)
- **Noctalia**: [noctalia-dev/noctalia](https://github.com/noctalia-dev/noctalia)
- **Noctalia Greeter**: [noctalia-dev/noctalia-greeter](https://github.com/noctalia-dev/noctalia-greeter)
- **Yazi**: [sxyazi/yazi](https://github.com/sxyazi/yazi)

