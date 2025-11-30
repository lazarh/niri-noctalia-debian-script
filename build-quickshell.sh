#!/bin/bash
# Script to install dependencies and build Quickshell on Debian 13 (Trixie)

set -e # Exit immediately if a command exits with a non-zero status.

QUICKSHELL_DIR="quickshell"
BUILD_DIR="build"

echo "--- 1. Installing Essential Build Tools (git, cmake, ninja) ---"
sudo apt update
sudo apt install -y git cmake ninja-build

echo "--- 2. Installing All Required Build Dependencies ---"

# Core Qt6 (Base, Tools, SVG)
# Qt6 Declarative (QML/Quick) & Controls
# Qt6 Graphics & Wayland
# Other Libraries
# Wayland Protocol Headers & Tools

sudo apt install -y \
    qt6-base-dev qt6-base-private-dev qt6-tools-dev qt6-svg-dev \
    qt6-declarative-dev qt6-declarative-private-dev \
    libqt6qmlcompiler6 \
    qt6-shadertools-dev qt6-quick3d-dev qt6-quick3d-private-dev \
    qt6-wayland-dev qt6-wayland-private-dev \
    qml-module-qtquick-privatewidgets \
    libcli11-dev \
    libdrm-dev \
    libpolkit-qt6-1-dev libpolkit-agent-1-dev \
    libjemalloc-dev \
    libpam-dev \
    wayland-protocols \
    librust-wayland-scanner-dev librust-wayland-protocols-dev librust-wayland-commons-dev \
    spirv-tools pkg-config

echo "--- 3. Cloning Quickshell Repository ---"
if [ -d "$QUICKSHELL_DIR" ]; then
    echo "Directory $QUICKSHELL_DIR already exists. Pulling latest changes."
    cd "$QUICKSHELL_DIR"
    git pull
else
    git clone https://github.com/quickshell-mirror/quickshell.git
    cd "$QUICKSHELL_DIR"
fi

echo "--- 4. Cleaning previous build and Configuring with CMake ---"
rm -rf "$BUILD_DIR"
# -DCRASH_REPORTER=OFF is crucial to bypass the missing Breakpad dependency.
cmake -GNinja -B "$BUILD_DIR" -DCMAKE_BUILD_TYPE=RelWithDebInfo -DCRASH_REPORTER=OFF

echo "--- 5. Building Quickshell with Ninja ---"
cmake --build "$BUILD_DIR"

echo "--- 6. Installing Quickshell ---"
# Installs to system directories (usually /usr/local/bin, /usr/local/lib, etc.)
sudo cmake --install "$BUILD_DIR"

echo "--- ✅ Quickshell Build and Installation Complete! ---"
echo "You can now run 'quickshell' (you might need to log out/in or refresh your shell for the new binary to be found)."
