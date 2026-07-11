#!/usr/bin/env bash
#
# Export every Auto Baseplates plate as its own STL, for slicers that need one
# object per file (OrcaSlicer, Bambu Studio multi-plate layouts, etc.).
#
# Pass the same -D overrides you would give openscad; cover_width and
# cover_depth must both be non-zero so auto mode is active. Example:
#
#   ./export_plates.sh -D cover_width=500 -D cover_depth=450 \
#       -D 'printer="p1s"' -D 'model="net_rigid"'
#
# The solver runs once (echo-only, no geometry) to learn the plate count, then
# every plate renders in parallel to build/plates/plate_NN.stl, each centered
# on its own origin, ready to import and arrange.
set -euo pipefail
cd "$(dirname "$0")"

if ! command -v openscad >/dev/null 2>&1; then
    echo "error: openscad not found on PATH" >&2
    exit 1
fi

SCAD="src/gridfinity_base.scad"
OUT="build/plates"
mkdir -p "$OUT"
rm -f "$OUT"/plate_*.stl

# Evaluate the script without rendering (echo export) to read the solver's
# "... = N plates" console line.
ECHO_DIR="$(mktemp -d -t plates)"
ECHO_TMP="$ECHO_DIR/solve.echo"
trap 'rm -rf "$ECHO_DIR"' EXIT
openscad -o "$ECHO_TMP" "$@" "$SCAD" 2>/dev/null || true
N="$(sed -n 's/.* = \([0-9][0-9]*\) plates.*/\1/p' "$ECHO_TMP" | head -1)"

if [[ -z "$N" ]]; then
    echo "error: Auto Baseplates is not active — set both cover sizes, e.g." >&2
    echo "  ./export_plates.sh -D cover_width=500 -D cover_depth=450" >&2
    exit 1
fi
echo "==> $N plates"
grep -o '"==>.*"' "$ECHO_TMP" | sed 's/^"//; s/"$//' || true

JOBS="$( (command -v nproc >/dev/null 2>&1 && nproc) || sysctl -n hw.ncpu 2>/dev/null || echo 4)"

render() {
    local k="$1"; shift
    local out
    out="$(printf '%s/plate_%02d.stl' "$OUT" "$k")"
    echo "==> $out"
    openscad -q -o "$out" -D "export_plate=$k" "$@" "$SCAD"
}
export -f render
export SCAD OUT

for k in $(seq 1 "$N"); do printf '%s\0' "$k"; done |
    xargs -0 -n1 -P "$JOBS" -I{} bash -c 'render "$@"' _ {} "$@"

echo "Done: $N plates -> $OUT/"
