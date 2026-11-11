include <../constants.scad>
use <../modules_utility.scad>
use <../modules_pipe.scad>

/* [Hidden] */
oneidaVersion = "1.0";
oneidaBeadHeight = 4.0;
oneidaMinLength = 1;
oneidaMeasurement = "inner";
oneidaWallThickness = 2.4;
oneidaInnerDiameter = 101.6;
oneidaBeadDiameter = 5.58;
oneidaBeadWidth = 5;
oneidaClearanceFromWall = 6.5;

oneidaSettings = ["oneida", [
  [iSettingsMeasurement, oneidaMeasurement],
  [iSettingsTaper, 0],
  [iSettingsVersion, oneidaVersion]
  ]];

function oneidaQuickClampMinimumLength(
  beadDiameter = oneidaBeadDiameter,
  beadWidth = oneidaBeadWidth
) = oneidaMinLength;

function oneidaQuickClampNeckOuterDiameter(
  nominalInnerDiameter = oneidaInnerDiameter,
  wallThickness = oneidaWallThickness
) = nominalInnerDiameter + (oneidaBeadDiameter - oneidaClearanceFromWall) * 2;

function oneidaQuickClampNeckInnerDiameter(
  nominalInnerDiameter = oneidaInnerDiameter,
  wallThickness = oneidaWallThickness
) = oneidaQuickClampNeckOuterDiameter(nominalInnerDiameter = nominalInnerDiameter, wallThickness = wallThickness)
    - wallThickness * 2;

function oneidaQuickClampTipOverhang(
  beadDiameter = oneidaBeadDiameter,
  beadWidth = oneidaBeadWidth
) = max(0, (beadDiameter - beadWidth) / 2);

module OneidaQuickClampConnector(
  innerEndDiameter = oneidaInnerDiameter,
  length = 6,
  wallThickness = oneidaWallThickness,
  beadDiameter = oneidaBeadDiameter,
  beadWidth = oneidaBeadWidth,
  flatWidth = 1.2,
  compensate3DPrint = true,
  clearanceFromWall = oneidaClearanceFromWall,
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

  beadRadius = beadDiameter / 2;
  beadCenterRadius = innerEndDiameter / 2 + beadRadius;
  beadOuterRadius = beadCenterRadius + beadRadius;
  outerWallRadius = beadOuterRadius - clearanceFromWall;
  compensatedInnerRadius = outerWallRadius - wallThickness;
  compensatedInnerDiameter = compensatedInnerRadius * 2;
  // Align the inner lip with the bead's tangent plane without changing the bead.
  lipLength = length + oneidaQuickClampTipOverhang(beadDiameter, beadWidth);

  echo("OneidaQuickClampConnector CONSTRAINTS:");
  echo("  1. beadDiameter =", beadDiameter, "beadRadius =", beadRadius);
  echo("  2. innerEndDiameter =", innerEndDiameter, "beadCenterRadius =", beadCenterRadius);
  echo("  3. beadOuterRadius =", beadOuterRadius, "outerWallRadius =", outerWallRadius);
  echo("  4. compensatedInnerDiameter =", compensatedInnerDiameter, "wallThickness =", wallThickness);
  echo("  Clearance check:", beadOuterRadius - outerWallRadius, "should equal", clearanceFromWall);

  union() {
    pipe(
      diameter1 = compensatedInnerDiameter,
      diameter2 = compensatedInnerDiameter,
      length = lipLength,
      wallThickness1 = wallThickness,
      wallThickness2 = wallThickness);

    // Back the bead to its centerline so the flange faces meet both horizontal tangents.
    pipe(
      diameter = compensatedInnerDiameter,
      length = beadDiameter,
      wallThickness = max(wallThickness, beadCenterRadius - compensatedInnerRadius),
      zPosition = length - beadWidth / 2 - beadRadius);

    translate([0, 0, length - beadWidth / 2])
    rotate_extrude($fn = $fn) {
      translate([beadCenterRadius, 0, 0]) {
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
  beadHeight = oneidaBeadHeight,
  beadWidth = oneidaBeadWidth,
  flatWidth = 1.2,
  compensate3DPrint = true,
  clearanceFromWall = 2.5,
  help,
  $fn = 64
){
  assert(is_num(innerDiameter) && innerDiameter > 0, "innerDiameter must be a number greater than 0");
  assert(is_num(wallThickness) && wallThickness > 0, "wallThickness must be a number greater than 0");
  assert(is_num(beadHeight) && beadHeight > 0, "beadHeight must be a number greater than 0");
  assert(is_num(beadWidth) && beadWidth > 0, "beadWidth must be a number greater than 0");
  assert(is_num(flatWidth) && flatWidth > 0, "flatWidth must be a number greater than 0");
  assert(is_num(clearanceFromWall) && clearanceFromWall > 0, "clearanceFromWall must be a number greater than 0");

  sheetMetalWallThickness = 0.2;
  wallCompensation = compensate3DPrint ? (wallThickness - sheetMetalWallThickness) * 2 : 0;
  adjustedInnerDiameter = innerDiameter - wallCompensation;
  outerDiameter = adjustedInnerDiameter + wallThickness * 2;
  maxBeadDiameter = outerDiameter - clearanceFromWall;
  maxBeadRadius = (maxBeadDiameter - adjustedInnerDiameter) / 2;
  adjustedBeadHeight = compensate3DPrint ? min(beadHeight, maxBeadRadius) : beadHeight;
  finalBeadRadius = max(adjustedBeadHeight, 0.5);
  beadRadius = finalBeadRadius;
  beadCenterRadius = adjustedInnerDiameter / 2 + beadRadius;
  beadCenterZ = 0;

  echo("OneidaQuickClampBead", innerDiameter = innerDiameter, adjustedInnerDiameter = adjustedInnerDiameter, outerDiameter = outerDiameter);
  echo("OneidaQuickClampBead", beadHeight = beadHeight, adjustedBeadHeight = adjustedBeadHeight, finalBeadRadius = finalBeadRadius, beadWidth = beadWidth);
  echo("OneidaQuickClampBead", wallCompensation = wallCompensation, clearanceFromWall = clearanceFromWall, maxBeadRadius = maxBeadRadius);
  echo("OneidaQuickClampBead", beadCenterRadius = beadCenterRadius, beadCenterZ = beadCenterZ, flatWidth = flatWidth);

  union() {
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
