#!/bin/bash
# Idempotency tests: running the same optional step twice must not corrupt or
# duplicate what it wrote the first time.
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

# Assert a file contains exactly $3 lines matching the extended regex $2
assert_count() {
    local label="$1" path="$2" pattern="$3" expected="$4" actual
    if [ ! -f "$path" ]; then
        no "$label" "file does not exist: $path"
        return
    fi
    actual="$(grep -cE -- "$pattern" "$path" || true)"
    if [ "$actual" = "$expected" ]; then
        ok "$label"
    else
        no "$label" "expected $expected match(es) of /$pattern/, found $actual"
    fi
}

assert_exists() {
    local label="$1" path="$2"
    if [ -f "$path" ]; then
        ok "$label"
    else
        no "$label" "missing file: $path"
    fi
}

sandbox_create
sandbox_created=true

echo "=== Test: --install-font does not duplicate the [font] tables ==="
ALACRITTY="$(sandbox_home '.config/alacritty/alacritty.toml')"
SANDBOX_STDIN=""
for _ in 1 2 3; do
    sandbox_run --install-font || true
done
assert_count "exactly one [font] table after 3 runs"      "$ALACRITTY" '^\[font\]$'       1
assert_count "exactly one [font.normal] table after 3 runs" "$ALACRITTY" '^\[font\.normal\]$' 1
assert_exists "alacritty.toml is backed up" "${ALACRITTY}.backup"
if grep -qE '0xProto Nerd Font Mono' "$ALACRITTY"; then
    ok "font family is configured"
else
    no "font family is configured" "0xProto Nerd Font Mono is not in alacritty.toml"
fi

echo ""
echo "=== Test: --install-font keeps unrelated alacritty settings ==="
cat > "$ALACRITTY" <<'CONF'
[general]
live_config_reload = true

[font]
size = 12.0

[font.normal]
family = "Some Old Font"

[font.bold]
family = "Some Old Font"
style = "Bold"

[colors.primary]
background = "#1e1e2e"
CONF
sandbox_run --install-font || true
assert_count "old [font] table replaced, not duplicated"   "$ALACRITTY" '^\[font\]$'            1
assert_count "old [font.normal] replaced"                  "$ALACRITTY" '^\[font\.normal\]$'    1
assert_count "stale [font.bold] subsection removed"        "$ALACRITTY" '^\[font\.bold\]$'       0
assert_count "[general] preserved"                         "$ALACRITTY" '^\[general\]$'          1
assert_count "[colors.primary] preserved"                  "$ALACRITTY" '^\[colors\.primary\]$'  1
if grep -qF 'Some Old Font' "$ALACRITTY"; then
    no "old font family is gone" "the previous font family survived"
else
    ok "old font family is gone"
fi
if grep -qF 'live_config_reload = true' "$ALACRITTY"; then
    ok "unrelated keys are untouched"
else
    no "unrelated keys are untouched" "live_config_reload was lost"
fi

echo ""
echo "=== Test: --install-nvim backs up an existing init.lua ==="
NVIM_INIT="$(sandbox_home '.config/nvim/init.lua')"
mkdir -p "$(sandbox_home '.config/nvim')"
printf 'vim.opt.number = true\n' > "$NVIM_INIT"
sandbox_run --install-nvim || true
assert_exists "init.lua is backed up" "${NVIM_INIT}.backup"
if grep -qF 'vim.opt.number = true' "${NVIM_INIT}.backup"; then
    ok "the backup holds the previous configuration"
else
    no "the backup holds the previous configuration" "init.lua.backup does not contain the old file"
fi
assert_count "the new config is written once" "$NVIM_INIT" 'stevearc/oil\.nvim' 1
cp "$NVIM_INIT" "$SANDBOX/init.lua.first"
sandbox_run --install-nvim || true
if cmp -s "$SANDBOX/init.lua.first" "$NVIM_INIT"; then
    ok "a second run produces an identical init.lua"
else
    no "a second run produces an identical init.lua" "init.lua changed between runs"
fi

echo ""
echo "=== Test: the niri config is only copied on confirmation ==="
NIRI_CONF="$(sandbox_home '.config/niri/config.kdl')"
rm -f "$NIRI_CONF" "${NIRI_CONF}.backup"
mkdir -p "$(sandbox_home '.config/niri')"
printf '// my own config\n' > "$NIRI_CONF"
SANDBOX_STDIN=$'2\nn\n'
sandbox_run --menu || true
if grep -qF 'my own config' "$NIRI_CONF"; then
    ok "declining the prompt keeps the existing config"
else
    no "declining the prompt keeps the existing config" "the config was overwritten anyway"
fi
if [ -f "${NIRI_CONF}.backup" ]; then
    no "declining the prompt writes no backup" "a backup was created"
else
    ok "declining the prompt writes no backup"
fi

SANDBOX_STDIN=$'2\ny\n'
sandbox_run --menu || true
if grep -qF 'screenshot' "$NIRI_CONF"; then
    ok "accepting the prompt installs the bundled config"
else
    no "accepting the prompt installs the bundled config" "config.kdl was not copied"
fi
assert_exists "the previous config was backed up" "${NIRI_CONF}.backup"

echo ""
echo "=== Test: the wallpaper step is safe to repeat ==="
WALLPAPER="$(sandbox_home '.local/bin/noctalia-random-wallpaper.sh')"
for _ in 1 2; do
    sandbox_run --install-wallpaper || true
done
if [ -x "$WALLPAPER" ]; then
    ok "wallpaper script is executable"
else
    no "wallpaper script is executable" "$WALLPAPER is missing or not executable"
fi
if bash -n "$WALLPAPER"; then
    ok "wallpaper script parses"
else
    no "wallpaper script parses" "bash -n reported a syntax error"
fi

echo ""
echo "Results: $pass passed, $fail failed"
if [ "$fail" -gt 0 ]; then
    exit 1
fi
