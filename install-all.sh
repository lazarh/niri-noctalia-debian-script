#!/usr/bin/env bash

# Combined installer for Niri, xwayland-satellite, Quickshell and Noctalia
# Usage:
#   chmod +x install-all.sh
#   sudo ./install-all.sh    # recommended (or run as root on bare minimum Debian)
# Environment flags:
#   NO_PACSTALL=1              # skip pacstall step
#   NOCTALIA_TARBALL_URL="..." # optional direct tarball URL for noctalia

set -euo pipefail

BOLD="\e[1m"
GREEN="\e[32m"
BLUE="\e[34m"
RESET="\e[0m"

echo -e "${BOLD}Niri + Quickshell + Noctalia Installation Script${RESET}"
echo -e "${BOLD}===============================================${RESET}\n"

# Detect invoking (non-root) user when run under sudo
if [ "$(id -u)" -eq 0 ] && [ -n "${SUDO_USER:-}" ]; then
    RUN_AS_ROOT=1
    INVOKING_USER="$SUDO_USER"
    INVOKING_HOME=$(eval echo "~$INVOKING_USER")
    echo "Running as root via sudo; user actions will run as: $INVOKING_USER"
else
    RUN_AS_ROOT=0
    INVOKING_USER="$USER"
    INVOKING_HOME="$HOME"
fi

# Helper: run a command as the invoking user (preserves home and env)
run_user() {
    if [ "${RUN_AS_ROOT}" -eq 1 ]; then
        sudo -u "$INVOKING_USER" -H bash -lc "$1"
    else
        bash -lc "$1"
    fi
}

# Setup directories
TARGET_DIR="$INVOKING_HOME/Documents/git"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
mkdir -p "$TARGET_DIR"

#==============================================================================
# SECTION 1: PREREQUISITES INSTALLATION
#==============================================================================
echo -e "\n${BOLD}${BLUE}[SECTION 1/3] Installing Prerequisites${RESET}"
echo -e "${BOLD}=======================================${RESET}\n"

# 1.1) Ensure sudo is installed (for bare minimum Debian)
echo -e "${GREEN}[1.1] Checking for sudo...${RESET}"
if ! command -v sudo >/dev/null 2>&1; then
    echo "sudo not found, installing it first..."
    apt update
    apt install -y sudo
    echo "✓ sudo installed successfully"
else
    echo "✓ sudo is already installed"
fi

# 1.2) Update package lists
echo -e "\n${GREEN}[1.2] Updating package lists...${RESET}"
sudo apt update

# 1.3) Install system dependencies
echo -e "\n${GREEN}[1.3] Installing system packages and development libraries...${RESET}"
echo "This may take several minutes..."
sudo apt install -y \
    git curl wget \
    build-essential pkg-config gcc clang cmake ninja-build \
    libxcb1-dev libxcb-cursor-dev libxcb-composite0-dev libxcb-xfixes0-dev \
    libudev-dev libgbm-dev libxkbcommon-dev libegl1-mesa-dev libwayland-dev \
    libinput-dev libdbus-1-dev libsystemd-dev libseat-dev libpipewire-0.3-dev \
    libpango1.0-dev libdisplay-info-dev \
    qt6-base-dev qt6-base-private-dev qt6-tools-dev qt6-svg-dev \
    qt6-declarative-dev qt6-declarative-private-dev libqt6qmlcompiler6 \
    qt6-shadertools-dev qt6-quick3d-dev qt6-quick3d-private-dev \
    qt6-wayland-dev qt6-wayland-private-dev qml-module-qtquick-privatewidgets \
    qt6-multimedia-dev \
    libcli11-dev libdrm-dev libpolkit-qt6-1-dev libpolkit-agent-1-dev \
    libjemalloc-dev libpam-dev wayland-protocols \
    librust-wayland-scanner-dev librust-wayland-protocols-dev librust-wayland-commons-dev \
    spirv-tools python3

echo "✓ System packages installed"

# 1.4) Install Wayland utilities and applications
echo -e "\n${GREEN}[1.4] Installing Wayland utilities and applications...${RESET}"
sudo apt install -y \
    fuzzel alacritty swayidle \
    brightnessctl ddcutil cliphist cava wlsunset \
    xdg-desktop-portal evolution-data-server polkit-kde-agent-1

echo "✓ Wayland utilities installed"

# 1.5) Install Rust toolchain
echo -e "\n${GREEN}[1.5] Installing Rust toolchain for $INVOKING_USER...${RESET}"
if ! run_user 'command -v cargo >/dev/null 2>&1'; then
    echo "Installing rustup..."
    if [ "${RUN_AS_ROOT}" -eq 1 ]; then
        sudo -u "$INVOKING_USER" -H bash -lc 'curl --proto "=https" --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y'
    else
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    fi
    # Source cargo env for current shell
    if [ -f "$INVOKING_HOME/.cargo/env" ]; then
        . "$INVOKING_HOME/.cargo/env"
    fi
    echo "✓ Rust toolchain installed"
else
    echo "✓ Rust toolchain already present"
fi

# 1.6) Optional: Install pacstall
if [ -z "${NO_PACSTALL:-}" ]; then
    echo -e "\n${GREEN}[1.6] Installing pacstall (optional package manager)...${RESET}"
    sudo bash -c "$(wget -q https://pacstall.dev/q/install -O -)" || echo "⚠ Pacstall installation skipped (optional)"
else
    echo -e "\n${GREEN}[1.6] Skipping pacstall (NO_PACSTALL is set)${RESET}"
fi

echo -e "\n${BOLD}✓ Prerequisites installation complete${RESET}"

#==============================================================================
# SECTION 2: DOWNLOAD AND COMPILE PACKAGES
#==============================================================================
echo -e "\n${BOLD}${BLUE}[SECTION 2/3] Downloading and Compiling Packages${RESET}"
echo -e "${BOLD}==================================================${RESET}\n"

# 2.1) Build Niri (Wayland compositor)
echo -e "${GREEN}[2.1] Building Niri...${RESET}"
if [ -d "$TARGET_DIR/niri" ]; then
    run_user "cd '$TARGET_DIR/niri' && git pull || true"
else
    run_user "cd '$TARGET_DIR' && git clone https://github.com/YaLTeR/niri.git 'niri'"
fi
# 2.1) Build Niri (Wayland compositor)
echo -e "${GREEN}[2.1] Building Niri...${RESET}"
if [ -d "$TARGET_DIR/niri" ]; then
    echo "Updating existing Niri repository..."
    run_user "cd '$TARGET_DIR/niri' && git pull || true"
else
    echo "Cloning Niri repository..."
    run_user "cd '$TARGET_DIR' && git clone https://github.com/YaLTeR/niri.git 'niri'"
fi
echo "Compiling Niri (this may take several minutes)..."
run_user "cd '$TARGET_DIR/niri' && cargo build --release --locked"
run_user "cd '$TARGET_DIR/niri' && cargo install --path . --locked || true"
echo "✓ Niri built successfully"

# 2.2) Build xwayland-satellite
echo -e "\n${GREEN}[2.2] Building xwayland-satellite...${RESET}"
XWS_DIR="$TARGET_DIR/xwayland-satellite"
if [ -d "$XWS_DIR" ]; then
    echo "Updating existing xwayland-satellite repository..."
    run_user "cd '$XWS_DIR' && git pull || true"
else
    echo "Cloning xwayland-satellite repository..."
    run_user "cd '$TARGET_DIR' && git clone https://github.com/Supreeeme/xwayland-satellite.git '$XWS_DIR'"
fi
echo "Compiling xwayland-satellite..."
run_user "cd '$XWS_DIR' && cargo build --release --locked"
echo "✓ xwayland-satellite built successfully"

# 2.3) Build Quickshell (CMake/Ninja)
echo -e "\n${GREEN}[2.3] Building Quickshell...${RESET}"
QS_DIR="$TARGET_DIR/quickshell"
if [ -d "$QS_DIR" ]; then
    echo "Updating existing Quickshell repository..."
    run_user "cd '$QS_DIR' && git pull || true"
else
    echo "Cloning Quickshell repository..."
    run_user "cd '$TARGET_DIR' && git clone https://github.com/quickshell-mirror/quickshell.git '$QS_DIR'"
fi
echo "Configuring and compiling Quickshell..."
run_user "cd '$QS_DIR' && rm -rf build && cmake -GNinja -B build -DCMAKE_BUILD_TYPE=RelWithDebInfo -DCRASH_REPORTER=OFF && cmake --build build"
echo "✓ Quickshell built successfully"

# 2.4) Build matugen (theme generator)
echo -e "\n${GREEN}[2.4] Building matugen...${RESET}"
run_user "command -v cargo >/dev/null 2>&1 && cargo install matugen || true"
echo "✓ matugen installed"

# 2.5) Download Noctalia shell theme
echo -e "\n${GREEN}[2.5] Downloading Noctalia shell...${RESET}"
if [ -n "${NOCTALIA_TARBALL_URL:-}" ]; then
    URL="$NOCTALIA_TARBALL_URL"
else
    URL="https://github.com/noctalia-dev/noctalia-shell/releases/latest/download/noctalia-latest.tar.gz"
fi
echo "Downloading from: $URL"
DEST_NOCTALIA_DIR="$INVOKING_HOME/.config/quickshell/noctalia-shell"
run_user "mkdir -p '$DEST_NOCTALIA_DIR'"
run_user "curl -sL '$URL' | tar -xz --strip-components=1 -C '$DEST_NOCTALIA_DIR' || true"
echo "✓ Noctalia downloaded"

echo -e "\n${BOLD}✓ All packages compiled successfully${RESET}"

#==============================================================================
# SECTION 3: POST-INSTALL CONFIGURATION
#==============================================================================
echo -e "\n${BOLD}${BLUE}[SECTION 3/3] Post-Installation Configuration${RESET}"
echo -e "${BOLD}==============================================${RESET}\n"

# 3.1) Install binaries to system paths
echo -e "${GREEN}[3.1] Installing binaries to /usr/local/bin...${RESET}"

# Install Niri
SOURCE_BINARY="$INVOKING_HOME/.cargo/bin/niri"
if [ -f "$SOURCE_BINARY" ]; then
    sudo cp "$SOURCE_BINARY" /usr/local/bin/niri
    sudo chmod 755 /usr/local/bin/niri
    echo "✓ Niri installed to /usr/local/bin/niri"
else
    echo "⚠ Warning: Niri binary not found at $SOURCE_BINARY"
fi

# Install xwayland-satellite
if [ -f "$XWS_DIR/target/release/xwayland-satellite" ]; then
    sudo cp "$XWS_DIR/target/release/xwayland-satellite" /usr/local/bin/
    sudo chmod 755 /usr/local/bin/xwayland-satellite
    echo "✓ xwayland-satellite installed to /usr/local/bin/xwayland-satellite"
else
    echo "⚠ Warning: xwayland-satellite binary not found"
fi

# Install Quickshell
sudo bash -lc "cd '$QS_DIR' && cmake --install build"
echo "✓ Quickshell installed system-wide"

# 3.2) Create Wayland session file
echo -e "\n${GREEN}[3.2] Creating Wayland session file...${RESET}"
DESKTOP_PATH="/usr/share/wayland-sessions/niri.desktop"
sudo mkdir -p /usr/share/wayland-sessions
sudo tee "$DESKTOP_PATH" > /dev/null <<EOF
[Desktop Entry]
Name=Niri
Comment=Niri Wayland Compositor
Exec=/usr/local/bin/niri
TryExec=/usr/local/bin/niri
Type=Application
DesktopNames=Wayland
X-LightDM-Seat=seat0
EOF
sudo chmod 644 "$DESKTOP_PATH"
echo "✓ Session file created at $DESKTOP_PATH"

# 3.3) Configure idle/lock script
echo -e "\n${GREEN}[3.3] Configuring idle and lock scripts...${RESET}"
DEST_IDLE_DIR="$INVOKING_HOME/.config/niri/scripts"
run_user "mkdir -p '$DEST_IDLE_DIR'"
run_user "cat > '$DEST_IDLE_DIR/idle.sh' <<'EOF'
#!/bin/sh
swayidle \
    timeout 300 'swaylock -f -c 000000' \
    timeout 600 'systemctl suspend' \
    before-sleep 'swaylock -f -c 000000'
EOF"
run_user "chmod +x '$DEST_IDLE_DIR/idle.sh'"
echo "✓ Idle script created at ~/.config/niri/scripts/idle.sh"

# Also drop a copy in the script directory for easy editing
if [ -n "${SCRIPT_DIR:-}" ]; then
    cat > "$SCRIPT_DIR/idle.sh" <<'EOF'
#!/bin/sh
swayidle \
    timeout 300 'swaylock -f -c 000000' \
    timeout 600 'systemctl suspend' \
    before-sleep 'swaylock -f -c 000000'
EOF
    chmod +x "$SCRIPT_DIR/idle.sh"
    echo "✓ Idle script copy created at $SCRIPT_DIR/idle.sh"
fi

# 3.4) Set correct file ownership
echo -e "\n${GREEN}[3.4] Setting correct file ownership...${RESET}"
if [ "${RUN_AS_ROOT}" -eq 1 ]; then
    sudo chown -R "$INVOKING_USER:$INVOKING_USER" "$INVOKING_HOME/.config/quickshell" 2>/dev/null || true
    sudo chown -R "$INVOKING_USER:$INVOKING_USER" "$INVOKING_HOME/.config/niri" 2>/dev/null || true
fi
echo "✓ File ownership configured"

#==============================================================================
# INSTALLATION COMPLETE
#==============================================================================
echo -e "\n${BOLD}${GREEN}=========================================${RESET}"
echo -e "${BOLD}${GREEN}Installation Complete!${RESET}"
echo -e "${BOLD}${GREEN}=========================================${RESET}\n"

echo "Installed components:"
echo "  • Niri (Wayland compositor)"
echo "  • xwayland-satellite (XWayland support)"
echo "  • Quickshell (shell framework)"
echo "  • Noctalia (shell theme)"
echo "  • matugen (theme generator)"
echo ""
echo "Next steps:"
echo "  1. Reboot or log out"
echo "  2. Select 'Niri' from your display manager"
echo "  3. Log in to start your Niri session"
echo ""
echo "Configuration files:"
echo "  • Niri config: ~/.config/niri/"
echo "  • Quickshell config: ~/.config/quickshell/"
echo "  • Idle script: ~/.config/niri/scripts/idle.sh"
echo ""

exit 0
