# Fix: Missing `librust-*` packages when building Niri on Debian Trixie

## Problem

The install script currently lists several `librust-*-dev` apt packages as build
dependencies for Niri. These are Debian-packaged Rust crates intended for building
`.deb` packages via `dh-cargo`. When building directly with `cargo build` they are
unnecessary, and on Debian Trixie some of them are missing or outdated, causing the
installation to fail.

## Proposed Fix

Remove all `librust-*-dev` apt packages and replace them with the underlying C
development libraries they wrap. Cargo will then resolve and compile the Rust crate
layer itself (from crates.io), linking against the system C libraries.

| Remove (apt) | Replace with (apt) |
|---|---|
| `librust-libspa-sys-dev` | `libpipewire-0.3-dev` (provides SPA headers) |
| `librust-libseat-sys-dev` | `libseat-dev` |
| `librust-pango-sys-dev` | `libpango1.0-dev` |
| `librust-libdisplay-info-sys-dev` | `libdisplay-info-dev` |

## Special case: `libdisplay-info-dev`

`libdisplay-info-dev` (the headers package) may also be absent from Trixie. The
script already works around the missing `libdisplay-info3` runtime package by
downloading it directly from `ftp.debian.org`. The same approach should be extended
to also fetch `libdisplay-info-dev` so that the Rust `-sys` crate can link against it
at build time.
