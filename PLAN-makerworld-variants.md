# Plan: Split MakerWorld Customizers (Single-Plate / Multi-Plate / Dev)

## The actual problem we're solving

MakerWorld's Parametric Model Maker (PMM) can export Auto Baseplates as a proper
multi-plate 3MF, but **we get almost no control over the print settings inside that
3MF**. This model needs heavily customized settings (ultra-light lattice), so the
downloaded 3MF has a bad print profile. Today the workaround is instructing the user
to open the downloaded 3MF, export every object out of it, and re-import them into a
properly configured print-profile 3MF — very tedious. The goal of every strategy below
is to reduce or eliminate that tedium.

Two strategies will be tried in parallel:

- **Strategy A** (this document, specified): restructure into purpose-built customizers
  so each MakerWorld listing is simple and the STL-friendly path stays first-class.
- **Strategy B** (TBD): to be specified next — a different attack on the print-profile
  problem itself.

## Current architecture (research summary)

- **`src/gridfinity_base.scad`** — single self-contained source of truth. Customizer
  sections in order: `[Model]`, `[Grid]`, `[Drawer Spacers]`, `[Custom Shape]`,
  `[Auto Baseplate Set Generation]`, `[Advanced]`, then `[Hidden]` internals, engine
  code, the Auto Baseplates solver, output modules (`assembly_view()`, `plate(k)`),
  a top-level render guarded by `if (!mw_export)`, and the inlined mesh modules.
- **`src/makerworld_hooks.scad`** — 36 `mw_plate_N()` modules + `mw_assembly_view()`.
  Must never coexist with a live top-level render (PMM renders the top level into
  every plate), which is why hooks live in a separate file.
- **`make_makerworld.sh`** — builds the current multi-plate upload variant:
  flips `mw_export = false` → `true` in the combined source, appends the hooks, writes
  `build/3DMM Filament Zero Gridfinity Baseplates.scad`.
- **`export_plates.sh`** — renders each auto plate to its own STL by passing
  `-D export_plate=k`. **Depends on the `export_plate` parameter existing.**
- **`generate.sh`** — batch STL renders of standard sizes from the combined source.
- **`inline-stls.sh` / `tools/inline_stls.py`** — regenerates the inlined
  `polyhedron()` modules inside `src/gridfinity_base.scad` (hardcoded path).
- OpenSCAD semantics that make this plan cheap: top-level variables are declarative
  (single assignment, position doesn't affect resolution), and everything after a
  `/* [Hidden] */` group header is excluded from the Customizer UI. So "removing" a
  parameter from a variant = moving its assignment into a hidden block; all engine
  code compiles unchanged.

## Strategy A: three build outputs from one source

### Source organization: keep the combined file (recommended)

Keep `src/gridfinity_base.scad` as the one source of truth, and add lightweight
**section markers** (comments like `// @section grid`) around the Customizer parameter
blocks. A new build tool assembles variants by transforming only the parameter header
(reorder sections, demote pinned params to a hidden block, flip `mw_export`) and
appending hooks where needed. The engine/solver/mesh code is byte-identical in every
variant.

Why not split into fragment files assembled by concatenation? It was considered
(`params_*.scad` + `core.scad` + `solver.scad` + per-target output files), but:

- The dev iteration cycle gets *worse*: you can no longer just open the src file in
  OpenSCAD and hit F5 — you'd have to rebuild after every edit or develop against a
  build artifact.
- `tools/inline_stls.py` and both shell scripts would need repointing.
- Cross-section references (e.g. `assembly_view()` touches manual *and* auto params)
  force either per-target code surgery or hidden-pin shims anyway — the same mechanism
  the header transform uses, with more moving parts.

With the combined file, **the dev "third output" is just `src/gridfinity_base.scad`
itself** — open it locally, full manual + auto capability, fastest possible iteration,
no MakerWorld anything (top level renders because `mw_export = false`). For symmetry
the build can still copy it to `build/` as the dev artifact, but nothing requires it.

### The three outputs

| Output | File (build/) | Audience |
|---|---|---|
| Single-Plate Customizer | `<single-name>.scad` | MakerWorld listing #1 |
| Multi-Plate Customizer | `<multi-name>.scad` | MakerWorld listing #2 |
| Dev / full combined | `src/gridfinity_base.scad` (optionally copied to build/) | local OpenSCAD |

MakerWorld names the downloaded file after the uploaded `.scad`, so the two build
filenames are product names — **naming decision needed** (e.g. "3DMM Filament Zero
Gridfinity Baseplate" vs "…Baseplate Set"; today's multi-plate name is
"3DMM Filament Zero Gridfinity Baseplates").

### Single-Plate Customizer

- Visible sections, in order: `[Model]`, `[Grid]`, `[Drawer Spacers]`,
  `[Custom Shape]`, `[Advanced]` (centered, pitch, preview color — **no
  `export_plate`**).
- Pinned hidden: `cover_width = 0`, `cover_depth = 0`, `printer`, custom print sizes,
  `tile_gap`, `mw_safe_plates`, `export_plate = 0`. Auto mode can never activate;
  the solver code is present but dead (harmless, small).
- No plate hooks, `mw_export` stays false → normal top-level render, so **MakerWorld
  keeps STL download enabled** — this is the easy on-ramp into a properly configured
  print-profile 3MF (import STL into our published profile).

### Multi-Plate Customizer

- Visible sections, in order: `[Model]`, then `[Auto Baseplate Set Generation]`
  promoted to slot 2 with **printer picker first, cover width/depth second** (basic
  operation: pick printer → pick area), then custom print sizes, `mw_safe_plates`;
  finally `[Advanced]` (centered, pitch, `tile_gap` moves here as a preview-only
  knob, preview color — no `export_plate`).
- Pinned hidden: `columns`, `rows`, all four `spacer_*`, all twenty `row_N_left/right`
  cut params, `export_plate = 0`.
- Built like today's variant: `mw_export = true` + hooks appended.
- **Decision needed — cover defaults**: with cover sizes defaulting to 0, auto mode is
  off and the variant renders a fallback 4×4 manual plate (current behavior). Options:
  (a) non-zero defaults (e.g. 400×400) so the first preview shows the real product,
  (b) keep 0 defaults + console note. Recommend (a).

### Build tool

Replace `make_makerworld.sh` with `tools/build_variants.py` (+ thin `build.sh`
wrapper, matching the repo's existing script style):

1. Parse `src/gridfinity_base.scad` into marked parameter sections + body.
2. For each variant: emit header (variant's section order), then a
   `/* [Hidden] */ // pinned by build` block for demoted params, then the unchanged
   body; flip `mw_export` and append `src/makerworld_hooks.scad` for the multi
   variant only.
3. Keep the existing sanity checks from `make_makerworld.sh` (marker present, hooks
   present, no `mw_` modules in src).
4. Fail loudly if a section marker or expected parameter is missing, so drift between
   the source and the build tool is caught immediately.

`export_plates.sh`, `generate.sh`, `inline-stls.sh` keep working against
`src/gridfinity_base.scad` untouched. `export_plate` stays in the source (hidden-group
or Advanced — it can simply move to `[Hidden]` in the source too, since it's a
scripting hook, not a UI feature; `-D` overrides work on hidden variables).

### Verification

- Render each variant headless: single-plate manual case, multi-plate cover case,
  dev both — assert manifold + expected footprint (reuse the existing test approach).
- Diff check: variant body must be byte-identical to source body (only headers differ).
- Customizer smoke test: open each variant in desktop OpenSCAD's Customizer and
  confirm section order and absence of pinned params.
- MakerWorld upload checklist (manual): multi variant generates N plates, empty plates
  discarded, no top-level bleed into plates; single variant still offers STL download.
- README: rewrite the "Publishing on MakerWorld" section for the two-listing setup.

### Open decisions

1. Product names for the two uploaded `.scad` files.
2. Multi-plate cover-size defaults (recommend non-zero, e.g. 400×400).
3. Whether cover sliders should have a non-zero minimum (e.g. 42) in the multi variant.
4. Whether to also emit the dev file into `build/` or leave `src/` as the dev artifact.

## Strategy B: STL-only, "Split to Objects" workflow

Drop MakerWorld multi-plate (PMM hook) support entirely. Every path — single plate
and multi-plate — exports **one STL**. The user workflow becomes:

1. Open one of our published, optimized print-profile 3MFs in Bambu Studio.
2. Import the downloaded STL.
3. Multi-plate only: click the object → **Split to Objects** → press **A**
   (auto-arrange). Three inputs total — far easier than exporting objects out of
   PMM's badly-profiled 3MF into a good one.

This keeps the user inside a correct print profile the whole time, which is the
actual problem being solved.

### The blocker: Split to Objects splits too much

Bambu's Split to Objects separates a mesh into its topologically connected
components. Plates were designed for this and split perfectly — except for small
box-shaped interior support structures inside the Beam/Beam+ corners, which break
out as dozens of tiny loose objects.

**Research findings (measured, 3×3 plate, `rigid` and `net_rigid`):**

- `rigid` and `net_rigid` plates: **21 shells** — 1 main body + 20 floating boxes.
  `net_light` / `net_heavy` plates: already **1 shell** (not affected). All 15 source
  STLs in `stl/` are single shells — the boxes emerge during CSG assembly.
- The floating boxes, all spanning **Z 0.6..3.25** (the bin-clearance relief-notch
  band of the Solid corner meshes):
  - **1.4 × 1.4 mm pillar** centered on every interior 4-cell crossing point
    (formed by the four meshes' 0.7×0.7 origin notches surrounding it);
  - **0.8 × 0.1 mm sliver** at every interior corner-arm tip (the wall material
    between an arm's own 0.4-wide tip notch and the mating arm's coincident face).
  - Count scales with interior intersections: a 3×3 plate has 4 crossings × (1
    pillar + 4 arm-tip slivers) = 20.
- **Key fact (established by signed-volume analysis):** the boxes are not solid
  pillars — they are **sealed internal air pockets** (their shells have negative
  signed volume). The four meshes' notches combine into enclosed cavities buried
  inside the double walls. They are intentional: the cavity splits the wide wall
  into separated perimeter lines when sliced. But a sealed cavity is *always* a
  separate closed shell in any exported mesh.

### Answers to the two proposed fixes

**"Rearrange the data so the slicer knows they belong to the object" — not possible
in STL.** STL is a bag of triangles with no object/part structure; Split to Objects
has exactly one input signal, mesh connectivity — and a sealed cavity's boundary can
never be connected to the outer boundary. Worse, today's split workflow silently
*deletes the inner structure*: after splitting, the plate object has lost its
cavities (they became the loose boxes), so the walls slice solid.

**"Zero-width connecting plane" — not producible and not reliable.** OpenSCAD's CSG
only emits solid manifolds (a zero-thickness wall can't survive a union), and a
post-processed degenerate wall makes the file non-manifold, inviting import repair
to delete or re-split it. (Solid-to-solid epsilon welds were also tried and are
useless here — there is nothing solid to weld the "boxes" to; they are air.)

### The fix (implemented): vent each cavity to the underside

A cavity stops being a separate shell the moment it connects to outside air. Each
pocket gets a hair-thin vent channel cut down through the 0.6mm floor to the bed
(`crossing_vents()` in `src/gridfinity_base.scad`, subtracted in `assembly()` for
`rigid`/`net_rigid` only):

- one 0.2 × 0.2 channel under the crossing pocket, one 0.1 × 0.2 channel under each
  arm-tip pocket, at every interior 4-cell crossing;
- far below one extrusion line width, so slicers drop them from toolpaths — the
  printed plate is unchanged — and they exit via the underside, invisible on the
  finished print;
- the cavities survive as (now open) pockets, preserving the separated-wall
  structure, and survive Split to Objects attached to their plate.

### Verification (done locally, pending Bambu Studio confirmation)

- Shell counts after venting: Beam and Beam+ 3×3 = **1 shell** (was 21); 2.5×2.5
  half-cells, 4×4 with Custom Shape cuts, 3×3 with spacers = 1 shell each;
  Net+/Tape+ unchanged at 1; auto layout 500×450/P1S = **6 shells for 6 plates**.
- Volume accounting is exact: 3×3 Beam = 7102.6 (outer) − 24.17 (cavities kept)
  − 0.29 (vent floor material) = 7078.1 mm³ measured.
- Test STLs for Bambu Studio in `build/split-test/`: import → Split to Objects →
  expect plates only, no loose boxes; slice and confirm vents don't appear in
  toolpaths and cavity walls still slice as separated perimeters.
- Worth adding `tools/check_shells.py` to encode the 1-shell-per-plate contract.

### Consequences for Strategy A if B is adopted

- `src/makerworld_hooks.scad`, `make_makerworld.sh`, `mw_export`, and
  `mw_safe_plates` are all deleted rather than restructured.
- The two MakerWorld customizers from Strategy A remain a good idea (the parameter
  simplification stands on its own), but the multi-plate variant becomes a plain
  STL-download listing whose output is the gapped auto layout — no PMM hooks, no
  3MF path, no 235 mm arranger cap (that cap existed only for PMM's arranger).
- README's publishing section documents the 3-click workflow (import → split →
  arrange) alongside the published print-profile 3MFs.

## Recommendation

The strategies compose rather than compete: B fixes the export/profile problem, A
fixes the customizer UX. Suggested order: implement the weld plugs first (small,
self-contained, testable locally), verify Split to Objects behaves in Bambu Studio,
then do the A restructure with B's simplifications (no hooks/mw_export machinery at
all), which makes the build tool even thinner.
