#!/usr/bin/env python3
"""Regenerate the inlined polyhedron() meshes in src/gridfinity_base.scad from the STLs.

Run from the repo root:

    python3 tools/inline_stls.py

How it works
------------
Each inlined mesh module in the .scad is preceded by a directive comment naming its
source STL, e.g.:

    // source-stl: AT Net Rigid Corner.stl (normalize)
    module mesh_corner_net_rigid() {
      polyhedron( ... );
    }

This script finds every such directive + module, reads the named STL from stl/, converts
it to a polyhedron() body, and rewrites the module in place. Nothing else in the file is
touched, so you can freely edit the surrounding OpenSCAD. To re-inline after editing a
mesh, just re-export the STL and re-run this script. To add a new mesh, copy an existing
directive+module pair, change the filename and module name, and run.

The directive:

    // source-stl: <filename in stl/> [(normalize)]

  (normalize)  shifts the mesh so its minimum-XY corner sits at the origin (used for the
               corner meshes, whose outer corner must land at 0,0 in the +X +Y quadrant).

The conversion, per mesh:
  1. Parse the binary STL triangles.
  2. Weld duplicate vertices (round to 4 dp) into points + faces — a clean manifold.
  3. If (normalize): translate so min X / min Y -> origin.
  4. REVERSE the face winding (see below).
  5. Emit polyhedron(points=..., faces=..., convexity=6).

The winding gotcha
------------------
STL orders a triangle's vertices counter-clockwise as seen from outside (outward normal
by the right-hand rule); OpenSCAD's polyhedron() wants them clockwise from outside. So
pasting STL triangles straight in yields inside-out normals. It's backend-dependent:
CGAL (older OpenSCAD, e.g. the 2021 macOS build) re-orients by topology and hides it,
while Manifold (newer OpenSCAD, and MakerWorld) trusts the winding and renders inverted.
We reverse the winding here, robustly: compute each mesh's signed volume and flip only
when it comes in counter-clockwise, so it's correct however the STL was exported.
"""
import os
import re
import struct
import sys

SCAD = "src/gridfinity_base.scad"
STL_DIR = "stl"

# A "// source-stl: <file> [(normalize)]" line, the module header, its body, and close.
UNIT = re.compile(
    r"^//[ \t]*source-stl:[ \t]*(?P<file>[^\n(]+?)[ \t]*(?P<norm>\(normalize\))?[ \t]*\n"
    r"module[ \t]+(?P<name>\w+)\(\)[ \t]*\{\n"
    r".*?"            # existing polyhedron body (regenerated)
    r"\n\}",          # module close brace on its own line
    re.S | re.M,
)


def load_binary_stl(path):
    d = open(path, "rb").read()
    n = struct.unpack("<I", d[80:84])[0]
    off, tris = 84, []
    for _ in range(n):
        v = struct.unpack("<12f", d[off:off + 48]); off += 50
        tris.append([(v[3], v[4], v[5]), (v[6], v[7], v[8]), (v[9], v[10], v[11])])
    return tris


def weld(tris):
    pts, idx, faces = [], {}, []
    key = lambda p: (round(p[0], 4), round(p[1], 4), round(p[2], 4))
    for t in tris:
        f = []
        for p in t:
            k = key(p)
            if k not in idx:
                idx[k] = len(pts); pts.append(list(k))
            f.append(idx[k])
        faces.append(f)
    return pts, faces


def signed_volume(pts, faces):
    V = 0.0
    for i, j, k in faces:
        a, b, c = pts[i], pts[j], pts[k]
        V += (a[0] * (b[1] * c[2] - b[2] * c[1])
              - a[1] * (b[0] * c[2] - b[2] * c[0])
              + a[2] * (b[0] * c[1] - b[1] * c[0])) / 6.0
    return V


def polyhedron_body(stl_path, normalize):
    pts, faces = weld(load_binary_stl(stl_path))
    if normalize:                                   # outer corner -> origin, +X +Y quadrant
        ox = min(p[0] for p in pts); oy = min(p[1] for p in pts)
        pts = [[p[0] - ox, p[1] - oy, p[2]] for p in pts]
    if signed_volume(pts, faces) > 0:               # STL CCW-from-outside -> polyhedron() wants CW
        faces = [[f[0], f[2], f[1]] for f in faces]
    ptss = ", ".join("[%g,%g,%g]" % (x, y, z) for x, y, z in pts)
    facess = ", ".join("[%d,%d,%d]" % (a, b, c) for a, b, c in faces)
    return "  polyhedron(\n    points=[%s],\n    faces=[%s], convexity=6);" % (ptss, facess)


def main():
    if not os.path.exists(SCAD):
        sys.exit("run me from the repo root (%s not found)" % SCAD)
    src = open(SCAD).read()

    seen = []

    def rewrite(m):
        fname = m.group("file").strip()
        normalize = bool(m.group("norm"))
        name = m.group("name")
        path = os.path.join(STL_DIR, fname)
        if not os.path.exists(path):
            sys.exit("module %s: STL not found: %s" % (name, path))
        body = polyhedron_body(path, normalize)
        seen.append((name, fname, normalize))
        flag = " (normalize)" if normalize else ""
        return "// source-stl: %s%s\nmodule %s() {\n%s\n}" % (fname, flag, name, body)

    new, count = UNIT.subn(rewrite, src)
    if count == 0:
        sys.exit("no '// source-stl:' directives found in %s — nothing to do" % SCAD)
    open(SCAD, "w").write(new)
    for name, fname, norm in seen:
        print("  %-26s <- %s%s" % (name, fname, "  (normalized)" if norm else ""))
    print("regenerated %d mesh module(s) in %s" % (count, SCAD))


if __name__ == "__main__":
    main()
