#!/usr/bin/env bash
#
# Regenerate the inlined polyhedron() meshes in src/gridfinity_base.scad from the STLs
# named in each module's "// source-stl:" directive.
#
# Thin wrapper around tools/inline_stls.py so you can just run ./inline-stls.sh from
# anywhere. Edit a mesh in stl/, re-export it, then run this.
#
# Pass --watch (or -w) to keep it running and auto-re-inline whenever any stl/*.stl
# changes:  ./inline-stls.sh --watch
#
set -euo pipefail

# Work from the repo root (this script's own directory), regardless of where it's invoked.
cd "$(dirname "$0")"

if ! command -v python3 >/dev/null 2>&1; then
    echo "error: python3 not found on PATH" >&2
    exit 1
fi

exec python3 tools/inline_stls.py "$@"
