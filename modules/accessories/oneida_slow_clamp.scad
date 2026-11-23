// Keep settings constants before connector records in the standalone bundle.
include <../constants.scad>
include <../connectors/connector_oneida.scad>
include <slow_clamp.scad>

module OneidaSlowClamp(
  nominalDiameter = 127,
  fitAdjustment = 0,
  bandWidth = 14, // Tapered bead-contact width, excluding the straight end supports.
  bandWall = 5,
  radialClearance = 0.35,
  draftAngle = 45,
  jointGap = 0,
  splitGap = 12,
  screwDiameter = 5,
  screwClearance = 0.5,
  nutAcrossFlats = 8,
  nutThickness = 4,
  hardwareClearance = 0.3,
  earThickness = 8,
  earProjection = 14,
  part = "clamp",
  edgeSupport = 3, // Extra axial support at each end of the taper.
  earRootChamfer = 3, // Added 45-degree plan-view ear-root reinforcement; zero disables.
  grooveFlatWidth = 6 // Axial flat at the groove bottom; zero restores the pointed profile.
) {
  SlowClamp(
    beadOuterDiameter = oneidaQuickClampBeadOuterDiameter(nominalDiameter, fitAdjustment),
    beadCrossSection = oneidaBeadDiameter,
    neckOuterDiameter = oneidaQuickClampNeckOuterDiameter(nominalDiameter, fitAdjustment),
    bandWidth = bandWidth,
    bandWall = bandWall,
    radialClearance = radialClearance,
    draftAngle = draftAngle,
    jointGap = jointGap,
    splitGap = splitGap,
    screwDiameter = screwDiameter,
    screwClearance = screwClearance,
    nutAcrossFlats = nutAcrossFlats,
    nutThickness = nutThickness,
    hardwareClearance = hardwareClearance,
    earThickness = earThickness,
    earProjection = earProjection,
    part = part,
    edgeSupport = edgeSupport,
    earRootChamfer = earRootChamfer,
    grooveFlatWidth = grooveFlatWidth);
}

function oneidaSlowClampBeadOuterDiameterFromNeckOuterDiameter(
  neckOuterDiameter
) =
  assert(is_num(neckOuterDiameter) && neckOuterDiameter > 0, "neckOuterDiameter must be > 0")
  neckOuterDiameter + (oneidaNominalOffsetBeadOuter - oneidaNominalOffsetNeckOuter);

module OneidaSlowClampFromNeckOuterDiameter(
  neckOuterDiameter,
  bandWidth = 14, // Tapered bead-contact width, excluding the straight end supports.
  bandWall = 5,
  radialClearance = 0.35,
  draftAngle = 45,
  jointGap = 0,
  splitGap = 12,
  screwDiameter = 5,
  screwClearance = 0.5,
  nutAcrossFlats = 8,
  nutThickness = 4,
  hardwareClearance = 0.3,
  earThickness = 8,
  earProjection = 14,
  part = "clamp",
  edgeSupport = 3, // Extra axial support at each end of the taper.
  earRootChamfer = 3, // Added 45-degree plan-view ear-root reinforcement; zero disables.
  grooveFlatWidth = 6 // Axial flat at the groove bottom; zero restores the pointed profile.
) {
  beadOuterDiameter = oneidaSlowClampBeadOuterDiameterFromNeckOuterDiameter(
    neckOuterDiameter = neckOuterDiameter);

  SlowClamp(
    beadOuterDiameter = beadOuterDiameter,
    beadCrossSection = oneidaBeadDiameter,
    neckOuterDiameter = neckOuterDiameter,
    bandWidth = bandWidth,
    bandWall = bandWall,
    radialClearance = radialClearance,
    draftAngle = draftAngle,
    jointGap = jointGap,
    splitGap = splitGap,
    screwDiameter = screwDiameter,
    screwClearance = screwClearance,
    nutAcrossFlats = nutAcrossFlats,
    nutThickness = nutThickness,
    hardwareClearance = hardwareClearance,
    earThickness = earThickness,
    earProjection = earProjection,
    part = part,
    edgeSupport = edgeSupport,
    earRootChamfer = earRootChamfer,
    grooveFlatWidth = grooveFlatWidth);
}
