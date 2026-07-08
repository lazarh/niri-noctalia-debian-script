#!/bin/bash
# Tests that install.sh detects Debian version and sets wlroots version correctly
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_SCRIPT="$SCRIPT_DIR/../install.sh"

pass=0
fail=0
tmpdir=""

cleanup() {
    if [ -n "$tmpdir" ] && [ -d "$tmpdir" ]; then
        rm -rf "$tmpdir"
    fi
}
trap cleanup EXIT

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

echo "=== Test: Debian version detection ==="

echo ""
echo "--- Detection function ---"
source_contains "detect_wlroots_version function defined" 'detect_wlroots_version()'

echo ""
echo "--- OS release source ---"
source_contains "reads os-release" '/etc/os-release'

echo ""
echo "--- Trixie check ---"
source_contains "checks for trixie" 'trixie'

echo ""
echo "--- Output variables ---"
source_contains "sets WLROOTS_VERSION" 'WLROOTS_VERSION'
source_contains "sets NEED_XML_CURL" 'NEED_XML_CURL'

echo ""
echo "--- Functional: mock detection ---"

extract_func() {
    sed -n '/^detect_wlroots_version()/,/^}/p' "$INSTALL_SCRIPT"
}

run_detection() {
    local mock_file="$1"
    bash -c "
$(extract_func)
detect_wlroots_version '$mock_file'
echo \"WLROOTS_VERSION=\$WLROOTS_VERSION NEED_XML_CURL=\$NEED_XML_CURL\"
"
}

# Trixie case
echo "  Testing Trixie detection..."
tmpdir=$(mktemp -d)
echo 'VERSION_CODENAME=trixie' > "$tmpdir/os-release"
trixie_result=$(run_detection "$tmpdir/os-release")
if echo "$trixie_result" | grep -q 'WLROOTS_VERSION=0.18' && echo "$trixie_result" | grep -q 'NEED_XML_CURL=true'; then
    echo "  PASS: Trixie sets version 0.18 and NEED_XML_CURL=true"
    pass=$((pass + 1))
else
    echo "  FAIL: Trixie detection got: $trixie_result"
    fail=$((fail + 1))
fi
rm -rf "$tmpdir"
tmpdir=""

# Sid/unstable case
echo "  Testing Sid detection..."
tmpdir=$(mktemp -d)
echo 'VERSION_CODENAME=sid' > "$tmpdir/os-release"
sid_result=$(run_detection "$tmpdir/os-release")
if echo "$sid_result" | grep -q 'WLROOTS_VERSION=0.20' && echo "$sid_result" | grep -q 'NEED_XML_CURL=false'; then
    echo "  PASS: Sid sets version 0.20 and NEED_XML_CURL=false"
    pass=$((pass + 1))
else
    echo "  FAIL: Sid detection got: $sid_result"
    fail=$((fail + 1))
fi
rm -rf "$tmpdir"
tmpdir=""

# No os-release file case (fallback to 0.20)
echo "  Testing missing os-release..."
mkdir -p "/tmp/nonexistent-test-dir"
no_file_result=$(run_detection "/tmp/nonexistent-test-dir/nope")
if echo "$no_file_result" | grep -q 'WLROOTS_VERSION=0.20' && echo "$no_file_result" | grep -q 'NEED_XML_CURL=false'; then
    echo "  PASS: No os-release defaults to version 0.20"
    pass=$((pass + 1))
else
    echo "  FAIL: No os-release got: $no_file_result"
    fail=$((fail + 1))
fi

echo ""
echo "Results: $pass passed, $fail failed"
if [ "$fail" -gt 0 ]; then
    exit 1
fi
