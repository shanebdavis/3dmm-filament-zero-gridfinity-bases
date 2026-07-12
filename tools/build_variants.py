#!/usr/bin/env python3
"""Build the two MakerWorld customizer variants from src/gridfinity_base.scad.

Run from the repo root (or via ./make_makerworld.sh):

    python3 tools/build_variants.py

The source file stays the single source of truth and the full-capability dev
script (open it directly in OpenSCAD). Each variant is the same file with only
the Customizer parameter header rearranged:

  - the variant's sections, in its own order;
  - every parameter from the omitted sections pinned to its default inside a
    /* [Hidden] */ block (OpenSCAD top-level variables are declarative, so
    moving them below the visible sections changes nothing but the UI);
  - optional per-variant default overrides (e.g. the multi-plate variant ships
    with a non-zero cover area so the first render shows the real product).

The engine/body below the parameter header is emitted byte-identical, so the
variants can never drift from the source geometry.

Variants (MakerWorld names the customizer's downloaded file after the uploaded
.scad, so the output filenames are product names):

  Single-Plate: Model, Grid, Drawer Spacers, Custom Shape, Advanced.
                Auto Baseplates pinned off. Classic one-plate customizer with
                STL download.
  Multi-Plate:  Model, Auto Baseplate Set Generation, Advanced. Manual Grid /
                Drawer Spacers / Custom Shape pinned. Downloads one STL of the
                whole gapped layout - the user splits it to objects in their
                slicer and auto-arranges.
"""
import os
import re
import sys

SRC = "src/gridfinity_base.scad"
OUT_DIR = "build"
SENTINEL = "// ---- end of Customizer parameters"

VARIANTS = [
    {
        "name": "3DMM Filament Zero Gridfinity Baseplate",
        "label": "Single-Plate customizer",
        "sections": ["Model", "Grid", "Drawer Spacers", "Custom Shape", "Advanced"],
        "drop_params": ["tile_gap"],   # auto-only knob living in Advanced
        "overrides": {},
    },
    {
        "name": "3DMM Filament Zero Gridfinity Baseplate Set",
        "label": "Multi-Plate customizer",
        "sections": ["Model", "Auto Baseplate Set Generation", "Advanced"],
        "drop_params": [],
        # Ship with a real layout on screen instead of the manual fallback.
        "overrides": {"cover_width": "400", "cover_depth": "400"},
    },
]

SECTION_RE = re.compile(r"^/\* \[(?P<name>[^\]]+)\] \*/\s*$", re.M)
ASSIGN_RE = re.compile(r"^(?P<name>\w+)\s*=\s*(?P<value>[^;]+);(?P<trail>[^\n]*)$")


def parse(src):
    """Split the file into (preamble, {section: chunks}, section order, body).
    A chunk is (param_name_or_None, text): a parameter assignment with the
    comment lines above it, or a bare comment block (kept with its section)."""
    cut = src.index(SENTINEL)
    header, body = src[:cut], src[cut:]

    marks = list(SECTION_RE.finditer(header))
    if not marks:
        sys.exit("no /* [Section] */ headers found in " + SRC)
    preamble = header[: marks[0].start()]
    order, sections = [], {}
    for m, nxt in zip(marks, marks[1:] + [None]):
        name = m.group("name")
        text = header[m.end() : nxt.start() if nxt else len(header)]
        order.append(name)
        sections[name] = chunks(text)
    return preamble, sections, order, body


def chunks(text):
    """Group a section's lines into (param|None, text) chunks: comments attach
    to the assignment that follows them."""
    out, pending = [], []
    for line in text.splitlines():
        m = ASSIGN_RE.match(line.strip()) and ASSIGN_RE.match(line)
        if m:
            out.append((m.group("name"), "\n".join(pending + [line])))
            pending = []
        elif line.strip() == "" and pending:
            out.append((None, "\n".join(pending)))
            pending = []
            out.append((None, ""))
        elif line.strip() == "":
            out.append((None, ""))
        else:
            pending.append(line)
    if pending:
        out.append((None, "\n".join(pending)))
    return out


def override(chunk_text, value):
    """Rewrite the default value in an assignment chunk, keeping the comments
    and the trailing Customizer range annotation."""
    lines = chunk_text.splitlines()
    m = ASSIGN_RE.match(lines[-1])
    lines[-1] = "%s = %s;%s" % (m.group("name"), value, m.group("trail"))
    return "\n".join(lines)


def build(variant, preamble, sections, order, body):
    known = {p for cs in sections.values() for p, _ in cs if p}
    for s in variant["sections"]:
        if s not in sections:
            sys.exit("variant %s: section [%s] not found in %s" % (variant["name"], s, SRC))
    for p in list(variant["overrides"]) + variant["drop_params"]:
        if p not in known:
            sys.exit("variant %s: parameter '%s' not found in %s" % (variant["name"], p, SRC))

    out = [
        "// ============================================================\n"
        "//  GENERATED FILE - do not edit. Built by tools/build_variants.py\n"
        "//  (./make_makerworld.sh) from %s.\n" % SRC,
        "//  Variant: %s\n" % variant["label"],
        "// ============================================================\n\n",
        preamble,
    ]
    pinned = []
    for name in order:
        visible = name in variant["sections"]
        parts = []
        for param, text in sections[name]:
            if param and param in variant["overrides"]:
                text = override(text, variant["overrides"][param])
            if param and (not visible or param in variant["drop_params"]):
                pinned.append(text.splitlines()[-1])   # assignment only, no comments
            elif visible:
                parts.append(text)
        if visible:
            out.append("/* [%s] */\n%s" % (name, "\n".join(parts).strip() + "\n\n"))

    out.append("/* [Hidden] */\n")
    out.append("// Fixed in this variant - not part of this customizer's UI.\n")
    out.append("\n".join(pinned) + "\n\n")
    out.append(body)
    return "".join(out)


def main():
    if not os.path.exists(SRC):
        sys.exit("run me from the repo root (%s not found)" % SRC)
    src = open(SRC).read()
    if SENTINEL not in src:
        sys.exit("sentinel %r not found in %s" % (SENTINEL, SRC))
    preamble, sections, order, body = parse(src)
    os.makedirs(OUT_DIR, exist_ok=True)
    for v in VARIANTS:
        path = os.path.join(OUT_DIR, v["name"] + ".scad")
        open(path, "w").write(build(v, preamble, sections, order, body))
        print("==> %s  (%s)" % (path, v["label"]))


if __name__ == "__main__":
    main()
