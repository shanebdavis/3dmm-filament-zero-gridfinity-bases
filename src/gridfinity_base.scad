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
model = "net_light"; // [net_light:Net+, net_heavy:Tape+, net_rigid:Beam+, rigid:Beam]

/* [Grid] */
// Squares wide
columns = 2; // [1:0.5:10]
// Squares deep
rows = 2;    // [1:0.5:10]

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

/* [Advanced] */
// Center on the plate
centered = true;
// Grid spacing in mm (42: standard gridfinity, 84: double, 168: quad)
pitch = 42;      // [21:1:168]

// Customize the preview color to match your filament. Use standard HTML color codes: e.g. #ff0000 for red. This does not affect the model output.
preview_color = "#0099ff";

// ---- end of Customizer parameters --------------------------
// Everything below is internal. The [Hidden] group keeps these
// constants (beam_len, ext_base_len, rail_*, etc.) out of the
// OpenSCAD / MakerWorld Customizer UI.
/* [Hidden] */

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
// the right edge. `plus`/`outer`/`both`/`swap` are supplied by rcell; the flexible-net
// models ignore them all.
module corner_part(plus = true, outer = true, both = true, swap = false) {
    if      (model == "net_light")                        mesh_corner_net_light();
    else if (model == "net_heavy" || model == "net_beam") mesh_corner_net_heavy();
    else if (model == "net_rigid") {
        if      (plus && both)  mesh_corner_net_rigid_outer();
        else if (plus)          diag(swap) mesh_corner_net_rigid_innerouter();
        else if (outer && both) mesh_corner_rigid_outer();
        else if (outer)         diag(swap) mesh_corner_rigid_innerouter();
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

// A fully-enclosed rectangular cell, w x h (mm): 4 corners + 4 edge connectors.
// Reduces to the standard 42mm square when w = h = pitch. Connector lengths
// shrink to fit, so half cells (w or h = pitch/2) still close into a rectangle.
// If a corner is too big for the edge (e.g. 12mm rigid corners on a 21mm half
// edge), the connector clamps to 0 and the two corners simply overlap and union.
module rcell(w, h, px = 0, py = 0) {
    cs = corner_size;
    // Classify each cell side that lies on the plate boundary. "exposed" = on the boundary
    // with no drawer spacer (it butts against a neighbouring print, so it wants a Solid+
    // corner); "blocked" = on the boundary but with a spacer (the spacer mates there, so
    // keep a plain Solid corner). px,py are the cell's plate-origin.
    fe = (py == 0)             && (ext_front == 0);   fb = (py == 0)             && (ext_front > 0);
    be = (py + h == plate_h()) && (ext_back  == 0);   bb = (py + h == plate_h()) && (ext_back  > 0);
    le = (px == 0)             && (ext_left  == 0);   lb = (px == 0)             && (ext_left  > 0);
    re = (px + w == plate_w()) && (ext_right == 0);   rb = (px + w == plate_w()) && (ext_right > 0);
    // Whether each side lies on the plate boundary at all (exposed or spacered).
    f = fe || fb;   b = be || bb;   l = le || lb;   r = re || rb;
    // corner_part(plus, outer, both, swap):
    //   plus  = the on-boundary edge is exposed AND neither edge is spacered (Solid+ mate);
    //           a boundary corner with a spacer in either direction falls back to plain Solid.
    //   outer = at least one edge on the boundary; both = both edges on it (a true plate corner).
    //   swap  = the lone boundary edge is the *other* one than this corner's canonical (local
    //           +X) side, so the asymmetric InnerOuter mesh must be mirrored across its diagonal.
    //           Canonical boundary side per corner: front-left->front, front-right->right,
    //           back-right->back, back-left->left.
    translate([0, 0, 0])                     corner_part((fe || le) && !(fb || lb), f || l, f && l, l && !f);
    translate([w, 0, 0]) rotate([0, 0,  90]) corner_part((fe || re) && !(fb || rb), f || r, f && r, f && !r);
    translate([w, h, 0]) rotate([0, 0, 180]) corner_part((be || re) && !(bb || rb), b || r, b && r, r && !b);
    translate([0, h, 0]) rotate([0, 0, 270]) corner_part((be || le) && !(bb || lb), b || l, b && l, b && !l);
    // edges, flush to the outer rim and extending inward. Mirror the top and right so
    // the (asymmetric) beam web lands on the outer rim, matching the bottom and left.
    translate([cs, 0, 0])                  connector_x(w - 2 * cs);  // bottom
    translate([cs, h, 0]) mirror([0,1,0])  connector_x(w - 2 * cs);  // top
    translate([0,  cs, 0])                 connector_y(h - 2 * cs);  // left
    translate([w,  cs, 0]) mirror([1,0,0]) connector_y(h - 2 * cs);  // right
}

// Split the (possibly fractional) grid size into whole cells plus a trailing half.
// A .5 on columns/rows means a half-cell column/row, so 2.5 -> 2 full + 1 half.
cols_full = floor(columns);
rows_full = floor(rows);
half_w = (columns - cols_full) >= 0.5;
half_h = (rows    - rows_full) >= 0.5;

// Tile full cells, then optionally append a half-width column and/or a
// half-height row (plus the half×half corner cell when both are present).
module grid() {
    hw = pitch / 2;
    for (i = [0 : cols_full - 1], j = [0 : rows_full - 1])
        translate([i * pitch, j * pitch, 0]) rcell(pitch, pitch, i * pitch, j * pitch);

    if (half_w)
        for (j = [0 : rows_full - 1])
            translate([cols_full * pitch, j * pitch, 0]) rcell(hw, pitch, cols_full * pitch, j * pitch);

    if (half_h)
        for (i = [0 : cols_full - 1])
            translate([i * pitch, rows_full * pitch, 0]) rcell(pitch, hw, i * pitch, rows_full * pitch);

    if (half_w && half_h)
        translate([cols_full * pitch, rows_full * pitch, 0]) rcell(hw, hw, cols_full * pitch, rows_full * pitch);
}

// ------------------------------------------------------------
// Drawer spacers. Outer-boundary corner positions along X (the front/back edges) and
// Y (the left/right edges): one entry per cell boundary, plus the half-cell boundary.
function hpos() = let(b = [for (i = [0 : cols_full]) i * pitch])
                  half_w ? concat(b, [cols_full * pitch + pitch / 2]) : b;
function vpos() = let(b = [for (j = [0 : rows_full]) j * pitch])
                  half_h ? concat(b, [rows_full * pitch + pitch / 2]) : b;
function plate_w() = cols_full * pitch + (half_w ? pitch / 2 : 0);
function plate_h() = rows_full * pitch + (half_h ? pitch / 2 : 0);

// Lay an extension prism against every outer-boundary corner on each active edge.
// Each corner contributes one prism whose tall ridge sits on the corner's outer point.
// Interior corners are doubled (two back-to-back corners), so their two prisms mirror
// ridge-to-ridge into a single larger triangular spacer; the two ends are single. The
// per-end guards drop the half whose taper would point off the end of the plate.
module spacers() {
    xs = hpos(); ys = vpos();
    W = plate_w(); H = plate_h();
    nx = len(xs); ny = len(ys);

    if (ext_front > 0) {                                // front edge (Y = 0), outward -Y
        for (k = [0 : nx - 1]) { cx = xs[k];
            if (k != nx - 1) translate([cx, 0, 0])                 rotate([0,0,-90]) extension_part(ext_front);
            if (k != 0)      translate([cx, 0, 0]) mirror([1,0,0]) rotate([0,0,-90]) extension_part(ext_front);
        }
        translate([0, -ext_front, 0]) cube([W, rail_w, rail_h]);          // tie-rail at the tips
    }

    if (ext_back > 0) {                                 // back edge (Y = H), outward +Y
        for (k = [0 : nx - 1]) { cx = xs[k];
            if (k != nx - 1) translate([cx, H, 0]) mirror([1,0,0]) rotate([0,0, 90]) extension_part(ext_back);
            if (k != 0)      translate([cx, H, 0])                 rotate([0,0, 90]) extension_part(ext_back);
        }
        translate([0, H + ext_back - rail_w, 0]) cube([W, rail_w, rail_h]);
    }

    if (ext_left > 0) {                                 // left edge (X = 0), outward -X
        for (k = [0 : ny - 1]) { cy = ys[k];
            if (k != ny - 1) translate([0, cy, 0]) mirror([0,1,0]) rotate([0,0,180]) extension_part(ext_left);
            if (k != 0)      translate([0, cy, 0])                 rotate([0,0,180]) extension_part(ext_left);
        }
        translate([-ext_left, 0, 0]) cube([rail_w, H, rail_h]);
    }

    if (ext_right > 0) {                                // right edge (X = W), outward +X
        for (k = [0 : ny - 1]) { cy = ys[k];
            if (k != ny - 1) translate([W, cy, 0])                 extension_part(ext_right);
            if (k != 0)      translate([W, cy, 0]) mirror([0,1,0]) extension_part(ext_right);
        }
        translate([W + ext_right - rail_w, 0, 0]) cube([rail_w, H, rail_h]);
    }
}

// Total outer footprint, including any drawer spacers. Printed to the Console
// (View -> Console) so you can size it against your drawer before exporting.
total_w = plate_w() + ext_left + ext_right;
total_d = plate_h() + ext_front + ext_back;
echo(str("==> Width: ", total_w, " mm"));
echo(str("==> Depth: ", total_d, " mm"));

// The whole assembly. Optionally shifted so its X/Y footprint (plate plus any
// asymmetric spacers) is centered on the origin; Z is left sitting on the bed.
module assembly() { grid(); spacers(); }

color(preview_color) {
    if (centered)
        translate([(ext_left - ext_right - plate_w()) / 2,
                   (ext_front - ext_back - plate_h()) / 2, 0])
            assembly();
    else
        assembly();
}

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
