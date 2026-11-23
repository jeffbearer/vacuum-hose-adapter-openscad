Case = "invalid_output_mode";

include <../../modules/vacuum-hose-adapter.scad>

validEnd1 = OneidaConnectorSettings(
  connector = 1,
  diameter = [0,5],
  wallThickness = 2.4,
  length = [20,0],
  fitAdjustment = 0
);

if (Case == "invalid_output_mode") {
  HoseAdapter(connector1 = validEnd1, outputMode = "bad_mode");
}
else if (Case == "invalid_output_end") {
  HoseAdapter(connector1 = validEnd1, outputMode = "slowclamp", outputEnd = "end4");
}
else if (Case == "alignment_end3") {
  HoseAdapter(connector1 = validEnd1, outputMode = "alignment_ring", outputEnd = "end3");
}
else if (Case == "legacy_conflict_with_slowclamp") {
  HoseAdapter(connector1 = validEnd1, drawAlignmentRing = "end1", outputMode = "slowclamp", outputEnd = "end1");
}
else if (Case == "legacy_conflict_with_alignment_mode") {
  HoseAdapter(connector1 = validEnd1, drawAlignmentRing = "end2", outputMode = "alignment_ring", outputEnd = "end2");
}
else if (Case == "selected_non_oneida_end2") {
  HoseAdapter(
    connector1 = validEnd1,
    connector2 = UserConnectorSettings(connector = 2, style = "hose", diameter = [50,0], length = [20,0]),
    outputMode = "slowclamp",
    outputEnd = "end2"
  );
}
else if (Case == "legacy_invalid_selector") {
  HoseAdapter(connector1 = validEnd1, outputMode = "adapter", drawAlignmentRing = "end3");
}
else if (Case == "adapter_selected_oneida_length_below_min") {
  HoseAdapter(
    connector1 = OneidaConnectorSettings(connector = 1, diameter = [0,5], wallThickness = 2.4, length = [1,0]),
    outputMode = "adapter"
  );
}
else {
  assert(false, str("Unsupported slow_clamp_output_expected_failures Case: ", Case));
}
