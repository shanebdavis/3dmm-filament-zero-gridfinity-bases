// ============================================================
//  AT Ultra-Light Gridfinity Base  —  parametric assembler
// ============================================================
//  Keep this repo layout intact: this .scad lives in src/ and the
//  corner STLs live in ../stl/, because import() uses relative paths.
//
//  Open in OpenSCAD, then: Window menu -> Customizer to get the
//  dropdown + sliders below. F5 = preview, F6 = render, then
//  File -> Export -> Export as STL.
// ============================================================

/* [Model] */
// Which base style to build
model = "net_light"; // [net_light:Net Light, net_heavy:Net Heavy, net_rigid:Net Rigid, rigid:Solid (Rigid)]

/* [Grid] */
// Squares wide (a .5 adds a half-cell column)
columns = 2; // [1:0.5:20.5]
// Squares tall (a .5 adds a half-cell row)
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
pitch = 42;      // [21:1:84]
// Smoothness of any curves
$fn = 48;

// ---- end of Customizer parameters --------------------------

// Per-model lookup. The "offset" is where each STL currently sits
// in space (Shapr3D laid them out side by side); we subtract it so
// every corner's OUTER corner lands at the origin (0,0).
corner_file =
    model == "net_light" ? "../stl/AT Net Light Corner.stl" :
    model == "net_heavy" ? "../stl/AT Net Heavy Corner.stl" :
    model == "net_rigid" ? "../stl/AT Net Rigid Corner.stl" :
                           "../stl/AT Rigid Corner.stl";

corner_offset =
    model == "net_light" ? [250, 200, 0] :
    model == "net_heavy" ? [300, 200, 0] :
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
        import(corner_file);
}

// ------------------------------------------------------------
// Drawer-spacer extension. The source STL is a 5mm-long triangular prism authored at
// [295..300, 250..253.5, 0..3.5]. Its cross-section (in Y-Z) is a tall 3.5mm "ridge"
// face at Y=250 that tapers down to ~0.5mm at Y=253.5 — the chamfered triangle that
// lines up with a corner. The prism axis (X) is the direction it sticks outward.
ext_file = "../stl/AT Extension.stl";
ext_base_len = 5;   // authored prism length (mm); we scale this to the requested distance

// One extension prism, normalized so the mating face is at X=0 and the tall ridge edge
// is at Y=0, tapering toward +Y and sitting on the bed (Z 0..3.5). Stretched along +X
// (outward) to length L, with a tiny inward overlap so it welds cleanly to the plate.
module extension_part(L) {
    eps = 0.02;
    if (L > 0)
        translate([-eps, 0, 0])
            scale([(L + eps) / ext_base_len, 1, 1])
                translate([-295, -250, 0])
                    import(ext_file);
}

// Connector beams: thin walls that bridge between corners along one edge,
// flush to the outer rim and sitting on the bed (z: 0..conn_h). The length is
// "scaled" to whatever edge it spans — full cells get long ones, half cells get
// short ones. connector_x runs along +X; connector_y runs along +Y.
module connector_x(len) { if (len > 0) cube([len, conn_w, conn_h]); }
module connector_y(len) { if (len > 0) cube([conn_w, len, conn_h]); }

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
    // edges, flush to the outer rim and extending inward
    translate([cs,         0,          0]) connector_x(w - 2 * cs);  // bottom
    translate([cs,         h - conn_w, 0]) connector_x(w - 2 * cs);  // top
    translate([0,          cs,         0]) connector_y(h - 2 * cs);  // left
    translate([w - conn_w, cs,         0]) connector_y(h - 2 * cs);  // right
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

    if (ext_front > 0)                                  // front edge (Y = 0), outward -Y
        for (k = [0 : nx - 1]) { cx = xs[k];
            if (k != nx - 1) translate([cx, 0, 0])                 rotate([0,0,-90]) extension_part(ext_front);
            if (k != 0)      translate([cx, 0, 0]) mirror([1,0,0]) rotate([0,0,-90]) extension_part(ext_front);
        }

    if (ext_back > 0)                                   // back edge (Y = H), outward +Y
        for (k = [0 : nx - 1]) { cx = xs[k];
            if (k != nx - 1) translate([cx, H, 0]) mirror([1,0,0]) rotate([0,0, 90]) extension_part(ext_back);
            if (k != 0)      translate([cx, H, 0])                 rotate([0,0, 90]) extension_part(ext_back);
        }

    if (ext_left > 0)                                   // left edge (X = 0), outward -X
        for (k = [0 : ny - 1]) { cy = ys[k];
            if (k != ny - 1) translate([0, cy, 0]) mirror([0,1,0]) rotate([0,0,180]) extension_part(ext_left);
            if (k != 0)      translate([0, cy, 0])                 rotate([0,0,180]) extension_part(ext_left);
        }

    if (ext_right > 0)                                  // right edge (X = W), outward +X
        for (k = [0 : ny - 1]) { cy = ys[k];
            if (k != ny - 1) translate([W, cy, 0])                 extension_part(ext_right);
            if (k != 0)      translate([W, cy, 0]) mirror([0,1,0]) extension_part(ext_right);
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
