#!/bin/bash

set -e  # Exit on error

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
                echo "Error: --upgrade requires an argument (niri, quickshell, noctalia, or all)"
                exit 1
            fi
            ;;
        --install-wallpaper)
            INSTALL_WALLPAPER=true
            shift
            ;;
        --help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --ask-step        Interactive mode - prompt before each core installation step"
            echo "  --menu            Show interactive menu to select components"
            echo "  --upgrade <type>  Upgrade components: niri, quickshell, noctalia, or all"
            echo "  --install-vscode  Install Visual Studio Code with Wayland support"
            echo "  --install-omz     Install Oh My Zsh"
            echo "  --install-docs    Install zathura and loupe (document viewers)"
            echo "  --install-office  Install patat, gnumeric, and abiword"
            echo "  --apply-fixes     Apply network & hardware fixes (NetworkManager, firmware, etc.)"
            echo "  --remove-gnome    Remove GDM3 and GNOME packages (WARNING: removes desktop environment)"
            echo "  --install-wallpaper Install random wallpaper changer (systemd timer)"
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
    echo "  [1] System dependencies (build tools, Qt6)"
    echo "  [2] Pacstall package manager"
    echo "  [3] Niri compositor"
    echo "  [4] Quickshell"
    echo "  [5] Noctalia-shell configuration"
    echo ""
    echo "Upgrade Options:"
    echo "  [U1] Upgrade Niri"
    echo "  [U2] Upgrade Quickshell"
    echo "  [U3] Upgrade Noctalia-shell"
    echo "  [UA] Upgrade all (Niri + Quickshell + Noctalia)"
    echo ""
    echo "Optional Components:"
    echo "  [6] Visual Studio Code (with Wayland support)"
    echo "  [7] Oh My Zsh"
    echo "  [8] Document viewers (zathura, loupe)"
    echo "  [9] Office tools (patat, gnumeric, abiword)"
    echo "  [10] Network & hardware fixes"
    echo "  [11] Remove GNOME/GDM3 (WARNING: removes desktop)"
    echo "  [12] Random wallpaper changer (systemd timer)"
    echo ""
    echo "  [A] Install all core components (1-5)"
    echo "  [Q] Quit"
    echo ""
    read -p "Select components (space-separated numbers, e.g., '1 2 3 6'): " selections
    
    # Parse selections
    for selection in $selections; do
        case $selection in
            1) INSTALL_DEPS=true ;;
            2) INSTALL_PACSTALL=true ;;
            3) INSTALL_NIRI=true ;;
            4) INSTALL_QUICKSHELL=true ;;
            5) INSTALL_NOCTALIA=true ;;
            6) INSTALL_VSCODE=true ;;
            7) INSTALL_OMZ=true ;;
            8) INSTALL_DOCS=true ;;
            9) INSTALL_OFFICE=true ;;
            10) APPLY_FIXES=true ;;
            11) REMOVE_GNOME=true ;;
            [Uu]1) UPGRADE_MODE="niri" ;;
            [Uu]2) UPGRADE_MODE="quickshell" ;;
            [Uu]3) UPGRADE_MODE="noctalia" ;;
            [Uu][Aa]) UPGRADE_MODE="all" ;;
            12) INSTALL_WALLPAPER=true ;;
            [Aa]) 
                INSTALL_DEPS=true
                INSTALL_PACSTALL=true
                INSTALL_NIRI=true
                INSTALL_QUICKSHELL=true
                INSTALL_NOCTALIA=true
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
INSTALL_PACSTALL=false
INSTALL_NIRI=false
INSTALL_QUICKSHELL=false
INSTALL_NOCTALIA=false

# Show menu if requested, otherwise enable all core components by default
if [ "$SHOW_MENU" = true ]; then
    show_interactive_menu
else
    # Default: install all core components unless using --ask-step or --upgrade
    if [ -z "$UPGRADE_MODE" ]; then
        INSTALL_DEPS=true
        INSTALL_PACSTALL=true
        INSTALL_NIRI=true
        INSTALL_QUICKSHELL=true
        INSTALL_NOCTALIA=true
    fi
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

# Handle upgrade mode
if [ -n "$UPGRADE_MODE" ]; then
    echo "================================================"
    echo "Niri + Quickshell + Noctalia Upgrade Script"
    echo "================================================"
    echo "Upgrade mode: $UPGRADE_MODE"
    echo ""
    
    case "$UPGRADE_MODE" in
        niri)
            echo "Upgrading Niri..."
            pacstall -I niri
            echo "Niri upgrade complete!"
            ;;
        quickshell)
            echo "Upgrading Quickshell..."
            TEMP_DIR=$(mktemp -d)
            cd "$TEMP_DIR"
            git clone https://git.outfoxxed.me/quickshell/quickshell
            cd quickshell
            cmake -B build -G Ninja -DCRASH_REPORTER=OFF
            cmake --build build
            sudo cmake --install build
            quickshell --version
            cd ~
            rm -rf "$TEMP_DIR"
            echo "Quickshell upgrade complete!"
            ;;
        noctalia)
            echo "Upgrading Noctalia-shell..."
            if [ -d ~/.config/quickshell/noctalia-shell ]; then
                cd ~/.config/quickshell/noctalia-shell
                git pull
                echo "Noctalia-shell upgrade complete!"
            else
                echo "Error: Noctalia-shell not found at ~/.config/quickshell/noctalia-shell"
                echo "Please install it first using the installation script."
                exit 1
            fi
            ;;
        all)
            echo "Upgrading all components (Niri + Quickshell + Noctalia)..."
            echo ""
            
            echo "[1/3] Upgrading Niri..."
            pacstall -I niri
            echo "Niri upgrade complete!"
            echo ""
            
            echo "[2/3] Upgrading Quickshell..."
            TEMP_DIR=$(mktemp -d)
            cd "$TEMP_DIR"
            git clone https://git.outfoxxed.me/quickshell/quickshell
            cd quickshell
            cmake -B build -G Ninja -DCRASH_REPORTER=OFF
            cmake --build build
            sudo cmake --install build
            quickshell --version
            cd ~
            rm -rf "$TEMP_DIR"
            echo "Quickshell upgrade complete!"
            echo ""
            
            echo "[3/3] Upgrading Noctalia-shell..."
            if [ -d ~/.config/quickshell/noctalia-shell ]; then
                cd ~/.config/quickshell/noctalia-shell
                git pull
                echo "Noctalia-shell upgrade complete!"
            else
                echo "Warning: Noctalia-shell not found at ~/.config/quickshell/noctalia-shell"
                echo "Skipping noctalia-shell upgrade."
            fi
            echo ""
            
            echo "All components upgraded successfully!"
            ;;
        *)
            echo "Error: Invalid upgrade type '$UPGRADE_MODE'"
            echo "Valid options: niri, quickshell, noctalia, all"
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
echo "Niri + Quickshell + Noctalia Installation Script"
echo "================================================"
if [ "$ASK_STEP" = true ]; then
    echo "Running in interactive mode (--ask-step)"
fi

# Update package list and install dependencies
if [ "$INSTALL_DEPS" = true ]; then
    echo ""
    echo "[1/5] System dependencies"
fi
if [ "$INSTALL_DEPS" = true ] && ask_skip "system dependencies (build tools, Qt6, and quickshell prerequisites)"; then
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
if [ "$INSTALL_PACSTALL" = true ]; then
    echo ""
    echo "[2/5] Pacstall package manager"
fi
if [ "$INSTALL_PACSTALL" = true ] && ask_skip "Pacstall package manager"; then
    bash -c "$(curl -fsSL https://pacstall.dev/q/ppr)"
    sudo apt update
    sudo apt install -y pacstall
fi

# Install niri using Pacstall
if [ "$INSTALL_NIRI" = true ]; then
    echo ""
    echo "[3/5] Niri compositor"
fi
if [ "$INSTALL_NIRI" = true ] && ask_skip "niri compositor"; then
    pacstall -I niri
fi

# Build and install quickshell
if [ "$INSTALL_QUICKSHELL" = true ]; then
    echo ""
    echo "[4/5] Quickshell"
fi
if [ "$INSTALL_QUICKSHELL" = true ] && ask_skip "quickshell (will be built from source)"; then
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
if [ "$INSTALL_NOCTALIA" = true ]; then
    echo ""
    echo "[5/5] Noctalia-shell configuration"
fi
if [ "$INSTALL_NOCTALIA" = true ] && ask_skip "noctalia-shell configuration"; then
    mkdir -p ~/.config/quickshell
    git clone https://github.com/noctalia-dev/noctalia-shell ~/.config/quickshell/noctalia-shell
fi

# Cleanup
if [ -n "$TEMP_DIR" ] && [ -d "$TEMP_DIR" ]; then
    rm -rf "$TEMP_DIR"
fi

# Apply niri configuration (only if niri was installed)
if [ "$INSTALL_NIRI" = true ]; then
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
fi

# Optional: Remove GNOME/GDM3
if [ "$REMOVE_GNOME" = true ]; then
    echo ""
    echo "================================================"
    echo "WARNING: Remove GNOME and GDM3"
    echo "================================================"
    echo "This will remove GDM3 and GNOME packages, set"
    echo "multi-user target, and reboot to console mode."
    echo ""
    read -p "Are you SURE you want to continue? (type 'yes' to confirm): " confirm
    if [[ "$confirm" == "yes" ]]; then
        sudo systemctl stop gdm3 || true
        sudo apt purge -y gnome-core gnome-shell gdm3 gnome-session gnome-settings-daemon gnome-terminal
        sudo apt autoremove --purge -y
        sudo systemctl set-default multi-user.target
        echo "GNOME and GDM3 removed. System will boot to console."
    else
        echo "Skipping GNOME removal."
    fi
fi

# Optional: Install Visual Studio Code
if [ "$INSTALL_VSCODE" = true ]; then
    echo ""
    echo "================================================"
    echo "Installing Visual Studio Code"
    echo "================================================"
    sudo apt install -y wget gpg apt-transport-https
    
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    if [ ! -f "$SCRIPT_DIR/packages.microsoft.gpg" ]; then
        wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > "$SCRIPT_DIR/packages.microsoft.gpg"
    fi
    
    sudo install -D -o root -g root -m 644 "$SCRIPT_DIR/packages.microsoft.gpg" /etc/apt/keyrings/packages.microsoft.gpg
    echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" | sudo tee /etc/apt/sources.list.d/vscode.list > /dev/null
    sudo apt update
    sudo apt install -y code
    
    # Copy desktop file and add Wayland flag
    mkdir -p ~/.local/share/applications
    cp /usr/share/applications/code.desktop ~/.local/share/applications/
    sed -i 's|^Exec=/usr/share/code/code|Exec=/usr/share/code/code --ozone-platform=wayland|g' ~/.local/share/applications/code.desktop
    
    # Add alias to shell configs
    for rc_file in ~/.bashrc ~/.zshrc; do
        if [ -f "$rc_file" ]; then
            if ! grep -q "alias code=" "$rc_file"; then
                echo "" >> "$rc_file"
                echo "# VS Code Wayland support" >> "$rc_file"
                echo "alias code='code --ozone-platform=wayland'" >> "$rc_file"
            fi
        fi
    done
    
    echo "VS Code installed with Wayland support."
    echo "Note: Alias added to ~/.bashrc and ~/.zshrc (restart shell to use)"
fi

# Optional: Install Oh My Zsh
if [ "$INSTALL_OMZ" = true ]; then
    echo ""
    echo "================================================"
    echo "Installing Oh My Zsh"
    echo "================================================"
    sudo apt install -y zsh
    
    # Change default shell
    read -p "Do you want to set zsh as your default shell? (Y/n): " zsh_response
    zsh_response=${zsh_response:-Y}
    if [[ "$zsh_response" =~ ^[Yy]$ ]]; then
        chsh -s "$(which zsh)"
        echo "Default shell changed to zsh (will take effect on next login)"
    fi
    
    # Install Oh My Zsh
    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        echo "Installing Oh My Zsh..."
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
        echo "Oh My Zsh installed."
    else
        echo "Oh My Zsh is already installed."
    fi
fi

# Optional: Install document viewers
if [ "$INSTALL_DOCS" = true ]; then
    echo ""
    echo "================================================"
    echo "Installing Document Viewers"
    echo "================================================"
    sudo apt install -y zathura zathura-pdf-poppler loupe
    echo "Installed: zathura, zathura-pdf-poppler, loupe"
fi

# Optional: Install office tools
if [ "$INSTALL_OFFICE" = true ]; then
    echo ""
    echo "================================================"
    echo "Installing Office Tools"
    echo "================================================"
    sudo apt install -y abiword gnumeric patat
    echo "Installed: abiword, gnumeric, patat"
fi

# Optional: Apply network and hardware fixes
if [ "$APPLY_FIXES" = true ]; then
    echo ""
    echo "================================================"
    echo "Applying Network & Hardware Fixes"
    echo "================================================"
    
    # Install packages
    sudo apt install -y network-manager bluez brightnessctl upower \
        pipewire-audio-client-libraries libpam0g-dev \
        firmware-linux firmware-iwlwifi firmware-realtek \
        wlsunset nwg-look
    
    # Add user to groups
    sudo usermod -aG netdev,bluetooth,video "$USER"
    echo "Added $USER to groups: netdev, bluetooth, video"
    
    # Update NetworkManager configuration
    NM_CONF="/etc/NetworkManager/NetworkManager.conf"
    if [ -f "$NM_CONF" ]; then
        sudo cp "$NM_CONF" "$NM_CONF.backup"
        echo "Backed up $NM_CONF to $NM_CONF.backup"
        
        if grep -q "^managed=false" "$NM_CONF"; then
            sudo sed -i 's/^managed=false/managed=true/' "$NM_CONF"
            echo "Updated NetworkManager to managed=true"
        fi
    fi
    
    # Update network interfaces
    INTERFACES="/etc/network/interfaces"
    if [ -f "$INTERFACES" ]; then
        sudo cp "$INTERFACES" "$INTERFACES.backup"
        echo "Backed up $INTERFACES to $INTERFACES.backup"
        
        if grep -q "allow-hotplug wlan0" "$INTERFACES" || grep -q "iface wlan0" "$INTERFACES"; then
            sudo sed -i '/allow-hotplug wlan0/s/^/# /' "$INTERFACES"
            sudo sed -i '/iface wlan0/s/^/# /' "$INTERFACES"
            echo "Commented out wlan0 entries in $INTERFACES"
        fi
    fi
    
    # Restart NetworkManager
    read -p "Do you want to restart NetworkManager now? (Y/n): " nm_response
    nm_response=${nm_response:-Y}
    if [[ "$nm_response" =~ ^[Yy]$ ]]; then
        sudo systemctl restart NetworkManager
        echo "NetworkManager restarted."
    else
        echo "Remember to restart NetworkManager: sudo systemctl restart NetworkManager"
    fi
    
    echo "Network & hardware fixes applied."
fi

# Optional: Install random wallpaper changer
if [ "$INSTALL_WALLPAPER" = true ]; then
    echo ""
    echo "================================================"
    echo "Installing Random Wallpaper Changer"
    echo "================================================"
    
    # Create directories
    mkdir -p ~/.local/bin
    mkdir -p ~/.config/systemd/user
    
    # Create the wallpaper script
    cat > ~/.local/bin/noctalia-random-wallpaper.sh << 'EOF'
#!/bin/bash
qs -c noctalia-shell ipc call wallpaper random
EOF
    chmod +x ~/.local/bin/noctalia-random-wallpaper.sh
    echo "Created ~/.local/bin/noctalia-random-wallpaper.sh"
    
    # Create systemd service file
    cat > ~/.config/systemd/user/noctalia-wallpaper.service << 'EOF'
[Unit]
Description=Random wallpaper via Noctalia IPC

[Service]
Type=oneshot
ExecStart=%h/.local/bin/noctalia-random-wallpaper.sh
EOF
    echo "Created ~/.config/systemd/user/noctalia-wallpaper.service"
    
    # Create systemd timer file
    cat > ~/.config/systemd/user/noctalia-wallpaper.timer << 'EOF'
[Unit]
Description=Rotate Noctalia wallpaper every 30 minutes

[Timer]
OnBootSec=1min
OnUnitActiveSec=30min
Unit=noctalia-wallpaper.service

[Install]
WantedBy=default.target
EOF
    echo "Created ~/.config/systemd/user/noctalia-wallpaper.timer"
    
    # Enable and start the timer
    systemctl --user daemon-reload
    systemctl --user enable --now noctalia-wallpaper.timer
    echo "Enabled and started noctalia-wallpaper.timer"
    echo "Wallpaper will change every 30 minutes"
fi

# Final message
if [ "$INSTALL_DEPS" = true ] || [ "$INSTALL_PACSTALL" = true ] || [ "$INSTALL_NIRI" = true ] || [ "$INSTALL_QUICKSHELL" = true ] || [ "$INSTALL_NOCTALIA" = true ] || [ "$INSTALL_VSCODE" = true ] || [ "$INSTALL_OMZ" = true ] || [ "$INSTALL_DOCS" = true ] || [ "$INSTALL_OFFICE" = true ] || [ "$APPLY_FIXES" = true ] || [ "$REMOVE_GNOME" = true ] || [ "$INSTALL_WALLPAPER" = true ]; then
    echo ""
    echo "================================================"
    echo "Installation complete!"
    echo "================================================"
    
    if [ "$INSTALL_NIRI" = true ]; then
        echo "You can now start niri with: niri"
    fi
fi
