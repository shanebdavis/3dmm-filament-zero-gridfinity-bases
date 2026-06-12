// ============================================================
//  AT Ultra-Light Gridfinity Base  —  parametric assembler
// ============================================================
//  Keep this .scad file in the SAME folder as the corner STLs,
//  because import() uses relative paths.
//
//  Open in OpenSCAD, then: Window menu -> Customizer to get the
//  dropdown + sliders below. F5 = preview, F6 = render, then
//  File -> Export -> Export as STL.
// ============================================================

/* [Model] */
// Which base style to build
model = "net_light"; // [net_light:Net Light, net_heavy:Net Heavy, rigid:Solid (Rigid)]

/* [Grid] */
// Squares wide
columns = 2; // [1:1:20]
// Squares tall
rows = 2;    // [1:1:20]

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
    model == "net_light" ? "AT Net Light Corner.stl" :
    model == "net_heavy" ? "AT Net Heavy Corner.stl" :
                           "AT Rigid Corner.stl";

corner_offset =
    model == "net_light" ? [250, 200, 0] :
    model == "net_heavy" ? [300, 200, 0] :
                           [350, 200, 0];

// Corner footprint along an edge (mm)
corner_size = (model == "rigid") ? 12 : 5;

// Connector cross-section: width (across the edge) x height (up)
conn_w = model == "net_light" ? 0.5 :
         model == "net_heavy" ? 2.15 :
                                0.9;   // rigid
conn_h = (model == "rigid") ? 4.0 : 0.5;

// ------------------------------------------------------------
// One imported corner, normalized so its outer corner is at origin
// and it occupies the +X +Y quadrant (profile faces toward center).
module corner_part() {
    translate([-corner_offset[0], -corner_offset[1], -corner_offset[2]])
        import(corner_file);
}

// A connector beam running along +X, flush to the outer edge
// (y: 0..conn_w) and sitting on the bed (z: 0..conn_h).
module connector(len) {
    cube([len, conn_w, conn_h]);
}

// One 42mm (pitch) cell: 4 corners + 4 edge connectors.
// We place the bottom-left corner and its bottom-edge connector,
// then rotate that whole pair 0/90/180/270 about the cell center
// to fill the other three corners and edges.
module cell() {
    gap = pitch - 2 * corner_size;   // length of each connector
    for (a = [0, 90, 180, 270])
        translate([pitch/2, pitch/2, 0])
            rotate([0, 0, a])
                translate([-pitch/2, -pitch/2, 0]) {
                    corner_part();
                    // Butt-joined exactly against the corners — no overlap,
                    // geometry untouched. Coincident faces union cleanly.
                    translate([corner_size, 0, 0])
                        connector(gap);
                }
}

// Tile the cell across the requested grid.
module grid() {
    for (i = [0 : columns - 1], j = [0 : rows - 1])
        translate([i * pitch, j * pitch, 0])
            cell();
}

grid();
