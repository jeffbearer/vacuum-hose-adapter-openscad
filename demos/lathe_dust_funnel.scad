// Lathe sanding dust funnel (mouth-down print orientation)
// Uses existing Nozzle + HoseConnector modules only.

include <../modules/connectors/connector_nozzle.scad>
include <../modules/connectors/connector_hose.scad>

/* [Part] */
part = "full"; // ["full","funnel","socket_fit"]

/* [Funnel dimensions] */
mouth_outside = [170, 100]; // Rectangular mouth outer size (mm)
funnel_depth = 80;          // Circle-to-rectangle transition depth (mm)
mouth_lip = 3;              // Straight mouth lip length (mm)
wall_thickness = 2.4;       // Nominal wall thickness (mm)
mouth_corner_radius = 8;    // Inner mouth corner radius (mm)

/* [Socket fit dimensions] */
socket_depth = 30;            // Female socket depth (mm)
socket_inner_deep = 43.8;     // Inner diameter at deep end (joins funnel neck)
socket_inner_opening = 44.8;  // Inner diameter at free opening
socket_overlap = 0.01;        // Small overlap to avoid seams

/* [Model detail] */
detail = 128;

/* [Hidden] */
module end_of_customizer_opts() {}
$fn = detail;

mouth_inner = [mouth_outside.x - wall_thickness * 2, mouth_outside.y - wall_thickness * 2];
funnel_neck_z = funnel_depth + mouth_lip + 0.03;

assert(mouth_inner.x > 0 && mouth_inner.y > 0, "mouth_outside must be larger than 2*wall_thickness.");

module LatheFunnelBody() {
  translate([0, 0, funnel_neck_z])
    rotate([180, 0, 0])
      Nozzle(
        innerStartDiameter = socket_inner_deep,
        length = funnel_depth,
        wallThickness = wall_thickness,
        nozzleShape = "square",
        nozzleSize = [mouth_inner.x, mouth_inner.y, mouth_lip],
        nozzleTipWallThickness = wall_thickness,
        nozzleRadius = mouth_corner_radius,
        nozzleOffset = [0, 0],
        nozzleChamferPercentage = 0,
        nozzleChamferAngle = 0,
        help = false
      );
}

module LatheFemaleSocket() {
  translate([0, 0, funnel_neck_z + socket_depth - socket_overlap])
    rotate([180, 0, 0])
      HoseConnector(
        innerStartDiameter = socket_inner_opening,
        innerEndDiameter = socket_inner_deep,
        connectorMeasurement = "inner",
        length = socket_depth,
        wallThickness = wall_thickness,
        barbsCount = 0,
        enableThreads = "disabled",
        help = false
      );
}

if (part == "funnel") {
  LatheFunnelBody();
} else if (part == "socket_fit") {
  LatheFemaleSocket();
} else {
  union() {
    LatheFunnelBody();
    LatheFemaleSocket();
  }
}
