// Uses the Vacuum Hose Adapter library: https://github.com/ostat/vacuum-hose-adapter-openscad
include <modules/vacuum-hose-adapter.scad>

/* [Output] */
Part = "adapter"; // [adapter: Complete wye, oneida-fit-ring: Oneida clamp fit ring, hose-fit-rings: Hose diameter fit rings]
Slice_Debug = false;
Resolution = 160; // [64:16:256]

/* [Oneida quick clamp] */
// Nominal duct diameter [mm, inches]; a nonzero inch value takes precedence.
Oneida_Diameter = [0, 5];
// Measured outside diameter across the bead (mm); 0 uses the nominal duct diameter above.
Oneida_Bead_Outside_Diameter = 136;
Oneida_Neck_Length = 20;
Oneida_Wall_Thickness = 2.4;

/* [Inline hose port] */
// Outside diameter of the spigot that fits INSIDE the hose [mm, inches].
Inline_Diameter = [0, 4];
// Diametral adjustment in mm; negative makes the hose fit looser.
Inline_Fit_Adjustment = 0;
Inline_Clamp_Length = 50;

/* [Wye hose port] */
// Outside diameter of the spigot that fits INSIDE the hose [mm, inches].
Branch_Diameter = [0, 2.5];
Branch_Fit_Adjustment = 0;
Branch_Clamp_Length = 45;
// Angle from the inline port; both hose openings point away from the Oneida inlet.
Branch_Angle = 45; // [30:1:60]

/* [Body] */
Hose_Wall_Thickness = 3;
Junction_Length = 67;
Inline_Junction_Height = 104;

/* [Hidden] */
module end_of_customizer_opts() {}

$fn = Resolution;
oneidaDiameter = Oneida_Bead_Outside_Diameter > 0
  ? Oneida_Bead_Outside_Diameter - 2 * oneidaBeadDiameter
  : measurement_to_mm(Oneida_Diameter);
inlineDiameter = measurement_to_mm(Inline_Diameter) + Inline_Fit_Adjustment;
branchDiameter = measurement_to_mm(Branch_Diameter) + Branch_Fit_Adjustment;

// Match HoseAdapter's hull endpoint placement so neither port is buried in the junction roof.
inletRadius = oneidaQuickClampNeckOuterDiameter(oneidaDiameter, Oneida_Wall_Thickness) / 2;
shapeOverlap = ((inletRadius - Hose_Wall_Thickness) - cos(Branch_Angle) * branchDiameter) / sin(Branch_Angle);
hullLength = max(0, -shapeOverlap) + Junction_Length;
edgeOffset = (shapeOverlap > 50
  ? inletRadius - branchDiameter / 2 - shapeOverlap / 2
  : inletRadius - branchDiameter / 2) * cos(Branch_Angle);
branchJoinX = -inletRadius + cos(Branch_Angle) * (inletRadius - edgeOffset)
  - sin(Branch_Angle) * (hullLength + Hose_Wall_Thickness);
branchJoinZ = Oneida_Neck_Length + sin(Branch_Angle) * (inletRadius - edgeOffset)
  + cos(Branch_Angle) * (hullLength + Hose_Wall_Thickness);
inlineJoinZ = Oneida_Neck_Length + Inline_Junction_Height;
oneidaPlacementOffset = oneidaQuickClampTipOverhang();

assert(Part == "adapter" || Part == "oneida-fit-ring" || Part == "hose-fit-rings",
  "Part must be adapter, oneida-fit-ring, or hose-fit-rings");
assert(Resolution >= 64 && floor(Resolution) == Resolution, "Resolution must be an integer >= 64");
assert(Oneida_Bead_Outside_Diameter >= 0, "Oneida bead outside diameter must be non-negative");
assert(oneidaDiameter > 0, "Oneida bead outside diameter must exceed twice the bead cross-section");
assert(Oneida_Neck_Length >= oneidaQuickClampMinimumLength(), "Oneida neck is too short for the clamp bead");
assert(Hose_Wall_Thickness > 0, "Hose wall thickness must be positive");
assert(inlineDiameter > 2 * Hose_Wall_Thickness && branchDiameter > 2 * Hose_Wall_Thickness,
  "Hose outside diameters must be greater than twice the wall thickness");
assert(Inline_Clamp_Length >= 25 && Branch_Clamp_Length >= 25, "Provide at least 25 mm of hose clamp land");
assert(Branch_Angle >= 30 && Branch_Angle <= 60, "Branch angle must be between 30 and 60 degrees");
assert(Junction_Length > 0 && Inline_Junction_Height > 0, "Junction dimensions must be positive");
assert(inlineJoinZ >= branchJoinZ + sin(Branch_Angle) * branchDiameter / 2 + Hose_Wall_Thickness,
  "Inline port is buried in the wye roof; increase Inline_Junction_Height");
assert(-sin(Branch_Angle) * branchJoinX + cos(Branch_Angle) * branchJoinZ
  >= sin(Branch_Angle) * inlineDiameter / 2 + cos(Branch_Angle) * inlineJoinZ + Hose_Wall_Thickness,
  "Branch port is buried in the wye roof; increase Junction_Length or reduce Inline_Junction_Height");

if (Part == "oneida-fit-ring") {
  translate([0, 0, 10 + oneidaPlacementOffset])
  mirror([0, 0, 1])
  OneidaQuickClampConnector(
    innerEndDiameter = oneidaDiameter,
    length = 10,
    wallThickness = Oneida_Wall_Thickness,
    $fn = Resolution);
} else if (Part == "hose-fit-rings") {
  for (i = [0:1])
    translate([i * ((inlineDiameter + branchDiameter) / 2 + 10), 0, 0])
    HoseConnector(
      innerStartDiameter = (i == 0 ? inlineDiameter : branchDiameter) - 2 * Hose_Wall_Thickness,
      innerEndDiameter = (i == 0 ? inlineDiameter : branchDiameter) - 2 * Hose_Wall_Thickness,
      connectorMeasurement = "outer",
      length = 15,
      wallThickness = Hose_Wall_Thickness,
      help = false);
} else {
  translate([0, 0, oneidaPlacementOffset])
  HoseAdapter(
    connector1 = UserConnectorSettings(
      connector = 1,
      style = "oneida",
      diameter = [oneidaDiameter, 0],
      length = [Oneida_Neck_Length, 0],
      wallThickness = Oneida_Wall_Thickness,
      taper = 0),
    connector2 = UserConnectorSettings(
      connector = 2,
      style = "hose",
      measurement = "outer",
      diameter = [branchDiameter, 0],
      length = [Branch_Clamp_Length, 0],
      wallThickness = Hose_Wall_Thickness,
      taper = 0),
    connector3 = UserConnectorSettings(
      connector = 3,
      style = "hose",
      measurement = "outer",
      diameter = [inlineDiameter, 0],
      length = [Inline_Clamp_Length, 0],
      wallThickness = Hose_Wall_Thickness,
      taper = 0),
    transitionStyle = "hull",
    transitionAngle = Branch_Angle,
    transitionLength = Junction_Length,
    transitionEnd2Count = 1,
    transitionHullCenter = "end3",
    transitionHullCenterHeight = Inline_Junction_Height,
    sliceDebug = Slice_Debug);
}
