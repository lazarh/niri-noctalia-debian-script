#!/bin/bash

set -e  # Exit on error

# Capture script directory at the beginning
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Configuration flags
ASK_STEP=false
SHOW_MENU=false
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
            shift
            ;;
        --install-omz)
            INSTALL_OMZ=true
            shift
            ;;
        --install-docs)
            INSTALL_DOCS=true
            shift
            ;;
        --install-office)
            INSTALL_OFFICE=true
            shift
            ;;
        --apply-fixes)
            APPLY_FIXES=true
            shift
            ;;
        --remove-gnome)
            REMOVE_GNOME=true
            shift
            ;;
        --upgrade)
            if [[ -n "$2" && ! "$2" =~ ^-- ]]; then
                UPGRADE_MODE="$2"
                shift 2
            else
                echo "Error: --upgrade requires an argument (niri, noctalia, greeter, or all)"
                exit 1
            fi
            ;;
        --install-wallpaper)
            INSTALL_WALLPAPER=true
            shift
            ;;
        --install-desktop-entry)
            INSTALL_DESKTOP_ENTRY=true
            shift
            ;;
        --install-yazi)
            INSTALL_YAZI=true
            shift
            ;;
        --install-font)
            INSTALL_FONT=true
            shift
            ;;
        --install-nvim)
            INSTALL_NVIM=true
            shift
            ;;
        --install-noctalia-greeter)
            INSTALL_NOCTALIA_GREETER=true
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
    clear
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
    read -p "Select components (space-separated numbers, e.g., '1 2 3 4 5'): " selections

    # Parse selections
    for selection in $selections; do
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

# Show menu if requested, otherwise enable all core components by default
if [ "$SHOW_MENU" = true ]; then
    show_interactive_menu
else
    # Default: install all core components only if no optional flags were explicitly set
    if [ -z "$UPGRADE_MODE" ] && \
       [ "$INSTALL_VSCODE" = false ] && [ "$INSTALL_OMZ" = false ] && \
       [ "$INSTALL_DOCS" = false ] && [ "$INSTALL_OFFICE" = false ] && \
       [ "$APPLY_FIXES" = false ] && [ "$REMOVE_GNOME" = false ] && \
       [ "$INSTALL_WALLPAPER" = false ] && [ "$INSTALL_DESKTOP_ENTRY" = false ] && \
       [ "$INSTALL_YAZI" = false ] && [ "$INSTALL_FONT" = false ] && \
       [ "$INSTALL_NVIM" = false ] && [ "$INSTALL_NOCTALIA_GREETER" = false ]; then
        INSTALL_DEPS=true
        INSTALL_NIRI=true
        INSTALL_NOCTALIA=true
        INSTALL_NOCTALIA_GREETER=true
    fi
fi

# Function to detect Debian version and set wlroots version
detect_wlroots_version() {
    local os_release_file="${1:-/etc/os-release}"
    local version_codename=""
    if [ -f "$os_release_file" ]; then
        version_codename=$(grep -oP 'VERSION_CODENAME=\K.*' "$os_release_file" 2>/dev/null || echo "")
    fi
    if [ "$version_codename" = "trixie" ] || [ "$version_codename" = "gigi" ]; then
        # LMDE 7 (gigi) is based on Trixie, so it uses wlroots 0.18 too
        WLROOTS_VERSION="0.18"
        NEED_XML_CURL=true
    else
        WLROOTS_VERSION="0.20"
        NEED_XML_CURL=false
    fi
}

# Function to ask user if they want to skip a step
ask_skip() {
    local step_name="$1"
    if [ "$ASK_STEP" = false ]; then
        return 0  # Don't skip, proceed with installation
    fi
    read -p "Do you want to install $step_name? (Y/n): " response
    response=${response:-Y}  # Default to Y if empty
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        echo "Skipping $step_name..."
        return 1
    fi
    return 0
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
    if [ -f "$HOME/.cargo/env" ]; then
        source "$HOME/.cargo/env"
    fi

    case "$UPGRADE_MODE" in
        niri)
            echo "Upgrading Niri (building from source)..."
            TEMP_DIR=$(mktemp -d)
            cd "$TEMP_DIR"
            git clone --depth=1 https://github.com/YaLTeR/niri.git
            cd niri
            cargo build --release
            sudo install -Dm755 target/release/niri /usr/local/bin/niri
            sudo install -Dm644 resources/niri-session /usr/local/bin/niri-session
            sudo install -Dm644 resources/niri-portals.conf /usr/share/xdg-desktop-portal/portals/niri-portals.conf
            cd ~
            rm -rf "$TEMP_DIR"
            echo "Niri upgrade complete!"
            ;;
        noctalia)
            echo "Upgrading Noctalia..."
            TEMP_DIR=$(mktemp -d)
            cd "$TEMP_DIR"
            git clone --depth=1 https://github.com/noctalia-dev/noctalia.git
            cd noctalia
            just configure release
            just build release
            sudo env PATH="$PATH" just install release
            cd ~
            rm -rf "$TEMP_DIR"
            echo "Noctalia upgrade complete!"
            ;;
        greeter)
            echo "Upgrading Noctalia Greeter..."

            if ! pkg-config --exists wlroots-${WLROOTS_VERSION}; then
                echo ""
                echo "Error: wlroots-${WLROOTS_VERSION} development files not found."
                echo "Run: sudo apt install libwlroots-${WLROOTS_VERSION}-dev"
                exit 1
            fi

            TEMP_DIR=$(mktemp -d)
            cd "$TEMP_DIR"
            git clone --depth=1 https://github.com/noctalia-dev/noctalia-greeter.git
            cd noctalia-greeter
            just configure-release
            just build-release
            sudo meson install -C build-release
            sudo ./scripts/setup_greeter_system.sh
            cd ~
            rm -rf "$TEMP_DIR"
            echo "Noctalia Greeter upgrade complete!"
            ;;
        all)
            echo "Upgrading all components (Niri + Noctalia + Greeter)..."
            echo ""

            echo "[1/3] Upgrading Niri (building from source)..."
            TEMP_DIR=$(mktemp -d)
            cd "$TEMP_DIR"
            git clone --depth=1 https://github.com/YaLTeR/niri.git
            cd niri
            cargo build --release
            sudo install -Dm755 target/release/niri /usr/local/bin/niri
            sudo install -Dm644 resources/niri-session /usr/local/bin/niri-session
            sudo install -Dm644 resources/niri-portals.conf /usr/share/xdg-desktop-portal/portals/niri-portals.conf
            cd ~
            rm -rf "$TEMP_DIR"
            echo "Niri upgrade complete!"
            echo ""

            echo "[2/3] Upgrading Noctalia..."
            TEMP_DIR=$(mktemp -d)
            cd "$TEMP_DIR"
            git clone --depth=1 https://github.com/noctalia-dev/noctalia.git
            cd noctalia
            just configure release
            just build release
            sudo env PATH="$PATH" just install release
            cd ~
            rm -rf "$TEMP_DIR"
            echo "Noctalia upgrade complete!"
            echo ""

            echo "[3/3] Upgrading Noctalia Greeter..."

            if ! pkg-config --exists wlroots-${WLROOTS_VERSION}; then
                echo ""
                echo "Error: wlroots-${WLROOTS_VERSION} development files not found."
                echo "Run: sudo apt install libwlroots-${WLROOTS_VERSION}-dev"
                exit 1
            fi

            TEMP_DIR=$(mktemp -d)
            cd "$TEMP_DIR"
            git clone --depth=1 https://github.com/noctalia-dev/noctalia-greeter.git
            cd noctalia-greeter
            just configure-release
            just build-release
            sudo meson install -C build-release
            sudo ./scripts/setup_greeter_system.sh
            cd ~
            rm -rf "$TEMP_DIR"
            echo "Noctalia Greeter upgrade complete!"
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

# Create temporary directory for builds
TEMP_DIR=$(mktemp -d)

# Ensure cargo/just are in PATH if already installed
if [ -f "$HOME/.cargo/env" ]; then
    source "$HOME/.cargo/env"
fi

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
        libsecret-1-dev libsodium-dev libstb-dev nwg-look greetd

    sudo systemctl enable greetd

    # Download ext-background-effect protocol XML for wlroots 0.18 (Trixie)
    if [ "$NEED_XML_CURL" = true ]; then
        echo "Downloading ext-background-effect protocol XML..."
        sudo mkdir -p /usr/share/wayland-protocols/staging/ext-background-effect
        sudo curl -L 'https://gitlab.freedesktop.org/wayland/wayland-protocols/-/raw/main/staging/ext-background-effect/ext-background-effect-v1.xml?inline=false' -o /usr/share/wayland-protocols/staging/ext-background-effect/ext-background-effect-v1.xml
    fi

    # Download and install libdisplay-info3 and libdisplay-info-dev (latest versions)
    echo "Downloading and installing libdisplay-info3 and libdisplay-info-dev..."
    LIBDISPLAY_POOL="http://ftp.debian.org/debian/pool/main/libd/libdisplay-info/"
    LIBDISPLAY_LISTING=$(wget -qO- "$LIBDISPLAY_POOL")

    LIBDISPLAY_URL=$(echo "$LIBDISPLAY_LISTING" | grep -oP 'libdisplay-info3_[^"]+_amd64\.deb' | sort -V | tail -1)
    if [ -n "$LIBDISPLAY_URL" ]; then
        TEMP_DEB=$(mktemp)
        wget -O "$TEMP_DEB" "${LIBDISPLAY_POOL}${LIBDISPLAY_URL}"
        sudo dpkg -i "$TEMP_DEB"
        rm "$TEMP_DEB"
        echo "libdisplay-info3 installed successfully"
    else
        echo "Warning: Could not find libdisplay-info3 package, trying apt install..."
        sudo apt install -y --no-install-recommends libdisplay-info3 || echo "Failed to install libdisplay-info3"
    fi

    LIBDISPLAY_DEV_URL=$(echo "$LIBDISPLAY_LISTING" | grep -oP 'libdisplay-info-dev_[^"]+_amd64\.deb' | sort -V | tail -1)
    if [ -n "$LIBDISPLAY_DEV_URL" ]; then
        TEMP_DEB=$(mktemp)
        wget -O "$TEMP_DEB" "${LIBDISPLAY_POOL}${LIBDISPLAY_DEV_URL}"
        sudo dpkg -i "$TEMP_DEB"
        rm "$TEMP_DEB"
        echo "libdisplay-info-dev installed successfully"
    else
        echo "Warning: Could not find libdisplay-info-dev package, trying apt install..."
        sudo apt install -y --no-install-recommends libdisplay-info-dev || echo "Failed to install libdisplay-info-dev"
    fi

    # Install Rust toolchain
    echo "Installing Rust toolchain..."
    if ! command -v rustc &> /dev/null; then
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain stable
        source "$HOME/.cargo/env"
        echo "Rust toolchain installed successfully"
    else
        echo "Rust already installed, updating..."
        rustup update stable
        rustup default stable
    fi

    # Install just (build tool required by Noctalia)
    echo "Installing just..."
    cargo install just
    echo "just installed successfully"

    echo "System dependencies installed successfully!"
fi

# Install Niri (build from source)
if [ "$INSTALL_NIRI" = true ]; then
    echo ""
    echo "[2/4] Niri compositor"
fi
if [ "$INSTALL_NIRI" = true ] && ask_skip "Niri compositor (build from source)"; then
    echo "Building and installing Niri from source..."

    # Ensure Rust is in PATH
    if [ -f "$HOME/.cargo/env" ]; then
        source "$HOME/.cargo/env"
    fi

    cd "$TEMP_DIR"
    git clone --depth=1 https://github.com/YaLTeR/niri.git
    cd niri

    echo "Building Niri (this may take several minutes)..."
    cargo build --release

    echo "Installing Niri..."
    sudo install -Dm755 target/release/niri /usr/local/bin/niri
    sudo install -Dm644 resources/niri-session /usr/local/bin/niri-session
    sudo install -Dm644 resources/niri-portals.conf /usr/share/xdg-desktop-portal/portals/niri-portals.conf

    # Verify installation
    if command -v niri &> /dev/null; then
        echo "Niri installed successfully → /usr/local/bin/niri"
        niri --version
    else
        echo "Error: Niri installation failed"
        exit 1
    fi

    echo ""
    echo "Applying the standard niri config"
    mkdir -p ~/.config/niri
    cp "$SCRIPT_DIR/config.kdl" ~/.config/niri/config.kdl
    echo "File config.kdl copied into ~/.config/niri "
fi

# Install Noctalia
if [ "$INSTALL_NOCTALIA" = true ]; then
    echo ""
    echo "[3/4] Noctalia"
fi
if [ "$INSTALL_NOCTALIA" = true ] && ask_skip "Noctalia"; then
    echo "Building and installing Noctalia from source..."

    cd "$TEMP_DIR"
    git clone --depth=1 https://github.com/noctalia-dev/noctalia.git
    cd noctalia

    just configure release
    just build release
    sudo env PATH="$PATH" just install release

    # Verify installation
    if command -v noctalia &> /dev/null; then
        echo "Noctalia installed successfully!"
        noctalia --version
    else
        echo "Error: Noctalia installation failed"
        exit 1
    fi
fi

# Install Noctalia Greeter
if [ "$INSTALL_NOCTALIA_GREETER" = true ]; then
    echo ""
    echo "[4/4] Noctalia Greeter"
fi
if [ "$INSTALL_NOCTALIA_GREETER" = true ] && ask_skip "Noctalia Greeter"; then
    if ! pkg-config --exists wlroots-${WLROOTS_VERSION}; then
        echo ""
        echo "Error: wlroots-${WLROOTS_VERSION} development files not found."
        echo "Run step [1] first to install system dependencies,"
        echo "or install manually: sudo apt install libwlroots-${WLROOTS_VERSION}-dev"
        exit 1
    fi

    echo "Building and installing Noctalia Greeter from source..."

    cd "$TEMP_DIR"
    git clone --depth=1 https://github.com/noctalia-dev/noctalia-greeter.git
    cd noctalia-greeter

    just configure-release
    just build-release
    sudo meson install -C build-release
    sudo ./scripts/setup_greeter_system.sh

    echo "Noctalia Greeter installed successfully!"
fi

# Cleanup
if [ -n "$TEMP_DIR" ] && [ -d "$TEMP_DIR" ]; then
    rm -rf "$TEMP_DIR"
fi

# Apply niri configuration (only if niri was installed)
if [ "$INSTALL_NIRI" = true ]; then
    echo ""
    if [ -f "$SCRIPT_DIR/config.kdl" ]; then
        read -p "Do you want to apply the niri configuration (config.kdl)? (Y/n): " config_response
        config_response=${config_response:-Y}
        if [[ "$config_response" =~ ^[Yy]$ ]]; then
            mkdir -p ~/.config/niri
            cp "$SCRIPT_DIR/config.kdl" ~/.config/niri/config.kdl
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
    read -p "Type 'yes' to confirm removal: " confirm

    if [ "$confirm" = "yes" ]; then
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

    wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > "$SCRIPT_DIR/packages.microsoft.gpg"
    sudo install -D -o root -g root -m 644 "$SCRIPT_DIR/packages.microsoft.gpg" /etc/apt/keyrings/packages.microsoft.gpg
    echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" | sudo tee /etc/apt/sources.list.d/vscode.list > /dev/null
    rm -f "$SCRIPT_DIR/packages.microsoft.gpg"

    sudo apt update
    sudo apt install -y --no-install-recommends code

    # Copy desktop file and add Wayland flag
    mkdir -p ~/.local/share/applications
    cp /usr/share/applications/code.desktop ~/.local/share/applications/
    sed -i 's/^Exec=\/usr\/share\/code\/code/Exec=\/usr\/share\/code\/code --enable-features=UseOzonePlatform --ozone-platform=wayland/' ~/.local/share/applications/code.desktop

    # Add shell alias
    if [ -f ~/.bashrc ]; then
        if ! grep -q "alias code=" ~/.bashrc; then
            echo "alias code='code --enable-features=UseOzonePlatform --ozone-platform=wayland'" >> ~/.bashrc
        fi
    fi
    if [ -f ~/.zshrc ]; then
        if ! grep -q "alias code=" ~/.zshrc; then
            echo "alias code='code --enable-features=UseOzonePlatform --ozone-platform=wayland'" >> ~/.zshrc
        fi
    fi

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
    read -p "Do you want to change your default shell to zsh? (Y/n): " zsh_response
    zsh_response=${zsh_response:-Y}
    if [[ "$zsh_response" =~ ^[Yy]$ ]]; then
        chsh -s $(which zsh)
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

    # Add user to groups
    sudo usermod -aG netdev,bluetooth,video "$USER"
    echo "Added $USER to groups: netdev, bluetooth, video"

    # Update NetworkManager configuration
    echo "Configuring NetworkManager..."
    sudo mkdir -p /etc/NetworkManager/conf.d/
    echo -e "[main]\nplugins=ifupdown,keyfile\n\n[ifupdown]\nmanaged=true" | sudo tee /etc/NetworkManager/conf.d/10-globally-managed-devices.conf > /dev/null

    # Comment out wlan0 in /etc/network/interfaces
    if [ -f /etc/network/interfaces ]; then
        sudo cp /etc/network/interfaces /etc/network/interfaces.backup
        sudo sed -i '/wlan0/s/^/# /' /etc/network/interfaces
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
    mkdir -p ~/.local/bin
    cat > ~/.local/bin/noctalia-random-wallpaper.sh << 'WALLPAPER_EOF'
#!/bin/bash
# Random wallpaper changer for Noctalia
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

    chmod +x ~/.local/bin/noctalia-random-wallpaper.sh

    # Create systemd service
    mkdir -p ~/.config/systemd/user
    cat > ~/.config/systemd/user/noctalia-wallpaper.service << 'SERVICE_EOF'
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
    cat > ~/.config/systemd/user/noctalia-wallpaper.timer << 'TIMER_EOF'
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
    
    # Create the desktop entry file
    sudo tee /usr/share/wayland-sessions/niri.desktop > /dev/null << 'DESKTOP_EOF'
[Desktop Entry]
Name=Niri
Comment=A scrollable-tiling Wayland compositor
Exec=niri
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
    sudo apt install -y --no-install-recommends ffmpeg 7zip jq poppler-utils fd-find ripgrep fzf zoxide imagemagick

    # Ensure Rust is in PATH
    if [ -f "$HOME/.cargo/env" ]; then
        source "$HOME/.cargo/env"
    fi

    YAZI_TEMP=$(mktemp -d)
    git clone --depth=1 https://github.com/sxyazi/yazi.git "$YAZI_TEMP/yazi"
    cd "$YAZI_TEMP/yazi"

    echo "Building yazi (this may take several minutes)..."
    cargo build --release --locked

    sudo install -Dm755 target/release/yazi /usr/local/bin/yazi
    sudo install -Dm755 target/release/ya /usr/local/bin/ya

    cd ~
    rm -rf "$YAZI_TEMP"

    if command -v yazi &> /dev/null; then
        echo "Yazi installed successfully → /usr/local/bin/yazi"
        yazi --version
    else
        echo "Error: Yazi installation failed"
        exit 1
    fi
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
    FONT_TMP=$(mktemp -d)
    wget -O "$FONT_TMP/0xProto.zip" "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/0xProto.zip"
    unzip -o "$FONT_TMP/0xProto.zip" "*.ttf" -d "$FONT_DIR"
    rm -rf "$FONT_TMP"

    echo "Rebuilding font cache..."
    fc-cache -fv

    echo "Applying font to alacritty configuration..."
    ALACRITTY_CONF="$HOME/.config/alacritty/alacritty.toml"
    mkdir -p "$HOME/.config/alacritty"
    if [ -f "$ALACRITTY_CONF" ]; then
        # Remove any existing [font] section and its keys
        python3 - "$ALACRITTY_CONF" <<'PYEOF'
import re, sys
path = sys.argv[1]
with open(path, 'r') as f:
    content = f.read()
# Remove existing [font] section (section ends at next [header] or EOF)
content = re.sub(r'\[font\][^\[]*', '', content, flags=re.DOTALL)
content = content.rstrip() + '\n'
with open(path, 'w') as f:
    f.write(content)
PYEOF
        cat >> "$ALACRITTY_CONF" << 'FONT_EOF'

[font]
size = 10.0

[font.normal]
family = "0xProto Nerd Font Mono"
style = "Regular"
FONT_EOF
    else
        cat > "$ALACRITTY_CONF" << 'FONT_EOF'
[font]
size = 10.0

[font.normal]
family = "0xProto Nerd Font Mono"
style = "Regular"
FONT_EOF
    fi

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

    echo "Downloading latest stable Neovim..."
    NVIM_TMP=$(mktemp -d)
    wget -O "$NVIM_TMP/nvim.tar.gz" "https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz"
    sudo tar -C /usr/local -xzf "$NVIM_TMP/nvim.tar.gz" --strip-components=1
    rm -rf "$NVIM_TMP"

    if ! command -v nvim &> /dev/null; then
        echo "Error: Neovim installation failed"
        exit 1
    fi
    echo "Neovim installed → $(command -v nvim)"
    nvim --version | head -1

    echo "Creating Neovim configuration with lazy.nvim and oil.nvim..."
    mkdir -p "$HOME/.config/nvim"
    cat > "$HOME/.config/nvim/init.lua" << 'NVIM_EOF'
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
