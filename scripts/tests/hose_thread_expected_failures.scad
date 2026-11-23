include <../../modules/connectors/connector_hose.scad>

Case = "outer_measurement";
assert(Case == "outer_measurement" || Case == "taper"
  || Case == "width_equal_pitch" || Case == "width_above_pitch",
  str("Unsupported hose_thread_expected_failures Case: ", Case));

HoseConnector(
  innerStartDiameter = 40.4,
  innerEndDiameter = Case == "taper" ? 41.4 : 40.4,
  connectorMeasurement = Case == "outer_measurement" ? "outer" : "inner",
  length = 20,
  wallThickness = 3,
  enableThreads = "enabled",
  threadProfile = "inward_triangle",
  threadPitch = 5,
  threadToothHeight = 2.5,
  threadToothWidth = Case == "width_equal_pitch" ? 5
    : Case == "width_above_pitch" ? 5.5 : 2.5,
  help = false);
