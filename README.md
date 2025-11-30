# Niri — Debian 13 installer

This repository contains a simple `build.sh` script to install and build Niri on Debian 13 systems.

**Quick Summary:**
- **Purpose:** Build and install the Niri compositor on Debian 13.
- **Main script:** `build.sh` — updates apt, installs dependencies, installs Rust if needed, clones/builds Niri and installs the binary.

**Requirements:**
- A Debian 13 system (or compatible Debian-based distribution).
- `sudo` privileges for package installation.
- Optional: `config.kdl` in the repository root if you want the script to copy a default config to `~/.config/niri/config.kdl`.

**Usage:**

1. Make the script executable (if not already):

```
chmod +x build.sh
```

2. Run the installer (recommended from the repository root so `config.kdl` can be detected):

```
sudo ./build.sh
```

Note: `build.sh` will call `sudo` for package installation. It will also attempt to install Rust via `rustup` if `cargo` isn't found.

**Where it places files:**
- Niri source is cloned to `~/Documents/git/niri` by default.
- The installed binary is placed under `$HOME/.cargo/bin/niri` when `cargo install` is run.
- Configuration (if copied) ends up in `~/.config/niri/config.kdl`.

If you no longer need guidance for removing or changing a git remote, it has been removed from this README. Manage remotes locally with `git remote` commands as needed.

**Troubleshooting:**
- If `cargo` is not found and `rustup` install failed, ensure `curl` is installed and your shell allows sourcing `$HOME/.cargo/env` (or restart the shell after install).
- If packages fail to install, run `sudo apt update` and retry.

**Notes:**
- The `build.sh` script uses `cargo build --release --locked` and `cargo install --path . --locked` to place the binary in the user's cargo bin. If you prefer different install paths, edit `build.sh` accordingly.

---

**Quickshell & Noctalia installer (second phase)**

This repository may include `build-quickshell.sh` which is intended to run after `build.sh` completes successfully. Its purpose is to build and install Quickshell on Debian 13 and then set up Noctalia on top of it.

- Usage (example):

```
chmod +x build-quickshell.sh
./build-quickshell.sh
```

`build-quickshell.sh` uses the following default repository URLs (edit the script to change them):

- Quickshell: `https://git.outfoxxed.me/quickshell/quickshell.git`
- Noctalia: `https://github.com/noctalia-dev/noctalia-shell.git`

The script will:
- Install system dependencies (apt packages)
- Ensure Rust (`cargo`) is installed
- Clone, build and `cargo install` Quickshell
- Clone Noctalia (if `NOCTALIA_REPO` is provided) and copy its configuration/assets into the appropriate Quickshell config directory (or another location you configure in the script)

Note: `build.sh` now attempts to build and install `xwayland-satellite` as part of the Niri install, and will copy the `xwayland-satellite` binary to `/usr/local/bin` so that `niri` can find it at runtime. If building `xwayland-satellite` fails due to missing native dependencies or an older Xwayland on Debian 13, see the Troubleshooting section below.

Important: do NOT run these scripts with `sudo sh scriptname` or run them as root. Running with `sh` or as root can cause environment sourcing to fail and may install tools into the wrong user's home.

Correct invocation examples:

```
chmod +x build.sh
./build.sh

chmod +x build-quickshell.sh
./build-quickshell.sh
```

The scripts will call `sudo` internally for package installation when necessary.

If you want me to wire specific repository URLs into `build-quickshell.sh` or make it install Noctalia to a particular path, tell me the exact repo URLs and target path and I'll update the script accordingly.

