#!/bin/sh
# Run by 'meson dist' to add pre-generated files that autotools used to
# distribute via EXTRA_DIST.  MESON_PROJECT_DIST_ROOT points to the
# unpacked dist tree that meson is building the tarball from.

set -e

DISTROOT="$MESON_PROJECT_DIST_ROOT"

# --------------------------------------------------------------------------
# Protocol buffers: ipc.proto and ctl.proto
# --------------------------------------------------------------------------

PROTOC=$(command -v protoc 2>/dev/null || command -v protoc-c 2>/dev/null || true)
if [ -z "$PROTOC" ]; then
    echo "dist-script: WARNING: protoc/protoc-c not found, skipping pb-c generation" >&2
else
    "$PROTOC" --c_out="$DISTROOT/src" \
              --proto_path="$DISTROOT/src" \
              "$DISTROOT/src/ipc.proto"
    "$PROTOC" --c_out="$DISTROOT/src" \
              --proto_path="$DISTROOT/src" \
              "$DISTROOT/src/ctl.proto"
fi

# --------------------------------------------------------------------------
# gperf: http-heads.h
# --------------------------------------------------------------------------

if command -v gperf >/dev/null 2>&1; then
    gperf --global-table -t "$DISTROOT/src/http-heads.gperf" \
        > "$DISTROOT/src/http-heads.h"
else
    echo "dist-script: WARNING: gperf not found, skipping http-heads.h generation" >&2
fi

# --------------------------------------------------------------------------
# version.inc
# --------------------------------------------------------------------------

VERSION=$(sed -n "s/^  version: '\\(.*\\)',\$/\\1/p" "$DISTROOT/meson.build" | head -1)
if [ -n "$VERSION" ] && [ -f "$DISTROOT/src/version.inc.in" ]; then
    sed "s/@VERSION@/$VERSION/" "$DISTROOT/src/version.inc.in" \
        > "$DISTROOT/src/version.inc"
fi

# --------------------------------------------------------------------------
# Man pages (ronn is optional)
# --------------------------------------------------------------------------

if command -v ronn >/dev/null 2>&1; then
    for page in ocserv.8 occtl.8 ocpasswd.8; do
        ronn --roff "$DISTROOT/doc/${page}.md" -o "$DISTROOT/doc"
    done
else
    echo "dist-script: NOTE: ronn not found, man pages not pre-generated in dist" >&2
fi
