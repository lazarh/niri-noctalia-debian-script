#!/bin/bash
# Lints install.sh and the test scripts with shellcheck. Skipped (not failed)
# when shellcheck is not installed, so the suite still runs on a bare machine.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

pass=0
fail=0

if ! command -v shellcheck > /dev/null 2>&1; then
    echo "  SKIP: shellcheck is not installed (apt install shellcheck)"
    echo ""
    echo "Results: 0 passed, 0 failed (skipped)"
    exit 0
fi

shellcheck_version="$(shellcheck --version | sed -n 's/^version: //p')"
echo "  Using shellcheck $shellcheck_version"
echo ""

check() {
    local file="$1"
    if shellcheck "$file"; then
        echo "  PASS: $(basename "$file") is shellcheck clean"
        pass=$((pass + 1))
    else
        echo "  FAIL: $(basename "$file") has shellcheck findings"
        fail=$((fail + 1))
    fi
}

echo "=== Test: shellcheck ==="
check "$SCRIPT_DIR/../install.sh"
for test_file in "$SCRIPT_DIR"/*.sh "$SCRIPT_DIR"/lib/*.sh; do
    [ -f "$test_file" ] || continue
    check "$test_file"
done

echo ""
echo "Results: $pass passed, $fail failed"
if [ "$fail" -gt 0 ]; then
    exit 1
fi
