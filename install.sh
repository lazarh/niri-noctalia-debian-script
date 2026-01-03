#!/bin/bash

set -e  # Exit on error

# Check for --ask-step parameter
ASK_STEP=false
if [[ "$1" == "--ask-step" ]]; then
    ASK_STEP=true
fi

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

echo "================================================"
echo "Niri + Quickshell + Noctalia Installation Script"
echo "================================================"
if [ "$ASK_STEP" = true ]; then
    echo "Running in interactive mode (--ask-step)"
fi

# Update package list and install dependencies
echo ""
echo "[1/5] System dependencies"
if ask_skip "system dependencies (build tools, Qt6, and quickshell prerequisites)"; then
    sudo apt update
    sudo apt install -y sudo gpg curl git cmake ninja-build build-essential systemd-resolved \
        qt6-base-dev qt6-base-private-dev qt6-declarative-dev qt6-declarative-private-dev \
        qt6-wayland-dev qt6-wayland-private-dev \
        qt6-shadertools-dev spirv-tools pkg-config libcli11-dev \
        wayland-protocols libwayland-dev libdrm-dev libgbm-dev libegl1-mesa-dev \
        libpolkit-agent-1-dev libjemalloc-dev libpam0g-dev gh
    
    # Ask if user wants to reboot due to systemd-resolved
    echo ""
    read -p "systemd-resolved was installed. Do you want to reboot now? (y/N): " reboot_response
    reboot_response=${reboot_response:-N}
    if [[ "$reboot_response" =~ ^[Yy]$ ]]; then
        echo "Rebooting system..."
        sudo reboot
    else
        echo "Continuing installation (you may need to reboot later)..."
    fi
    
    # Check GitHub authentication
    echo ""
    if ! gh auth status &>/dev/null; then
        read -p "GitHub CLI is not authenticated. Do you want to login now? (Y/n): " gh_response
        gh_response=${gh_response:-Y}
        if [[ "$gh_response" =~ ^[Yy]$ ]]; then
            gh auth login
        else
            echo "Skipping GitHub authentication (you can run 'gh auth login' later)..."
        fi
    else
        echo "GitHub CLI is already authenticated."
    fi
fi

# Install Pacstall package manager
echo ""
echo "[2/5] Pacstall package manager"
if ask_skip "Pacstall package manager"; then
    bash -c "$(curl -fsSL https://pacstall.dev/q/ppr)"
    sudo apt update
    sudo apt install -y pacstall
fi

# Install niri using Pacstall
echo ""
echo "[3/5] Niri compositor"
if ask_skip "niri compositor"; then
    pacstall -I niri
fi

# Build and install quickshell
echo ""
echo "[4/5] Quickshell"
if ask_skip "quickshell (will be built from source)"; then
    TEMP_DIR=$(mktemp -d)
    cd "$TEMP_DIR"
    git clone https://git.outfoxxed.me/quickshell/quickshell
    cd quickshell
    cmake -B build -G Ninja -DCRASH_REPORTER=OFF
    cmake --build build
    sudo cmake --install build
    quickshell --version
    cd ~
fi

# Clone noctalia-shell configuration
echo ""
echo "[5/5] Noctalia-shell configuration"
if ask_skip "noctalia-shell configuration"; then
    mkdir -p ~/.config/quickshell
    git clone https://github.com/noctalia-dev/noctalia-shell ~/.config/quickshell/noctalia-shell
fi

# Cleanup
if [ -n "$TEMP_DIR" ] && [ -d "$TEMP_DIR" ]; then
    rm -rf "$TEMP_DIR"
fi

# Apply niri configuration
echo ""
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
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

echo ""
echo "================================================"
echo "Installation complete!"
echo "================================================"
echo "You can now start niri with: niri"
