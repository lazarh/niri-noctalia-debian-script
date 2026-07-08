#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
any_failed=false

run_test() {
    local test_file="$1"
    echo "================================================"
    echo "Running: $(basename "$test_file")"
    echo "================================================"
    if bash "$test_file"; then
        echo "SUCCESS"
    else
        any_failed=true
        echo "FAILED"
    fi
    echo ""
}

run_test "$SCRIPT_DIR/test_help_output.sh"
run_test "$SCRIPT_DIR/test_menu_source.sh"
run_test "$SCRIPT_DIR/test_greeter_source.sh"
run_test "$SCRIPT_DIR/test_debian_detection.sh"

echo "================================================"
if [ "$any_failed" = true ]; then
    echo "Some tests FAILED"
    exit 1
else
    echo "All tests PASSED"
fi
