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

**Combined Installer**

This repository also includes `install-all.sh` — a single, opinionated installer that merges the steps from `build.sh` and `build-quickshell.sh` so you can install Niri, xwayland-satellite, Quickshell, and Noctalia in one run.

- **Purpose:** automate installing system packages, Rust, building Niri and xwayland-satellite, building Quickshell (CMake/Ninja), installing optional helper tools, and extracting the Noctalia release into the Quickshell config directory.
- **Path:** `install-all.sh` (at repository root).

Usage (recommended):

```
chmod +x install-all.sh
sudo ./install-all.sh
```

Environment options:
- `NO_PACSTALL=1` — skip the optional `pacstall` installer step.
- `NOCTALIA_TARBALL_URL="<url>"` — override the default Noctalia release tarball URL used when extracting into `~/.config/quickshell/noctalia-shell`.

What it installs/does:
- Installs system packages (build tools, Qt6 dev packages for Quickshell, XCB dev libs, and other utilities).
- Installs Rust (`rustup`) for the invoking user if missing.
- Clones and builds `niri` via `cargo` and runs `cargo install` for the invoking user.
- Copies the built `niri` binary to `/usr/local/bin/niri` so display managers (GDM) can launch it.
- Builds `xwayland-satellite` from source and installs it to `/usr/local/bin`.
- Builds Quickshell using CMake/Ninja and installs it system-wide via `cmake --install`.
- Installs `matugen` via `cargo` for the invoking user.
- Optionally runs the `pacstall` installer (can be skipped with `NO_PACSTALL=1`).
- Downloads the Noctalia release tarball and extracts it to `~/.config/quickshell/noctalia-shell` for the invoking user.
- Writes a Wayland session `.desktop` file at `/usr/share/wayland-sessions/niri.desktop` that points to `/usr/local/bin/niri`.

Notes & warnings:
- The script is large and will pull many development packages (Qt6, etc.) — allow time and disk space for these downloads.
- Run it as `sudo ./install-all.sh` or as your normal user — when run with `sudo`, the installer detects `SUDO_USER` and performs user-local installs as that user so paths/ownership are correct.
- The `pacstall` invocation runs a third-party installer script; skip it unless you trust that source.
- If a step fails (missing apt packages or build errors), the script prints warnings; inspect the output and rerun the failing command manually if needed.

If you want the installer adjusted (for example, to avoid copying the `niri` binary and use a wrapper instead, or to make Quickshell optional), tell me which behavior you prefer and I will update `install-all.sh` accordingly.

