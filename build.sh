#!/bin/bash

# Stop the script if any command fails
set -e

# Visual formatting
BOLD="\e[1m"
GREEN="\e[32m"
RESET="\e[0m"

# Record the directory where the script was invoked so config copying works
START_DIR="$(pwd)"

echo -e "${BOLD}Starting Niri Installation for Debian 13...${RESET}"

# 1. Update Repositories
echo -e "${GREEN}[1/5] Updating package lists...${RESET}"
sudo apt update

# 2. Install Dependencies
# Based on your log line 802, plus 'git', 'curl', 'pkg-config' and 'build-essential'
# which are required for the build process to find the libraries.
echo -e "${GREEN}[2/5] Installing system dependencies...${RESET}"
sudo apt install -y \
    git \
    curl \
    build-essential \
    pkg-config \
    gcc \
    clang \
    libxcb1-dev \
    libxcb-cursor-dev \
    libxcb-composite0-dev \
    libxcb-xfixes0-dev \
    libudev-dev \
    libgbm-dev \
    libxkbcommon-dev \
    libegl1-mesa-dev \
    libwayland-dev \
    libinput-dev \
    libdbus-1-dev \
    libsystemd-dev \
    libseat-dev \
    libpipewire-0.3-dev \
    libpango1.0-dev \
    libdisplay-info-dev \
    fuzzel \
    alacritty

# 3. Install Rust (if not present)
# Based on your log lines 784-785
echo -e "${GREEN}[3/5] Checking Rust installation...${RESET}"
if ! command -v cargo &> /dev/null; then
    echo "Rust not found. Installing via rustup..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    
    # Source the environment for the current script execution (POSIX dot for sh compatibility)
    if [ -f "$HOME/.cargo/env" ]; then
        . "$HOME/.cargo/env"
    fi
else
    echo "Rust is already installed."
fi

# 4. Clone or Update Niri
echo -e "${GREEN}[4/5] Fetching Niri source code...${RESET}"
TARGET_DIR="$HOME/Documents/git"

# Create directory if it doesn't exist
mkdir -p "$TARGET_DIR"
cd "$TARGET_DIR"

if [ -d "niri" ]; then
    echo "Niri repository exists. Pulling latest changes..."
    cd niri
    git pull
else
    echo "Cloning Niri repository..."
    git clone https://github.com/YaLTeR/niri.git
    cd niri
fi

# 5. Build Niri
# We use --release because debug builds (default 'cargo build') are too slow for daily usage
echo -e "${GREEN}[5/5] Building Niri (Release Mode)...${RESET}"
cargo build --release --locked

# Optional: Install the binary to ~/.cargo/bin so you can run it from anywhere
echo -e "${GREEN}Installing binary to ~/.cargo/bin...${RESET}"
cargo install --path . --locked

# Install xwayland-satellite (required by newer Niri features)
echo -e "${GREEN}[X/6] Installing xwayland-satellite (rootless Xwayland helper)...${RESET}"
XWS_DIR="$TARGET_DIR/xwayland-satellite"
if [ -d "$XWS_DIR" ]; then
    echo "xwayland-satellite directory exists. Pulling latest changes..."
    cd "$XWS_DIR"
    git pull || true
else
    echo "Cloning xwayland-satellite..."
    git clone https://github.com/Supreeeme/xwayland-satellite.git "$XWS_DIR"
    cd "$XWS_DIR"
fi

# Build as the invoking user if script was run with sudo, otherwise as current user
if [ -n "${SUDO_USER:-}" ]; then
    echo "Building xwayland-satellite as user: $SUDO_USER"
    sudo -u "$SUDO_USER" -H bash -lc "cd '$XWS_DIR' && cargo build --release --locked"
else
    echo "Building xwayland-satellite as current user"
    cargo build --release --locked
fi

# Install the binary to /usr/local/bin so it's available in PATH
if [ -f "$XWS_DIR/target/release/xwayland-satellite" ]; then
    echo "Installing xwayland-satellite to /usr/local/bin"
    sudo cp "$XWS_DIR/target/release/xwayland-satellite" /usr/local/bin/
    sudo chmod 755 /usr/local/bin/xwayland-satellite || true
else
    echo "Warning: built xwayland-satellite binary not found; skipping install"
fi

# 6. Setup Configuration
echo -e "${GREEN}[6/6] Setting up configuration...${RESET}"
# Create the config directory if it doesn't exist
mkdir -p "$HOME/.config/niri"

# Check if config.kdl exists in the folder where script was launched
if [ -f "$START_DIR/config.kdl" ]; then
    echo "Copying config.kdl from current folder..."
    cp "$START_DIR/config.kdl" "$HOME/.config/niri/config.kdl"
else
    echo "No 'config.kdl' found in $START_DIR. Skipping config copy."
fi

echo -e "${BOLD}${GREEN}Success! Niri has been installed.${RESET}"
echo "You can start it by running: niri"
echo "Binary location (user): $HOME/.cargo/bin/niri"

# Copy user binary to system-wide location so display managers can exec it
# Determine source binary based on invoking user (respect SUDO_USER)
if [ -n "${SUDO_USER:-}" ]; then
    SOURCE_HOME=$(eval echo "~$SUDO_USER")
else
    SOURCE_HOME="$HOME"
fi
SOURCE_BINARY="$SOURCE_HOME/.cargo/bin/niri"
if [ -f "$SOURCE_BINARY" ]; then
    echo "Copying $SOURCE_BINARY to /usr/local/bin/niri (requires sudo)..."
    sudo cp "$SOURCE_BINARY" /usr/local/bin/niri
    sudo chmod 755 /usr/local/bin/niri || true
    echo "Installed system binary: /usr/local/bin/niri"
else
    echo "Warning: $SOURCE_BINARY not found; skipping system-wide install. You may need to copy it manually."
fi

# Create a Wayland session desktop file so display managers can start Niri
# The desktop file should point to the installed binary in the user's cargo bin.
DESKTOP_PATH="/usr/share/wayland-sessions/niri.desktop"
# Determine target user/home: prefer SUDO_USER if present
if [ -n "${SUDO_USER:-}" ]; then
    TARGET_USER="$SUDO_USER"
    TARGET_HOME=$(eval echo "~$TARGET_USER")
else
    TARGET_USER="$USER"
    TARGET_HOME="$HOME"
fi

# Use the system-wide binary if available 
BINARY_PATH="/usr/local/bin/niri"

echo "Creating Wayland session file at $DESKTOP_PATH (Exec -> $BINARY_PATH)"
sudo tee "$DESKTOP_PATH" > /dev/null <<EOF
[Desktop Entry]
Name=Niri
Comment=Niri Wayland session
Exec=$BINARY_PATH
TryExec=$BINARY_PATH
Type=Application
DesktopNames=Wayland
X-LightDM-Seat=seat0
EOF

sudo chmod 644 "$DESKTOP_PATH" || true

echo "Installed Wayland session file: $DESKTOP_PATH"
