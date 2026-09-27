#!/bin/bash
# Shared harness for running install.sh without touching the real system.
#
# Every privileged or package-managing command is replaced by a stub on PATH, and
# $HOME is redirected into a throwaway directory, so the tests exercise the real
# control flow of install.sh while remaining safe to run anywhere.
#
# Usage:
#   source "$(dirname "$0")/lib/sandbox.sh"
#   sandbox_create
#   sandbox_run --install-font            # stdin comes from $SANDBOX_STDIN
#   sandbox_output                       # combined stdout+stderr of the last run
#   sandbox_destroy

SANDBOX=""

sandbox_create() {
    SANDBOX="$(mktemp -d)"
    SANDBOX_BIN="$SANDBOX/bin"
    SANDBOX_HOME="$SANDBOX/home"
    SANDBOX_OUT="$SANDBOX/output.log"
    SANDBOX_STDIN=""
    mkdir -p "$SANDBOX_BIN" "$SANDBOX_HOME"

    # sudo: refuses anything that would write outside the sandbox, otherwise
    # runs the command with the sandbox PATH so nested stubs still apply.
    cat > "$SANDBOX_BIN/sudo" <<'STUB'
#!/bin/bash
for arg in "$@"; do
    case "$arg" in
        /etc/*|/usr/*|/bin/*|/sbin/*|/boot/*|/lib/*|*NetworkManager*)
            echo "[stub sudo] blocked: $*"
            exit 0
            ;;
    esac
done
exec "$@"
STUB

    # Package manager: pretends every package is available, unless the caller
    # listed packages to hide in $SANDBOX_APT_MISSING.
    cat > "$SANDBOX_BIN/apt" <<'STUB'
#!/bin/bash
for arg in "$@"; do
    for missing in ${SANDBOX_APT_MISSING:-}; do
        if [ "$arg" = "$missing" ]; then
            echo "E: Unable to locate package $arg" >&2
            exit 100
        fi
    done
done
echo "[stub apt] $*"
exit 0
STUB
    cp "$SANDBOX_BIN/apt" "$SANDBOX_BIN/apt-get"
    sed -i 's/\[stub apt\]/[stub apt-get]/' "$SANDBOX_BIN/apt-get"

    cat > "$SANDBOX_BIN/dpkg" <<'STUB'
#!/bin/bash
if [ "$1" = "--print-architecture" ]; then
    echo "${SANDBOX_ARCH:-amd64}"
    exit 0
fi
echo "[stub dpkg] $*"
exit 0
STUB

    # git: creates the target directory (and the greeter setup script the build
    # step invokes) so the surrounding build flow can proceed.
    cat > "$SANDBOX_BIN/git" <<'STUB'
#!/bin/bash
echo "[stub git] $*"
if [ "$1" = "clone" ]; then
    dest=""
    for arg in "$@"; do
        case "$arg" in
            http*|git*) ;;
            *) dest="$arg" ;;
        esac
    done
    mkdir -p "$dest/scripts"
    printf '#!/bin/bash\necho "[stub] setup_greeter_system.sh $*"\n' \
        > "$dest/scripts/setup_greeter_system.sh"
    chmod +x "$dest/scripts/setup_greeter_system.sh"
fi
exit 0
STUB

    # wget: serves a fake Debian pool listing, otherwise writes an empty file.
    cat > "$SANDBOX_BIN/wget" <<'STUB'
#!/bin/bash
if [ "$1" = "-qO-" ]; then
    printf '%s' "${SANDBOX_POOL_LISTING:-}"
    exit 0
fi
out=""
url=""
while [ $# -gt 0 ]; do
    case "$1" in
        -O) out="$2"; shift ;;
        http*|https*) url="$1" ;;
    esac
    shift
done
echo "[stub wget] GET $url"
[ -n "$out" ] && : > "$out"
exit 0
STUB

    # curl: records the call on stderr and writes nothing to stdout, so callers
    # that pipe it into another command (gpg) or eval it (Oh My Zsh) stay valid.
    printf '#!/bin/bash\necho "[stub curl] $*" >&2\nexit 0\n' > "$SANDBOX_BIN/curl"

    # No-op stubs for everything else install.sh shells out to.
    for cmd in cargo just meson systemctl install unzip tar fc-cache usermod \
               chsh gpg rustup rustc; do
        printf '#!/bin/bash\necho "[stub %s] $*"\nexit 0\n' "$cmd" \
            > "$SANDBOX_BIN/$cmd"
    done

    # Fakes for the binaries the script verifies after installing.
    for cmd in niri noctalia yazi nvim; do
        printf '#!/bin/bash\necho "%s 0.0.0 (stub)"\n' "$cmd" > "$SANDBOX_BIN/$cmd"
    done

    # pkg-config succeeds by default; callers that want the missing-dev-files
    # path set SANDBOX_NO_WLROOTS=1.
    cat > "$SANDBOX_BIN/pkg-config" <<'STUB'
#!/bin/bash
[ -n "${SANDBOX_NO_WLROOTS:-}" ] && exit 1
exit 0
STUB

    chmod +x "$SANDBOX"/bin/*
    # Point TMPDIR inside the sandbox so every mktemp call the script makes is
    # observable here and can never pollute the host /tmp.
    mkdir -p "$SANDBOX/tmp"
    export SANDBOX_BIN SANDBOX_HOME SANDBOX_OUT SANDBOX_STDIN SANDBOX_TMP
    export SANDBOX_APT_MISSING="" SANDBOX_ARCH="amd64" SANDBOX_NO_WLROOTS=""
    export SANDBOX_POOL_LISTING=""
    SANDBOX_TMP="$SANDBOX/tmp"
}

# Run install.sh inside the sandbox. Args are passed through to the script,
# stdin comes from $SANDBOX_STDIN, output is captured in $SANDBOX_OUT.
sandbox_run() {
    printf '%s' "$SANDBOX_STDIN" | env -i \
        HOME="$SANDBOX_HOME" \
        PATH="$SANDBOX_BIN:/usr/bin:/bin" \
        TMPDIR="$SANDBOX_TMP" \
        TERM=dumb \
        SANDBOX_APT_MISSING="$SANDBOX_APT_MISSING" \
        SANDBOX_ARCH="$SANDBOX_ARCH" \
        SANDBOX_NO_WLROOTS="$SANDBOX_NO_WLROOTS" \
        SANDBOX_POOL_LISTING="$SANDBOX_POOL_LISTING" \
        bash "$SCRIPT_DIR/../install.sh" "$@" > "$SANDBOX_OUT" 2>&1
}

# Echo the captured output of the last sandbox_run
sandbox_output() {
    cat "$SANDBOX_OUT"
}

# Echo a path inside the sandboxed $HOME
sandbox_home() {
    printf '%s' "$SANDBOX_HOME/$1"
}

# Paths the script allocated via mktemp and failed to clean up. The script
# registers every one of them with its EXIT trap, so this must always be empty.
sandbox_leftover_temp_paths() {
    find "$SANDBOX_TMP" -mindepth 1 2>/dev/null
}

sandbox_destroy() {
    [ -n "$SANDBOX" ] && rm -rf "$SANDBOX"
    SANDBOX=""
}
