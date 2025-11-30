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

**Removing the git repository association (safe options):**

If this local repository is currently linked to the remote `lazarh/niri-noctalia-debian-script` and you want to remove or change that association, choose one of the safe approaches below.

- Inspect current remotes:

```
git remote -v
```

- Remove the remote named `origin` (or whichever name points to the `lazarh/...` repository):

```
git remote remove origin
```

- Change the remote to a different repository URL instead of removing it:

```
git remote set-url origin git@github.com:youruser/yourrepo.git
```

- If you want to completely unlink the repository and remove Git history locally (destructive — irreversible for local history):

```
# WARNING: this deletes all local git history in this folder
rm -rf .git
```

If your goal is to delete the remote repository on GitHub (the `lazarh/niri-noctalia-debian-script` repo itself), that must be done via GitHub's web UI or API by the repository owner.

**Troubleshooting:**
- If `cargo` is not found and `rustup` install failed, ensure `curl` is installed and your shell allows sourcing `$HOME/.cargo/env` (or restart the shell after install).
- If packages fail to install, run `sudo apt update` and retry.

**Notes:**
- The `build.sh` script uses `cargo build --release --locked` and `cargo install --path . --locked` to place the binary in the user's cargo bin. If you prefer different install paths, edit `build.sh` accordingly.

---

If you'd like, I can also:
- Modify `build.sh` to set a `START_DIR` variable so the config copying step works reliably.
- Add a small `uninstall.sh` helper that undoes the local install steps.

