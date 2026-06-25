#!/bin/bash
# Tests for install.sh --help output
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_SCRIPT="$SCRIPT_DIR/../install.sh"

pass=0
fail=0

assert_contains() {
    local label="$1" pattern="$2" output="$3"
    if echo "$output" | grep -qF -- "$pattern"; then
        echo "  PASS: $label"
        pass=$((pass + 1))
    else
        echo "  FAIL: $label — expected to contain: $pattern"
        fail=$((fail + 1))
    fi
}

assert_not_contains() {
    local label="$1" pattern="$2" output="$3"
    if ! echo "$output" | grep -qF -- "$pattern"; then
        echo "  PASS: $label"
        pass=$((pass + 1))
    else
        echo "  FAIL: $label — should NOT contain: $pattern"
        fail=$((fail + 1))
    fi
}

echo "=== Test: install.sh --help ==="
HELP_OUTPUT=$("$INSTALL_SCRIPT" --help 2>&1 || true)

echo ""
echo "--- Upgrade option display ---"
assert_contains "upgrade help line"       "--upgrade" "$HELP_OUTPUT"
assert_contains "niri upgrade"           "niri" "$HELP_OUTPUT"
assert_contains "noctalia upgrade"       "noctalia" "$HELP_OUTPUT"
assert_contains "greeter upgrade"        "greeter" "$HELP_OUTPUT"
assert_contains "or all"                 "or all" "$HELP_OUTPUT"

echo ""
echo "--- Install flags ---"
assert_contains "greeter install flag"   "--install-noctalia-greeter" "$HELP_OUTPUT"

echo ""
echo "Results: $pass passed, $fail failed"
if [ "$fail" -gt 0 ]; then
    exit 1
fi
