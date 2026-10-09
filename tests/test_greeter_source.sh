#!/bin/bash
# Tests that install.sh contains greeter-specific code paths
#
# Single quotes are deliberate throughout: the patterns are matched literally
# against the install.sh source and must not be expanded by the shell.
# shellcheck disable=SC2016
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_SCRIPT="$SCRIPT_DIR/../install.sh"

pass=0
fail=0

source_contains() {
    local label="$1" pattern="$2"
    if grep -qF -- "$pattern" "$INSTALL_SCRIPT"; then
        echo "  PASS: $label"
        pass=$((pass + 1))
    else
        echo "  FAIL: $label — pattern not found: $pattern"
        fail=$((fail + 1))
    fi
}

source_not_contains() {
    local label="$1" pattern="$2"
    if ! grep -qF -- "$pattern" "$INSTALL_SCRIPT"; then
        echo "  PASS: $label"
        pass=$((pass + 1))
    else
        echo "  FAIL: $label — pattern should NOT exist: $pattern"
        fail=$((fail + 1))
    fi
}

echo "=== Test: Greeter-specific source patterns ==="

echo ""
echo "--- Flag ---"
source_contains "INSTALL_NOCTALIA_GREETER flag" 'INSTALL_NOCTALIA_GREETER=false'

echo ""
echo "--- Dependencies ---"
source_contains "greetd package"          'greetd'
source_contains "greetd enable"           'sudo systemctl enable greetd'
source_contains "pkg-config check"        'pkg-config --exists "$module"'

echo ""
echo "--- bindgen / libclang (Niri build needs libclang.so) ---"
source_contains "clang package"     'clang'
source_contains "libclang-dev"      'libclang-dev'

echo ""
echo "--- wlroots version the greeter is built against ---"
# Upstream noctalia-greeter pins wlroots-0.20 in its meson.build. The release's
# own wlroots version must not decide that, or the build dies inside meson with
# 'Dependency "wlroots-0.20" not found'.
source_contains "greeter pins its wlroots version" 'GREETER_WLROOTS_VERSION="0.20"'
source_contains "guard checks the greeter version" 'pkg-config --exists "$module"'
source_contains "guard also checks the package is configured" "ok installed"
source_not_contains "guard does not use the release version" 'pkg-config --exists "wlroots-${WLROOTS_VERSION}"'

echo ""
echo "--- wlroots 0.20 comes from forky, never auto-added ---"
source_contains "wlroots tried via apt"   'libwlroots-${GREETER_WLROOTS_VERSION}-dev'
source_contains "forky is offered"        'apt install -t forky libwlroots-'
source_contains "forky pinned low"       'Pin-Priority: 100'
source_contains "forky source suggested" 'forky.list'
# The script must not add a repository on its own: doing so changes system-wide
# upgrade behaviour, which is the user's decision. It may only *print* the
# commands, so a `tee` into the sources dir is fine but a redirect into one
# (what actually running them would look like) is not.
source_not_contains "forky.list is only printed, never written" '> /etc/apt/sources.list.d/forky.list'
source_not_contains "no apt update is run for forky"           'apt update -o Dir::Etc::sourcelist'
source_not_contains "wlroots is not fetched from the pool" 'install_pool_deb "libwlroots-'

echo ""
echo "--- A failed .deb install must not be reported as success ---"
# dpkg unpacks but cannot configure a .deb with unmet deps, so its exit status
# has to be checked or the script reports success over a broken install.
source_contains "dpkg failure is handled" 'if sudo dpkg -i "$deb"; then'

echo ""
echo "--- XML protocol download (Trixie) ---"
source_contains "mkdir for XML protocol"     'mkdir -p /usr/share/wayland-protocols/staging/ext-background-effect'
source_contains "curl XML protocol"          'ext-background-effect-v1.xml'

echo ""
echo "--- No apt install in build step ---"
source_not_contains "no apt in greeter step" 'Installing greeter dependencies'

echo ""
echo "--- Build/install step ---"
source_contains "clone greeter"           'https://github.com/noctalia-dev/noctalia-greeter.git'
source_contains "configure-release"       'just configure-release'
source_contains "build-release"           'just build-release'
source_contains "meson install"           'sudo meson install -C build-release'
source_contains "setup greeter"           'sudo ./scripts/setup_greeter_system.sh'

echo ""
echo "--- Upgrade case ---"
source_contains "greeter upgrade case"    'greeter)'

echo ""
echo "--- Step counter ---"
source_contains "step 4 counter"          '[4/4]'

echo ""
echo "Results: $pass passed, $fail failed"
if [ "$fail" -gt 0 ]; then
    exit 1
fi
