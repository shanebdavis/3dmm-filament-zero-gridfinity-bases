// ============================================================
//  AT Ultra-Light Gridfinity Base  —  parametric assembler
// ============================================================
//  Self-contained: all geometry is inlined as polyhedron() below, so
//  this single file runs anywhere (incl. MakerWorld's Parametric Model
//  Maker / customizer) with no external STL dependencies.
//
//  Open in OpenSCAD, then: Window menu -> Customizer to get the
//  dropdown + sliders below. F5 = preview, F6 = render, then
//  File -> Export -> Export as STL.
// ============================================================

/* [Model] */
// Which base style to build
model = "rigid"; // [net_light:Net+, net_heavy:Tape+, rigid:Beam, net_rigid:Beam+]

/* [Grid] */
// Squares wide
columns = 4; // [1:0.5:10]
// Squares deep
rows = 4;    // [1:0.5:10]

/* [Drawer Spacers] */
// Outward spacer on each side (mm) so the plate sits flush in a drawer. 0 = none.
// Capped at 41 mm — past that, just add another Gridfinity cell instead.
// Front is the side closest to you when you place the grid on a surface
ext_front = 0; // [0:0.5:41]
// Back is the side furthest from you
ext_back  = 0; // [0:0.5:41]
// Left will be to your left
ext_left  = 0; // [0:0.5:41]
// Right will be to your right
ext_right = 0; // [0:0.5:41]

/* [Custom Shape] */

// Remove squares from row 1 left
row_1_left = 0; // [0:1:9]
// Remove squares from row 1 right
row_1_right = 0; // [0:1:9]
// Remove squares from row 2 left
row_2_left = 0; // [0:1:9]
// Remove squares from row 2 right
row_2_right = 0; // [0:1:9]
// Remove squares from row 3 left
row_3_left = 0; // [0:1:9]
// Remove squares from row 3 right
row_3_right = 0; // [0:1:9]
// Remove squares from row 4 left
row_4_left = 0; // [0:1:9]
// Remove squares from row 4 right
row_4_right = 0; // [0:1:9]
// Remove squares from row 5 left
row_5_left = 0; // [0:1:9]
// Remove squares from row 5 right
row_5_right = 0; // [0:1:9]
// Remove squares from row 6 left
row_6_left = 0; // [0:1:9]
// Remove squares from row 6 right
row_6_right = 0; // [0:1:9]
// Remove squares from row 7 left
row_7_left = 0; // [0:1:9]
// Remove squares from row 7 right
row_7_right = 0; // [0:1:9]
// Remove squares from row 8 left
row_8_left = 0; // [0:1:9]
// Remove squares from row 8 right
row_8_right = 0; // [0:1:9]
// Remove squares from row 9 left
row_9_left = 0; // [0:1:9]
// Remove squares from row 9 right
row_9_right = 0; // [0:1:9]
// Remove squares from row 10 left
row_10_left = 0; // [0:1:9]
// Remove squares from row 10 right
row_10_right = 0; // [0:1:9]

/* [Auto Baseplates] */
// Cover a whole area (a drawer, a shelf) with auto-sized plates: set BOTH cover sizes
// non-zero and the solver fills the area with the largest grid that fits, splits it
// into plates sized for your printer, and turns the leftover millimeters into edge
// spacers so the assembled footprint is exactly what you asked for. While active,
// the Grid, Drawer Spacers and Custom Shape settings above are ignored.
// Total width (mm) of the area to cover. 0 = off.
cover_width = 0; // [0:0.5:2000]
// Total depth (front-to-back, mm) of the area to cover. 0 = off.
cover_depth = 0; // [0:0.5:2000]
// Printer the plates must fit on. Sizes are the largest single-color rectangle from the
// official Bambu Studio machine profiles, not the advertised bed: P1/X1 series lose an
// 18x28mm front-left corner to the filament-cutter stopper (plates print full-depth,
// nudged right of the corner), and the dual-nozzle H2/X2 machines are limited to one
// nozzle's reach for a single color.
printer = "p1s"; // [a1_mini:A1 mini (180x180), a1:A1 (256x256), a2l:A2L (330x320), p1p:P1P (238x256 - cutter corner), p1s:P1S (238x256 - cutter corner), p2s:P2S (256x256), x1c:X1 Carbon (238x256 - cutter corner), x1e:X1E (238x256 - cutter corner), x2d:X2D (256x256), h2s:H2S (340x320), h2d:H2D (325x320 single color), h2d_pro:H2D Pro (325x320 single color), h2c:H2C (325x320 single color), custom:Custom (set below)]
// Printable width (mm), used only when Printer = Custom
custom_print_width = 256; // [100:1:1000]
// Printable depth (mm), used only when Printer = Custom
custom_print_depth = 256; // [100:1:1000]
// Gap between plates in the preview/export, so the slicer can split them into separate objects
tile_gap = 5; // [2:0.5:20]

/* [Advanced] */
// Center on the plate
centered = true;
// Grid spacing in mm (42: standard gridfinity, 84: double, 168: quad)
pitch = 42;      // [21:1:168]

// Auto Baseplates only: render a single plate by number (1 = front-left plate, counting left to right then front to back) instead of the whole layout - use it to export plates one at a time to your slicer. 0 = the whole layout. Ignored on MakerWorld, where every plate already downloads separately.
export_plate = 0; // [0:1:36]

// Customize the preview color to match your filament. Use standard HTML color codes: e.g. #ff0000 for red. This does not affect the model output.
preview_color = "#0099ff";

// ---- end of Customizer parameters --------------------------
// Everything below is internal. The [Hidden] group keeps these
// constants (beam_len, ext_base_len, rail_*, etc.) out of the
// OpenSCAD / MakerWorld Customizer UI.
/* [Hidden] */

// MakerWorld multi-plate switch. When true, nothing renders at the top level and the
// mw_plate_N() / mw_assembly_view() modules (bottom of this file) are the only output —
// MakerWorld's Parametric Model Maker calls them itself and exports a multi-plate 3MF.
// Kept false here so desktop OpenSCAD shows the model; ./make_makerworld.sh flips it
// to generate the upload variant. Do not edit by hand.
mw_export = false;

// Corner footprint along an edge (mm). Solid and Solid+ share the 12mm corner.
corner_size = (model == "rigid" || model == "net_rigid") ? 12 : 5;

// Connector cross-section: width (across the edge) x height (up). Solid+ (net_rigid)
// uses the same 0.9 x 4.0 connector as Solid (rigid) — it looks just like Solid; only
// its outer-perimeter corners differ (see corner_part).
conn_w = model == "net_light" ? 0.5 :
         model == "net_heavy" ? 2.15 :
                                0.9;   // rigid + net_rigid
conn_h = (model == "rigid" || model == "net_rigid") ? 4.0 : 0.5;

// ------------------------------------------------------------
// One corner, already normalized (outer corner at the origin, in the +X +Y quadrant
// with the profile facing the cell centre). Solid (rigid) and Solid+ (net_rigid)
// distinguish corner roles by how many of the corner's two edges lie on the plate
// boundary:
//   both edges on boundary  -> `outer` corner (a true plate corner)
//   one edge on boundary    -> `innerouter` corner (sits mid-edge: one side is the
//                              perimeter wall, the other mates with the neighbouring cell)
//   neither edge on boundary -> `inner` corner (fully interior, where four cells meet)
// `outer` is true whenever at least one edge is on the boundary; `both` narrows that to a
// true plate corner. Solid+ adds the `plus` role: where the on-boundary edge is *exposed*
// (no drawer spacer) it mates with a neighbouring print, so it swaps in the special Solid+
// outer/innerouter mesh; a spacered boundary edge falls back to the plain Solid corner.
//
// The InnerOuter mesh is asymmetric — its outer (perimeter) edge runs along local +X and
// its inner (mating) edge along local +Y. rcell places every corner so local +X points at
// that corner's "canonical" boundary side; when the actual boundary edge is the *other*
// one, `swap` mirrors the mesh across its diagonal (swap X/Y) to put the perimeter wall on
// the right edge. `open` marks a corner whose two adjacent squares are present but whose
// diagonal square was removed by a Custom Shape cut (a re-entrant plate corner). Solid+
// must NOT use the fully-interior corner there: its edge-connector clip only fits an
// intersection where every square-corner presents the connectable outer profile, so any
// missing square at the intersection forces the outer piece on all corners around it.
// Plain Solid has no clip and keeps the interior corner. `plus`/`outer`/`both`/`swap`/
// `open` are supplied by rcell; the flexible-net models ignore them all.
module corner_part(plus = true, outer = true, both = true, swap = false, open = false) {
    if      (model == "net_light")                        mesh_corner_net_light();
    else if (model == "net_heavy" || model == "net_beam") mesh_corner_net_heavy();
    else if (model == "net_rigid") {
        if      (plus && both)  mesh_corner_net_rigid_outer();
        else if (plus)          diag(swap) mesh_corner_net_rigid_innerouter();
        else if (outer && both) mesh_corner_rigid_outer();
        else if (outer)         diag(swap) mesh_corner_rigid_innerouter();
        else if (open)          mesh_corner_net_rigid_outer();
        else                    mesh_corner_rigid_inner();
    }
    else {  // rigid / Solid
        if      (outer && both) mesh_corner_rigid_outer();
        else if (outer)         diag(swap) mesh_corner_rigid_innerouter();
        else                    mesh_corner_rigid_inner();
    }
}

// Mirror children across the corner's diagonal (swap X/Y) when `s` is set — used to flip an
// asymmetric InnerOuter corner so its perimeter wall lands on the correct edge.
module diag(s) {
    if (s) multmatrix([[0,1,0,0],[1,0,0,0],[0,0,1,0],[0,0,0,1]]) children();
    else   children();
}

// ------------------------------------------------------------
// Drawer-spacer extension. The source STL is a 5mm-long triangular prism authored at
// [295..300, 250..253.5, 0..3.5]. Its cross-section (in Y-Z) is a tall 3.5mm "ridge"
// face at Y=250 that tapers down to ~0.5mm at Y=253.5 — the chamfered triangle that
// lines up with a corner. The prism axis (X) is the direction it sticks outward.
ext_base_len = 5;   // authored prism length (mm); we scale this to the requested distance

// Spacer tie-rail: a beam run along the far (outer) edge of the spacers to lock the
// otherwise-cantilevered prisms together. Always the Net Heavy connector profile
// (2.15 wide across the edge x 0.5 tall), regardless of the chosen model.
rail_w = 2.15;
rail_h = 0.5;

// One extension prism, normalized so the mating face is at X=0 and the tall ridge edge
// is at Y=0, tapering toward +Y and sitting on the bed (Z 0..3.5). Stretched along +X
// (outward) to length L, with a tiny inward overlap so it welds cleanly to the plate.
module extension_part(L) {
    eps = 0.02;
    if (L > 0)
        translate([-eps, 0, 0])
            scale([(L + eps) / ext_base_len, 1, 1])
                translate([-295, -250, 0])
                    mesh_extension();
}

// The "Net Beam" model pairs the Net Heavy corner with this taller beam connector: an
// L-shaped section (a 0.5mm-thick web rising to 4mm at the outer rim, plus a 0.5mm-tall
// foot reaching 2.15mm inward). Imported rather than drawn as a cube because the profile
// isn't a box. Authored 10mm long at X 305..315, web face at Y=230, on the bed (Z 0..4).
beam = (model == "net_beam");
beam_len = 10;

// Beam normalized to web-at-Y=0, foot toward +Y, running along +X scaled to len.
module beam_x(len) {
    scale([len / beam_len, 1, 1]) translate([-305, -230, 0]) mesh_beam();
}
// Same beam turned to run along +Y with its web at X=0, foot toward +X (swap X/Y).
module beam_y(len) {
    multmatrix([[0,1,0,0],[1,0,0,0],[0,0,1,0],[0,0,0,1]]) beam_x(len);
}

// Connector beams: walls that bridge between corners along one edge, flush to the outer
// rim and sitting on the bed. Most models use a simple cube (conn_w x conn_h); Net Beam
// substitutes the imported L-section. The length is "scaled" to whatever edge it spans —
// full cells get long ones, half cells get short ones. _x runs along +X; _y along +Y.
module connector_x(len) { if (len > 0) { if (beam) beam_x(len); else cube([len, conn_w, conn_h]); } }
module connector_y(len) { if (len > 0) { if (beam) beam_y(len); else cube([conn_w, len, conn_h]); } }

// A fully-enclosed rectangular cell at grid position (i, j): 4 corners + 4 edge
// connectors. Reduces to the standard 42mm square; a trailing half column/row
// yields w or h = pitch/2 and the connector lengths shrink to fit. If a corner
// is too big for the edge (e.g. 12mm rigid corners on a 21mm half edge), the
// connector clamps to 0 and the two corners simply overlap and union.
module rcell(s, i, j) {
    w = col_w(s, i);  h = row_h(s, j);
    cs = corner_size;
    // Classify each cell side. A side is on the shape boundary when there is no
    // neighbouring cell on that side — either the plate rim, or a jagged step where
    // Custom Shape cuts removed the neighbour. "exposed" = boundary with no drawer
    // spacer (it butts against a neighbouring print, so it wants a Solid+ corner);
    // "blocked" = boundary with a spacer mating there (keep a plain Solid corner).
    // Spacers only run along the outermost rows/columns, so a cut-created step is
    // always exposed, never blocked.
    f = !cell_at(s, i, j - 1);   b = !cell_at(s, i, j + 1);
    l = !cell_at(s, i - 1, j);   r = !cell_at(s, i + 1, j);
    fb = f && (j == 0)              && (s_ext_front(s) > 0);   fe = f && !fb;
    bb = b && (j == s_nrows(s) - 1) && (s_ext_back(s)  > 0);   be = b && !bb;
    lb = l && (i == 0)              && (s_ext_left(s)  > 0);   le = l && !lb;
    rb = r && (i == s_ncols(s) - 1) && (s_ext_right(s) > 0);   re = r && !rb;
    // Diagonal neighbours: a corner with both adjacent squares present but the diagonal
    // square cut away is a re-entrant plate corner ("open" intersection) — see corner_part.
    dfl = !cell_at(s, i - 1, j - 1);   dfr = !cell_at(s, i + 1, j - 1);
    dbl = !cell_at(s, i - 1, j + 1);   dbr = !cell_at(s, i + 1, j + 1);
    // corner_part(plus, outer, both, swap, open):
    //   plus  = the on-boundary edge is exposed AND neither edge is spacered (Solid+ mate);
    //           a boundary corner with a spacer in either direction falls back to plain Solid.
    //   outer = at least one edge on the boundary; both = both edges on it (a true plate corner).
    //   swap  = the lone boundary edge is the *other* one than this corner's canonical (local
    //           +X) side, so the asymmetric InnerOuter mesh must be mirrored across its diagonal.
    //           Canonical boundary side per corner: front-left->front, front-right->right,
    //           back-right->back, back-left->left.
    //   open  = both adjacent squares present but the diagonal square is missing.
    translate([0, 0, 0])                     corner_part((fe || le) && !(fb || lb), f || l, f && l, l && !f, !f && !l && dfl);
    translate([w, 0, 0]) rotate([0, 0,  90]) corner_part((fe || re) && !(fb || rb), f || r, f && r, f && !r, !f && !r && dfr);
    translate([w, h, 0]) rotate([0, 0, 180]) corner_part((be || re) && !(bb || rb), b || r, b && r, r && !b, !b && !r && dbr);
    translate([0, h, 0]) rotate([0, 0, 270]) corner_part((be || le) && !(bb || lb), b || l, b && l, b && !l, !b && !l && dbl);
    // edges, flush to the outer rim and extending inward. Mirror the top and right so
    // the (asymmetric) beam web lands on the outer rim, matching the bottom and left.
    translate([cs, 0, 0])                  connector_x(w - 2 * cs);  // bottom
    translate([cs, h, 0]) mirror([0,1,0])  connector_x(w - 2 * cs);  // top
    translate([0,  cs, 0])                 connector_y(h - 2 * cs);  // left
    translate([w,  cs, 0]) mirror([1,0,0]) connector_y(h - 2 * cs);  // right
    // Re-entrant plate corners (Custom Shape cuts only), plain Solid model: this cell
    // keeps its fully-interior corner at an open intersection, but that mesh has a
    // 0.7 x 0.7 relief notch right at the crossing point (z 0.6..3.25, clearance for
    // bin corners at a 4-cell crossing), so the two neighbours' perimeter walls meet
    // it only along a vertical line — a non-manifold pinch. Plug the notch so the
    // perimeter wall turns the corner solidly — bins never reach it (their ~3.75mm
    // corner radius keeps them well clear of the crossing point). Solid+ swaps in its
    // outer corner at open intersections and the 5mm net corners have no notch, so
    // only plain Solid needs the plug.
    if (model == "rigid") {
        np = 0.7; nz = 3.25;   // notch footprint and height, from mesh_corner_rigid_inner
        if (!f && !l && dfl) translate([0,      0,      0]) cube([np, np, nz]);
        if (!f && !r && dfr) translate([w - np, 0,      0]) cube([np, np, nz]);
        if (!b && !r && dbr) translate([w - np, h - np, 0]) cube([np, np, nz]);
        if (!b && !l && dbl) translate([0,      h - np, 0]) cube([np, np, nz]);
    }
}

// ------------------------------------------------------------
// Plate spec. One generator builds both the manual plate and every Auto Baseplates
// tile, so all per-plate inputs travel together as a single list (OpenSCAD has no
// structs) and everything below takes the spec `s` as its first argument:
//   [cols, rows, ext_front, ext_back, ext_left, ext_right, cuts_left, cuts_right]
// cols/rows may end in .5 (trailing half column/row); the cuts are per-row Custom
// Shape lists, row 1 (front) first — entries beyond the list's length count as 0,
// so an empty list means "no cuts".
function spec(cols, rows, extF, extB, extL, extR, cutsL, cutsR) =
    [cols, rows, extF, extB, extL, extR, cutsL, cutsR];
function s_cols(s)       = s[0];
function s_rows(s)       = s[1];
function s_ext_front(s)  = s[2];
function s_ext_back(s)   = s[3];
function s_ext_left(s)   = s[4];
function s_ext_right(s)  = s[5];
function s_cuts_left(s)  = s[6];
function s_cuts_right(s) = s[7];

// Split the (possibly fractional) grid size into whole cells plus a trailing half.
// A .5 on cols/rows means a half-cell column/row, so 2.5 -> 2 full + 1 half;
// ncols/nrows count the half as one (narrower) cell.
function s_half_w(s) = s_cols(s) - floor(s_cols(s)) >= 0.5;
function s_half_h(s) = s_rows(s) - floor(s_rows(s)) >= 0.5;
function s_ncols(s)  = floor(s_cols(s)) + (s_half_w(s) ? 1 : 0);
function s_nrows(s)  = floor(s_rows(s)) + (s_half_h(s) ? 1 : 0);

// ------------------------------------------------------------
// Cell model. The grid is ncols x nrows cells. Custom Shape cuts remove cells
// from the left/right end of each row, so a cell exists only if its column index
// lands inside the row's surviving span. Everything downstream (corner selection,
// connectors, spacers) asks cell_at() instead of assuming a full rectangle.

// Effective cuts, clamped so every row keeps at least one cell (left wins a tie).
function cut_at(cuts, j) = j < len(cuts) ? cuts[j] : 0;
function cutL(s, j) = min(cut_at(s_cuts_left(s), j),  s_ncols(s) - 1);
function cutR(s, j) = min(cut_at(s_cuts_right(s), j), s_ncols(s) - 1 - cutL(s, j));

// Does a cell exist at column i, row j? False off-grid, so neighbour probes
// like cell_at(s, i, j - 1) work unguarded from edge cells.
function cell_at(s, i, j) =
    i >= 0 && i < s_ncols(s) && j >= 0 && j < s_nrows(s) &&
    i >= cutL(s, j) && i < s_ncols(s) - cutR(s, j);

// Cell sizes: uniform pitch except the trailing half column/row.
function col_w(s, i) = (s_half_w(s) && i == s_ncols(s) - 1) ? pitch / 2 : pitch;
function row_h(s, j) = (s_half_h(s) && j == s_nrows(s) - 1) ? pitch / 2 : pitch;

// Tile every surviving cell. Cell (i, j) sits at [i, j] * pitch (only the
// trailing column/row can be half-size, so origins stay on the pitch grid).
module grid(s) {
    for (i = [0 : s_ncols(s) - 1], j = [0 : s_nrows(s) - 1])
        if (cell_at(s, i, j))
            translate([i * pitch, j * pitch, 0]) rcell(s, i, j);
}

// ------------------------------------------------------------
// Drawer spacers.
function plate_w(s) = floor(s_cols(s)) * pitch + (s_half_w(s) ? pitch / 2 : 0);
function plate_h(s) = floor(s_rows(s)) * pitch + (s_half_h(s) ? pitch / 2 : 0);

// Lay extension prisms along each active edge, but only against cells that survived
// the Custom Shape cuts: the front/back spacers run along the present cells of the
// first/last row, and the left/right spacers only along rows whose cut on that side
// is zero (i.e. rows that actually reach that edge of the plate).
//
// Each present edge cell contributes one prism at each of its two boundary corners,
// tapering inward across the cell, plus its own stretch of tie-rail. Where two
// present cells meet, their prisms land back-to-back and mirror ridge-to-ridge into
// a single larger triangular spacer, and the rail stretches fuse — reproducing the
// old whole-edge layout on a full rectangle, while gaps and run-ends get single
// prisms and the rail stops with them.
module spacers(s) {
    W = plate_w(s); H = plate_h(s);
    extF = s_ext_front(s); extB = s_ext_back(s);
    extL = s_ext_left(s);  extR = s_ext_right(s);

    if (extF > 0)                                       // front edge (Y = 0), outward -Y
        for (i = [0 : s_ncols(s) - 1]) if (cell_at(s, i, 0)) {
            x0 = i * pitch; x1 = x0 + col_w(s, i);
            translate([x0, 0, 0])                 rotate([0,0,-90]) extension_part(extF);
            translate([x1, 0, 0]) mirror([1,0,0]) rotate([0,0,-90]) extension_part(extF);
            translate([x0, -extF, 0]) cube([col_w(s, i), rail_w, rail_h]);   // tie-rail at the tips
        }

    if (extB > 0)                                       // back edge (Y = H), outward +Y
        for (i = [0 : s_ncols(s) - 1]) if (cell_at(s, i, s_nrows(s) - 1)) {
            x0 = i * pitch; x1 = x0 + col_w(s, i);
            translate([x0, H, 0]) mirror([1,0,0]) rotate([0,0, 90]) extension_part(extB);
            translate([x1, H, 0])                 rotate([0,0, 90]) extension_part(extB);
            translate([x0, H + extB - rail_w, 0]) cube([col_w(s, i), rail_w, rail_h]);
        }

    if (extL > 0)                                       // left edge (X = 0), outward -X
        for (j = [0 : s_nrows(s) - 1]) if (cell_at(s, 0, j)) {
            y0 = j * pitch; y1 = y0 + row_h(s, j);
            translate([0, y0, 0]) mirror([0,1,0]) rotate([0,0,180]) extension_part(extL);
            translate([0, y1, 0])                 rotate([0,0,180]) extension_part(extL);
            translate([-extL, y0, 0]) cube([rail_w, row_h(s, j), rail_h]);
        }

    if (extR > 0)                                       // right edge (X = W), outward +X
        for (j = [0 : s_nrows(s) - 1]) if (cell_at(s, s_ncols(s) - 1, j)) {
            y0 = j * pitch; y1 = y0 + row_h(s, j);
            translate([W, y0, 0])                 extension_part(extR);
            translate([W, y1, 0]) mirror([0,1,0]) extension_part(extR);
            translate([W + extR - rail_w, y0, 0]) cube([rail_w, row_h(s, j), rail_h]);
        }
}

// The whole assembly for one plate spec. Optionally shifted (below) so its X/Y
// footprint (plate plus any asymmetric spacers) is centered on the origin; Z is
// left sitting on the bed.
module assembly(s) { grid(s); spacers(s); }

// ------------------------------------------------------------
// Manual mode: one plate built straight from the Customizer settings.
cuts_left  = [row_1_left, row_2_left, row_3_left, row_4_left, row_5_left,
              row_6_left, row_7_left, row_8_left, row_9_left, row_10_left];
cuts_right = [row_1_right, row_2_right, row_3_right, row_4_right, row_5_right,
              row_6_right, row_7_right, row_8_right, row_9_right, row_10_right];
manual_spec = spec(columns, rows, ext_front, ext_back, ext_left, ext_right,
                   cuts_left, cuts_right);

// ------------------------------------------------------------
// Auto Baseplates solver. Active when both cover sizes are set. The grid is the
// largest half-pitch multiple that fits inside the cover area; the leftover width
// splits evenly into the left and right spacers and the leftover depth all goes
// to the back spacer, so the assembled footprint is exactly cover_width x
// cover_depth. The grid is then chunked into plates that each fit the printer.
auto_mode = cover_width > 0 && cover_depth > 0;

// Printer id -> largest single-color printable rectangle [width, depth] in mm, per the
// bed_exclude_area / extruder_printable_area in Bambu Studio's official machine profiles
// (github.com/bambulab/BambuStudio, resources/profiles/BBL/machine):
//   - P1P/P1S/X1C/X1E: 256x256 bed minus an 18x28 front-left cutter-stopper corner.
//     A full-depth 238-wide plate clears it when placed right of the corner. (The A1,
//     A1 mini, P2S and X2D profiles have no excluded bed area.)
//   - H2D/H2D Pro (350x320 bed) and H2C (330x320 bed): one nozzle only reaches 325
//     of the bed width, and a single color prints from one nozzle.
//   - X2D: the left nozzle covers the full 256x256, so single color is unrestricted.
bed_sizes = [
    ["a1_mini", [180, 180]],
    ["a1",      [256, 256]], ["a2l", [330, 320]],
    ["p1p",     [238, 256]], ["p1s", [238, 256]], ["p2s", [256, 256]],
    ["x1c",     [238, 256]], ["x1e", [238, 256]], ["x2d", [256, 256]],
    ["h2s",     [340, 320]],
    ["h2d",     [325, 320]], ["h2d_pro", [325, 320]], ["h2c", [325, 320]],
];
bed = printer == "custom" ? [custom_print_width, custom_print_depth]
                          : bed_sizes[search([printer], bed_sizes)[0]][1];

// Grid size in (possibly fractional) cells, and the leftover slack in mm.
auto_cols = floor(cover_width / (pitch / 2)) / 2;
auto_rows = floor(cover_depth / (pitch / 2)) / 2;
slack_w   = cover_width - auto_cols * pitch;
slack_d   = cover_depth - auto_rows * pitch;

// Chunk `total` cells into per-plate cell counts, scanning from the lead edge.
// `lead`/`tail` are the spacer lengths on the two outermost plates; every plate's
// printed footprint (cells * pitch + its spacers) must fit in `avail`. Plates take
// whole cells only, except the grid's trailing half cell, which (like the tail
// spacer) rides along in the last plate.
function tile_split(total, avail, lead, tail) =
    total * pitch + lead + tail <= avail
        ? [total]
        : let (n = min(floor((avail - lead) / pitch), ceil(total) - 1))
          assert(n >= 1, "Printable area too small for one grid cell plus its edge spacer - pick a bigger printer or a smaller pitch.")
          concat([n], tile_split(total - n, avail, 0, tail));

col_spans = auto_mode ? tile_split(auto_cols, bed[0], slack_w / 2, slack_w / 2) : [];
row_spans = auto_mode ? tile_split(auto_rows, bed[1], 0, slack_d) : [];

// mm position of plate k in the assembled plan: the cells of all plates before it.
function tile_pos(spans, k) = k <= 0 ? 0 : spans[k - 1] * pitch + tile_pos(spans, k - 1);

// The spec for the plate at column ci, row ri of the plan: spacers only on its
// outward-facing edges (interior plate-to-plate edges stay exposed, so Beam+
// puts its interlocking corners there automatically), and no Custom Shape cuts.
function tile_spec(ci, ri) = spec(
    col_spans[ci], row_spans[ri],
    0,                                                 // front: slack all went to the back
    ri == len(row_spans) - 1 ? slack_d     : 0,
    ci == 0                  ? slack_w / 2 : 0,
    ci == len(col_spans) - 1 ? slack_w / 2 : 0,
    [], []);

// Every plate of the plan, laid out in assembled positions plus tile_gap between
// plates — the gap keeps the meshes separate so the slicer can split the export
// into one object per plate ("Split to Objects" in Bambu Studio / Orca).
module auto_layout() {
    for (ci = [0 : len(col_spans) - 1], ri = [0 : len(row_spans) - 1])
        translate([tile_pos(col_spans, ci) + ci * tile_gap,
                   tile_pos(row_spans, ri) + ri * tile_gap, 0])
            assembly(tile_spec(ci, ri));
}

// ------------------------------------------------------------
// Console notes (View -> Console).
if (auto_mode) {
    assert(auto_cols >= 0.5 && auto_rows >= 0.5,
           "Cover area is smaller than half a grid cell - increase cover sizes or reduce the pitch.");
    echo(str("==> Auto Baseplates: covering ", cover_width, " x ", cover_depth, " mm (",
             auto_cols, " x ", auto_rows, " squares) with ",
             len(col_spans), " x ", len(row_spans), " = ",
             len(col_spans) * len(row_spans), " plates"));
    echo(str("==> Slack: ", slack_w / 2, " mm left + ", slack_w / 2,
             " mm right, ", slack_d, " mm back (spacers)"));
    for (ci = [0 : len(col_spans) - 1])
        echo(str("==> Plate column ", ci + 1, ": ", col_spans[ci], " squares wide (",
                 col_spans[ci] * pitch
                     + (ci == 0 ? slack_w / 2 : 0)
                     + (ci == len(col_spans) - 1 ? slack_w / 2 : 0),
                 " mm printed)"));
    for (ri = [0 : len(row_spans) - 1])
        echo(str("==> Plate row ", ri + 1, ": ", row_spans[ri], " squares deep (",
                 row_spans[ri] * pitch + (ri == len(row_spans) - 1 ? slack_d : 0),
                 " mm printed)"));
    echo("NOTE: Auto Baseplates is active - Grid, Drawer Spacers and Custom Shape settings are ignored.");
} else {
    // Total outer footprint, including any drawer spacers, so you can size it
    // against your drawer before exporting.
    echo(str("==> Width: ", plate_w(manual_spec) + ext_left + ext_right, " mm"));
    echo(str("==> Depth: ", plate_h(manual_spec) + ext_front + ext_back, " mm"));

    // Custom Shape sanity notes.
    nrows = s_nrows(manual_spec); ncols = s_ncols(manual_spec);
    for (j = [0 : nrows - 1])
        if (cuts_left[j] != cutL(manual_spec, j) || cuts_right[j] != cutR(manual_spec, j))
            echo(str("NOTE: Row ", j + 1, " cuts clamped to keep at least one square."));
    if (nrows < 10)
        for (j = [nrows : 9])
            if (cuts_left[j] > 0 || cuts_right[j] > 0)
                echo(str("NOTE: Row ", j + 1, " cuts ignored - the grid only has ", nrows, " rows."));
    // Adjacent rows whose surviving spans do not overlap leave the plate in two pieces.
    if (nrows > 1)
        for (j = [0 : nrows - 2])
            if (cutL(manual_spec, j) >= ncols - cutR(manual_spec, j + 1) ||
                cutL(manual_spec, j + 1) >= ncols - cutR(manual_spec, j))
                echo(str("WARNING: Rows ", j + 1, " and ", j + 2,
                         " do not overlap - the plate will be disconnected."));
}

// ------------------------------------------------------------
// Output. Everything printable is reachable two ways — the whole layout at once
// (assembly_view) or one plate at a time (plate) — so the same geometry serves
// desktop OpenSCAD, per-plate STL export, and MakerWorld multi-plate 3MF.

// The whole plan. Centering shifts the X/Y footprint onto the origin — the full
// tile layout (including gaps) in auto mode, the single plate in manual mode.
module assembly_view() {
    if (auto_mode) {
        if (centered)
            translate([slack_w / 2 - (cover_width + (len(col_spans) - 1) * tile_gap) / 2,
                       -(cover_depth + (len(row_spans) - 1) * tile_gap) / 2, 0])
                auto_layout();
        else
            auto_layout();
    } else {
        if (centered)
            translate([(ext_left - ext_right - plate_w(manual_spec)) / 2,
                       (ext_front - ext_back - plate_h(manual_spec)) / 2, 0])
            assembly(manual_spec);
        else
            assembly(manual_spec);
    }
}

n_plates = auto_mode ? len(col_spans) * len(row_spans) : 1;

// One printable plate, centered on the origin (its own build plate). Plates are
// numbered 1..n_plates: 1 = front-left, counting left to right, then front to back.
// Manual mode is a single plate. Out-of-range k renders nothing — MakerWorld
// discards empty plates, which is how the fixed list of mw_plate_N() hooks below
// adapts to the solver's variable plate count.
module plate(k) {
    if (k >= 1 && k <= n_plates) {
        s = auto_mode ? tile_spec((k - 1) % len(col_spans),
                                  floor((k - 1) / len(col_spans)))
                      : manual_spec;
        translate([(s_ext_left(s) - s_ext_right(s) - plate_w(s)) / 2,
                   (s_ext_front(s) - s_ext_back(s) - plate_h(s)) / 2, 0])
            assembly(s);
    }
}

if (auto_mode && n_plates > 36)
    echo(str("WARNING: ", n_plates, " plates - only the first 36 are reachable via ",
             "export_plate / MakerWorld. Use a larger printer or split the cover area."));

if (!mw_export)
    color(preview_color) {
        if (auto_mode && export_plate > 0) plate(export_plate);
        else assembly_view();
    }

// ------------------------------------------------------------
// MakerWorld Parametric Model Maker hooks (multi-plate 3MF output).
// PMM detects modules named mw_plate_N() and exports each as its own build plate;
// mw_assembly_view() is the preview-only assembled view (never exported). Empty
// plates are discarded, so 36 fixed hooks cover any solver outcome up to 6x6
// plates. These are inert on desktop OpenSCAD (nothing calls them); the uploaded
// MakerWorld variant (see make_makerworld.sh) sets mw_export = true so they are
// the only output.
module mw_assembly_view() { color(preview_color) assembly_view(); }
module mw_plate_1()  { color(preview_color) plate(1); }
module mw_plate_2()  { color(preview_color) plate(2); }
module mw_plate_3()  { color(preview_color) plate(3); }
module mw_plate_4()  { color(preview_color) plate(4); }
module mw_plate_5()  { color(preview_color) plate(5); }
module mw_plate_6()  { color(preview_color) plate(6); }
module mw_plate_7()  { color(preview_color) plate(7); }
module mw_plate_8()  { color(preview_color) plate(8); }
module mw_plate_9()  { color(preview_color) plate(9); }
module mw_plate_10() { color(preview_color) plate(10); }
module mw_plate_11() { color(preview_color) plate(11); }
module mw_plate_12() { color(preview_color) plate(12); }
module mw_plate_13() { color(preview_color) plate(13); }
module mw_plate_14() { color(preview_color) plate(14); }
module mw_plate_15() { color(preview_color) plate(15); }
module mw_plate_16() { color(preview_color) plate(16); }
module mw_plate_17() { color(preview_color) plate(17); }
module mw_plate_18() { color(preview_color) plate(18); }
module mw_plate_19() { color(preview_color) plate(19); }
module mw_plate_20() { color(preview_color) plate(20); }
module mw_plate_21() { color(preview_color) plate(21); }
module mw_plate_22() { color(preview_color) plate(22); }
module mw_plate_23() { color(preview_color) plate(23); }
module mw_plate_24() { color(preview_color) plate(24); }
module mw_plate_25() { color(preview_color) plate(25); }
module mw_plate_26() { color(preview_color) plate(26); }
module mw_plate_27() { color(preview_color) plate(27); }
module mw_plate_28() { color(preview_color) plate(28); }
module mw_plate_29() { color(preview_color) plate(29); }
module mw_plate_30() { color(preview_color) plate(30); }
module mw_plate_31() { color(preview_color) plate(31); }
module mw_plate_32() { color(preview_color) plate(32); }
module mw_plate_33() { color(preview_color) plate(33); }
module mw_plate_34() { color(preview_color) plate(34); }
module mw_plate_35() { color(preview_color) plate(35); }
module mw_plate_36() { color(preview_color) plate(36); }

// ============================================================
//  INLINED GEOMETRY
// ============================================================
//  Each module below is generated from the STL named in its `// source-stl:` comment
//  by tools/inline_stls.py. Do NOT hand-edit the polyhedron data — edit the STL in
//  stl/ and re-run `python3 tools/inline_stls.py`. Winding is reversed from the source
//  (STL is CCW-from-outside; OpenSCAD polyhedron() wants CW); `(normalize)` shifts a
//  corner mesh so its outer corner sits at the origin in the +X +Y quadrant.
// ============================================================

// source-stl: AT Net Light Corner.stl (normalize)
module mesh_corner_net_light() {
  polyhedron(
    points=[[2.15,5,2.75], [2.15,4,2.75], [2.15,4,2.15], [2.15,5,2.15], [1.9,5,3], [1.9,4,3], [0.5,4,3], [0.5,4,0.5], [0.5,5,0.5], [0,5,3], [0,5,0], [0.5,5,0], [0.5,0.5,3], [0.5,0.5,0], [0,0,0], [0,0,3], [5,0,0], [5,0.5,0], [5,0,3], [4,0.5,3], [5,1.9,3], [4,1.9,3], [4,0.5,0.5], [5,0.5,0.5], [5,2.15,2.1184], [5,2.15,2.75], [4,2.15,2.75], [4,2.15,2.1184]],
    faces=[[0,2,1], [2,0,3], [4,1,5], [1,4,0], [6,1,2], [6,2,7], [1,6,5], [2,8,7], [8,2,3], [9,0,4], [10,8,9], [0,9,3], [3,9,8], [8,10,11], [12,7,13], [11,7,8], [7,11,13], [7,12,6], [9,14,10], [14,9,15], [16,13,14], [10,13,11], [13,10,14], [13,16,17], [15,16,14], [16,15,18], [4,6,9], [15,6,12], [15,19,18], [20,19,21], [6,15,9], [19,20,18], [19,15,12], [6,4,5], [17,22,13], [12,22,19], [22,12,13], [22,17,23], [18,24,23], [24,18,25], [16,23,17], [23,16,18], [25,18,20], [19,27,26], [19,26,21], [27,19,22], [26,20,21], [20,26,25], [25,27,24], [27,25,26], [24,22,23], [22,24,27]], convexity=6);
}

// source-stl: AT Net Heavy Corner.stl (normalize)
module mesh_corner_net_heavy() {
  polyhedron(
    points=[[4,0.5,3], [4,0.5,0.5], [0.5,0.5,0.5], [0.5,0.5,3], [0.5,4,0.5], [0.5,4,3], [2.15,2.15,0.5], [4,2.15,0.5], [2.15,4,0.5], [2.15,4,2.75], [1.9,4,3], [4,1.9,3], [4,2.15,2.75], [5,1.9,3], [5,2.15,2.75], [5,2.15,0], [2.15,2.15,0], [2.15,5,0], [2.15,5,2.75], [1.9,5,3], [5,0,0], [5,0,3], [0,5,3], [0,0,3], [0,0,0], [0,5,0]],
    faces=[[0,2,1], [2,0,3], [3,4,2], [4,3,5], [4,6,2], [1,6,7], [6,1,2], [6,4,8], [4,9,8], [9,4,5], [9,5,10], [1,12,11], [1,11,0], [12,1,7], [11,14,13], [14,11,12], [14,7,15], [16,7,6], [7,16,15], [7,14,12], [16,8,17], [18,8,9], [8,18,17], [8,16,6], [19,9,10], [9,19,18], [20,14,15], [14,20,13], [13,20,21], [19,5,22], [23,5,3], [23,0,21], [13,0,11], [5,23,22], [0,13,21], [0,23,3], [5,19,10], [20,16,24], [25,16,17], [16,25,24], [16,20,15], [25,18,22], [22,18,19], [18,25,17], [23,20,24], [20,23,21], [22,24,25], [24,22,23]], convexity=6);
}

// source-stl: AT Net Rigid Outer Corner.stl (normalize)
module mesh_corner_net_rigid_outer() {
  polyhedron(
    points=[[4,0,4], [12,0,4], [12,0.9,4], [4,0.9,4], [5,2.15,2.75], [4,2.15,2.75], [12,0.9,0], [5,2.15,0], [12,0,0], [4,2.15,0.5], [2.15,2.15,0], [2.15,2.15,0.5], [4,0.5,0.5], [4,0.5,3], [4,0,3], [0,0,0], [0,0,3], [0.5,0.5,0.5], [0.5,0.5,3], [0.5,4,0.5], [2.15,4,0.5], [0,4,3], [0.5,4,3], [0,12,0], [0.9,12,0], [2.15,5,0], [0,12,4], [0,4,4], [0.9,12,4], [2.15,4,2.75], [0.9,4,4], [2.15,5,2.75]],
    faces=[[0,2,1], [2,0,3], [3,4,2], [4,3,5], [6,4,7], [4,6,2], [6,1,2], [1,6,8], [4,9,7], [10,9,11], [9,10,7], [9,4,5], [12,5,13], [0,13,3], [5,12,9], [13,5,3], [13,0,14], [15,14,8], [1,14,0], [14,1,8], [14,15,16], [13,17,12], [17,13,18], [19,11,17], [12,11,9], [11,12,17], [11,19,20], [21,18,16], [14,18,13], [18,14,16], [18,21,22], [17,22,19], [22,17,18], [8,7,15], [23,25,24], [15,7,10], [25,23,15], [25,15,10], [7,8,6], [26,21,23], [15,21,16], [21,15,23], [21,26,27], [26,24,28], [24,26,23], [19,29,20], [29,22,30], [27,22,21], [22,27,30], [29,19,22], [10,20,25], [31,20,29], [20,31,25], [20,10,11], [28,27,26], [27,28,30], [30,31,29], [31,30,28], [24,31,28], [31,24,25]], convexity=6);
}

// source-stl: AT Rigid InnerOuter Corner.stl (normalize)
module mesh_corner_rigid_innerouter() {
  polyhedron(
    points=[[0.9,12,0], [0,12,0], [0,12,4], [0.9,12,4], [0,0,4], [0,0,0], [12,0,0], [12,0,4], [12,0.9,0], [12,0.9,4], [0.9,0.9,0], [2.15,4,1.25], [2.15,2.15,1.25], [4,2.15,1.25], [4,2.15,2.75], [2.15,2.15,2.75], [0.9,0.9,4], [2.15,4,2.75]],
    faces=[[0,2,1], [2,0,3], [4,1,2], [1,4,5], [5,7,6], [7,5,4], [8,7,9], [7,8,6], [6,10,5], [1,10,0], [10,1,5], [10,6,8], [10,11,0], [11,10,12], [10,13,12], [13,10,8], [14,12,13], [12,14,15], [8,14,13], [14,8,9], [2,16,4], [7,16,9], [16,7,4], [16,2,3], [16,17,15], [17,16,3], [16,14,9], [14,16,15], [11,15,17], [15,11,12], [3,11,17], [11,3,0]], convexity=6);
}

// source-stl: AT Net Rigid InnerOuter Corner.stl (normalize)
module mesh_corner_net_rigid_innerouter() {
  polyhedron(
    points=[[4,0,4], [12,0,4], [12,0.9,4], [4,0.9,4], [5,2.15,2.75], [4,2.15,2.75], [12,0.9,0], [5,2.15,0], [12,0,0], [4,2.15,0.5], [2.15,2.15,0], [2.15,2.15,0.5], [4,0.5,0.5], [4,0.5,3], [4,0,3], [0,0,0], [0,0,3], [0.5,0.5,0.5], [0.5,0.5,3], [0.5,4,0.5], [2.15,4,0.5], [0,4,3], [0.5,4,3], [0,12,0], [0.9,12,0], [2.15,5,0], [0,12,4], [0,4,4], [0.9,12,4], [2.15,4,2.75], [0.9,4,4], [2.15,5,2.75]],
    faces=[[0,2,1], [2,0,3], [3,4,2], [4,3,5], [6,4,7], [4,6,2], [6,1,2], [1,6,8], [4,9,7], [10,9,11], [9,10,7], [9,4,5], [12,5,13], [0,13,3], [5,12,9], [13,5,3], [13,0,14], [15,14,8], [1,14,0], [14,1,8], [14,15,16], [13,17,12], [17,13,18], [19,11,17], [12,11,9], [11,12,17], [11,19,20], [21,18,16], [14,18,13], [18,14,16], [18,21,22], [17,22,19], [22,17,18], [8,7,15], [23,25,24], [15,7,10], [25,23,15], [25,15,10], [7,8,6], [26,21,23], [15,21,16], [21,15,23], [21,26,27], [26,24,28], [24,26,23], [19,29,20], [29,22,30], [27,22,21], [22,27,30], [29,19,22], [10,20,25], [31,20,29], [20,31,25], [20,10,11], [28,27,26], [27,28,30], [30,31,29], [31,30,28], [24,31,28], [31,24,25]], convexity=6);
}

// source-stl: AT Rigid Inner Corner.stl (normalize)
module mesh_corner_rigid_inner() {
  polyhedron(
    points=[[0.9,0.9,4], [2.15,2.15,2.75], [2.15,4,2.75], [0.9,12,4], [12,0.9,4], [4,2.15,2.75], [4,2.15,1.25], [2.15,2.15,1.25], [2.15,4,1.25], [0.9,0.9,0], [0.9,12,0], [12,0.9,0], [12,0,0], [0,0,0], [0,12,0], [0,12,4], [0,0,4], [12,0,4], [0.4,12,3.25], [0.4,12,0.6], [0,12,0.6], [0,12,3.25], [0.4,11.9,3.25], [0,11.9,3.25], [0,11.9,0.6], [0.4,11.9,0.6], [0,0.7,3.25], [0,0.7,0.6], [0,0,0.6], [0,0,3.25], [0.7,0.7,3.25], [0.7,0,3.25], [0.7,0.7,0.6], [0.7,0,0.6], [11.9,0,0.6], [12,0,0.6], [11.9,0,3.25], [12,0,3.25], [12,0.4,0.6], [12,0.4,3.25], [11.9,0.4,3.25], [11.9,0.4,0.6]],
    faces=[[0,2,1], [2,0,3], [0,5,4], [5,0,1], [5,7,6], [7,5,1], [8,1,2], [1,8,7], [9,8,10], [8,9,7], [9,6,7], [6,9,11], [11,5,6], [5,11,4], [3,8,2], [8,3,10], [12,9,13], [14,9,10], [9,14,13], [9,12,11], [15,0,16], [17,0,4], [0,17,16], [0,15,3], [15,18,3], [10,18,19], [18,10,3], [14,19,20], [19,14,10], [18,15,21], [22,21,23], [21,22,18], [20,25,24], [25,20,19], [22,24,25], [24,22,23], [22,19,18], [19,22,25], [16,26,23], [27,23,26], [23,27,24], [13,27,28], [14,24,13], [27,13,24], [26,16,29], [15,23,21], [23,15,16], [24,14,20], [30,29,31], [29,30,26], [32,28,27], [28,32,33], [31,32,30], [32,31,33], [26,32,27], [32,26,30], [31,34,33], [12,34,35], [13,33,12], [34,12,33], [34,31,36], [16,31,29], [17,36,16], [31,16,36], [33,13,28], [36,17,37], [12,38,11], [11,39,4], [39,11,38], [17,39,37], [39,17,4], [38,12,35], [39,36,37], [36,39,40], [34,38,35], [38,34,41], [40,38,41], [38,40,39], [36,41,34], [41,36,40]], convexity=6);
}

// source-stl: AT Rigid Outer Corner.stl (normalize)
module mesh_corner_rigid_outer() {
  polyhedron(
    points=[[0.9,12,0], [0,12,0], [0,12,4], [0.9,12,4], [0,0,4], [0,0,0], [12,0,0], [12,0,4], [12,0.9,0], [12,0.9,4], [0.9,0.9,0], [2.15,4,1.25], [2.15,2.15,1.25], [4,2.15,1.25], [4,2.15,2.75], [2.15,2.15,2.75], [0.9,0.9,4], [2.15,4,2.75]],
    faces=[[0,2,1], [2,0,3], [4,1,2], [1,4,5], [5,7,6], [7,5,4], [8,7,9], [7,8,6], [6,10,5], [1,10,0], [10,1,5], [10,6,8], [10,11,0], [11,10,12], [10,13,12], [13,10,8], [14,12,13], [12,14,15], [8,14,13], [14,8,9], [2,16,4], [7,16,9], [16,7,4], [16,2,3], [16,17,15], [17,16,3], [16,14,9], [14,16,15], [11,15,17], [15,11,12], [3,11,17], [11,3,0]], convexity=6);
}

// source-stl: AT Extension.stl
module mesh_extension() {
  polyhedron(
    points=[[295,252.15,0], [300,252.15,0], [300,250,0], [295,250,0], [300,250,3], [295,250,3], [295,250.5,3], [295,252.15,0.5], [300,252.15,0.5], [300,250.5,3]],
    faces=[[0,2,1], [2,0,3], [3,4,2], [4,3,5], [3,6,5], [6,3,7], [7,3,0], [2,9,8], [2,8,1], [9,2,4], [5,9,4], [9,5,6], [6,8,9], [8,6,7], [7,1,8], [1,7,0]], convexity=6);
}

// source-stl: AT Net Heavy Beam Connector.stl
module mesh_beam() {
  polyhedron(
    points=[[305,230,0], [305,232.15,0], [315,232.15,0], [315,230,0], [305,232.15,0.5], [315,232.15,0.5], [315,230,3], [305,230,3], [305,230.5,0.5], [305,230.5,3], [315,230.5,0.5], [315,230.5,3]],
    faces=[[0,2,1], [2,0,3], [2,4,1], [4,2,5], [0,6,3], [6,0,7], [1,8,0], [7,8,9], [8,7,0], [8,1,4], [6,10,3], [2,10,5], [10,2,3], [10,6,11], [4,10,8], [10,4,5], [11,8,10], [8,11,9], [9,6,7], [6,9,11]], convexity=6);
}
