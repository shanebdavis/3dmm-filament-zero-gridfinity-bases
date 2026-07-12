# 3DMM Filament Zero — Gridfinity Bases

**What is the absolute minimum filament — and print time — that still makes a usable
Gridfinity base?** That's the whole point of this project. At this point the answer is,
in truth, *filament approximately zero*: there's no way to remove any more material
without making the base non-functional. Hence the name.

Part of the **3D Modular Madness** collection. Released on MakerWorld:
https://makerworld.com/en/models/1384108-gridfinity-base-fastest-lightest-customizable

## The variants

Three levels of structure, depending on your needs — plus connectable versions of each:

- **Net+** — Doubly flexible, but strong in *tension* — which is mostly what a Gridfinity
  base needs anyway. By far the lightest and fastest print. (`net_light` in the source.)
- **Tape+** — Adds horizontal sliding rigidity while staying flexible. Probably the sweet
  spot if you don't care about looks. (`net_heavy` in the source.)
- **Beam** — If you want it to look nice *and* want the strongest option, go for the beam:
  a traditional-looking solid Gridfinity base, still trimmed to the bone for speed.
  (`rigid` in the source.)
- **Beam+** — Beam, made connectable (see below). Identical to Beam except the *exposed*
  outer-perimeter corners use a special profile designed to mate with neighbouring prints.
  Any perimeter corner on an edge with a drawer spacer falls back to the plain Beam outer
  corner. (`net_rigid` in the source.)

### Connecting plates into one big grid

A natural fallout of how the Net and Tape versions are built: their corners made it
natural to design a **connector** that joins separately-printed plates, so if possible you
can interconnect all your Gridfinity into one large piece. Once the connectors existed,
**Beam+** followed — so the nicest-looking, strongest option can use the connectors too.

## Benchmarks

Bambu Studio slicer estimates on an **A1 mini**, normalized per 42 mm tile (most rows are a
4×4 / 16-tile plate). Lower is better on both columns. ★ = this project.

| Model | By | g / tile | s / tile |
|-------|-----|---------:|---------:|
| ★ **3DMM Net+** | this project | **0.167** | **23.5** |
| Ultralight+ Gridfinity Bases | DBT85 | 0.267 | 52.3 |
| ★ **3DMM Tape+** | this project | 0.326 | 49.9 |
| ★ **3DMM Beam** | this project | 0.500 | 74.4 |
| Lightest Gridfinity Base Ever | Sparky | 0.780 | 96.3 |
| 3DMM Original Ultimate Turbo | this project (old) | 0.828 | 51.9 |
| Gridfinity Lightweight Stackable | DJR Engineering | 1.081 | 123.8 |
| Slim Gridfinity Base (IKEA Alex) | — | 1.258 | 138.9 |
| Gridfinity Simple Base | Schmidsfeld | 1.324 | 243.8 |

Highlights:

- **Net+ is the lightest and fastest base in the field** — 0.167 g/tile, ~37% less filament
  than the next-lightest (Ultralight+) and ~2.2× faster per tile.
- **Beam — a traditional, solid-looking base — beats "Lightest Gridfinity Base Ever"** by
  ~36% on filament and ~23% on time, while still looking like a normal Gridfinity base.
- **Tape+** adds real semi-rigid cross-bracing for only a little more filament than corner-only
  designs, at comparable print speed (49.9 s/tile vs Ultralight+'s 52.3 s/tile).
- Versus a standard Simple Base, **Net+ uses ~1/8th the filament and prints ~10× faster** per tile.

## Repo layout

```
src/               OpenSCAD source — the parametric assembler
stl/               Source geometry: per-variant Corner and Connector STLs
tools/             STL → polyhedron() inliner (regenerates the geometry baked into the .scad)
inline-stls.sh     Convenience wrapper: re-inline the STLs into the .scad
generate.sh        Batch-render the standard sizes for every model type
export_plates.sh   Auto Baseplates: render each plate to its own STL (build/plates/)
make_makerworld.sh Generate the two MakerWorld customizer variants (build-src/)
tools/build_variants.py  The variant builder behind make_makerworld.sh
build-src/         The generated customizer variants, committed so the shipped
                   files exist verbatim even without rerunning the generator
```

`src/gridfinity_base.scad` is **self-contained**: the corner / connector geometry is
inlined directly as `polyhedron()` blocks, so the single file renders anywhere —
including MakerWorld's Parametric Model Maker — with no external STL dependencies. The
`stl/` folder is kept as the editable source of truth, and `tools/inline_stls.py`
regenerates the inlined blocks from it. See *Inlining the geometry* below.

## Installing OpenSCAD

On macOS, install via Homebrew:

```
brew install --cask openscad
```

This installs the OpenSCAD app (and the `openscad` CLI used for headless rendering).

## Customizing your layout (OpenSCAD)

1. Open `src/gridfinity_base.scad` in OpenSCAD.
2. Open the Customizer: **Window → Customizer**.
3. Set:
   - **Model** — Net+, Tape+, Beam+, or Beam
   - **Sparse** — merge cells up to double width/depth and drop the internal walls
     between them: roughly **half the filament and print time** on large areas.
     Corners stay at standard Gridfinity positions (nothing is scaled — only the
     connectors between corners stretch), so bins seat and plates tile exactly as
     usual, just with less support under them. Works per plate in Auto Baseplates
     too; half cells are never merged, and it's ignored when Custom Shape cuts
     are set.
   - **Columns** / **Rows** — grid size in 42 mm cells, in 0.5 steps from 1 to 20.5.
     A `.5` appends a fully-enclosed half-cell (21 mm) column and/or row, for fitting
     odd drawer sizes (e.g. `2.5` = two full cells plus a half)
   - **Custom Shape** — carve a non-rectangular plate by removing squares from the
     left / right end of each row (row 1 = the front row). Corners, connectors and
     drawer spacers all adapt automatically: spacers only run along squares that
     survived the cuts, and each row always keeps at least one square. The Console
     warns if adjacent rows no longer overlap (which would split the plate in two).
   - **Drawer Spacers** — front / back / left / right, in mm (0 = none, 41 mm max).
     Adds a triangular spacer that projects outward from that edge so the plate sits
     flush in a drawer. Each is independent, so you can pad just the sides you need.
     A tie-rail runs along the outer edge of each spaced side, locking the spacers
     together for rigidity. Past 41 mm, add another Gridfinity cell instead.
   - **Auto Baseplates** — fill a whole area with one click: enter the total width
     and depth to cover (both must be non-zero to activate — otherwise everything
     works as normal) and pick your printer (or a custom printable area). Printer
     sizes are the largest single-color rectangle from the official Bambu Studio
     machine profiles, not the advertised bed — e.g. the P1/X1 series lose an
     18×28 mm front-left corner to the filament-cutter stopper (so 238×256 usable,
     with plates placed right of the corner), and the dual-nozzle H2D/H2C print a
     single color from one nozzle, which only reaches 325 mm of the bed. The solver
     fits the largest half-cell grid inside the area, splits it into plates that each
     fit your printer, and converts the leftover millimeters into drawer spacers
     (split left/right for width, all to the back for depth), so the assembled
     footprint is *exactly* what you entered. While active it overrides Grid, Drawer
     Spacers and Custom Shape. Two checkboxes tune the fill: **Drawer spacers**
     (uncheck for bare plates — the set shrinks to the largest grid that fits) and
     **Half tiles** (uncheck for whole 42 mm squares only; the extra leftover goes
     to the spacers). The preview shows all plates laid out in their assembled
     positions with a small gap. With **Beam+**, plate-to-plate edges get the
     interlocking corners automatically, so the finished grid clips together.
     The Console lists every plate size and its printed footprint.

     To print, export the whole layout as **one STL**, import it into the slicer,
     then **Split to Objects** and auto-arrange (press **A** in Bambu Studio) —
     every plate separates cleanly into its own object (see *cavity vents* in the
     MakerWorld section). To render each plate to its own file instead, run

     ```
     ./export_plates.sh -D cover_width=500 -D cover_depth=450 -D 'printer="p1s"'
     ```

     which renders every plate in parallel to `build/plates/… - Plate NN.stl`
     (driving the hidden `export_plate` parameter via `-D`). Plates are numbered
     left to right, then front to back.
   - **Advanced** — pitch (42 mm = standard Gridfinity), centering, and preview colour
4. `F5` to preview, `F6` to render, then **File → Export → Export as STL**.

The **Console** (**View → Console**) prints the total outer footprint in mm
(`Total size: … wide (X) x … deep (Y)`), including any spacers, so you can check it
against your drawer before exporting.

## Publishing on MakerWorld (two customizers)

MakerWorld gets **two purpose-built customizer scripts**, both generated from
the one source file:

```
./make_makerworld.sh
# -> build-src/3DMM Filament Zero Gridfinity Single Baseplate.scad   (Single-Plate)
# -> build-src/3DMM Filament Zero Gridfinity Multi Baseplate.scad    (Multi-Plate)
```

- **Single-Plate** exposes Model, Grid, Drawer Spacers, Custom Shape and
  Advanced — the classic one-plate customizer, with the Auto Baseplates solver
  pinned off.
- **Multi-Plate** ("Baseplate Set") exposes Model, then Auto Baseplate Set
  Generation — pick your printer, enter the area to cover — then Advanced. The
  manual Grid / Drawer Spacers / Custom Shape settings are pinned off, and it
  ships with a 400×400 mm cover area so the first preview shows a real layout.

Both are plain single-output scripts — deliberately **no Parametric Model
Maker multi-plate hooks** — so MakerWorld keeps the **STL download** button on
both listings. STL is the point: PMM's multi-plate 3MF ships MakerWorld's
default print profile, which is wrong for these models, and walking makers
through exporting objects out of it into a correct profile was tedious. With
an STL the maker starts inside our published print profile and stays there.
Printing a Baseplate Set is three inputs in Bambu Studio: import the STL into
the print profile, click it and **Split to Objects**, press **A** to
auto-arrange. Done.

Each variant is the source file with only the Customizer parameter header
rearranged — parameters of omitted sections are pinned to their defaults in a
hidden block, and everything below the header is emitted byte-identical.
`tools/build_variants.py` fails the build if an expected section or parameter
disappears, so the variants can't silently drift from
`src/gridfinity_base.scad` (which remains the full-capability script for local
development). MakerWorld names the downloaded file after the uploaded `.scad`,
so the build outputs carry the product names — rename them in
`tools/build_variants.py` if the product names change.

### Cavity vents (why Split to Objects works)

The Beam/Beam+ corners intentionally enclose sealed air pockets at interior
cell crossings — they split the doubled walls into separated perimeter lines
when sliced. A sealed cavity is always a separate shell in an exported mesh,
so slicers' *Split to Objects* used to break those pockets out as dozens of
loose boxes (and silently delete the inner structure from the plate). Every
pocket is therefore vented to the plate's underside through a hair-thin
channel (`crossing_vents()` in the source): the mesh becomes one connected
shell per plate, the pockets survive splitting, and the channels are far below
one extrusion width so they never appear in toolpaths.

## References & inspiration

These makers did excellent work, and their designs directly inspired this project. They
raised the bar — this project is my attempt to push it further. Go give them a boost.

- **[Ultralight+ Gridfinity Bases](https://makerworld.com/en/models/1226917-ultralight-gridfinity-bases)**
  by DBT85 — Corner-only alignment bases (the grid sides are skipped entirely, since only
  the corners are needed to align bins), with optional pins to connect plates. Roughly
  6.5 g and ~20 min for a 2-wall 5×5 on a P1S. The closest reference point for the
  **Net+** and **Tape+** variants.
- **[Lightest Gridfinity Base Ever – Customizable](https://makerworld.com/en/models/1685835-lightest-gridfinity-base-ever-customizable)**
  by Sparky — Parametric, skeletonized walls-only base with the bottom lip and inter-grid
  overhangs removed; a 4×4 in ~14 min on a 0.8 mm nozzle (1 wall). The reference point for
  the **Beam** variant.
- **[Gridfinity Lightweight Stackable Base Plates](https://makerworld.com/en/models/1927235-gridfinity-lightweight-stackable-base-plates)**
  by DJR Engineering — A clever stackable "peanut" interlock so you can run a whole
  Z-height stack overnight. It requires support material (an AMS) to separate the stacked
  layers. A genuinely interesting idea — but in practice the support material and per-plate
  overhead mean it isn't a net win on time or filament versus printing flat.
- **[Gridfinity Simple Base – all sizes](https://makerworld.com/en/models/700948-gridfinity-simple-base-all-sizes)**
  by Schmidsfeld — The popular, standard full baseplate (built with the FreeCAD Gridfinity
  Workbench). The non-optimized baseline for "normal" Gridfinity weight and print time.

Gridfinity itself was created by Zack Freeman as an open, free system — a framework for the
community.

## How it works

The base is assembled from two reused source parts per variant — a **corner** and a
**connector** beam. `src/gridfinity_base.scad` places four corners per 42 mm cell and
joins them with connector beams, then tiles that cell across your chosen grid. Because
every cell reuses the same inlined geometry, file size and slicing stay tiny even on
large plates.

## Inlining the geometry (and the STL winding gotcha)

The corner and connector parts are modeled by hand (in Shapr3D) and live in `stl/` as
small binary STL meshes. Rather than have the `.scad` `import()` them at render time —
which needs the files alongside the script and is **not supported by MakerWorld's
Parametric Model Maker** — the geometry is **inlined** into `src/gridfinity_base.scad`
as `polyhedron()` blocks. That makes the script a single self-contained file that runs
anywhere.

The mapping lives in the source itself: each inlined module is preceded by a directive
comment naming its STL, e.g.

```
// source-stl: AT Net Rigid Outer Corner.stl (normalize)
module mesh_corner_net_rigid_outer() {
  polyhedron( ... );
}
```

Running `./inline-stls.sh` (a thin wrapper around `tools/inline_stls.py`) scans those
directives, reads each named STL from `stl/`, converts it, and rewrites that module in
place — so after editing a mesh you just re-export the STL and run the script. It can be
run from anywhere; `(normalize)` shifts a corner mesh so its outer corner lands at the
origin.

For a tight edit loop, run `./inline-stls.sh --watch`: it stays running and re-inlines
automatically whenever any `stl/*.stl` changes, so re-exporting from your modeller is
enough to refresh the `.scad` (it only rewrites the file when the geometry actually
changes). Ctrl-C to stop.

Per mesh, the conversion (binary STL → `polyhedron()`) is:

1. **Parse** the binary STL triangles.
2. **Weld** duplicate vertices (round to 4 dp, dedupe) into a points + faces list, so the
   result is a clean manifold rather than triangle soup.
3. **Normalize** corner meshes so the outer corner sits at the origin in the +X +Y
   quadrant (the script then just rotates and places them).
4. **Reverse the face winding** — see below.
5. Emit `polyhedron(points=…, faces=…, convexity=6)`.

### The winding gotcha

STL and OpenSCAD disagree on how a triangle's vertices are ordered:

- **STL** orders them **counter-clockwise as seen from outside** (the outward normal by
  the right-hand rule).
- **OpenSCAD `polyhedron()`** wants them **clockwise from outside**.

So copying STL triangles straight into `polyhedron()` produces **inverted, inside-out
normals**. This is easy to miss because it depends on the rendering backend:

- **CGAL** (older OpenSCAD, e.g. the 2021 macOS build) re-orients faces by topology, so it
  silently fixes the inversion — everything looks fine locally.
- **Manifold** (newer OpenSCAD, and what **MakerWorld** uses) trusts the supplied winding,
  so the inverted faces render inside-out.

That's exactly the bug we hit: the corners and the beam connector (both `polyhedron()`)
showed inside-out on MakerWorld while the native `cube()` connectors were fine, and the
local Mac app looked correct either way. The fix is to **reverse every face**
(`[a,b,c] → [a,c,b]`) during conversion. `tools/inline_stls.py` does this robustly: it
computes each mesh's signed volume and flips the winding whenever the source comes in
counter-clockwise, so the result is correct regardless of how the STL was exported.

## License

MIT — see [LICENSE](LICENSE).
