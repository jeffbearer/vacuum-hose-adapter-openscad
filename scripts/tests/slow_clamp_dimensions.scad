include <../../modules/accessories/oneida_slow_clamp.scad>

beadOD = oneidaQuickClampBeadOuterDiameter(127);
beadSection = oneidaBeadDiameter;
neckOD = oneidaQuickClampNeckOuterDiameter(127);
beadRadius = beadSection / 2;
seat = slowClampSeatingRadius(beadOD, beadSection, 45, 0);
contactZ = beadRadius + beadRadius / sqrt(2);
contactR = beadOD / 2 - beadRadius + beadRadius / sqrt(2);

assert(abs(beadOD - 136) < 0.001 && abs(neckOD - 123) < 0.001);
assert(abs(seat - contactR - contactZ) < 0.0001, "Groove must be tangent to the two round beads");
assert(contactZ < 7, "Both contact locations must lie inside the band");
assert(abs(slowClampGrooveInnerRadius(contactZ, beadOD, beadSection) - contactR - 0.35) < 0.0001);
assert(abs(slowClampGrooveInnerRadius(-contactZ, beadOD, beadSection) - contactR - 0.35) < 0.0001);
assert(slowClampGrooveInnerRadius(7, beadOD, beadSection) > neckOD / 2 + 0.35);
assert(abs(slowClampSeatingRadius(beadOD, beadSection, 45, 1) - seat - 0.5) < 0.0001);
flatR = slowClampGrooveInnerRadius(0, beadOD, beadSection);
assert(abs(flatR - (seat + 0.35 - 3)) < 0.0001, "The 6 mm flat removes 3 mm of radial groove depth at 45 degrees");
assert(flatR > beadOD / 2 + 0.35, "The flat must stay clear of both beads");
assert(abs(slowClampBandOuterRadius(beadOD, beadSection) - flatR - 5) < 0.0001,
  "The thinner outer band must retain a 5 mm minimum wall");
assert(abs(slowClampBandOuterRadius(beadOD, beadSection, grooveFlatWidth=0)
  - slowClampBandOuterRadius(beadOD, beadSection) - 3) < 0.0001,
  "The default flat must reduce outside diameter by 6 mm");
assert(abs(slowClampScrewAxisX(beadOD, beadSection)
  - slowClampBandOuterRadius(beadOD, beadSection) - 7) < 0.0001);
for (z = [-3, -1, 0, 1, 3])
  assert(abs(slowClampGrooveInnerRadius(z, beadOD, beadSection) - flatR) < 0.0001,
    "The groove bottom must be constant-radius across the flat");
assert(abs(slowClampGrooveInnerRadius(0, beadOD, beadSection, grooveFlatWidth=0)
  - seat - 0.35) < 0.0001, "Zero flat width must recover the original pointed groove");
assert(abs(slowClampNutPocketDepth(4, 0.3) - 4.3) < 0.001);
assert(8 - slowClampNutPocketDepth(4, 0.3) > 3, "The nut must retain a solid bearing ligament");
assert(2 * PI * 0.35 < 12, "Estimated seating travel must leave a closure gap");

assert(slowClampTotalWidth() == 20, "Default supports add 3 mm to each end of the 14 mm taper");
assert(slowClampTotalWidth(14, 0) == 14, "Zero support must retain the original axial extent");
assert(slowClampTotalWidth(18, 1.25) == 20.5, "Custom supports must not change the tapered width");
assert(abs(slowClampTotalWidth() / 2 - 10) < 0.0001, "The joint and screw plane must move to Z10");
assert(abs(slowClampGrooveInnerRadius(10, beadOD, beadSection) - (seat + 0.35 - 10)) < 0.0001,
  "Outside the flat, the original flank helper must retain its positional API and values");

for (r = [40, slowClampBandOuterRadius(beadOD, beadSection), 200],
     chamfer = [0.1, 3, 5]) {
  // The smallest band needs more radial wall to keep its rounded ear root integral.
  wall = r == 40 ? 8 : 5;
  rootX = sqrt(r * r - 14 * 14);
  profile = _slowClampEarRootProfile(r, wall, 12, 8, 14, chamfer);
  assert(abs(profile[0].x - rootX - chamfer) < 0.0001);
  assert(profile[0].y == 14, "The diagonal must start on the flat ear outer side");
  assert(abs((profile[0].x - profile[1].x) / (profile[1].y - profile[0].y) - 1) < 0.0001,
    "The added root face must be 45 degrees in plan view");
  assert(norm(profile[1]) < r && norm(profile[2]) < r,
    "Root polygons must overlap the band, not meet it at only one point");
  assert(profile[2].y < 14 && profile[2].y > 6, "Root polygons must overlap the ear");
  assert(_slowClampSegmentRadius(profile[2], profile[1]) > r - wall,
    "Added material must stay outside the deepest V-groove radius");
}

cube(1);
