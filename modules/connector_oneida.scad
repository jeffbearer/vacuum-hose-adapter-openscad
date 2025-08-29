include <constants.scad>
use <modules_utility.scad>
use <modules_pipe.scad>
include <ub.scad>

/* [Hidden] */
oneidaVersion = "1.0";
oneidaBeadHeight = 4.0;  // Standard bead height for Oneida quick clamp
oneidaMinLength = 1;  // Minimal length - just enough for the bead
oneidaMeasurement = "inner";  // Oneida duct sizes refer to inner diameter
oneidaWallThickness = 2.4;

// Standard Oneida quick clamp duct sizes (inner diameter)
// Common sizes: 4", 5", 6", 7", 8", 10", 12", 14", 16"
// Default to 4" (101.6mm) inner diameter for testing
oneidaInnerDiameter = 101.6; // 4 inch inner diameter
oneidaOuterDiameter = oneidaInnerDiameter + (oneidaWallThickness * 2);

oneidaSettings = ["oneida", [
  [iSettingsLength, oneidaMinLength],
  [iSettingsMeasurement, oneidaMeasurement],
  // No default diameter - let user specify diameter
  [iSettingsWallThickness, oneidaWallThickness],
  [iSettingsTaper, 0],
  [iSettingsVersion, oneidaVersion],
  [iSettingsStopThickness, 0],  // No stop sections for Oneida
  [iSettingsStopLength, 0]      // No stop length for Oneida
  ]];

//OneidaQuickClampConnector();

module OneidaQuickClampConnector(
  innerEndDiameter = oneidaInnerDiameter,
  length = 6,  // Use specified length instead of ignoring it
  wallThickness = oneidaWallThickness,
  beadDiameter = 6.7,    // Fixed bead diameter (was beadHeight)
  beadWidth = 5,         // Width along Z axis
  flatWidth = 1.2,       // Width of flat surface for bed adhesion
  compensate3DPrint = true,  // Apply 3D printing compensation
  clearanceFromWall = 6.5,   // Distance from outside of bead to outside wall
  help,
  $fn = 64
){
  assert(is_num(innerEndDiameter) && innerEndDiameter > 0, "innerEndDiameter must be a number greater than 0");
  assert(is_num(length) && length > 0, "length must be a number greater than 0");
  assert(is_num(wallThickness) && wallThickness > 0, "wallThickness must be a number greater than 0");
  assert(is_num(beadDiameter) && beadDiameter > 0, "beadDiameter must be a number greater than 0");
  assert(is_num(beadWidth) && beadWidth > 0, "beadWidth must be a number greater than 0");
  assert(is_num(flatWidth) && flatWidth > 0, "flatWidth must be a number greater than 0");
  assert(is_num(clearanceFromWall) && clearanceFromWall > 0, "clearanceFromWall must be a number greater than 0");

  // CONSTRAINT RESOLUTION ORDER:
  // 1. Bead diameter = 6.7mm (radius = 3.35mm)
  beadRadius = beadDiameter / 2;
  
  // 2. Inside of bead = specified inner diameter
  // Bead center radius = inner radius + bead radius (so inside of bead touches inner wall)
  beadCenterRadius = innerEndDiameter/2 + beadRadius;
  
  // 3. Outside wall = outside of bead - 6.5mm clearance
  // Outside of bead = bead center + bead radius
  beadOuterRadius = beadCenterRadius + beadRadius;
  outerWallRadius = beadOuterRadius - clearanceFromWall;
  
  // 4. Inner wall beyond bead compensates to maintain wall thickness
  // Required inner radius = outer radius - wall thickness
  compensatedInnerRadius = outerWallRadius - wallThickness;
  compensatedInnerDiameter = compensatedInnerRadius * 2;
  
  echo("OneidaQuickClampConnector CONSTRAINTS:");
  echo("  1. beadDiameter =", beadDiameter, "beadRadius =", beadRadius);
  echo("  2. innerEndDiameter =", innerEndDiameter, "beadCenterRadius =", beadCenterRadius);
  echo("  3. beadOuterRadius =", beadOuterRadius, "outerWallRadius =", outerWallRadius);
  echo("  4. compensatedInnerDiameter =", compensatedInnerDiameter, "wallThickness =", wallThickness);
  echo("  Clearance check:", beadOuterRadius - outerWallRadius, "should equal", clearanceFromWall);

  union() {
    // Main pipe body - use compensated inner diameter to maintain proper wall thickness
    Pipe (
      diameter1 = compensatedInnerDiameter,
      diameter2 = compensatedInnerDiameter,
      length = length,
      wallThickness1 = wallThickness,
      wallThickness2 = wallThickness); 
      
    // Bead positioned at the very edge of the connector
    // Inside of bead exactly at specified inner diameter
    translate([0, 0, length - beadWidth/2])  // Position bead at connector end
    rotate_extrude($fn = $fn) {
      translate([beadCenterRadius, 0, 0]) {  // Position based on constraint resolution
        circle(r = beadRadius, $fn = 16);
      }
    }
  }
  
  HelpTxt("OneidaQuickClampConnector",[
    "innerEndDiameter", innerEndDiameter,
    "compensatedInnerDiameter", compensatedInnerDiameter,
    "length", length,
    "wallThickness", wallThickness,
    "compensate3DPrint", compensate3DPrint,
    "clearanceFromWall", clearanceFromWall,
    "beadDiameter", beadDiameter,
    "beadWidth", beadWidth,
    "flatWidth", flatWidth,
    "outerWallRadius", outerWallRadius,
    "beadCenterRadius", beadCenterRadius
    ], help);
}

module OneidaQuickClampBead(
  innerDiameter,
  wallThickness,
  beadHeight = 4.0,  // Increased for more prominent bead
  beadWidth = 5,     // Increased width for more prominent bead
  flatWidth = 1.2,  // Width of flat surface for bed adhesion
  compensate3DPrint = true,  // Apply 3D printing compensation
  clearanceFromWall = 2.5,   // Reduced clearance to allow larger beads with thin walls
  help,
  $fn = 64
){
  assert(is_num(innerDiameter) && innerDiameter > 0, "innerDiameter must be a number greater than 0");
  assert(is_num(wallThickness) && wallThickness > 0, "wallThickness must be a number greater than 0");
  assert(is_num(beadHeight) && beadHeight > 0, "beadHeight must be a number greater than 0");
  assert(is_num(beadWidth) && beadWidth > 0, "beadWidth must be a number greater than 0");
  assert(is_num(flatWidth) && flatWidth > 0, "flatWidth must be a number greater than 0");
  assert(is_num(clearanceFromWall) && clearanceFromWall > 0, "clearanceFromWall must be a number greater than 0");

  // 3D printing compensation calculations
  sheetMetalWallThickness = 0.2;  // Oneida sheet metal thickness
  // Use actual wallThickness parameter instead of hardcoded typical value
  wallCompensation = compensate3DPrint ? (wallThickness - sheetMetalWallThickness) * 2 : 0;
  
  // Adjust inner diameter for thicker 3D printed walls
  adjustedInnerDiameter = innerDiameter - wallCompensation;
  
  outerDiameter = adjustedInnerDiameter + wallThickness * 2;
  
  // Calculate maximum bead radius to maintain clearance from outer wall
  // The bead extends from the inner wall, so max bead diameter = outerDiameter - clearanceFromWall
  // This gives us the available space for the bead
  maxBeadDiameter = outerDiameter - clearanceFromWall;
  maxBeadRadius = (maxBeadDiameter - adjustedInnerDiameter) / 2;
  
  // Use the smaller of requested bead height or maximum possible
  adjustedBeadHeight = compensate3DPrint ? min(beadHeight, maxBeadRadius) : beadHeight;
  
  // Ensure we have a minimum bead size even if clearance is tight
  finalBeadRadius = max(adjustedBeadHeight, 0.5);  // Minimum 0.5mm bead
  
  beadRadius = finalBeadRadius;
  // Position bead so inner edge is tangent to inner wall and center is at the pipe end
  beadCenterRadius = adjustedInnerDiameter/2 + beadRadius;  // Bead center radius for inner edge tangency
  beadCenterZ = 0;  // Center at Z=0 so bead extends both above and below
  
  echo("OneidaQuickClampBead", innerDiameter=innerDiameter, adjustedInnerDiameter=adjustedInnerDiameter, outerDiameter=outerDiameter);
  echo("OneidaQuickClampBead", beadHeight=beadHeight, adjustedBeadHeight=adjustedBeadHeight, finalBeadRadius=finalBeadRadius, beadWidth=beadWidth);
  echo("OneidaQuickClampBead", wallCompensation=wallCompensation, clearanceFromWall=clearanceFromWall, maxBeadRadius=maxBeadRadius);
  echo("OneidaQuickClampBead", beadCenterRadius=beadCenterRadius, beadCenterZ=beadCenterZ, flatWidth=flatWidth);

  union() {
    // Rounded portion of the bead (torus shape)
    translate([0, 0, beadCenterZ])
    rotate_extrude($fn = $fn) {
      translate([beadCenterRadius, 0, 0]) {
        circle(r = beadRadius, $fn = 16);
      }
    }
  }
  
  HelpTxt("OneidaQuickClampBead",[
    "innerDiameter", innerDiameter,
    "adjustedInnerDiameter", adjustedInnerDiameter,
    "wallThickness", wallThickness,
    "beadHeight", beadHeight,
    "adjustedBeadHeight", adjustedBeadHeight,
    "beadWidth", beadWidth,
    "beadRadius", beadRadius,
    "flatWidth", flatWidth,
    "wallCompensation", wallCompensation,
    "clearanceFromWall", clearanceFromWall,
    "beadCenterRadius", beadCenterRadius,
    "beadCenterZ", beadCenterZ
    ], help);
}