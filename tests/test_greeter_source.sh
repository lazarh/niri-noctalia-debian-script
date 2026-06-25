#!/bin/bash
# Tests that install.sh contains greeter-specific code paths
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

echo "=== Test: Greeter-specific source patterns ==="

echo ""
echo "--- Flag ---"
source_contains "INSTALL_NOCTALIA_GREETER flag" 'INSTALL_NOCTALIA_GREETER=false'

echo ""
echo "--- Dependencies ---"
source_contains "greetd package"          'greetd'
source_contains "wlroots package"         'libwlroots-0.20-dev'
source_contains "egl package"             'libegl-dev'
source_contains "gles package"            'libgles-dev'
source_contains "greetd enable"           'sudo systemctl enable greetd'

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
