#!/usr/bin/env python3
"""Build the two MakerWorld customizer variants from src/gridfinity_base.scad.

Run from the repo root (or via ./make_makerworld.sh):

    python3 tools/build_variants.py

The source file stays the single source of truth and the full-capability dev
script (open it directly in OpenSCAD). Each variant is the same file with only
the Customizer parameter header rearranged:

  - the variant's output groups, in its own order and grouping. MakerWorld only
    auto-expands the FIRST group, so each variant leads with a "Basic" group
    holding everything a user normally touches. A group entry is either a
    single parameter name (emitted with its comments) or "@Section" (that whole
    source section in source order, intro comments included);
  - every parameter not placed in any group is pinned to its default inside a
    /* [Hidden] */ block (OpenSCAD top-level variables are declarative, so
    moving them below the visible groups changes nothing but the UI);
  - optional per-variant default overrides (e.g. the multi-plate variant ships
    with a non-zero cover area so the first render shows the real product).

The engine/body below the parameter header is emitted byte-identical, so the
variants can never drift from the source geometry.

Variants (MakerWorld names the customizer's downloaded file after the uploaded
.scad, so the output filenames are product names):

  Single-Plate: Basic (model, grid, sparse, drawer spacers), Custom Shape,
                Advanced. Auto Baseplates pinned off. Classic one-plate
                customizer with STL download.
  Multi-Plate:  Basic (model, printer, cover area, fill toggles, sparse),
                Advanced. Manual Grid / Drawer Spacers / Custom Shape pinned.
                Downloads one STL of the whole gapped layout - the user splits
                it to objects in their slicer and auto-arranges.
"""
import os
import re
import sys

SRC = "src/gridfinity_base.scad"
OUT_DIR = "build-src"
SENTINEL = "// ---- end of Customizer parameters"

VARIANTS = [
    {
        "name": "3DMM Filament Zero Gridfinity Single Baseplate",
        "label": "Single-Plate customizer",
        "groups": [
            ("Basic", ["model", "@Grid", "sparse", "@Drawer Spacers"]),
            ("Custom Shape", ["@Custom Shape"]),
            ("Advanced", ["centered", "pitch", "preview_color"]),
        ],
        "overrides": {},
    },
    {
        "name": "3DMM Filament Zero Gridfinity Multi Baseplate",
        "label": "Multi-Plate customizer",
        "groups": [
            ("Basic", ["model", "@Auto Baseplate Set Generation", "sparse"]),
            ("Advanced", ["@Advanced"]),
        ],
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
    chunk_of = {p: text for cs in sections.values() for p, text in cs if p}
    # Parameters placed explicitly by name anywhere in this variant's groups —
    # an @Section pull skips these so nothing is emitted twice.
    explicit = {e for _, entries in variant["groups"] for e in entries
                if not e.startswith("@")}
    for e in explicit:
        if e not in known:
            sys.exit("variant %s: parameter '%s' not found in %s" % (variant["name"], e, SRC))
    for p in variant["overrides"]:
        if p not in known:
            sys.exit("variant %s: override '%s' not found in %s" % (variant["name"], p, SRC))

    def chunk(param):
        text = chunk_of[param]
        return override(text, variant["overrides"][param]) if param in variant["overrides"] else text

    out = [
        "// ============================================================\n"
        "//  GENERATED FILE - do not edit. Built by tools/build_variants.py\n"
        "//  (./make_makerworld.sh) from %s.\n" % SRC,
        "//  Variant: %s\n" % variant["label"],
        "// ============================================================\n\n",
        preamble,
    ]
    emitted = set()
    for title, entries in variant["groups"]:
        parts = []
        for e in entries:
            if e.startswith("@"):
                name = e[1:]
                if name not in sections:
                    sys.exit("variant %s: section [%s] not found in %s" % (variant["name"], name, SRC))
                for param, text in sections[name]:
                    if param in explicit:
                        continue
                    parts.append(chunk(param) if param else text)
                    if param:
                        emitted.add(param)
            else:
                parts.append(chunk(e))
                emitted.add(e)
        out.append("/* [%s] */\n%s" % (title, "\n".join(parts).strip() + "\n\n"))

    pinned = [chunk_of[p].splitlines()[-1] for name in order   # assignment only, no comments
              for p, _ in sections[name] if p and p not in emitted]
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
