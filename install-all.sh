#!/usr/bin/env bash

# Combined installer for Niri, xwayland-satellite, Quickshell and Noctalia
# Usage:
#   chmod +x install-all.sh
#   sudo ./install-all.sh    # recommended
# Environment flags:
#   NO_PACSTALL=1    # skip pacstall step
#   NOCTALIA_TARBALL_URL="..."  # optional direct tarball URL for noctalia

set -euo pipefail

BOLD="\e[1m"
GREEN="\e[32m"
RESET="\e[0m"

echo -e "${BOLD}Starting combined installer: Niri + Quickshell + Noctalia + helpers${RESET}"

# Detect invoking (non-root) user when run under sudo
if [ "$(id -u)" -eq 0 ] && [ -n "${SUDO_USER:-}" ]; then
    RUN_AS_ROOT=1
    INVOKING_USER="$SUDO_USER"
    INVOKING_HOME=$(eval echo "~$INVOKING_USER")
    echo "Running as root via sudo; actions that affect user files will run as: $INVOKING_USER"
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

# 1) Update apt and install combined deps
echo -e "${GREEN}[1/6] Updating package lists and installing dependencies...${RESET}"
sudo apt update

# Combined package list: build tools, xcb dev libs, Qt6 devs for Quickshell, and utilities
sudo apt install -y \
    git curl build-essential pkg-config gcc clang cmake ninja-build \
    libxcb1-dev libxcb-cursor-dev libxcb-composite0-dev libxcb-xfixes0-dev \
    libudev-dev libgbm-dev libxkbcommon-dev libegl1-mesa-dev libwayland-dev \
    libinput-dev libdbus-1-dev libsystemd-dev libseat-dev libpipewire-0.3-dev \
    libpango1.0-dev libdisplay-info-dev fuzzel alacritty \
    qt6-base-dev qt6-base-private-dev qt6-tools-dev qt6-svg-dev \
    qt6-declarative-dev qt6-declarative-private-dev libqt6qmlcompiler6 \
    qt6-shadertools-dev qt6-quick3d-dev qt6-quick3d-private-dev \
    qt6-wayland-dev qt6-wayland-private-dev qml-module-qtquick-privatewidgets \
    libcli11-dev libdrm-dev libpolkit-qt6-1-dev libpolkit-agent-1-dev \
    libjemalloc-dev libpam-dev wayland-protocols librust-wayland-scanner-dev \
    librust-wayland-protocols-dev librust-wayland-commons-dev spirv-tools pkg-config \
    gpu-screen-recorder brightnessctl ddcutil cliphist cava wlsunset xdg-desktop-portal python3 evolution-data-server polkit-kde-agent-1 || true

echo -e "${GREEN}[2/6] Ensuring Rust (cargo) is installed for invoking user...${RESET}"
if ! run_user 'command -v cargo >/dev/null 2>&1'; then
    echo "Installing rustup for $INVOKING_USER..."
    if [ "${RUN_AS_ROOT}" -eq 1 ]; then
        sudo -u "$INVOKING_USER" -H bash -lc 'curl --proto "=https" --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y'
    else
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    fi
    # source the cargo env for the current shell if present (best-effort)
    if [ -f "$INVOKING_HOME/.cargo/env" ]; then
        . "$INVOKING_HOME/.cargo/env"
    fi
else
    echo "cargo present for $INVOKING_USER"
fi

# convenience variables
TARGET_DIR="$INVOKING_HOME/Documents/git"
mkdir -p "$TARGET_DIR"

### Niri build (cargo)
echo -e "${GREEN}[3/6] Building Niri (release) as $INVOKING_USER...${RESET}"
if [ -d "$TARGET_DIR/niri" ]; then
    run_user "cd '$TARGET_DIR/niri' && git pull || true"
else
    run_user "cd '$TARGET_DIR' && git clone https://github.com/YaLTeR/niri.git 'niri'"
fi
run_user "cd '$TARGET_DIR/niri' && cargo build --release --locked"
run_user "cd '$TARGET_DIR/niri' && cargo install --path . --locked || true"

# Copy user niri binary to /usr/local/bin so display managers can find it
SOURCE_BINARY="$INVOKING_HOME/.cargo/bin/niri"
if [ -f "$SOURCE_BINARY" ]; then
    echo "Copying $SOURCE_BINARY to /usr/local/bin/niri"
    sudo cp "$SOURCE_BINARY" /usr/local/bin/niri
    sudo chmod 755 /usr/local/bin/niri || true
else
    echo "Warning: $SOURCE_BINARY not found; niri system install skipped"
fi

### xwayland-satellite
echo -e "${GREEN}[4/6] Building and installing xwayland-satellite...${RESET}"
XWS_DIR="$TARGET_DIR/xwayland-satellite"
if [ -d "$XWS_DIR" ]; then
    run_user "cd '$XWS_DIR' && git pull || true"
else
    run_user "cd '$TARGET_DIR' && git clone https://github.com/Supreeeme/xwayland-satellite.git '$XWS_DIR'"
fi
run_user "cd '$XWS_DIR' && cargo build --release --locked"
if [ -f "$INVOKING_HOME/Documents/git/xwayland-satellite/target/release/xwayland-satellite" ]; then
    sudo cp "$INVOKING_HOME/Documents/git/xwayland-satellite/target/release/xwayland-satellite" /usr/local/bin/
    sudo chmod 755 /usr/local/bin/xwayland-satellite || true
fi

### Quickshell (CMake/Ninja)
echo -e "${GREEN}[5/6] Building and installing Quickshell (CMake/Ninja)...${RESET}"
QS_DIR="$TARGET_DIR/quickshell"
if [ -d "$QS_DIR" ]; then
    run_user "cd '$QS_DIR' && git pull || true"
else
    run_user "cd '$TARGET_DIR' && git clone https://github.com/quickshell-mirror/quickshell.git '$QS_DIR'"
fi
run_user "cd '$QS_DIR' && rm -rf build && cmake -GNinja -B build -DCMAKE_BUILD_TYPE=RelWithDebInfo -DCRASH_REPORTER=OFF && cmake --build build"
sudo bash -lc "cd '$QS_DIR' && cmake --install build"

# Optional tools: matugen (cargo) and pacstall step (if not disabled)
echo -e "${GREEN}Installing matugen (cargo) for $INVOKING_USER...${RESET}"
run_user "command -v cargo >/dev/null 2>&1 && cargo install matugen || true"

if [ -z "${NO_PACSTALL:-}" ]; then
    echo -e "${GREEN}Running pacstall installer (optional) to get some packages (as root)...${RESET}"
    sudo bash -c "$(wget -q https://pacstall.dev/q/install -O -)" || true
else
    echo "Skipping pacstall as NO_PACSTALL is set"
fi

### Noctalia installation (release tarball into quickshell config)
echo -e "${GREEN}[6/6] Installing Noctalia shell files into Quickshell config...${RESET}"
DEST_NOCTALIA_DIR="$INVOKING_HOME/.config/quickshell/noctalia-shell"
run_user "mkdir -p '$DEST_NOCTALIA_DIR'"
if [ -n "${NOCTALIA_TARBALL_URL:-}" ]; then
    URL="$NOCTALIA_TARBALL_URL"
else
    URL="https://github.com/noctalia-dev/noctalia-shell/releases/latest/download/noctalia-latest.tar.gz"
fi
echo "Downloading noctalia from: $URL"
run_user "curl -sL '$URL' | tar -xz --strip-components=1 -C '$DEST_NOCTALIA_DIR' || true"

# Ensure config ownership is correct
if [ "${RUN_AS_ROOT}" -eq 1 ]; then
    sudo chown -R "$INVOKING_USER:$INVOKING_USER" "$INVOKING_HOME/.config/quickshell" || true
else
    run_user "chown -R '$INVOKING_USER:$INVOKING_USER' '$INVOKING_HOME/.config/quickshell' || true"
fi

# Create Wayland session file for Niri (system-wide)
DESKTOP_PATH="/usr/share/wayland-sessions/niri.desktop"
echo "Creating Wayland session file at $DESKTOP_PATH -> Exec: /usr/local/bin/niri"
sudo tee "$DESKTOP_PATH" > /dev/null <<EOF
[Desktop Entry]
Name=Niri
Comment=Niri Wayland session
Exec=/usr/local/bin/niri
TryExec=/usr/local/bin/niri
Type=Application
DesktopNames=Wayland
X-LightDM-Seat=seat0
EOF
sudo chmod 644 "$DESKTOP_PATH" || true

echo -e "${BOLD}${GREEN}All done: Niri, xwayland-satellite, Quickshell and Noctalia installation attempted.${RESET}"
echo "If anything failed, inspect output above and run the failing step manually as needed."

exit 0
