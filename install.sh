#!/bin/bash

set -euo pipefail

# Capture script directory and original working directory at the beginning
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ORIG_PWD="$(pwd)"

# Temporary build directories/files, all removed when the script exits — even on
# error or Ctrl-C, so builds never leak into /tmp.
TEMP_PATHS=()

# Register a path to be removed by the exit trap. Must be called at top level or
# inside a function invoked in the current shell (not in a subshell).
register_temp() {
    TEMP_PATHS+=("$1")
}

cleanup_temps() {
    local path
    for path in "${TEMP_PATHS[@]+"${TEMP_PATHS[@]}"}"; do
        [ -n "$path" ] && rm -rf "$path"
    done
    TEMP_PATHS=()
}

cleanup_on_exit() {
    local status=$?
    cleanup_temps
    exit "$status"
}
trap cleanup_on_exit EXIT

# Put the rustup-installed toolchain (cargo, rustc) on PATH
source_cargo_env() {
    if [ -f "$HOME/.cargo/env" ]; then
        # shellcheck disable=SC1091
        source "$HOME/.cargo/env"
    fi
}

# Configuration flags
ASK_STEP=false
SHOW_MENU=false
# Core components are installed by default; any explicitly requested component
# (other than --menu) switches that off.
CORE_BY_DEFAULT=true
INSTALL_VSCODE=false
INSTALL_OMZ=false
INSTALL_DOCS=false
INSTALL_OFFICE=false
APPLY_FIXES=false
REMOVE_GNOME=false
UPGRADE_MODE=""
INSTALL_WALLPAPER=false
INSTALL_DESKTOP_ENTRY=false
INSTALL_YAZI=false
INSTALL_FONT=false
INSTALL_NVIM=false
INSTALL_NOCTALIA_GREETER=false

# Any explicitly requested component turns off the "install everything core" default
select_component() {
    CORE_BY_DEFAULT=false
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --ask-step)
            ASK_STEP=true
            shift
            ;;
        --menu)
            SHOW_MENU=true
            shift
            ;;
        --install-vscode)
            INSTALL_VSCODE=true
            select_component
            shift
            ;;
        --install-omz)
            INSTALL_OMZ=true
            select_component
            shift
            ;;
        --install-docs)
            INSTALL_DOCS=true
            select_component
            shift
            ;;
        --install-office)
            INSTALL_OFFICE=true
            select_component
            shift
            ;;
        --apply-fixes)
            APPLY_FIXES=true
            select_component
            shift
            ;;
        --remove-gnome)
            REMOVE_GNOME=true
            select_component
            shift
            ;;
        --upgrade)
            if [[ -n "${2:-}" && ! "${2:-}" =~ ^-- ]]; then
                UPGRADE_MODE="$2"
                select_component
                shift 2
            else
                echo "Error: --upgrade requires an argument (niri, noctalia, greeter, or all)"
                exit 1
            fi
            ;;
        --install-wallpaper)
            INSTALL_WALLPAPER=true
            select_component
            shift
            ;;
        --install-desktop-entry)
            INSTALL_DESKTOP_ENTRY=true
            select_component
            shift
            ;;
        --install-yazi)
            INSTALL_YAZI=true
            select_component
            shift
            ;;
        --install-font)
            INSTALL_FONT=true
            select_component
            shift
            ;;
        --install-nvim)
            INSTALL_NVIM=true
            select_component
            shift
            ;;
        --install-noctalia-greeter)
            INSTALL_NOCTALIA_GREETER=true
            select_component
            shift
            ;;
        --help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --ask-step        Interactive mode - prompt before each core installation step"
            echo "  --menu            Show interactive menu to select components"
            echo "  --upgrade <type>  Upgrade components: niri, noctalia, greeter, or all"
            echo "  --install-vscode  Install Visual Studio Code with Wayland support"
            echo "  --install-omz     Install Oh My Zsh"
            echo "  --install-docs    Install zathura and loupe (document viewers)"
            echo "  --install-office  Install patat, gnumeric, and abiword"
            echo "  --apply-fixes     Apply network & hardware fixes (NetworkManager, firmware, etc.)"
            echo "  --remove-gnome    Remove GDM3 and GNOME packages (WARNING: removes desktop environment)"
            echo "  --install-wallpaper Install random wallpaper changer (systemd timer)"
            echo "  --install-desktop-entry Install wayland-session desktop entry for display managers"
            echo "  --install-yazi        Install yazi terminal file manager (builds from source)"
            echo "  --install-font        Install 0xProto Nerd Font and apply to alacritty"
            echo "  --install-nvim        Install Neovim (latest stable) with lazy.nvim and oil.nvim"
            echo "  --install-noctalia-greeter Install Noctalia Greeter (greetd login greeter)"
            echo "  --help            Show this help message"
            echo ""
            echo "With no options, the four core components are installed (dependencies,"
            echo "Niri, Noctalia, Noctalia Greeter). Passing any --install-* or --upgrade"
            echo "flag installs only what you asked for; --menu lets you pick from a list."
            echo ""
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Interactive menu function
show_interactive_menu() {
    clear 2>/dev/null || true
    echo "================================================"
    echo "  Niri Installation - Component Selection Menu"
    echo "================================================"
    echo ""
    echo "Core Components:"
    echo "  [1] System dependencies (build tools, Rust, and prerequisites)"
    echo "  [2] Niri compositor (build from source)"
    echo "  [3] Noctalia"
    echo "  [4] Noctalia Greeter"
    echo ""
    echo "Upgrade Options:"
    echo "  [U1] Upgrade Niri"
    echo "  [U2] Upgrade Noctalia"
    echo "  [U3] Upgrade Noctalia Greeter"
    echo "  [UA] Upgrade all (Niri + Noctalia + Greeter)"
    echo ""
    echo "Optional Components:"
    echo "  [5] Visual Studio Code (with Wayland support)"
    echo "  [6] Oh My Zsh"
    echo "  [7] Document viewers (zathura, loupe)"
    echo "  [8] Office tools (patat, gnumeric, abiword)"
    echo "  [9] Network & hardware fixes"
    echo "  [10] Remove GNOME/GDM3 (WARNING: removes desktop)"
    echo "  [11] Random wallpaper changer (systemd timer)"
    echo "  [12] Wayland session desktop entry (for display managers)"
    echo "  [13] Yazi terminal file manager (builds from source)"
    echo "  [14] 0xProto Nerd Font (downloads and applies to alacritty)"
    echo "  [15] Neovim with lazy.nvim + oil.nvim (latest stable binary)"
    echo ""
    echo "  [A] Install all core components (1-4)"
    echo "  [Q] Quit"
    echo ""
    read -r -p "Select components (space-separated numbers, e.g., '1 2 3 4 5'): " selections || true

    # Parse selections
    for selection in ${selections:-}; do
        case $selection in
            1) INSTALL_DEPS=true ;;
            2) INSTALL_NIRI=true ;;
            3) INSTALL_NOCTALIA=true ;;
            4) INSTALL_NOCTALIA_GREETER=true ;;
            5) INSTALL_VSCODE=true ;;
            6) INSTALL_OMZ=true ;;
            7) INSTALL_DOCS=true ;;
            8) INSTALL_OFFICE=true ;;
            9) APPLY_FIXES=true ;;
            10) REMOVE_GNOME=true ;;
            [Uu]1) UPGRADE_MODE="niri" ;;
            [Uu]2) UPGRADE_MODE="noctalia" ;;
            [Uu]3) UPGRADE_MODE="greeter" ;;
            [Uu][Aa]) UPGRADE_MODE="all" ;;
            11) INSTALL_WALLPAPER=true ;;
            12) INSTALL_DESKTOP_ENTRY=true ;;
            13) INSTALL_YAZI=true ;;
            14) INSTALL_FONT=true ;;
            15) INSTALL_NVIM=true ;;
            [Aa])
                INSTALL_DEPS=true
                INSTALL_NIRI=true
                INSTALL_NOCTALIA=true
                INSTALL_NOCTALIA_GREETER=true
                ;;
            [Qq])
                echo "Installation cancelled."
                exit 0
                ;;
            *)
                echo "Invalid selection: $selection"
                ;;
        esac
    done
}

# Initialize installation flags for core components
INSTALL_DEPS=false
INSTALL_NIRI=false
INSTALL_NOCTALIA=false
INSTALL_NOCTALIA_GREETER=false

# Show menu if requested, otherwise enable all core components unless a specific
# component was requested on the command line
if [ "$SHOW_MENU" = true ]; then
    show_interactive_menu
elif [ "$CORE_BY_DEFAULT" = true ]; then
    INSTALL_DEPS=true
    INSTALL_NIRI=true
    INSTALL_NOCTALIA=true
    INSTALL_NOCTALIA_GREETER=true
fi

# Detect Debian version and set wlroots version. Accepts an os-release path as an
# optional argument so tests can point it at a fixture.
# shellcheck disable=SC2120
detect_wlroots_version() {
    local os_release_file="${1:-/etc/os-release}"
    local version_codename=""
    if [ -f "$os_release_file" ]; then
        # Sourced in a subshell so the os-release variables do not leak into the
        # script's own namespace
        # shellcheck disable=SC1090
        version_codename=$( . "$os_release_file" >/dev/null 2>&1 && printf '%s' "${VERSION_CODENAME:-}" )
    fi
    if [ "$version_codename" = "trixie" ]; then
        WLROOTS_VERSION="0.18"
        NEED_XML_CURL=true
    else
        WLROOTS_VERSION="0.20"
        NEED_XML_CURL=false
    fi
}

# Ask the user whether to run a step (only prompts in --ask-step mode)
ask_skip() {
    local step_name="$1"
    if [ "$ASK_STEP" = false ]; then
        return 0  # Don't skip, proceed with installation
    fi
    local response
    read -r -p "Do you want to install $step_name? (Y/n): " response || true
    response=${response:-Y}  # Default to Y if empty
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        echo "Skipping $step_name..."
        return 1
    fi
    return 0
}

# Clone a repository shallowly into the current build directory
clone_repo() {
    local url="$1" name="$2"
    echo "Cloning $url..."
    git clone --depth=1 "$url" "$name"
}

# Fail early with instructions if the wlroots development files are missing
require_wlroots_dev() {
    if ! pkg-config --exists wlroots-${WLROOTS_VERSION}; then
        echo ""
        echo "Error: wlroots-${WLROOTS_VERSION} development files not found."
        echo "Install the system dependencies first, or run it manually:"
        echo "  sudo apt install libwlroots-${WLROOTS_VERSION}-dev"
        return 1
    fi
}

# Verify a freshly installed binary is reachable, failing loudly if it is not
verify_installed() {
    local bin="$1" label="$2"
    if ! command -v "$bin" &> /dev/null; then
        echo "Error: $label installation failed ($bin not found on PATH)"
        return 1
    fi
    echo "$label installed successfully → $(command -v "$bin")"
    "$bin" --version || true
}

# Build and install the Niri compositor from source
build_niri() {
    echo "Building and installing Niri from source..."

    cd "$TEMP_DIR"
    clone_repo https://github.com/YaLTeR/niri.git niri
    cd niri

    echo "Building Niri (this may take several minutes)..."
    cargo build --release

    echo "Installing Niri..."
    sudo install -Dm755 target/release/niri /usr/local/bin/niri
    sudo install -Dm644 resources/niri-session /usr/local/bin/niri-session
    sudo install -Dm644 resources/niri-portals.conf /usr/share/xdg-desktop-portal/portals/niri-portals.conf

    cd "$ORIG_PWD"
    verify_installed niri "Niri"
}

# Build and install the Noctalia shell from source
build_noctalia() {
    echo "Building and installing Noctalia from source..."

    cd "$TEMP_DIR"
    clone_repo https://github.com/noctalia-dev/noctalia.git noctalia
    cd noctalia

    just configure release
    just build release
    sudo env PATH="$PATH" just install release

    cd "$ORIG_PWD"
    verify_installed noctalia "Noctalia"
}

# Build and install the Noctalia Greeter from source and configure greetd
build_noctalia_greeter() {
    require_wlroots_dev

    echo "Building and installing Noctalia Greeter from source..."

    cd "$TEMP_DIR"
    clone_repo https://github.com/noctalia-dev/noctalia-greeter.git noctalia-greeter
    cd noctalia-greeter

    just configure-release
    just build-release
    sudo meson install -C build-release
    sudo ./scripts/setup_greeter_system.sh

    cd "$ORIG_PWD"
    echo "Noctalia Greeter installed successfully!"
}

# Dispatch a component name to its build+install routine
build_component() {
    case "$1" in
        niri)     build_niri ;;
        noctalia) build_noctalia ;;
        greeter)  build_noctalia_greeter ;;
        *)
            echo "Error: unknown component '$1'"
            return 1
            ;;
    esac
}

# Install a package, preferring the Debian repository and falling back to the
# pool .deb when the release is too old to carry it
install_pool_deb() {
    local pkg="$1" pool="https://ftp.debian.org/debian/pool/main/libd/libdisplay-info/"
    local arch listing url deb

    if sudo apt-get install -y --no-install-recommends "$pkg" 2>/dev/null; then
        echo "$pkg installed from the Debian repositories"
        return 0
    fi

    echo "Warning: $pkg is not available via apt, downloading the .deb directly..."
    arch="$(dpkg --print-architecture 2>/dev/null | tr -d '[:space:]')"
    if [ -z "$arch" ]; then
        echo "Error: could not determine the system architecture via dpkg"
        return 1
    fi
    listing="$(wget -qO- "$pool" 2>/dev/null || true)"
    url="$(printf '%s' "$listing" | grep -oE "${pkg}_[^\"]*_${arch}\.deb" | sort -V | tail -1 || true)"

    if [ -z "$url" ]; then
        echo "Error: no ${pkg}_*_${arch}.deb found at $pool"
        return 1
    fi

    deb="$(mktemp)"; register_temp "$deb"
    wget --progress=bar:force -O "$deb" "${pool}${url}"
    sudo dpkg -i "$deb"
    echo "$pkg installed successfully"
}

# Detect Debian version and set wlroots variables
detect_wlroots_version

# Handle upgrade mode
if [ -n "$UPGRADE_MODE" ]; then
    echo "================================================"
    echo "Niri + Noctalia Upgrade Script"
    echo "================================================"
    echo "Upgrade mode: $UPGRADE_MODE"
    echo ""

    # Ensure cargo/just are in PATH
    source_cargo_env

    TEMP_DIR="$(mktemp -d)"; register_temp "$TEMP_DIR"

    case "$UPGRADE_MODE" in
        niri|noctalia|greeter)
            build_component "$UPGRADE_MODE"
            ;;
        all)
            step=0
            for component in niri noctalia greeter; do
                step=$((step + 1))
                echo ""
                echo "[$step/3] Upgrading $component..."
                build_component "$component"
            done
            echo ""
            echo "All components upgraded successfully!"
            ;;
        *)
            echo "Error: Invalid upgrade type '$UPGRADE_MODE'"
            echo "Valid options: niri, noctalia, greeter, all"
            exit 1
            ;;
    esac

    echo ""
    echo "================================================"
    echo "Upgrade complete!"
    echo "================================================"
    exit 0
fi

echo "================================================"
echo "Niri + Noctalia Installation Script"
echo "================================================"
if [ "$ASK_STEP" = true ]; then
    echo "Running in interactive mode (--ask-step)"
fi

# Create temporary directory for builds (removed automatically on exit)
TEMP_DIR="$(mktemp -d)"; register_temp "$TEMP_DIR"

# Ensure cargo/just are in PATH if already installed
source_cargo_env

# Update package list and install dependencies
if [ "$INSTALL_DEPS" = true ]; then
    echo ""
    echo "[1/4] System dependencies"
fi
if [ "$INSTALL_DEPS" = true ] && ask_skip "system dependencies (build tools, Rust, and prerequisites)"; then
    echo "Updating package lists..."
    sudo apt update

    echo "Installing system dependencies..."
    sudo apt install -y --no-install-recommends sudo gpg curl git cmake ninja-build build-essential \
	meson libsdbus-c++-dev libical-dev libjxl-dev libsndfile1-dev \
	libpipewire-0.3-dev pkg-config libmd4c-dev \
        wayland-protocols libwayland-dev libegl1-mesa-dev \
        libwlroots-${WLROOTS_VERSION}-dev libegl-dev libgles-dev \
        libpolkit-agent-1-dev libjemalloc-dev libpam0g-dev swayidle \
	libpango1.0-dev libwireplumber-0.5-dev nlohmann-json3-dev \
	libfreetype-dev libfontconfig1-dev libcairo2-dev libharfbuzz-dev \
	librsvg2-dev libxkbcommon-dev libglib2.0-dev libtomlplusplus-dev \
	libcurl4-gnutls-dev libqalculate-dev libxml2-dev libwebp-dev libepoxy-dev \
	alacritty fuzzel waybar xdg-desktop-portal-gtk xwayland \
        libsecret-1-dev libsodium-dev libstb-dev nwg-look greetd \
        wget python3

    sudo systemctl enable greetd

    # Download ext-background-effect protocol XML for wlroots 0.18 (Trixie)
    if [ "$NEED_XML_CURL" = true ]; then
        echo "Downloading ext-background-effect protocol XML..."
        sudo mkdir -p /usr/share/wayland-protocols/staging/ext-background-effect
        sudo curl -fL --retry 3 'https://gitlab.freedesktop.org/wayland/wayland-protocols/-/raw/main/staging/ext-background-effect/ext-background-effect-v1.xml?inline=false' -o /usr/share/wayland-protocols/staging/ext-background-effect/ext-background-effect-v1.xml
    fi

    # Install libdisplay-info3 and libdisplay-info-dev (needed by Niri). Debian
    # often ships versions too old for Niri, so fall back to the pool .deb.
    echo "Installing libdisplay-info3 and libdisplay-info-dev..."
    install_pool_deb libdisplay-info3
    install_pool_deb libdisplay-info-dev

    # Install Rust toolchain
    echo "Installing Rust toolchain..."
    if ! command -v rustc &> /dev/null; then
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain stable
        source_cargo_env
        echo "Rust toolchain installed successfully"
    else
        echo "Rust already installed, updating..."
        rustup update stable
        rustup default stable
    fi

    # Install just (build tool required by Noctalia)
    if command -v just &> /dev/null; then
        echo "just already installed ($(just --version))"
    else
        echo "Installing just..."
        cargo install just
        echo "just installed successfully"
    fi

    echo "System dependencies installed successfully!"
fi

# Install Niri (build from source)
if [ "$INSTALL_NIRI" = true ]; then
    echo ""
    echo "[2/4] Niri compositor"
fi
if [ "$INSTALL_NIRI" = true ] && ask_skip "Niri compositor (build from source)"; then
    # Ensure Rust is in PATH
    source_cargo_env

    build_niri
fi

# Install Noctalia
if [ "$INSTALL_NOCTALIA" = true ]; then
    echo ""
    echo "[3/4] Noctalia"
fi
if [ "$INSTALL_NOCTALIA" = true ] && ask_skip "Noctalia"; then
    build_noctalia
fi

# Install Noctalia Greeter
if [ "$INSTALL_NOCTALIA_GREETER" = true ]; then
    echo ""
    echo "[4/4] Noctalia Greeter"
fi
if [ "$INSTALL_NOCTALIA_GREETER" = true ] && ask_skip "Noctalia Greeter"; then
    build_noctalia_greeter
fi

# Return to the directory the script was started from
cd "$ORIG_PWD"

# Apply niri configuration (only if niri was installed)
if [ "$INSTALL_NIRI" = true ]; then
    echo ""
    if [ -f "$SCRIPT_DIR/config.kdl" ]; then
        read -r -p "Do you want to apply the niri configuration (config.kdl)? (Y/n): " config_response || true
        config_response=${config_response:-Y}
        if [[ "$config_response" =~ ^[Yy]$ ]]; then
            if [ -f "$HOME/.config/niri/config.kdl" ]; then
                cp "$HOME/.config/niri/config.kdl" "$HOME/.config/niri/config.kdl.backup"
                echo "Existing config backed up to ~/.config/niri/config.kdl.backup"
            fi
            mkdir -p "$HOME/.config/niri"
            cp "$SCRIPT_DIR/config.kdl" "$HOME/.config/niri/config.kdl"
            echo "Niri configuration applied to ~/.config/niri/config.kdl"
        else
            echo "Skipping niri configuration..."
        fi
    fi
fi

# Optional: Remove GNOME/GDM3
if [ "$REMOVE_GNOME" = true ]; then
    echo ""
    echo "================================================"
    echo "WARNING: Remove GNOME and GDM3"
    echo "================================================"
    echo "This will remove your desktop environment."
    echo "After removal, the system will boot to console mode."
    echo ""
    read -r -p "Type 'yes' to confirm removal: " confirm || true

    if [ "${confirm:-}" = "yes" ]; then
        echo "Stopping GDM3..."
        sudo systemctl stop gdm3 || true

        echo "Removing GNOME packages..."
        sudo apt purge -y gnome-core gnome-shell gdm3 gnome-session gnome-terminal \
            gnome-control-center gnome-software nautilus || true

        echo "Cleaning up..."
        sudo apt autoremove -y

        echo "Setting system to boot to multi-user target..."
        sudo systemctl set-default multi-user.target

        echo "GNOME and GDM3 removed successfully!"
        echo "System will boot to console. Use 'niri' to start the compositor."
    else
        echo "GNOME removal cancelled."
    fi
fi

# Optional: Install Visual Studio Code
if [ "$INSTALL_VSCODE" = true ]; then
    echo ""
    echo "================================================"
    echo "Installing Visual Studio Code"
    echo "================================================"

    sudo apt install -y --no-install-recommends wget gpg apt-transport-https

    # The key lands in a temp file (not next to the script) so an interrupted run
    # cannot leave a stray .gpg in the repository.
    VSCODE_KEY="$(mktemp)"; register_temp "$VSCODE_KEY"
    curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > "$VSCODE_KEY"
    sudo install -D -o root -g root -m 644 "$VSCODE_KEY" /etc/apt/keyrings/packages.microsoft.gpg
    echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" | sudo tee /etc/apt/sources.list.d/vscode.list > /dev/null

    sudo apt update
    sudo apt install -y --no-install-recommends code

    # Copy desktop file and add Wayland flag
    mkdir -p "$HOME/.local/share/applications"
    if [ ! -f /usr/share/applications/code.desktop ]; then
        echo "Warning: /usr/share/applications/code.desktop not found;"
        echo "         skipping the Wayland desktop entry (the shell alias below still works)"
    else
        if [ ! -f "$HOME/.local/share/applications/code.desktop" ]; then
            cp /usr/share/applications/code.desktop "$HOME/.local/share/applications/code.desktop"
        fi
        sed -i 's|^Exec=/usr/share/code/code$|Exec=/usr/share/code/code --enable-features=UseOzonePlatform --ozone-platform=wayland|' "$HOME/.local/share/applications/code.desktop"
        if ! grep -q "ozone-platform=wayland" "$HOME/.local/share/applications/code.desktop"; then
            echo "Warning: could not patch code.desktop for Wayland; the shell alias below still works"
        fi
    fi

    # Add shell alias
    for rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
        [ -f "$rc" ] || continue
        if ! grep -q "alias code=" "$rc"; then
            echo "alias code='code --enable-features=UseOzonePlatform --ozone-platform=wayland'" >> "$rc"
        fi
    done

    echo "Visual Studio Code installed with Wayland support!"
fi

# Optional: Install Oh My Zsh
if [ "$INSTALL_OMZ" = true ]; then
    echo ""
    echo "================================================"
    echo "Installing Oh My Zsh"
    echo "================================================"

    sudo apt install -y --no-install-recommends zsh

    # Change default shell
    read -r -p "Do you want to change your default shell to zsh? (Y/n): " zsh_response || true
    zsh_response=${zsh_response:-Y}
    if [[ "$zsh_response" =~ ^[Yy]$ ]]; then
        chsh -s "$(command -v zsh)"
        echo "Default shell changed to zsh (will take effect on next login)"
    fi

    # Install Oh My Zsh
    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
        echo "Oh My Zsh installed successfully!"
    else
        echo "Oh My Zsh is already installed"
    fi
fi

# Optional: Install document viewers
if [ "$INSTALL_DOCS" = true ]; then
    echo ""
    echo "================================================"
    echo "Installing document viewers"
    echo "================================================"

    sudo apt install -y --no-install-recommends zathura zathura-pdf-poppler loupe
    echo "Installed: zathura, zathura-pdf-poppler, loupe"
fi

# Optional: Install office tools
if [ "$INSTALL_OFFICE" = true ]; then
    echo ""
    echo "================================================"
    echo "Installing office tools"
    echo "================================================"

    sudo apt install -y --no-install-recommends abiword gnumeric patat
    echo "Installed: abiword, gnumeric, patat"
fi

# Optional: Apply network & hardware fixes
if [ "$APPLY_FIXES" = true ]; then
    echo ""
    echo "================================================"
    echo "Applying network & hardware fixes"
    echo "================================================"

    echo "Installing NetworkManager, bluez, brightnessctl, firmware packages..."
    sudo apt install -y --no-install-recommends network-manager bluez brightnessctl upower \
        pipewire-audio-client-libraries libpam0g-dev \
        firmware-linux firmware-iwlwifi firmware-realtek \
        wlsunset nwg-look

    # Add user to groups (SUDO_USER when run via sudo, so the real user gets access)
    TARGET_USER="${SUDO_USER:-${USER:-$(id -un)}}"
    sudo usermod -aG netdev,bluetooth,video "$TARGET_USER"
    echo "Added $TARGET_USER to groups: netdev, bluetooth, video"

    # Update NetworkManager configuration
    echo "Configuring NetworkManager..."
    sudo mkdir -p /etc/NetworkManager/conf.d/
    printf '[main]\nplugins=ifupdown,keyfile\n\n[ifupdown]\nmanaged=true\n' \
        | sudo tee /etc/NetworkManager/conf.d/10-globally-managed-devices.conf > /dev/null

    # Comment out wlan0 in /etc/network/interfaces (only active stanzas, so
    # re-running does not stack comments on an already-commented line)
    if [ -f /etc/network/interfaces ] && grep -qE '^[[:space:]]*wlan0' /etc/network/interfaces; then
        sudo cp /etc/network/interfaces /etc/network/interfaces.backup
        sudo sed -i -E 's/^([[:space:]]*wlan0)/# \1/' /etc/network/interfaces
        echo "Backed up and updated /etc/network/interfaces"
    fi

    sudo systemctl restart NetworkManager
    echo "NetworkManager configured and restarted"
    echo ""
    echo "Network & hardware fixes applied successfully!"
    echo "Note: You may need to log out and back in for group changes to take effect"
fi

# Optional: Install random wallpaper changer
if [ "$INSTALL_WALLPAPER" = true ]; then
    echo ""
    echo "================================================"
    echo "Installing random wallpaper changer"
    echo "================================================"

    # Create wallpaper script
    mkdir -p "$HOME/.local/bin"
    cat > "$HOME/.local/bin/noctalia-random-wallpaper.sh" << 'WALLPAPER_EOF'
#!/bin/bash
# Random wallpaper changer for Noctalia
set -euo pipefail
WALLPAPER_DIR="$HOME/Pictures/Wallpapers"
if [ ! -d "$WALLPAPER_DIR" ]; then
    echo "Wallpaper directory not found: $WALLPAPER_DIR"
    exit 1
fi

RANDOM_WALLPAPER=$(find "$WALLPAPER_DIR" -type f \( -iname "*.jpg" -o -iname "*.png" -o -iname "*.jpeg" \) | shuf -n 1)

if [ -n "$RANDOM_WALLPAPER" ]; then
    noctalia msg wallpaper-set "$RANDOM_WALLPAPER"
    echo "Wallpaper changed to: $RANDOM_WALLPAPER"
else
    echo "No wallpapers found in $WALLPAPER_DIR"
fi
WALLPAPER_EOF

    chmod +x "$HOME/.local/bin/noctalia-random-wallpaper.sh"

    # Create systemd service
    mkdir -p "$HOME/.config/systemd/user"
    cat > "$HOME/.config/systemd/user/noctalia-wallpaper.service" << 'SERVICE_EOF'
[Unit]
Description=Noctalia Random Wallpaper Changer
After=graphical-session.target

[Service]
Type=oneshot
ExecStart=%h/.local/bin/noctalia-random-wallpaper.sh

[Install]
WantedBy=default.target
SERVICE_EOF

    # Create systemd timer
    cat > "$HOME/.config/systemd/user/noctalia-wallpaper.timer" << 'TIMER_EOF'
[Unit]
Description=Change Noctalia wallpaper every 30 minutes
Requires=noctalia-wallpaper.service

[Timer]
OnBootSec=1min
OnUnitActiveSec=30min

[Install]
WantedBy=timers.target
TIMER_EOF

    # Enable and start timer
    systemctl --user daemon-reload
    systemctl --user enable noctalia-wallpaper.timer
    systemctl --user start noctalia-wallpaper.timer

    echo "Random wallpaper changer installed!"
    echo "Script location: ~/.local/bin/noctalia-random-wallpaper.sh"
    echo "Timer enabled: wallpaper will change every 30 minutes"
    echo ""
    echo "Note: Make sure to create ~/Pictures/Wallpapers directory and add wallpaper images"
fi

# Optional: Install wayland-session desktop entry
if [ "$INSTALL_DESKTOP_ENTRY" = true ]; then
    echo ""
    echo "================================================"
    echo "Installing Wayland Session Desktop Entry"
    echo "================================================"

    # /usr/share/wayland-sessions does not exist on minimal installs
    sudo mkdir -p /usr/share/wayland-sessions
    sudo tee /usr/share/wayland-sessions/niri.desktop > /dev/null << 'DESKTOP_EOF'
[Desktop Entry]
Name=Niri
Comment=A scrollable-tiling Wayland compositor
Exec=/usr/local/bin/niri
Type=Application
DesktopNames=niri
DESKTOP_EOF

    echo "Wayland session desktop entry installed!"
    echo "Location: /usr/share/wayland-sessions/niri.desktop"
    echo ""
    echo "You can now select Niri from your display manager (GDM, SDDM, LightDM, etc.)"
fi

# Optional: Install yazi terminal file manager
if [ "$INSTALL_YAZI" = true ]; then
    echo ""
    echo "================================================"
    echo "Installing Yazi terminal file manager"
    echo "================================================"

    echo "Installing yazi prerequisites..."
    sudo apt install -y --no-install-recommends ffmpeg jq poppler-utils fd-find ripgrep fzf zoxide imagemagick
    # Debian renamed the 7-Zip package; try the new name first, fall back to the old one
    sudo apt install -y --no-install-recommends 7zip || \
        sudo apt install -y --no-install-recommends p7zip-full

    # fd-find ships the binary as `fdfind` on Debian to avoid clashing with another fd
    if ! command -v fd &> /dev/null && command -v fdfind &> /dev/null; then
        mkdir -p "$HOME/.local/bin"
        ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd"
        echo "Linked fd → fdfind in ~/.local/bin"
    fi

    # Ensure Rust is in PATH
    source_cargo_env

    YAZI_TEMP="$(mktemp -d)"; register_temp "$YAZI_TEMP"
    git clone --depth=1 https://github.com/sxyazi/yazi.git "$YAZI_TEMP/yazi"
    cd "$YAZI_TEMP/yazi"

    echo "Building yazi (this may take several minutes)..."
    cargo build --release --locked

    sudo install -Dm755 target/release/yazi /usr/local/bin/yazi
    sudo install -Dm755 target/release/ya /usr/local/bin/ya

    cd "$ORIG_PWD"
    verify_installed yazi "Yazi"
fi

# Optional: Install 0xProto Nerd Font
if [ "$INSTALL_FONT" = true ]; then
    echo ""
    echo "================================================"
    echo "Installing 0xProto Nerd Font"
    echo "================================================"

    FONT_DIR="$HOME/.local/share/fonts/0xProto"
    mkdir -p "$FONT_DIR"

    echo "Installing unzip prerequisite..."
    sudo apt install -y --no-install-recommends unzip

    echo "Downloading 0xProto Nerd Font..."
    FONT_TMP="$(mktemp -d)"; register_temp "$FONT_TMP"
    wget --progress=bar:force -O "$FONT_TMP/0xProto.zip" "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/0xProto.zip"
    unzip -o "$FONT_TMP/0xProto.zip" "*.ttf" -d "$FONT_DIR"

    echo "Rebuilding font cache..."
    fc-cache -fv

    echo "Applying font to alacritty configuration..."
    ALACRITTY_CONF="$HOME/.config/alacritty/alacritty.toml"
    mkdir -p "$HOME/.config/alacritty"
    if [ -f "$ALACRITTY_CONF" ]; then
        cp "$ALACRITTY_CONF" "$ALACRITTY_CONF.backup"
        echo "Existing alacritty.toml backed up to $ALACRITTY_CONF.backup"
        # Drop every existing font table. This has to be done line by line
        # because [font] is followed by subsections such as [font.normal]:
        # a plain "[font] up to the next [" match leaves those subsections
        # behind, orphaning them on re-runs.
        python3 - "$ALACRITTY_CONF" <<'PYEOF'
import re, sys

path = sys.argv[1]
with open(path) as f:
    lines = f.read().splitlines(keepends=True)

header = re.compile(r'^[ \t]*\[([^]]+)\][ \t]*$')

kept = []
skipping = False
for line in lines:
    match = header.match(line.rstrip('\n'))
    if match:
        table = match.group(1).strip()
        # Start skipping at [font] or any [font.*] table, resume at the next
        # header that is not a font table
        skipping = table == 'font' or table.startswith('font.')
    if not skipping:
        kept.append(line)

with open(path, 'w') as f:
    content = ''.join(kept).strip('\n')
    if content:
        f.write(content + '\n')
PYEOF
    fi

    # Appended in both cases: a missing file is created, an existing one has had
    # its old font tables stripped above
    cat >> "$ALACRITTY_CONF" << 'FONT_EOF'

[font]
size = 10.0

[font.normal]
family = "0xProto Nerd Font Mono"
style = "Regular"
FONT_EOF

    echo "0xProto Nerd Font installed and applied to alacritty!"
    echo "Font location: $FONT_DIR"
    echo "Alacritty config: $ALACRITTY_CONF"
fi

# Optional: Install Neovim with lazy.nvim and oil.nvim
if [ "$INSTALL_NVIM" = true ]; then
    echo ""
    echo "================================================"
    echo "Installing Neovim with lazy.nvim and oil.nvim"
    echo "================================================"

    # Map the host CPU to the Neovim release asset name
    case "$(uname -m)" in
        x86_64)  NVIM_ARCH="x86_64" ;;
        aarch64|arm64) NVIM_ARCH="arm64" ;;
        *)
            echo "Error: unsupported architecture $(uname -m) for the Neovim release tarball"
            exit 1
            ;;
    esac

    echo "Downloading latest stable Neovim ($NVIM_ARCH)..."
    NVIM_TMP="$(mktemp -d)"; register_temp "$NVIM_TMP"
    wget --progress=bar:force -O "$NVIM_TMP/nvim.tar.gz" "https://github.com/neovim/neovim/releases/latest/download/nvim-linux-${NVIM_ARCH}.tar.gz"
    sudo tar -C /usr/local -xzf "$NVIM_TMP/nvim.tar.gz" --strip-components=1

    verify_installed nvim "Neovim"

    echo "Creating Neovim configuration with lazy.nvim and oil.nvim..."
    NVIM_INIT="$HOME/.config/nvim/init.lua"
    mkdir -p "$HOME/.config/nvim"
    if [ -f "$NVIM_INIT" ]; then
        cp "$NVIM_INIT" "$NVIM_INIT.backup"
        echo "Existing init.lua backed up to $NVIM_INIT.backup"
    fi
    cat > "$NVIM_INIT" << 'NVIM_EOF'
-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local out = vim.fn.system({
    "git", "clone", "--filter=blob:none", "--branch=stable",
    "https://github.com/folke/lazy.nvim.git", lazypath,
  })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({ { "Failed to clone lazy.nvim:\n", "ErrorMsg" }, { out, "WarningMsg" } }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

-- Setup lazy.nvim
require("lazy").setup({
  {
    "stevearc/oil.nvim",
    opts = {},
    dependencies = { "nvim-tree/nvim-web-devicons" },
  },
})

-- Setup oil.nvim (file manager replacing netrw)
require("oil").setup()
vim.keymap.set("n", "-", "<CMD>Oil<CR>", { desc = "Open parent directory" })
NVIM_EOF

    echo "Neovim configuration created at ~/.config/nvim/init.lua"
    echo "Plugins (lazy.nvim + oil.nvim) will be installed on first launch of nvim."
fi

echo ""
echo "================================================"
echo ""
echo "Enjoy your Niri + Noctalia setup!"
echo ""
