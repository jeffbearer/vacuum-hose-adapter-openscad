// Hose connector
// repo https://github.com/ostat/vacuum-hose-adapter-openscad
//
// Local preset: 58 mm OD straight to 57 mm OD tapered (male-male), 30 mm insertion per side.

include <../modules/vacuum-hose-adapter.scad>

/* [Adapter dimensions] */
diameter0 = 58; // End 1 outside diameter (mm)
diameter1 = 57; // End 2 outside diameter (mm)
length0 = 30;   // End 1 insertion length (mm)
length1 = 30;   // End 2 insertion length (mm)
wall = 2;       // Wall thickness (mm)
taper0 = 0;     // End 1 diametral taper (mm)
taper1 = 1;     // End 2 diametral taper (mm): free tip 56.5 to base 57.5
transition_length = 1; // Join section length (mm)

/* [Model detail] */
detail = 192; // Fragment count

/* [Hidden] */
module end_of_customizer_opts() {}
$fn = detail;

HoseAdapter(
  connector1 = UserConnectorSettings(
    connector = 1,
    style = "hose",
    wallThickness = wall,
    measurement = "outer",
    diameter = [diameter0, 0],
    length = [length0, 0],
    taper = taper0,
    barbsCount = 0
  ),
  connector2 = UserConnectorSettings(
    connector = 2,
    style = "hose",
    wallThickness = wall,
    measurement = "outer",
    diameter = [diameter1, 0],
    length = [length1, 0],
    taper = taper1,
    barbsCount = 0
  ),
  connector3 = UserConnectorSettings(
    connector = 3,
    style = "none",
    length = [0, 0]
  ),
  transitionStyle = "flat",
  transitionLength = transition_length,
  transitionAngle = 0
);
