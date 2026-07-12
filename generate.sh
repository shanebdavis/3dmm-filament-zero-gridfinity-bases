#!/usr/bin/env bash
#
# Batch-generate the standard Gridfinity base sizes for every model type.
#
# Renders src/gridfinity_base.scad once per (model x size) combination via the
# OpenSCAD CLI, leaving every other Customizer option at its default. Renders run
# in parallel, one job per core. Output STLs land in build/ (git-ignored).
#
# Usage:  ./generate.sh
set -euo pipefail

# Work from the repo root (this script's own directory), regardless of where it's invoked.
cd "$(dirname "$0")"

if ! command -v openscad >/dev/null 2>&1; then
    echo "error: openscad not found on PATH" >&2
    exit 1
fi

SCAD="src/gridfinity_base.scad"
OUT="build"
mkdir -p "$OUT"

# One job per core (fall back to 4 if we can't detect).
JOBS="$( (command -v nproc >/dev/null 2>&1 && nproc) || sysctl -n hw.ncpu 2>/dev/null || echo 4)"

# Model id -> friendly label used in the output filename.
MODELS=(
    "net_light:Net+"
    "net_heavy:Tape+"
    "rigid:Beam"
    "net_rigid:Beam+"
)

# Standard sizes as "columns x rows".
SIZES=(
    "2 2"
    "2 4"
    "4 4"
    "6 6"
)

# Sizes also rendered with the sparse option on, one per model.
SPARSE_SIZES=(
    "6 6"
)

# Render one STL. Exported so xargs -P can call it in parallel subshells.
render() {
    local id="$1" label="$2" cols="$3" rows="$4" sparse="$5"
    local suffix=""; [[ "$sparse" == "true" ]] && suffix=" Sparse"
    local out="$OUT/$label ${cols}x${rows}${suffix}.stl"
    echo "==> $out"
    openscad -q -o "$out" --export-format binstl \
        -D "model=\"$id\"" \
        -D "columns=$cols" \
        -D "rows=$rows" \
        -D "sparse=$sparse" \
        "$SCAD"
}
export -f render
export SCAD OUT

# Emit one NUL-delimited job (id label cols rows sparse) per line, fan out across cores.
for entry in "${MODELS[@]}"; do
    id="${entry%%:*}"
    label="${entry##*:}"
    for size in "${SIZES[@]}"; do
        read -r cols rows <<<"$size"
        printf '%s\0%s\0%s\0%s\0%s\0' "$id" "$label" "$cols" "$rows" "false"
    done
    for size in "${SPARSE_SIZES[@]}"; do
        read -r cols rows <<<"$size"
        printf '%s\0%s\0%s\0%s\0%s\0' "$id" "$label" "$cols" "$rows" "true"
    done
done | xargs -0 -n5 -P "$JOBS" bash -c 'render "$@"' _

echo "Done. ${#MODELS[@]} models x ($((${#SIZES[@]} + ${#SPARSE_SIZES[@]}))) sizes -> $OUT/ (parallel: $JOBS jobs)"
