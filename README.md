# Niri / Quickshell Installer (combined)

This repository provides a single, opinionated installer script `install-all.sh` that automates installing and building:

- Niri (Wayland compositor)
- xwayland-satellite (rootless Xwayland helper)
- Quickshell (Qt-based shell)
- Noctalia shell assets (extracted into Quickshell config)

The original two scripts (`build.sh` and `build-quickshell.sh`) have been consolidated into this one script to simplify setup on Debian 13.

**Important:** this installer performs system package installs and builds large projects (Qt6, Rust builds). Run it only on a machine where you are comfortable installing development packages and building from source.

**Quick start**

1. Make the script executable:

```bash
chmod +x install-all.sh
```

2. Run the installer (recommended):

```bash
sudo ./install-all.sh
```

Running under `sudo` is fine: the script detects `SUDO_USER` and will run user-local steps (rustup, cargo installs, config extraction) as that non-root user so ownership and paths remain correct.

## Environment variables

- `NO_PACSTALL=1` — skip the optional `pacstall` step (recommended if you don't want to run third-party install scripts).
- `NOCTALIA_TARBALL_URL="<url>"` — override the default Noctalia release tarball URL (the script extracts this into `~/.config/quickshell/noctalia-shell`).

## What the script does

- Installs system packages (build tools, XCB dev libs, Qt6 dev packages used by Quickshell, and utilities).
- Installs Rust (`rustup`) for the invoking user if missing, then builds Niri with `cargo` and runs `cargo install`.
- Copies the resulting `niri` binary to `/usr/local/bin/niri` so display managers (GDM) can execute it.
- Builds `xwayland-satellite` from source and installs it to `/usr/local/bin`.
- Builds Quickshell with CMake/Ninja and installs it system-wide via `cmake --install`.
- Installs a few helper tools (for example `matugen` via `cargo`) and optionally runs `pacstall` if not skipped.
- Downloads and extracts the Noctalia release tarball into `~/.config/quickshell/noctalia-shell` for the invoking user.
- Writes a Wayland session file at `/usr/share/wayland-sessions/niri.desktop` that points to `/usr/local/bin/niri`.

## Troubleshooting

- If `apt` fails to find a package (especially Qt6 dev packages), your apt sources may not include the required repositories. Inspect the failed `apt` output and add the necessary sources or install those packages manually.
- If `cargo build` fails, copy the cargo error output and re-run the failing `cargo build` command manually as the invoking user — commonly missing native dev packages or incorrect toolchain versions cause failures.
- If `niri` warns about `xwayland-satellite` missing at runtime, verify the installed binary exists in the path visible to the compositor session:

```bash
which xwayland-satellite || ls -l /usr/local/bin/xwayland-satellite
which niri || ls -l /usr/local/bin/niri ~/.cargo/bin/niri
```

- If your display manager does not show the Niri session, ensure `/usr/share/wayland-sessions/niri.desktop` exists and its `Exec` points to `/usr/local/bin/niri`. Some DMs require a session restart:

```bash
sudo systemctl restart display-manager   # careful: this ends the graphical session
```

## Recommendations and options

- If you prefer not to copy the `niri` binary system-wide, I can change the script to create a small wrapper at `/usr/local/bin/niri` that execs the invoking user's `~/.cargo/bin/niri` instead.
- If you only want Niri (not Quickshell), or only Quickshell, tell me and I will add flags (e.g. `--no-quickshell`) to make the installer modular.

## Support

If anything fails when you run `install-all.sh`, paste the failing command output here and I will help fix the script or the missing dependencies.

## License & notes

This repository contains installer scripts and instructions only. The projects built by the script (Niri, Quickshell, xwayland-satellite, Noctalia) are external — review their upstream licenses and documentation for runtime and build notes.
