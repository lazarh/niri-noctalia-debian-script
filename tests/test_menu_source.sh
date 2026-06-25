#!/bin/bash
# Tests that install.sh source contains correct menu patterns
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

echo "=== Test: Menu source patterns ==="

echo ""
echo "--- Upgrade menu display ---"
source_contains "U1 menu line"    '[U1] Upgrade Niri'
source_contains "U2 menu line"    '[U2] Upgrade Noctalia'
source_contains "U3 menu line"    '[U3] Upgrade Noctalia Greeter'
source_contains "UA menu line"    '[UA] Upgrade all (Niri + Noctalia + Greeter)'

echo ""
echo "--- Upgrade parsing ---"
source_contains "U1 case"        '[Uu]1)'
source_contains "U2 case"        '[Uu]2)'
source_contains "U3 case"        '[Uu]3)'
source_contains "UA case"        '[Uu][Aa])'

echo ""
echo "--- Core components menu ---"
source_contains "Step 1 menu"    'System dependencies'
source_contains "Step 2 menu"    'Niri compositor'
source_contains "Step 3 menu"    'Noctalia'
source_contains "Step 4 menu"    'Noctalia Greeter'

echo ""
echo "--- All-core install includes greeter ---"
source_contains "A sets greeter" 'INSTALL_NOCTALIA_GREETER=true'

echo ""
echo "Results: $pass passed, $fail failed"
if [ "$fail" -gt 0 ]; then
    exit 1
fi
