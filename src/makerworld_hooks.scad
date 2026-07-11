// ============================================================
//  MakerWorld Parametric Model Maker multi-plate hooks
// ============================================================
//  Appended to the end of gridfinity_base.scad by ./make_makerworld.sh to build
//  the multi-plate upload variant (build/gridfinity_base_makerworld.scad).
//
//  NOT part of the normal desktop script: PMM renders the script's top level
//  into every plate module it finds, so these hooks may only exist in the
//  variant, where the top-level render is silenced (mw_export = true).
//
//  PMM exports each mw_plate_N() module as its own build plate in the 3MF;
//  empty plates are discarded, which is how this fixed list adapts to the
//  solver's variable plate count. mw_assembly_view() is the preview-only
//  assembled view and is never exported.
//
//  This file is not valid OpenSCAD on its own (it references modules from
//  gridfinity_base.scad).

// Plates are placed at the center of the selected printer's printable rectangle
// (bed_center, defined in the main script) because PMM's Auto Arrangement must be
// disabled for plates larger than ~240x235 mm, and without it the geometry's own
// coordinates are the placement.
module mw_assembly_view() { color(preview_color) assembly_view(); }
module mw_plate_1()  { translate(bed_center) color(preview_color) plate(1); }
module mw_plate_2()  { translate(bed_center) color(preview_color) plate(2); }
module mw_plate_3()  { translate(bed_center) color(preview_color) plate(3); }
module mw_plate_4()  { translate(bed_center) color(preview_color) plate(4); }
module mw_plate_5()  { translate(bed_center) color(preview_color) plate(5); }
module mw_plate_6()  { translate(bed_center) color(preview_color) plate(6); }
module mw_plate_7()  { translate(bed_center) color(preview_color) plate(7); }
module mw_plate_8()  { translate(bed_center) color(preview_color) plate(8); }
module mw_plate_9()  { translate(bed_center) color(preview_color) plate(9); }
module mw_plate_10() { translate(bed_center) color(preview_color) plate(10); }
module mw_plate_11() { translate(bed_center) color(preview_color) plate(11); }
module mw_plate_12() { translate(bed_center) color(preview_color) plate(12); }
module mw_plate_13() { translate(bed_center) color(preview_color) plate(13); }
module mw_plate_14() { translate(bed_center) color(preview_color) plate(14); }
module mw_plate_15() { translate(bed_center) color(preview_color) plate(15); }
module mw_plate_16() { translate(bed_center) color(preview_color) plate(16); }
module mw_plate_17() { translate(bed_center) color(preview_color) plate(17); }
module mw_plate_18() { translate(bed_center) color(preview_color) plate(18); }
module mw_plate_19() { translate(bed_center) color(preview_color) plate(19); }
module mw_plate_20() { translate(bed_center) color(preview_color) plate(20); }
module mw_plate_21() { translate(bed_center) color(preview_color) plate(21); }
module mw_plate_22() { translate(bed_center) color(preview_color) plate(22); }
module mw_plate_23() { translate(bed_center) color(preview_color) plate(23); }
module mw_plate_24() { translate(bed_center) color(preview_color) plate(24); }
module mw_plate_25() { translate(bed_center) color(preview_color) plate(25); }
module mw_plate_26() { translate(bed_center) color(preview_color) plate(26); }
module mw_plate_27() { translate(bed_center) color(preview_color) plate(27); }
module mw_plate_28() { translate(bed_center) color(preview_color) plate(28); }
module mw_plate_29() { translate(bed_center) color(preview_color) plate(29); }
module mw_plate_30() { translate(bed_center) color(preview_color) plate(30); }
module mw_plate_31() { translate(bed_center) color(preview_color) plate(31); }
module mw_plate_32() { translate(bed_center) color(preview_color) plate(32); }
module mw_plate_33() { translate(bed_center) color(preview_color) plate(33); }
module mw_plate_34() { translate(bed_center) color(preview_color) plate(34); }
module mw_plate_35() { translate(bed_center) color(preview_color) plate(35); }
module mw_plate_36() { translate(bed_center) color(preview_color) plate(36); }
