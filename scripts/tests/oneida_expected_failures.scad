Case = "invalid_nominal_13";

include <../../modules/connectors/connectors.scad>

if (Case == "invalid_nominal_13") {
  _invalidNominal13 = oneidaQuickClampDimensions(nominalDiameter = 13 * 25.4);
}
else if (Case == "invalid_nominal_15") {
  _invalidNominal15 = oneidaQuickClampDimensions(nominalDiameter = 15 * 25.4);
}
else if (Case == "invalid_nominal_17") {
  _invalidNominal17 = oneidaQuickClampDimensions(nominalDiameter = 17 * 25.4);
}
else if (Case == "invalid_nominal_fractional") {
  _invalidNominalFractional = oneidaQuickClampDimensions(nominalDiameter = 5.25 * 25.4);
}
else if (Case == "invalid_nominal_type") {
  _invalidNominalType = oneidaQuickClampDimensions(nominalDiameter = "127");
}
else if (Case == "invalid_fit_type") {
  _invalidFitType = UserConnectorSettings(
    connector = 1,
    style = "oneida",
    diameter = [0,5],
    wallThickness = 2.4,
    length = [20,0],
    oneidaFitAdjustment = "bad-value"
  );
}
else if (Case == "below_min_length") {
  OneidaQuickClampConnector(
    nominalDiameter = 127,
    wallThickness = 2.4,
    length = oneidaQuickClampMinimumLength(wallThickness = 2.4) - 0.01
  );
}
else if (Case == "bore_invalid") {
  OneidaQuickClampConnector(
    nominalDiameter = 127,
    wallThickness = 80,
    length = 20
  );
}
else if (Case == "fit_shrinks_bore") {
  OneidaQuickClampConnector(nominalDiameter = 127, fitAdjustment = -200);
}
else {
  assert(false, str("Unsupported oneida_expected_failures Case: ", Case));
}
