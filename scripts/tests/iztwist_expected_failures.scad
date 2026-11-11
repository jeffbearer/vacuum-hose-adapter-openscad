Case = "invalid_nominal_3";

include <../../modules/connectors/connectors.scad>

if (Case == "invalid_nominal_3") {
  _invalidNominal3 = izTwistProfile(nominalDiameter = 3 * 25.4);
}
else if (Case == "invalid_nominal_5") {
  _invalidNominal5 = izTwistProfile(nominalDiameter = 5 * 25.4);
}
else if (Case == "invalid_nominal_7") {
  _invalidNominal7 = izTwistProfile(nominalDiameter = 7 * 25.4);
}
else if (Case == "invalid_nominal_fractional") {
  _invalidNominalFractional = izTwistProfile(nominalDiameter = 2.75 * 25.4);
}
else if (Case == "invalid_nominal_type") {
  _invalidNominalType = izTwistProfile(nominalDiameter = "63.5");
}
else if (Case == "below_min_length_screw") {
  IzTwistConnector(
    nominalDiameter = 2.5 * 25.4,
    side = "screw",
    wallThickness = 3,
    length = izTwistMinimumLength(nominalDiameter = 2.5 * 25.4, side = "screw", wallThickness = 3) - 0.01
  );
}
else if (Case == "below_min_length_hook") {
  IzTwistConnector(
    nominalDiameter = 2.5 * 25.4,
    side = "hook",
    wallThickness = 3,
    length = izTwistMinimumLength(nominalDiameter = 2.5 * 25.4, side = "hook", wallThickness = 3) - 0.01
  );
}
else if (Case == "wall_interference") {
  IzTwistConnector(
    nominalDiameter = 2.5 * 25.4,
    side = "hook",
    wallThickness = 10,
    length = 40
  );
}
else if (Case == "invalid_side") {
  IzTwistConnector(
    nominalDiameter = 2.5 * 25.4,
    side = "bad-side",
    wallThickness = 3,
    length = 40
  );
}
else if (Case == "invalid_threaded_type") {
  IzTwistConnector(
    nominalDiameter = 2.5 * 25.4,
    side = "screw",
    wallThickness = 3,
    length = 40,
    threaded = "yes"
  );
}
else if (Case == "invalid_wall_type") {
  _invalidWallType = UserConnectorSettings(
    connector = 1,
    style = "iztwist_screw",
    diameter = [0,2.5],
    wallThickness = "3",
    length = [25,0]
  );
}
else {
  assert(false, str("Unsupported iztwist_expected_failures Case: ", Case));
}
