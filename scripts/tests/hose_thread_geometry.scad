include <../../modules/vacuum-hose-adapter.scad>

Case = "enabled"; // [enabled,reversed]
Layout = "flat"; // [flat,hull]
$fn = 64;
assert(Case == "enabled" || Case == "reversed", "Unsupported thread geometry case");
assert(Layout == "flat" || Layout == "hull", "Unsupported thread geometry layout");

function sleeveSettings(connector) = UserConnectorSettings(
  connector = connector, style = "hose", measurement = "inner",
  diameter = 40.4, length = 20, wallThickness = 3, taper = 0,
  enableThreads = Case, threadProfile = "inward_triangle",
  threadPitch = 5, threadToothHeight = 2.5, threadToothWidth = 2.5);

module Actual() {
  if (Layout == "flat")
    HoseAdapter(
      connector1 = sleeveSettings(1),
      connector2 = sleeveSettings(2),
      transitionStyle = "flat",
      transitionLength = 10);
  else
    HoseAdapter(
      connector1 = UserConnectorSettings(
        connector = 1, measurement = "inner", diameter = 60, length = 20, taper = 0),
      connector2 = UserConnectorSettings(
        connector = 2, measurement = "inner", diameter = 30, length = 20, taper = 0),
      connector3 = sleeveSettings(3),
      transitionStyle = "hull",
      transitionAngle = 45,
      transitionLength = 10,
      transitionHullCenter = "end3",
      transitionHullCenterHeight = 60);
}

module Probe(point, end) {
  // The hull center port starts at 20 + 60 and ends at 100 mm.
  translate([0, 0, end == 1 ? 0 : end == 2 ? 50 : 100])
    rotate([0, end == 1 ? 0 : 180, 0])
      translate(point)
        cube(0.01, center = true);
}

module ProfileProbes(solid) {
  for (end = Layout == "flat" ? [1, 2] : [3], angle = [0, 90, 180, 270],
      offset = [0, 0.25, 0.5, 1, 1.5, 2],
      radius = [17.6, 17.8, 18.4, 19.2, 20.1, 20.3, 23.1, 23.3]) {
    // Full-height cutter is shifted by half its 0.001*length extension.
    tip = (Case == "enabled" ? 180 - angle : angle) * 5 / 360 - 0.01;
    z = 10 + tip + offset;
    ridge = max(0, 2.5 * (1 - offset / 1.25));
    inMaterial = radius > 20.2 - ridge && radius < 23.2;
    if (inMaterial == solid)
      Probe([radius * cos(angle), radius * sin(angle), z], end);
  }
}

// Solid probes must survive and void probes must stay empty, with a margin from faces.
difference() {
  ProfileProbes(true);
  Actual();
}
intersection() {
  union() {
    ProfileProbes(false);
    cylinder(h = Layout == "flat" ? 50 : 100, d = 1);
  }
  Actual();
}
