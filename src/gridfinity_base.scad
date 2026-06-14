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
model = "net_light"; // [net_light:Net Light, net_heavy:Net Heavy, net_beam:Net Beam, net_rigid:Net Rigid, rigid:Solid (Rigid)]

/* [Grid] */
// Squares wide (0.5 adds a half-cell column)
columns = 2; // [1:0.5:20.5]
// Squares tall (0.5 adds a half-cell row)
rows = 2;    // [1:0.5:20.5]

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
// Grid spacing in mm (42 = standard gridfinity)
pitch = 42;      // [21:1:168]

// ---- end of Customizer parameters --------------------------

// Per-model lookup. The "offset" is where each STL currently sits
// in space (Shapr3D laid them out side by side); we subtract it so
// every corner's OUTER corner lands at the origin (0,0).
corner_offset =
    model == "net_light" ? [250, 200, 0] :
    model == "net_heavy" ? [300, 200, 0] :
    model == "net_beam"  ? [300, 200, 0] :
    model == "net_rigid" ? [350, 250, 0] :
                           [350, 200, 0];

// Corner footprint along an edge (mm). Net Rigid shares the Rigid corner's 12mm size.
corner_size = (model == "rigid" || model == "net_rigid") ? 12 : 5;

// Connector cross-section: width (across the edge) x height (up).
// Net Rigid uses its own connector: 0.9 wide (shares rigid's width, falls through
// the default) but only 3.5 tall, matching its 3.5mm corner height (vs rigid's 4.0).
conn_w = model == "net_light" ? 0.5 :
         model == "net_heavy" ? 2.15 :
                                0.9;   // rigid + net_rigid
conn_h = model == "rigid"     ? 4.0 :
         model == "net_rigid" ? 3.5 :
                                0.5;

// ------------------------------------------------------------
// One imported corner, normalized so its outer corner is at origin
// and it occupies the +X +Y quadrant (profile faces toward center).
module corner_part() {
    translate([-corner_offset[0], -corner_offset[1], -corner_offset[2]])
        corner_mesh();
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
module rcell(w, h) {
    cs = corner_size;
    // corners, each rotated to face the cell centre
    translate([0, 0, 0])                   corner_part();
    translate([w, 0, 0]) rotate([0, 0,  90]) corner_part();
    translate([w, h, 0]) rotate([0, 0, 180]) corner_part();
    translate([0, h, 0]) rotate([0, 0, 270]) corner_part();
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
        translate([i * pitch, j * pitch, 0]) rcell(pitch, pitch);

    if (half_w)
        for (j = [0 : rows_full - 1])
            translate([cols_full * pitch, j * pitch, 0]) rcell(hw, pitch);

    if (half_h)
        for (i = [0 : cols_full - 1])
            translate([i * pitch, rows_full * pitch, 0]) rcell(pitch, hw);

    if (half_w && half_h)
        translate([cols_full * pitch, rows_full * pitch, 0]) rcell(hw, hw);
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

grid();
spacers();


// ------------------------------------------------------------
// Corner dispatcher: picks the inlined corner mesh for the model.
// (net_beam shares the Net Heavy corner.) Each mesh keeps its
// originally-authored coordinates, so corner_offset still applies.
module corner_mesh() {
    if      (model == "net_light") mesh_corner_net_light();
    else if (model == "net_heavy") mesh_corner_net_heavy();
    else if (model == "net_beam")  mesh_corner_net_heavy();
    else if (model == "net_rigid") mesh_corner_net_rigid();
    else                           mesh_corner_rigid();
}

// ------------------------------------------------------------
// Inlined geometry (was import() of ../stl/*.stl). Vertices welded
// and faces wound for a manifold solid; do not hand-edit.

module mesh_corner_net_light() {
  polyhedron(
    points=[[252.15,205,2.75], [252.15,204,2.75], [252.15,204,2.15], [252.15,205,2.15], [251.4,205,3.5], [251.4,204,3.5], [250.5,204,3.5], [250.5,204,0.5], [250.5,205,0.5], [250,205,3.5], [250,205,0], [250.5,205,0], [250.5,200.5,3.5], [250.5,200.5,0], [250,200,0], [250,200,3.5], [255,200,0], [255,200.5,0], [255,200,3.5], [254,200.5,3.5], [255,201.4,3.5], [254,201.4,3.5], [254,200.5,0.5], [255,200.5,0.5], [255,202.15,2.75], [255,202.15,2.1184], [254,202.15,2.75], [254,202.15,2.1184]],
    faces=[[0,1,2], [2,3,0], [4,5,1], [1,0,4], [2,1,5], [6,7,2], [5,6,2], [2,7,8], [8,3,2], [3,9,4], [10,9,8], [4,0,3], [3,8,9], [8,11,10], [12,13,7], [11,8,7], [7,13,11], [7,6,12], [14,15,9], [9,10,14], [16,14,13], [10,11,13], [13,14,10], [13,17,16], [15,14,16], [16,18,15], [4,9,6], [15,12,6], [15,18,19], [20,21,19], [6,9,15], [19,18,20], [19,12,15], [6,5,4], [17,13,22], [12,19,22], [22,13,12], [22,23,17], [23,24,20], [23,25,24], [16,17,23], [23,18,16], [20,18,23], [22,21,26], [22,19,21], [26,27,22], [26,21,20], [20,24,26], [24,25,27], [27,26,24], [25,23,22], [22,27,25]], convexity=6);
}

module mesh_corner_net_heavy() {
  polyhedron(
    points=[[304,200.5,3.5], [304,200.5,0.5], [300.5,200.5,0.5], [300.5,200.5,3.5], [300.5,204,0.5], [300.5,204,3.5], [302.15,202.15,0.5], [304,202.15,0.5], [302.15,204,0.5], [302.15,204,2.75], [301.4,204,3.5], [304,201.4,3.5], [304,202.15,2.75], [305,201.4,3.5], [305,202.15,2.75], [305,202.15,0], [302.15,202.15,0], [302.15,205,0], [302.15,205,2.75], [301.4,205,3.5], [305,200,0], [305,200,3.5], [300,205,3.5], [300,200,3.5], [300,200,0], [300,205,0]],
    faces=[[0,1,2], [2,3,0], [3,2,4], [4,5,3], [4,2,6], [1,7,6], [6,2,1], [6,8,4], [4,9,10], [4,8,9], [10,5,4], [1,11,12], [1,0,11], [12,7,1], [12,11,13], [13,14,12], [14,15,7], [16,6,7], [7,15,16], [7,12,14], [16,17,8], [18,9,8], [8,17,18], [8,6,16], [19,10,9], [9,18,19], [20,15,14], [14,13,20], [13,21,20], [19,22,5], [23,3,5], [23,21,0], [13,11,0], [5,22,23], [0,21,13], [0,3,23], [5,10,19], [20,24,16], [25,17,16], [16,24,25], [16,15,20], [25,22,19], [19,18,25], [18,17,25], [23,24,20], [20,21,23], [24,23,22], [22,25,24]], convexity=6);
}

module mesh_corner_net_rigid() {
  polyhedron(
    points=[[350,262,3.5], [350.9,262,3.5], [350.9,262,0], [350,262,0], [350,250,0], [350,250,3.5], [362,250,0], [362,250,3.5], [362,250.9,0], [362,250.9,3.5], [355,252.15,0], [352.15,255,0], [352.15,252.15,0], [355,252.15,2.75], [359.2,251.4,3.5], [351.4,259.2,3.5], [352.15,255,2.75], [351.4,254,3.5], [352.15,254,2.75], [352.15,254,0.5], [352.15,252.15,0.5], [354,252.15,0.5], [354,252.15,2.75], [354,251.4,3.5], [350.5,254,0.5], [350.5,254,3.5], [354,250.5,3.5], [350.5,250.5,3.5], [350.5,250.5,0.5], [354,250.5,0.5]],
    faces=[[0,1,2], [2,3,0], [0,3,4], [4,5,0], [4,6,7], [7,5,4], [8,9,7], [7,6,8], [6,4,10], [3,2,11], [4,12,10], [11,4,3], [11,12,4], [10,8,6], [10,13,14], [14,8,10], [14,9,8], [11,2,15], [2,1,15], [15,16,11], [17,18,16], [16,15,17], [12,11,19], [16,18,19], [19,11,16], [19,20,12], [13,10,21], [12,20,21], [21,10,12], [21,22,13], [23,14,13], [13,22,23], [24,18,17], [24,19,18], [17,25,24], [25,17,15], [26,7,14], [15,0,25], [5,27,25], [5,7,26], [7,9,14], [25,0,5], [14,23,26], [26,27,5], [15,1,0], [24,28,20], [29,21,20], [20,28,29], [20,19,24], [29,23,22], [29,26,23], [22,21,29], [26,29,28], [28,27,26], [27,28,24], [24,25,27]], convexity=6);
}

module mesh_corner_rigid() {
  polyhedron(
    points=[[350.9,212,0], [350,212,0], [350,212,4], [350.9,212,4], [350,200,4], [350,200,0], [362,200,0], [362,200,4], [362,200.9,0], [362,200.9,4], [350.9,200.9,0], [352.15,204,1.25], [352.15,202.15,1.25], [354,202.15,1.25], [354,202.15,2.75], [352.15,202.15,2.75], [350.9,200.9,4], [352.15,204,2.75]],
    faces=[[0,1,2], [2,3,0], [4,2,1], [1,5,4], [5,6,7], [7,4,5], [8,9,7], [7,6,8], [6,5,10], [1,0,10], [10,5,1], [10,8,6], [10,0,11], [11,12,10], [10,12,13], [13,8,10], [14,13,12], [12,15,14], [8,13,14], [14,9,8], [2,4,16], [7,9,16], [16,4,7], [16,3,2], [16,15,17], [17,3,16], [16,9,14], [14,15,16], [11,17,15], [15,12,11], [3,17,11], [11,0,3]], convexity=6);
}

module mesh_extension() {
  polyhedron(
    points=[[295,252.15,0], [300,252.15,0], [300,250,0], [295,250,0], [300,250,3.5], [295,250,3.5], [295,250.5,3.5], [295,252.15,0.5], [300,252.15,0.5], [300,250.5,3.5]],
    faces=[[0,1,2], [2,3,0], [3,2,4], [4,5,3], [3,5,6], [6,7,3], [7,0,3], [2,8,9], [2,1,8], [9,4,2], [5,4,9], [9,6,5], [6,9,8], [8,7,6], [7,8,1], [1,0,7]], convexity=6);
}

module mesh_beam() {
  polyhedron(
    points=[[305,230,0], [305,232.15,0], [315,232.15,0], [315,230,0], [305,232.15,0.5], [315,232.15,0.5], [315,230,3.5], [305,230,3.5], [305,230.5,0.5], [305,230.5,3.5], [315,230.5,0.5], [315,230.5,3.5]],
    faces=[[0,1,2], [2,3,0], [2,1,4], [4,5,2], [0,3,6], [6,7,0], [1,0,8], [7,9,8], [8,0,7], [8,4,1], [6,3,10], [2,5,10], [10,3,2], [10,11,6], [4,8,10], [10,5,4], [11,10,8], [8,9,11], [9,7,6], [6,11,9]], convexity=6);
}
