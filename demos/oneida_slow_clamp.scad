// SlowClamp: experimental screw-tightened bead clamp, not a load-rated fitting.
include <../modules/accessories/oneida_slow_clamp.scad>

/* [View] */
Part = "assembly"; // [clamp: Printable band only, assembly: Mating beads and hardware preview, section: Groove cross-section]
Show_Hardware = true;

/* [Oneida bead] */
Nominal_Size = 5; // [3,4,5,6,7,8,9,10,11,12,14,16,18]
Fit_Adjustment = 0; //0.1
Joint_Gap = 0; //0.1

/* [Split band] */
// Axial width of the tapered bead-contact region, excluding straight end supports.
Band_Width = 14; //0.1
// Extra straight axial support beyond each end of the taper.
Edge_Support = 3; //0.1
Band_Wall = 5; //0.1
Groove_Clearance = 0.35; //0.05
Groove_Draft_Angle = 45; // [30:1:60]
// Axial flat at the groove bottom; reduces outside diameter while retaining Band_Wall.
Groove_Flat_Width = 6; //0.1
Split_Gap = 12; //0.1

/* [Metal screw and captured nut] */
Screw_Diameter = 5; //0.1
Screw_Clearance = 0.5; //0.1
Nut_Across_Flats = 8; //0.1
Nut_Thickness = 4; //0.1
Hardware_Clearance = 0.3; //0.1
Ear_Thickness = 8; //0.1
Ear_Projection = 14; //0.1
// Added 45-degree gussets at the ear-to-band roots in plan view; zero disables.
Ear_Root_Chamfer = 3; //0.1

/* [Detail] */
Resolution = 160; // [64:16:256]

/* [Hidden] */
module end_of_customizer_opts() {}

$fn = Resolution;
nominalDiameter = Nominal_Size * 25.4;
beadOD = oneidaQuickClampBeadOuterDiameter(nominalDiameter, Fit_Adjustment);
neckOD = oneidaQuickClampNeckOuterDiameter(nominalDiameter, Fit_Adjustment);
outerRadius = slowClampBandOuterRadius(beadOD, oneidaBeadDiameter,
  Band_Wall, Groove_Clearance, Groove_Draft_Angle, Joint_Gap, Groove_Flat_Width);
totalWidth = slowClampTotalWidth(Band_Width, Edge_Support);
jointZ = totalWidth / 2;

assert(Part == "clamp" || Part == "assembly" || Part == "section",
  "Part must be clamp, assembly, or section");
assert(is_bool(Show_Hardware), "Show_Hardware must be boolean");
assert(Resolution >= 64 && floor(Resolution) == Resolution, "Resolution must be an integer >= 64");

module Band(output = "clamp") {
  OneidaSlowClamp(
    nominalDiameter = nominalDiameter,
    fitAdjustment = Fit_Adjustment,
    bandWidth = Band_Width,
    bandWall = Band_Wall,
    radialClearance = Groove_Clearance,
    draftAngle = Groove_Draft_Angle,
    jointGap = Joint_Gap,
    splitGap = Split_Gap,
    screwDiameter = Screw_Diameter,
    screwClearance = Screw_Clearance,
    nutAcrossFlats = Nut_Across_Flats,
    nutThickness = Nut_Thickness,
    hardwareClearance = Hardware_Clearance,
    earThickness = Ear_Thickness,
    earProjection = Ear_Projection,
    part = output,
    edgeSupport = Edge_Support,
    earRootChamfer = Ear_Root_Chamfer,
    grooveFlatWidth = Groove_Flat_Width);
}

module MatingBeads() {
  color("SteelBlue")
  translate([0,0,jointZ - Joint_Gap / 2 - 15])
    OneidaQuickClampConnector(
      nominalDiameter = nominalDiameter, fitAdjustment = Fit_Adjustment,
      length = 15, wallThickness = 2.4, $fn = Resolution);
  color("SeaGreen")
  translate([0,0,jointZ + Joint_Gap / 2 + 15])
  rotate([180,0,0])
    OneidaQuickClampConnector(
      nominalDiameter = nominalDiameter, fitAdjustment = Fit_Adjustment,
      length = 15, wallThickness = 2.4, $fn = Resolution);
}

module Assembly() {
  color("Goldenrod") Band();
  MatingBeads();
}

if (Part == "clamp")
  Band();
else if (Part == "assembly")
  Assembly();
else
  difference() {
    Assembly();
    translate([0,-outerRadius * 2,-30])
      cube([outerRadius * 3, outerRadius * 4, totalWidth + 60]);
  }

if ($preview && Show_Hardware && Part == "assembly")
  %Band("hardware");
