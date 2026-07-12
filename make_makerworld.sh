#!/usr/bin/env bash
#
# Generate the two MakerWorld customizer variants from src/gridfinity_base.scad:
#
#   build/3DMM Filament Zero Gridfinity Baseplate.scad       (Single-Plate)
#   build/3DMM Filament Zero Gridfinity Baseplate Set.scad   (Multi-Plate)
#
# Each variant is the same engine with a simplified Customizer header: the
# Single-Plate customizer hides the Auto Baseplates solver; the Multi-Plate
# customizer hides the manual Grid / Drawer Spacers / Custom Shape settings and
# leads with printer + cover area. Both are plain single-output scripts, so
# MakerWorld keeps STL download enabled. The multi-plate STL is the whole
# gapped layout - in the slicer: select it, Split to Objects, auto-arrange.
#
# src/gridfinity_base.scad itself stays the full-capability dev script; open it
# directly in OpenSCAD to work on the engine.
#
# Usage:  ./make_makerworld.sh
set -euo pipefail
cd "$(dirname "$0")"

if ! command -v python3 >/dev/null 2>&1; then
    echo "error: python3 not found on PATH" >&2
    exit 1
fi

exec python3 tools/build_variants.py "$@"
