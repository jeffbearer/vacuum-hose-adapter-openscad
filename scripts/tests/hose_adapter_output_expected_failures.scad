Case = "invalid_output_mode";

include <../../modules/vacuum-hose-adapter.scad>

function validConnector(connectorNumber) =
  UserConnectorSettings(
    connector = connectorNumber,
    style = "hose",
    measurement = "outer",
    diameter = [40, 0],
    wallThickness = 2,
    length = [20, 0]
  );

function validIzTwistConnector(connectorNumber, nominalInch = 2.5, style = "iztwist_screw") =
  UserConnectorSettings(
    connector = connectorNumber,
    style = style,
    diameter = [0, nominalInch],
    wallThickness = 3,
    length = [0, 0]
  );

if (Case == "invalid_output_mode") {
  HoseAdapter(outputMode = "bad_mode");
}
else if (Case == "invalid_output_end") {
  HoseAdapter(outputMode = "adapter", outputEnd = "end4");
}
else if (Case == "alignment_ring_end3") {
  HoseAdapter(outputMode = "alignment_ring", outputEnd = "end3");
}
else if (Case == "gasket_non_iztwist_style") {
  HoseAdapter(
    connector1 = validConnector(1),
    outputMode = "iztwist_gasket",
    outputEnd = "end1"
  );
}
else if (Case == "gasket_invalid_nominal") {
  HoseAdapter(
    connector1 = validIzTwistConnector(1, nominalInch = 5, style = "iztwist_hook"),
    outputMode = "iztwist_gasket",
    outputEnd = "end1"
  );
}
else if (Case == "gasket_invalid_record") {
  HoseAdapter(connector2 = undef, outputMode = "iztwist_gasket", outputEnd = "end2");
}
else if (Case == "legacy_conflict_alignment") {
  HoseAdapter(outputMode = "alignment_ring", outputEnd = "end1", drawAlignmentRing = "end2");
}
else if (Case == "legacy_conflict_gasket") {
  HoseAdapter(
    connector1 = validIzTwistConnector(1),
    outputMode = "iztwist_gasket",
    outputEnd = "end1",
    drawAlignmentRing = "end1"
  );
}
else {
  assert(false, str("Unsupported hose_adapter_output_expected_failures Case: ", Case));
}
