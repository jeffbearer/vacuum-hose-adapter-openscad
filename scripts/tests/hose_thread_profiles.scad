include <../../modules/connectors/connectors.scad>

function approx(a, b, tolerance = 0.0001) = abs(a - b) <= tolerance;

inwardUser = UserConnectorSettings(
  connector = 1,
  style = "hose",
  measurement = "inner",
  diameter = [40.4,0],
  length = [20,0],
  taper = 0,
  wallThickness = 3,
  enableThreads = "enabled",
  threadPitch = 5,
  threadToothAngle = 30,
  threadToothHeight = 2.5,
  threadProfile = "inward_triangle",
  threadToothWidth = 2.5
);
assert(len(inwardUser) == userSettingsLength);
assert(inwardUser[iThreadProfile] == "inward_triangle");
assert(approx(inwardUser[iThreadToothWidth], 2.5));

legacyLengthUser = [for (i = [0:iAlignmentRing]) inwardUser[i]];
assert(len(ValidateUserConnectorSettings(legacyLengthUser)) == iAlignmentRing + 1);

inwardConnector = getConnectorSettings(
  userSettings = inwardUser,
  slipRingSettings = [[0,0], 3, 3, 0],
  alignmentDepth = 0,
  alignmentUpperWidth = 0,
  alignmentLowerWidth = 0,
  alignmentSideClearance = 0,
  alignmentDepthClearance = 0,
  adapterColor = ["CornflowerBlue", 1],
  con1OuterEndDiameter = 46.4,
  con1Measurement = "inner",
  con1WallThickness = 3
);
assert(len(inwardConnector) == connectorSettingsLength);
assert(approx(inwardConnector[iInnerDiameter], 40.4));
assert(approx(inwardConnector[iOuterStartDiameter], 46.4));
assert(approx(inwardConnector[iThreadToothWidth], 2.5));

HoseConnector(
  innerStartDiameter = inwardConnector[iInnerStartDiameter],
  innerEndDiameter = inwardConnector[iInnerEndDiameter],
  connectorMeasurement = inwardConnector[iMeasurement],
  length = inwardConnector[iLength],
  wallThickness = inwardConnector[iWallThickness],
  enableThreads = inwardConnector[iEnableThreads],
  threadPitch = inwardConnector[iThreadPitch],
  threadToothAngle = inwardConnector[iThreadToothAngle],
  threadToothHeight = inwardConnector[iThreadToothHeight],
  threadToothWidth = inwardConnector[iThreadToothWidth],
  threadProfile = inwardConnector[iThreadProfile],
  help = false
);
