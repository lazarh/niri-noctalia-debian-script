#!/bin/bash
# Functional tests for install.sh, run against stubbed system commands so the
# real control flow is exercised without installing anything.
#
# The sandbox_* variables are consumed by lib/sandbox.sh when it builds the child
# environment, which static analysis cannot see across the source boundary.
# shellcheck disable=SC2034
# shellcheck disable=SC1091
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/sandbox.sh"

pass=0
fail=0
sandbox_created=false

cleanup() {
    [ "$sandbox_created" = true ] && sandbox_destroy
    return 0
}
trap cleanup EXIT

ok() {
    echo "  PASS: $1"
    pass=$((pass + 1))
}

no() {
    echo "  FAIL: $1${2:+ — $2}"
    fail=$((fail + 1))
}

assert_contains() {
    local label="$1" pattern="$2"
    if sandbox_output | grep -qF -- "$pattern"; then
        ok "$label"
    else
        no "$label" "output missing: $pattern"
    fi
}

assert_not_contains() {
    local label="$1" pattern="$2"
    if sandbox_output | grep -qF -- "$pattern"; then
        no "$label" "output unexpectedly contains: $pattern"
    else
        ok "$label"
    fi
}

assert_file_exists() {
    local label="$1" path
    path="$(sandbox_home "$2")"
    if [ -e "$path" ]; then
        ok "$label"
    else
        no "$label" "missing file: $2"
    fi
}

assert_status() {
    local label="$1" expected="$2" actual="$3"
    if [ "$expected" = "$actual" ]; then
        ok "$label"
    else
        no "$label" "expected exit $expected, got $actual"
    fi
}

sandbox_create
sandbox_created=true

echo "=== Test: core install path (deps, niri, noctalia, greeter) ==="
SANDBOX_STDIN=$'1 2 3 4\ny\n'
status=0
sandbox_run --menu || status=$?
assert_status "core install completes" 0 "$status"

assert_contains "step 1 banner"   "[1/4] System dependencies"        output
assert_contains "step 2 banner"   "[2/4] Niri compositor"            output
assert_contains "step 3 banner"   "[3/4] Noctalia"                   output
assert_contains "step 4 banner"   "[4/4] Noctalia Greeter"           output
assert_contains "niri verified"   "Niri installed successfully"      output
assert_contains "noctalia verified" "Noctalia installed successfully" output
assert_contains "greeter configured" "setup_greeter_system.sh"        output
assert_contains "greetd enabled"  "enable greetd"                    output
assert_contains "niri config applied" "Niri configuration applied"    output
assert_file_exists "niri config written" ".config/niri/config.kdl"

leftover="$(sandbox_leftover_temp_paths)"
if [ -z "$leftover" ]; then
    ok "temp build directories cleaned up by the exit trap"
else
    no "temp build directories cleaned up by the exit trap" "left behind: $leftover"
fi

echo ""
echo "=== Test: niri config is applied only once ==="
assert_contains "config applied once" "Niri configuration applied to" output
if [ "$(sandbox_output | grep -c 'Niri configuration applied to')" = "1" ]; then
    ok "no duplicate config copy"
else
    no "no duplicate config copy" "config step ran more than once"
fi

echo ""
echo "=== Test: pre-existing niri config is backed up ==="
mkdir -p "$(sandbox_home '.config/niri')"
printf '// hand written\n' > "$(sandbox_home '.config/niri/config.kdl')"
SANDBOX_STDIN=$'2\ny\n'
sandbox_run --menu || true
assert_file_exists "existing niri config backed up" ".config/niri/config.kdl.backup"

echo ""
echo "=== Test: wlroots dev files missing is reported clearly ==="
SANDBOX_NO_WLROOTS=1
SANDBOX_STDIN=""
status=0
sandbox_run --upgrade greeter || status=$?
assert_status "greeter upgrade fails without wlroots-dev" 1 "$status"
assert_contains "wlroots error shown"   "development files not found" output
assert_contains "wlroots fix suggested" "apt install libwlroots-"   output
SANDBOX_NO_WLROOTS=""

echo ""
echo "=== Test: upgrade mode validates its argument ==="
status=0
sandbox_run --upgrade || status=$?
assert_status "--upgrade without a value fails" 1 "$status"
assert_contains "--upgrade without a value explains" "requires an argument" output

status=0
sandbox_run --upgrade nonsense || status=$?
assert_status "--upgrade with a bad value fails" 1 "$status"
assert_contains "--upgrade with a bad value lists the options" "Valid options: niri, noctalia, greeter, all" output

echo ""
echo "=== Test: --upgrade all builds every component ==="
SANDBOX_STDIN=""
status=0
sandbox_run --upgrade all || status=$?
assert_status "--upgrade all completes" 0 "$status"
assert_contains "niri upgraded"     "Niri installed successfully"     output
assert_contains "noctalia upgraded" "Noctalia installed successfully" output
assert_contains "greeter upgraded"  "setup_greeter_system.sh"        output
assert_contains "upgrade banner"    "Upgrade complete!"              output
leftover="$(sandbox_leftover_temp_paths)"
if [ -z "$leftover" ]; then
    ok "upgrade cleans up its temp directory"
else
    no "upgrade cleans up its temp directory" "left behind: $leftover"
fi

echo ""
echo "=== Test: --help and unknown options ==="
status=0
sandbox_run --help || status=$?
assert_status "--help exits 0" 0 "$status"
assert_contains "--help documents --install-font" "--install-font"   output
assert_contains "--help documents --install-nvim" "--install-nvim"   output
assert_contains "--help explains the defaults" "With no options" output

status=0
sandbox_run --not-a-flag || status=$?
assert_status "unknown option fails" 1 "$status"
assert_contains "unknown option is named" "Unknown option: --not-a-flag" output

echo ""
echo "=== Test: optional components ==="
for flag in --install-vscode --install-omz --install-docs --install-office \
            --apply-fixes --remove-gnome --install-wallpaper \
            --install-desktop-entry --install-yazi \
            --install-font --install-nvim; do
    SANDBOX_STDIN=$'n\n'
    status=0
    sandbox_run "$flag" || status=$?
    if [ "$status" = 0 ]; then
        ok "$flag runs cleanly"
    else
        no "$flag runs cleanly" "exit status $status"
    fi
done

assert_file_exists "wallpaper script created" ".local/bin/noctalia-random-wallpaper.sh"
assert_file_exists "wallpaper timer created"  ".config/systemd/user/noctalia-wallpaper.timer"
assert_file_exists "font installed"           ".local/share/fonts/0xProto"
assert_file_exists "alacritty config created" ".config/alacritty/alacritty.toml"
assert_file_exists "nvim config created"      ".config/nvim/init.lua"
assert_not_contains "no stray key file in the repo" "packages.microsoft.gpg" output

echo ""
echo "=== Test: --apply-fixes resolves a user without $USER set ==="
SANDBOX_STDIN=""
status=0
sandbox_run --apply-fixes || status=$?
assert_status "--apply-fixes runs without a login environment" 0 "$status"
assert_contains "network fixes report success" "Network & hardware fixes applied successfully" output
assert_contains "group membership uses a real user" "to groups: netdev, bluetooth, video" output

echo ""
echo "=== Test: --remove-gnome requires an explicit confirmation ==="
SANDBOX_STDIN=$'no\n'
status=0
sandbox_run --remove-gnome || status=$?
assert_status "declining the removal exits cleanly" 0 "$status"
assert_contains "declining is reported" "GNOME removal cancelled" output
assert_not_contains "nothing is purged when declined" "purge -y gnome-core" output

SANDBOX_STDIN=$'yes\n'
sandbox_run --remove-gnome || true
assert_contains "confirming purges GNOME" "purge -y gnome-core" output
assert_contains "confirming switches the boot target" "set-default multi-user.target" output

echo ""
echo "=== Test: just is not rebuilt when already present ==="
printf '#!/bin/bash\necho "just 1.36.0"\n' > "$SANDBOX_BIN/just"
chmod +x "$SANDBOX_BIN/just"
SANDBOX_STDIN=$'1\n'
sandbox_run --menu || true
assert_contains "existing just is reused" "just already installed" output
if sandbox_output | grep -qF "cargo install just"; then
    no "just is not reinstalled" "cargo install just ran again"
else
    ok "just is not reinstalled"
fi

echo ""
echo "=== Test: libdisplay-info falls back to the Debian pool ==="
SANDBOX_APT_MISSING="libdisplay-info3 libdisplay-info-dev"
SANDBOX_ARCH="amd64"
SANDBOX_POOL_LISTING="libdisplay-info-dev_0.2.0+ds-1_amd64.deb
libdisplay-info-dev_0.3.0+ds-1_amd64.deb
libdisplay-info-dev_0.4.0+ds-1_arm64.deb
libdisplay-info3_0.2.0+ds-1_amd64.deb
libdisplay-info3_0.3.0+ds-1_amd64.deb
libdisplay-info3_0.9.0+ds-1_arm64.deb
"
SANDBOX_STDIN=$'1\n'
sandbox_run --menu || true
assert_contains "warns about the missing package" "is not available via apt" output
assert_contains "picks the newest matching deb"  "libdisplay-info3_0.3.0+ds-1_amd64.deb" output
if sandbox_output | grep -qF "0.9.0"; then
    no "ignores debs for other architectures" "an arm64 deb was selected on amd64"
else
    ok "ignores debs for other architectures"
fi

echo ""
echo "=== Test: repository packages are preferred over the pool ==="
SANDBOX_APT_MISSING=""
SANDBOX_POOL_LISTING=""
SANDBOX_STDIN=$'1\n'
sandbox_run --menu || true
assert_contains "installs from apt when available" "installed from the Debian repositories" output
if sandbox_output | grep -qF "downloading the .deb directly"; then
    no "no pool download when apt works" "the pool fallback was used anyway"
else
    ok "no pool download when apt works"
fi

echo ""
echo "Results: $pass passed, $fail failed"
if [ "$fail" -gt 0 ]; then
    exit 1
fi
