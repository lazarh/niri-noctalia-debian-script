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
    libdisplay-info-dev

# 3. Install Rust (if not present)
# Based on your log lines 784-785
echo -e "${GREEN}[3/5] Checking Rust installation...${RESET}"
if ! command -v cargo &> /dev/null; then
    echo "Rust not found. Installing via rustup..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    
    # Source the environment for the current script execution
    source "$HOME/.cargo/env"
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
echo "Binary location: $HOME/.cargo/bin/niri"
