include <../../modules/accessories/slow_clamp.scad>

// The default is a positive render fixture; override Case for assertion regressions.
Case = "valid";

if (Case == "valid") {
  SlowClamp(edgeSupport=0, earRootChamfer=0, $fn=64);
  translate([200, 0, 0])
    SlowClamp(bandWidth=18, edgeSupport=1.25, earRootChamfer=2, $fn=64);
  translate([0, 200, 0])
    SlowClamp(bandWidth=10, edgeSupport=3, nutAcrossFlats=10.7, $fn=64);
  translate([200, 200, 0])
    SlowClamp(grooveFlatWidth=0, $fn=64);
  translate([400, 0, 0])
    SlowClamp(grooveFlatWidth=2, draftAngle=30, $fn=64);
  translate([400, 200, 0])
    SlowClamp(grooveFlatWidth=6, draftAngle=60, $fn=64);
} else if (Case == "negative_support")
  SlowClamp(edgeSupport=-1);
else if (Case == "nonnumeric_support")
  SlowClamp(edgeSupport="3");
else if (Case == "negative_chamfer")
  SlowClamp(earRootChamfer=-1);
else if (Case == "nonnumeric_chamfer")
  SlowClamp(earRootChamfer="3");
else if (Case == "short_contact_region")
  SlowClamp(bandWidth=8, edgeSupport=20);
else if (Case == "neck_interference")
  SlowClamp(bandWidth=22, edgeSupport=3);
else if (Case == "nut_exceeds_total_width")
  SlowClamp(edgeSupport=0, nutAcrossFlats=14);
else if (Case == "root_misses_circle")
  SlowClamp(splitGap=150);
else if (Case == "root_on_rounded_corner")
  SlowClamp(bandWall=2);
else if (Case == "chamfer_on_rounded_tip")
  SlowClamp(earRootChamfer=20);
else if (Case == "hardware_path_blocked")
  SlowClamp(earRootChamfer=10);
else if (Case == "chamfer_misses_circle")
  linear_extrude(1)
    polygon(_slowClampEarRootProfile(20, 10, 4, 6, 14, 3));
else if (Case == "chamfer_cuts_groove")
  linear_extrude(1)
    polygon(_slowClampEarRootProfile(100, 1.01, 0.2, 0.1, 50, 40));
else if (Case == "negative_flat")
  SlowClamp(grooveFlatWidth=-1);
else if (Case == "nonnumeric_flat")
  SlowClamp(grooveFlatWidth="6");
else if (Case == "flat_reaches_contacts")
  SlowClamp(grooveFlatWidth=10);
else if (Case == "flat_reaches_beads")
  SlowClamp(grooveFlatWidth=8);
else
  assert(false, str("Unknown SlowClamp reinforcement test case: ", Case));
