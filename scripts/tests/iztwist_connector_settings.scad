include <../../modules/connectors/connectors.scad>

epsilon = 0.0001;

function approx(a, b, tolerance = epsilon) = abs(a - b) <= tolerance;

function izTwistConnector(
  connectorNumber = 1,
  style = "iztwist_screw",
  wall = 3,
  nominal = [0,2.5],
  lengthValue = [25,0],
  measurement = "outer",
  taperValue = 3
) =
  getConnectorSettings(
    userSettings = UserConnectorSettings(
      connector = connectorNumber,
      style = style,
      measurement = measurement,
      taper = taperValue,
      diameter = nominal,
      wallThickness = wall,
      length = lengthValue
    ),
    slipRingSettings = [[0,0], wall, wall, 0],
    alignmentDepth = 0,
    alignmentUpperWidth = 0,
    alignmentLowerWidth = 0,
    alignmentSideClearance = 0,
    alignmentDepthClearance = 0,
    adapterColor = ["CornflowerBlue", 1],
    con1OuterEndDiameter = 127,
    con1Measurement = "outer",
    con1WallThickness = wall
  );

defaultIzTwistSettings = UserConnectorSettings(
  connector = 1,
  style = "iztwist_screw",
  diameter = [0,2.5],
  wallThickness = 3,
  length = [25,0]
);
assert(len(defaultIzTwistSettings) == userSettingsLength);
assert(defaultIzTwistSettings[iStyle] == "iztwist_screw");

defaultHookSettings = UserConnectorSettings(
  connector = 1,
  style = "iztwist_hook",
  diameter = [0,2.5],
  wallThickness = 3,
  length = [25,0]
);
assert(defaultHookSettings[iStyle] == "iztwist_hook");

for (style = ["iztwist_screw", "iztwist_hook"]) {
  settings = izTwistConnector(style = style, wall = 3, nominal = [0,2.5], measurement = "outer", taperValue = 7);
  assert(settings[iStyle] == style);
  assert(settings[iMeasurement] == "inner");
  assert(approx(settings[iTaper], 0));
  assert(approx(settings[iDiameter], 63.5));
  assert(approx(settings[iInnerDiameter], 56));
  assert(approx(settings[iOuterStartDiameter], 62));
  assert(approx(settings[iOuterEndDiameter], 62));
  assert(approx(settings[iInterfaceInnerDiameter], 56));
  assert(approx(settings[iInterfaceOuterDiameter], 62));
}

for (connector = [1:3])
  for (wall = [3, 4])
    for (nominal = [2.5, 4, 6]) {
      settings = izTwistConnector(
        connectorNumber = connector,
        style = connector % 2 == 0 ? "iztwist_hook" : "iztwist_screw",
        wall = wall,
        nominal = [0, nominal],
        lengthValue = [40,0],
        measurement = "outer",
        taperValue = 5
      );
      profile = izTwistProfile(nominalDiameter = nominal * 25.4);
      assert(settings[iConnector] == connector);
      assert(settings[iWallThickness] == wall);
      assert(settings[iInterfaceWallThickness] == wall);
      assert(settings[iMeasurement] == "inner");
      assert(approx(settings[iTaper], 0));
      assert(approx(settings[iInnerDiameter], profile[iIzTwistBore]));
      assert(approx(settings[iOuterStartDiameter], profile[iIzTwistBore] + 2 * wall));
      assert(approx(settings[iOuterEndDiameter], profile[iIzTwistBore] + 2 * wall));
      assert(approx(settings[iLength], 40));
    }

inchOverrideSettings = izTwistConnector(
  style = "iztwist_screw",
  nominal = [999, 2.5],
  lengthValue = [25,0]
);
assert(approx(inchOverrideSettings[iDiameter], 63.5));
assert(approx(inchOverrideSettings[iInnerDiameter], 56));

hiddenIzTwist = izTwistConnector(style = "iztwist_screw", lengthValue = [0,0]);
assert(hiddenIzTwist[iLength] == 0 && hiddenIzTwist[iInterfaceLength] == 0);

cube([1,1,1]);
