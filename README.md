# Ultimate Gridfinity Base

The lightest, fastest-printing Gridfinity baseplates — now fully customizable in OpenSCAD.

Part of the **3D Modular Madness** collection. Released on MakerWorld:
https://makerworld.com/en/models/1384108-gridfinity-base-fastest-lightest-customizable

## The variants

All are dramatically lighter and faster to print than anything else on MakerWorld. They form
a stiffness spectrum — pick based on how much rigidity you want (most flexible first):

- **Net** — Maximum flexibility and by far the lightest, fastest print. (`net_light` in the source.)
- **Tape** — Semi-flexible / semi-rigid middle ground. (`net_heavy` in the source.)
- **Net Beam** — The Tape corner paired with a taller beam connector (a thin web rising 4 mm at
  the outer rim with a low base foot), so the grid sides resist flexing far better than Tape for
  only a little more filament. (`net_beam` in the source.)
- **Net Rigid** — A blend between Tape and Rigid: it shares the Rigid corner's 12 mm footprint,
  but with lighter blended geometry and its own shorter connector (3.5 mm tall vs Rigid's
  4.0 mm) — stiffer than Tape, lighter than solid. (`net_rigid` in the source.)
- **Rigid** — Traditional-looking solid Gridfinity base. The familiar look, still trimmed for speed. (`rigid` in the source.)

## Benchmarks

Bambu Studio slicer estimates on an **A1 mini**, normalized per 42 mm tile (most rows are a
4×4 / 16-tile plate). Lower is better on both columns. ★ = this project.

| Model | By | g / tile | s / tile |
|-------|-----|---------:|---------:|
| ★ **3DMM Net** | this project | **0.167** | **23.5** |
| Ultralight+ Gridfinity Bases | DBT85 | 0.267 | 52.3 |
| ★ **3DMM Tape** | this project | 0.326 | 49.9 |
| ★ **3DMM Rigid (Solid)** | this project | 0.500 | 74.4 |
| Lightest Gridfinity Base Ever | Sparky | 0.780 | 96.3 |
| 3DMM Original Ultimate Turbo | this project (old) | 0.828 | 51.9 |
| Gridfinity Lightweight Stackable | DJR Engineering | 1.081 | 123.8 |
| Slim Gridfinity Base (IKEA Alex) | — | 1.258 | 138.9 |
| Gridfinity Simple Base | Schmidsfeld | 1.324 | 243.8 |

Highlights:

- **Net is the lightest and fastest base in the field** — 0.167 g/tile, ~37% less filament
  than the next-lightest (Ultralight+) and ~2.2× faster per tile.
- **Rigid — a traditional, solid-looking base — beats "Lightest Gridfinity Base Ever"** by
  ~36% on filament and ~23% on time, while still looking like a normal Gridfinity base.
- **Tape** adds real semi-rigid cross-bracing for only a little more filament than corner-only
  designs, at comparable print speed (49.9 s/tile vs Ultralight+'s 52.3 s/tile).
- Versus a standard Simple Base, **Net uses ~1/8th the filament and prints ~10× faster** per tile.

## Repo layout

```
src/   OpenSCAD source — the parametric assembler
stl/   Source geometry: per-variant Corner and Connector STLs
```

`src/gridfinity_base.scad` imports the corner STLs from `../stl/` using relative
paths, so keep this folder structure intact.

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
   - **Model** — Net, Tape, Net Beam, Net Rigid, or Rigid
   - **Columns** / **Rows** — grid size in 42 mm cells, in 0.5 steps from 1 to 20.5.
     A `.5` appends a fully-enclosed half-cell (21 mm) column and/or row, for fitting
     odd drawer sizes (e.g. `2.5` = two full cells plus a half)
   - **Drawer Spacers** — front / back / left / right, in mm (0 = none, 41 mm max).
     Adds a triangular spacer that projects outward from that edge so the plate sits
     flush in a drawer. Each is independent, so you can pad just the sides you need.
     A tie-rail runs along the outer edge of each spaced side, locking the spacers
     together for rigidity. Past 41 mm, add another Gridfinity cell instead.
   - **Advanced** — pitch (42 mm = standard Gridfinity) and curve smoothness
4. `F5` to preview, `F6` to render, then **File → Export → Export as STL**.

The **Console** (**View → Console**) prints the total outer footprint in mm
(`Total size: … wide (X) x … deep (Y)`), including any spacers, so you can check it
against your drawer before exporting.

## Customizing your layout (Bambu Studio, no OpenSCAD needed)

For non-rectangular layouts without touching OpenSCAD:

1. Import a full rectangular plate STL.
2. **Ungroup** the plate into individual squares.
3. Select and **delete** the squares you don't want.
4. **Regroup** the remaining squares.
5. Slice and print.

## References & inspiration

These makers did excellent work, and their designs directly inspired this project. They
raised the bar — this project is my attempt to push it further. Go give them a boost.

- **[Ultralight+ Gridfinity Bases](https://makerworld.com/en/models/1226917-ultralight-gridfinity-bases)**
  by DBT85 — Corner-only alignment bases (the grid sides are skipped entirely, since only
  the corners are needed to align bins), with optional pins to connect plates. Roughly
  6.5 g and ~20 min for a 2-wall 5×5 on a P1S. The closest reference point for the
  **Net** and **Tape** variants.
- **[Lightest Gridfinity Base Ever – Customizable](https://makerworld.com/en/models/1685835-lightest-gridfinity-base-ever-customizable)**
  by Sparky — Parametric, skeletonized walls-only base with the bottom lip and inter-grid
  overhangs removed; a 4×4 in ~14 min on a 0.8 mm nozzle (1 wall). The reference point for
  the **Rigid** variant.
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
every cell reuses the same imported geometry, file size and slicing stay tiny even on
large plates.
