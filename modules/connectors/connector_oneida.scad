include <../constants.scad>
use <../thirdparty/ub.scad>
use <../modules_utility.scad>

/* [Hidden] */
oneidaVersion = "2.0";
oneidaMeasurement = "inner";
oneidaDefaultNominalDiameter = 5 * 25.4;
oneidaBeadDiameter = 5.58;
oneidaDefaultWallThickness = 2.4;
oneidaNominalOffsetBeadOuter = 9;
oneidaNominalOffsetBeadInner = -2.16;
oneidaNominalOffsetNeckOuter = -4;

iOneidaDimensionNominal = 0;
iOneidaDimensionBeadOuterDiameter = 1;
iOneidaDimensionBeadInnerDiameter = 2;
iOneidaDimensionNeckOuterDiameter = 3;
iOneidaDimensionNeckInnerDiameter = 4;

oneidaSettings = ["oneida", [
  [iSettingsMeasurement, oneidaMeasurement],
  [iSettingsTaper ,0],
  [iSettingsVersion, oneidaVersion]
  ]];

function oneidaQuickClampSupportedNominalsInch() = [3,4,5,6,7,8,9,10,11,12,14,16,18];
function oneidaQuickClampSupportedNominalDiameters() =
  [for (nominalInch = oneidaQuickClampSupportedNominalsInch()) nominalInch * 25.4];

function oneidaQuickClampResolvedNominalDiameter(
  nominalDiameter = oneidaDefaultNominalDiameter,
  epsilon = 0.001
) =
  assert(is_num(nominalDiameter) && nominalDiameter > 0, "Oneida nominal diameter must be a positive number")
  let(
  matches = [for (supported = oneidaQuickClampSupportedNominalDiameters()) if (abs(supported - nominalDiameter) <= epsilon) supported]
) len(matches) > 0 ? matches[0] : undef;

function oneidaQuickClampMinimumLength(
  wallThickness = oneidaDefaultWallThickness
) =
  assert(is_num(wallThickness) && wallThickness > 0, "Oneida wall thickness must be positive")
  oneidaBeadDiameter + wallThickness;

function oneidaQuickClampDimensions(
  nominalDiameter = oneidaDefaultNominalDiameter,
  wallThickness = oneidaDefaultWallThickness,
  fitAdjustment = 0
) =
  assert(is_num(wallThickness) && wallThickness > 0, str("Oneida wallThickness must be greater than 0. wallThickness=", wallThickness))
  assert(is_num(fitAdjustment), "Oneida fit adjustment must be a number")
  let(nominal = oneidaQuickClampResolvedNominalDiameter(nominalDiameter = nominalDiameter))
  assert(!is_undef(nominal),
    str("Unsupported Oneida nominal diameter ", nominalDiameter, "mm. Use supported inch nominals ", oneidaQuickClampSupportedNominalsInch(), " (mm ", oneidaQuickClampSupportedNominalDiameters(), ")."))
  let(
  beadOuterDiameter = nominal + oneidaNominalOffsetBeadOuter + fitAdjustment,
  beadInnerDiameter = nominal + oneidaNominalOffsetBeadInner + fitAdjustment,
  neckOuterDiameter = nominal + oneidaNominalOffsetNeckOuter + fitAdjustment,
  neckInnerDiameter = neckOuterDiameter - wallThickness * 2
)
  assert(neckInnerDiameter > 0, "Oneida fit adjustment and wall thickness must leave a positive bore")
  [
  nominal,
  beadOuterDiameter,
  beadInnerDiameter,
  neckOuterDiameter,
  neckInnerDiameter
];

function oneidaQuickClampBeadOuterDiameter(
  nominalDiameter = oneidaDefaultNominalDiameter,
  fitAdjustment = 0
) = oneidaQuickClampDimensions(nominalDiameter = nominalDiameter, fitAdjustment = fitAdjustment)[iOneidaDimensionBeadOuterDiameter];

function oneidaQuickClampNeckOuterDiameter(
  nominalDiameter = oneidaDefaultNominalDiameter,
  fitAdjustment = 0
) = oneidaQuickClampDimensions(nominalDiameter = nominalDiameter, fitAdjustment = fitAdjustment)[iOneidaDimensionNeckOuterDiameter];

function oneidaQuickClampNeckInnerDiameter(
  nominalDiameter = oneidaDefaultNominalDiameter,
  wallThickness = oneidaDefaultWallThickness,
  fitAdjustment = 0
) = oneidaQuickClampDimensions(nominalDiameter = nominalDiameter, wallThickness = wallThickness, fitAdjustment = fitAdjustment)[iOneidaDimensionNeckInnerDiameter];

module OneidaQuickClampConnector(
  nominalDiameter = oneidaDefaultNominalDiameter,
  length = 20,
  wallThickness = oneidaDefaultWallThickness,
  fitAdjustment = 0,
  help = false,
  $fn = 64
){
  assert(is_num(nominalDiameter) && nominalDiameter > 0, str("nominalDiameter must be a number greater than 0. Provided:", nominalDiameter));
  assert(is_num(length) && length > 0, str("length must be a number greater than 0. Provided:", length));
  assert(is_num(wallThickness) && wallThickness > 0, str("wallThickness must be a number greater than 0. Provided:", wallThickness));
  assert(is_num(fitAdjustment), str("fitAdjustment must be a number. Provided:", fitAdjustment));

  dimensions = oneidaQuickClampDimensions(
    nominalDiameter = nominalDiameter,
    wallThickness = wallThickness,
    fitAdjustment = fitAdjustment);
  nominal = dimensions[iOneidaDimensionNominal];
  beadOuterDiameter = dimensions[iOneidaDimensionBeadOuterDiameter];
  neckOuterDiameter = dimensions[iOneidaDimensionNeckOuterDiameter];
  neckInnerDiameter = dimensions[iOneidaDimensionNeckInnerDiameter];
  minimumLength = oneidaQuickClampMinimumLength(wallThickness = wallThickness);

  assert(length >= minimumLength,
    str("length must be at least ", minimumLength, " for Oneida quick-clamp. length=", length));
  assert(neckInnerDiameter > 0,
    str("Oneida neck inner diameter must be greater than 0. neckInnerDiameter=", neckInnerDiameter));
  assert(neckOuterDiameter > neckInnerDiameter,
    str("Oneida neck outer diameter must be greater than neck inner diameter. neckOuterDiameter=", neckOuterDiameter, " neckInnerDiameter=", neckInnerDiameter));
  assert(beadOuterDiameter > neckOuterDiameter,
    str("Oneida bead outer diameter must be greater than neck outer diameter. beadOuterDiameter=", beadOuterDiameter, " neckOuterDiameter=", neckOuterDiameter));

  beadRadius = oneidaBeadDiameter/2;
  beadCenterRadius = beadOuterDiameter/2 - beadRadius;
  beadCenterZ = length - oneidaBeadDiameter/2;
  beadStartZ = length - oneidaBeadDiameter;

  assert(beadStartZ >= 0, str("Oneida bead start must be >= 0. beadStartZ=", beadStartZ, " length=", length));

  difference(){
    union(){
      cylinder(h = length, d = neckOuterDiameter);
      translate([0,0,beadStartZ])
      difference(){
        cylinder(h = oneidaBeadDiameter, d = beadCenterRadius*2);
        translate([0,0,-fudgeFactor])
        cylinder(h = oneidaBeadDiameter + fudgeFactor*2, d = neckInnerDiameter);
      }
      translate([0,0,beadCenterZ])
      rotate_extrude($fn = $fn)
      translate([beadCenterRadius,0,0])
      circle(r = beadRadius, $fn = 16);
    }

    translate([0,0,-fudgeFactor])
    cylinder(h = length + fudgeFactor*2, d = neckInnerDiameter);
  }

  HelpTxt("OneidaQuickClampConnector",[
    "nominalDiameter", nominalDiameter,
    "resolvedNominalDiameter", nominal,
    "length", length,
    "wallThickness", wallThickness,
    "fitAdjustment", fitAdjustment,
    "neckOuterDiameter", neckOuterDiameter,
    "neckInnerDiameter", neckInnerDiameter,
    "beadOuterDiameter", beadOuterDiameter,
    "beadDiameter", oneidaBeadDiameter,
    "beadCenterZ", beadCenterZ]
    ,help);
}
