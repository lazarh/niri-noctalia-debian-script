#!/usr/bin/env bash
# install-testing.sh
# 2026 edition — for Debian testing (Trixie)

set -euo pipefail

echo "Updating system and installing build dependencies..."

sudo apt update
sudo apt upgrade -y

# Core build tools + Wayland/Mesa/graphics dependencies + Qt6 for Quickshell
sudo apt install -y \
    git curl wget build-essential pkg-config ninja-build cmake \
    cargo rustc rust-all \
    libwayland-dev wayland-protocols \
    libegl1-mesa-dev libgles2-mesa-dev libgbm-dev libvulkan-dev vulkan-validationlayers \
    libdrm-dev libinput-dev libxkbcommon-dev libudev-dev seatd libpam0g-dev \
    libgtk-3-dev libsystemd-dev \
    qt6-base-dev qt6-declarative-dev qt6-shadertools-dev qt6-wayland-private-dev \
    qt6-svg-dev qt6-svg-plugins libqt6qmlmodels6-extra \
    libpam0g-dev libjemalloc-dev spirv-tools \
    fonts-roboto fonts-font-awesome \
    polkitd  # usually already installed, but just in case

echo "Installing/updating rustup (recommended for latest stable toolchain)..."
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
source "$HOME/.cargo/env"

rustup update stable
rustup default stable

# ────────────────────────────────────────────────
echo "Building & installing Niri (from git main)"
# ────────────────────────────────────────────────

cd /tmp
rm -rf niri
git clone https://github.com/YaLTeR/niri.git
cd niri

cargo build --release

sudo install -Dm755 target/release/niri /usr/local/bin/niri
sudo install -Dm644 resources/niri-session /usr/local/bin/niri-session   # optional helper
sudo install -Dm644 resources/niri-portals.conf /usr/share/xdg-desktop-portal/portals/niri-portals.conf  # optional

echo "Niri binary installed → /usr/local/bin/niri"

# ────────────────────────────────────────────────
echo "Building & installing Quickshell"
# ────────────────────────────────────────────────

cd /tmp
rm -rf quickshell
git clone https://git.outfoxxed.me/quickshell/quickshell.git
cd quickshell

cmake -B build -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr/local
cmake --build build --parallel $(nproc)
sudo cmake --install build

echo "Quickshell installed → /usr/local/bin/quickshell"

# ────────────────────────────────────────────────
echo "Installing Noctalia shell (config/theme for Quickshell)"
# ────────────────────────────────────────────────

mkdir -p ~/.config/quickshell
cd ~/.config/quickshell

rm -rf noctalia-shell
git clone https://github.com/noctalia-dev/noctalia-shell.git

# Most people symlink or rename to make it the default config
ln -sf noctalia-shell/config.qml config.qml   # or just use -c noctalia-shell later

echo "Noctalia cloned → ~/.config/quickshell/noctalia-shell"

# Optional: minimal niri config tweak to work nicely with Noctalia
mkdir -p ~/.config/niri
cat > ~/.config/niri/config.kdl << 'EOF'
// Minimal starting config — you can expand it later
input {
    keyboard {
        xkb {
            layout "us"
        }
    }
}

window-rule {
    geometry-corner-radius 12
    clip-to-geometry true
}

spawn-at-startup "quickshell" "-c" "~/.config/quickshell/noctalia-shell"
EOF

echo "Basic niri config created with Noctalia autostart"

# ────────────────────────────────────────────────
echo "Done! Now try running niri"
# ────────────────────────────────────────────────

cat << 'EOF'

Next steps:

1. From a TTY (Ctrl+Alt+F3), login and run:
   niri

2. Default keys (Super = Mod4/Win key):
   Super ← / →        focus left/right
   Super T            open terminal (you need to install one)
   Super Q            close window
   Super Shift Q      exit niri

3. Recommended extra packages:
   sudo apt install alacritty fuzzel waybar xdg-desktop-portal-gtk xwayland

4. To autostart quickshell differently, edit ~/.config/niri/config.kdl

5. For nicer login → create ~/.config/systemd/user/niri.service

Enjoy your new scrollable-tiling setup ฅ^•ﻌ•^ฅ

EOF
