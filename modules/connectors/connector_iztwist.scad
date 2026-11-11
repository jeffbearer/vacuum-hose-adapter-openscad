// Inspired by our favorite South Carolina inventor.
// Experimental screw-and-hook interface; GPL-compatible licensing permission remains unresolved.
// Reference design: HybridHobbyist (@IceDeck_241588) on Printables.
// Dust Collector/Vacuum Hose Couplers Variety.
// Creator: https://www.printables.com/@IceDeck_241588
// Reference: https://www.printables.com/model/332587 (CC BY-NC-SA 4.0).
include <../constants.scad>
use <../modules_pipe.scad>
use <../thirdparty/threads-scad/threads.scad>

// Each row is a fixed mating family, not a scale factor for the hose port.
// inches, bore, catch OD, bolt circle, slot, root OD, plate, tip, ramp run,
// carrier OD, carrier thickness, screw diameter, pitch, head OD, head height, screw length.
izTwistProfiles = [
  [2.5, 56, 100, 84, 5.4, 75, 8, 5, 12, 96, 10, 5, 0.8, 8.5, 5, 20],
  [4, 90, 160, 134.4, 10.5, 112, 10.25, 6.4, 19.2, 153.6, 16, 10, 1.5, 16, 10, 30],
  [6, 135, 240.6, 202.104, 12.5, 180.45, 15.416, 9.624, 28.872, 230.976, 24.06, 10, 1.5, 16, 10, 35]
];

iIzTwistSize = 0;
iIzTwistBore = 1;
iIzTwistCatchDiameter = 2;
iIzTwistBoltCircle = 3;
iIzTwistSlotWidth = 4;
iIzTwistRootDiameter = 5;
iIzTwistPlateHeight = 6;
iIzTwistTipHeight = 7;
iIzTwistRampRun = 8;
iIzTwistCarrierDiameter = 9;
iIzTwistCarrierThickness = 10;
iIzTwistScrewDiameter = 11;
iIzTwistPitch = 12;
iIzTwistHeadDiameter = 13;
iIzTwistHeadHeight = 14;
iIzTwistScrewLength = 15;

izTwistScrewSettings = ["iztwist_screw", [
  [iSettingsMeasurement, "inner"],
  [iSettingsTaper, 0],
  [iSettingsVersion, "prototype-1"]
]];
izTwistHookSettings = ["iztwist_hook", [
  [iSettingsMeasurement, "inner"],
  [iSettingsTaper, 0],
  [iSettingsVersion, "prototype-1"]
]];

function izTwistSupportedNominalsInch() = [for (profile = izTwistProfiles) profile[iIzTwistSize]];
function izTwistIsStyle(style) = style == "iztwist_screw" || style == "iztwist_hook";
function izTwistSide(style) =
  assert(izTwistIsStyle(style), str("Unsupported IzTwist style: ", style))
  style == "iztwist_screw" ? "screw" : "hook";

function izTwistProfile(nominalDiameter = 63.5) =
  assert(is_num(nominalDiameter) && nominalDiameter > 0, "IzTwist nominal diameter must be positive")
  let(matches = [for (profile = izTwistProfiles)
    if (abs(profile[iIzTwistSize] * 25.4 - nominalDiameter) < 0.001) profile])
  assert(len(matches) == 1, "IzTwist interface must be nominal 2.5, 4, or 6 inches")
  matches[0];

function izTwistNeckInnerDiameter(nominalDiameter = 63.5) =
  izTwistProfile(nominalDiameter)[iIzTwistBore];

function izTwistNeckOuterDiameter(nominalDiameter = 63.5, wallThickness = 3) =
  assert(is_num(wallThickness) && wallThickness > 0, "IzTwist wall thickness must be positive")
  izTwistNeckInnerDiameter(nominalDiameter) + 2 * wallThickness;

function izTwistMinimumLength(nominalDiameter = 63.5, side = "screw", wallThickness = 3) =
  assert(side == "screw" || side == "hook", "IzTwist side must be screw or hook")
  assert(is_num(wallThickness) && wallThickness > 0, "IzTwist wall thickness must be positive")
  let(profile = izTwistProfile(nominalDiameter))
  (side == "screw" ? profile[iIzTwistCarrierThickness] : profile[iIzTwistPlateHeight]) + wallThickness;

function izTwistForkCornerRadius() = 1.5;
function izTwistMouthChamferSize() = 1;

function izTwistHookInnerExtent(profile) =
  let(root = profile[iIzTwistRootDiameter] / 2, halfWidth = profile[iIzTwistRampRun])
  assert(halfWidth < root, "IzTwist hook width must fit its root flange")
  // Overlap the circular flange at the hook's corners, not only on its centerline.
  sqrt(root * root - halfWidth * halfWidth) - izTwistForkCornerRadius() - 1;

function izTwistHookLeadInTip(profile) =
  let(slotInner = (profile[iIzTwistBoltCircle] - profile[iIzTwistSlotWidth]) / 2,
      run = profile[iIzTwistRampRun])
  assert(run < slotInner, "IzTwist mouth must fit the screw orbit")
  [sqrt(slotInner * slotInner - run * run), run];

function izTwistHookLeadInRoot(profile) =
  let(root = profile[iIzTwistRootDiameter] / 2,
      tip = izTwistHookLeadInTip(profile),
      diagonal = tip.x + tip.y,
      discriminant = 2 * root * root - diagonal * diagonal)
  assert(discriminant > 0, "IzTwist forward sweep must meet the round flange")
  [(diagonal + sqrt(discriminant)) / 2, (diagonal - sqrt(discriminant)) / 2];

function izTwistHookOuterMouth(profile) =
  let(slotOuter = (profile[iIzTwistBoltCircle] + profile[iIzTwistSlotWidth]) / 2,
      run = profile[iIzTwistRampRun])
  assert(run < slotOuter, "IzTwist entrance must fit the outer screw orbit")
  [sqrt(slotOuter * slotOuter - run * run), run];

module izTwistHookFootprint(profile) {
  radius = profile[iIzTwistBoltCircle] / 2;
  outer = profile[iIzTwistCatchDiameter] / 2;
  run = profile[iIzTwistRampRun];
  back = run;
  inner = izTwistHookInnerExtent(profile);
  difference() {
    union() {
      // Round the external outline before cutting the slot, so its working width stays fixed.
      offset(r = izTwistForkCornerRadius())
      offset(delta = -izTwistForkCornerRadius())
      intersection() {
        circle(r = outer);
        translate([inner, -back])
        square([outer - inner + 1, run + back]);
      }
      // Extend forward from the mouth into the flange instead of relieving the tip backward.
      leadIn = izTwistHookLeadInTip(profile);
      leadRoot = izTwistHookLeadInRoot(profile);
      rootX = leadRoot.x - 1;
      polygon([
        [rootX, run - fudgeFactor],
        [leadIn.x, run - fudgeFactor],
        leadIn,
        [rootX, leadIn.x + leadIn.y - rootX]
      ]);
    }
    // The shank follows a circular orbit while twisting, not a straight slot.
    slot = profile[iIzTwistSlotWidth];
    entryAngle = asin((run + slot) / radius);
    union() {
      intersection() {
        difference() {
          circle(r = radius + slot / 2);
          circle(r = radius - slot / 2);
        }
        polygon([[0,0], [2*radius,0],
          [2*radius*cos(entryAngle),2*radius*sin(entryAngle)]]);
      }
      translate([radius, 0]) circle(d = slot);
      rotate(entryAngle) translate([radius, 0]) circle(d = slot);
    }
    // Flare only the outer tine's slot-facing entry corner, leaving the working slot intact.
    mouth = izTwistHookOuterMouth(profile);
    chamfer = izTwistMouthChamferSize();
    cutStart = mouth.x - 2 * chamfer;
    polygon([
      [cutStart, run - 3 * chamfer],
      [mouth.x + chamfer + fudgeFactor, run + fudgeFactor],
      [cutStart, run + fudgeFactor]
    ]);
  }
}

module izTwistOuterRoundoverCut(outer, height, radius) {
  if (radius > 0)
    rotate_extrude()
    translate([outer - radius, height - radius])
    polygon(concat(
      [[0, radius + fudgeFactor], [radius + fudgeFactor, radius + fudgeFactor],
       [radius + fudgeFactor, 0], [radius, 0]],
      [for (i = [1:12]) [radius * cos(i * 7.5), radius * sin(i * 7.5)]]
    ));
}

module izTwistRoundedFlange(height, outer, radius) {
  // Explicit profiles avoid coincident cylinder surfaces at the roundover tangents.
  rotate_extrude()
    polygon(concat(
      [[0,0], [outer,0], [outer,height-radius]],
      [for (i = [1:12])
        [outer-radius + radius*cos(i*7.5), height-radius + radius*sin(i*7.5)]],
      [[0,height]]
    ));
}

module izTwistForkEndRoundoverCut(profile, radius, front) {
  run = profile[iIzTwistRampRun];
  outer = profile[iIzTwistCatchDiameter] / 2;
  leadTip = izTwistHookLeadInTip(profile);
  startX = front ? leadTip.x + fudgeFactor : izTwistHookInnerExtent(profile);
  direction = front ? 1 : -1;
  multmatrix([
    [0,0,1,startX],
    [direction,0,0,direction*(run-radius)],
    [0,1,0,profile[iIzTwistPlateHeight]-radius],
    [0,0,0,1]
  ])
  linear_extrude(height = outer - startX + fudgeFactor)
    polygon(concat(
      [[0, radius + fudgeFactor], [radius + fudgeFactor, radius + fudgeFactor],
       [radius + fudgeFactor, 0], [radius, 0]],
      [for (i = [1:12]) [radius * cos(i * 7.5), radius * sin(i * 7.5)]]
    ));
}

module izTwistHook(profile, roundover) {
  peak = profile[iIzTwistPlateHeight];
  tip = profile[iIzTwistTipHeight];
  run = profile[iIzTwistRampRun];
  rampStart = run / 4;
  slope = (peak - tip) / (run - rampStart);
  outer = profile[iIzTwistCatchDiameter] / 2;
  difference() {
    linear_extrude(height = peak)
      izTwistHookFootprint(profile);
    // Clip only the rear bearing surface; the mating face remains flat.
    translate([0, rampStart, peak])
    rotate([-atan(slope), 0, 0])
    translate([-2 * outer, -4 * outer, 0])
      cube([4 * outer, 8 * outer, 4 * outer]);
    izTwistOuterRoundoverCut(outer, peak, roundover);
    // Follow the sloping top too, without rounding the slot's head-bearing edges.
    multmatrix([[1,0,0,0], [0,1,0,0], [0,-slope,1,slope*rampStart], [0,0,0,1]])
      izTwistOuterRoundoverCut(outer, peak, roundover);
    izTwistForkEndRoundoverCut(profile, roundover, false);
    multmatrix([[1,0,0,0], [0,1,0,0], [0,-slope,1,slope*rampStart], [0,0,0,1]])
      izTwistForkEndRoundoverCut(profile, roundover, true);
  }
}

module izTwistNeckFillet(neckRadius, flangeHeight, radius) {
  if (radius > 0)
    rotate_extrude()
    polygon(concat(
      [[neckRadius-fudgeFactor, flangeHeight-fudgeFactor],
       [neckRadius+radius, flangeHeight-fudgeFactor]],
      [for (i = [0:12])
        [neckRadius+radius + radius*cos(270-i*7.5),
         flangeHeight+radius + radius*sin(270-i*7.5)]],
      [[neckRadius-fudgeFactor, flangeHeight+radius]]
    ));
}

module izTwistFaceBody(profile, side, length, wallThickness, threaded) {
  bore = profile[iIzTwistBore];
  neck = bore + 2 * wallThickness;
  radius = profile[iIzTwistBoltCircle] / 2;
  flangeHeight = side == "screw" ? profile[iIzTwistCarrierThickness] : profile[iIzTwistPlateHeight];
  flangeRadius = (side == "screw" ? profile[iIzTwistCarrierDiameter] : profile[iIzTwistRootDiameter]) / 2;
  shoulderWidth = flangeRadius - neck / 2;
  roundover = min(1, shoulderWidth / 3);
  fillet = min(2, wallThickness, length - flangeHeight, shoulderWidth - roundover);
  difference() {
    union() {
      cylinder(h = length, d = neck);
      izTwistNeckFillet(neck / 2, flangeHeight, fillet);
      if (side == "screw")
        izTwistRoundedFlange(flangeHeight, flangeRadius, roundover);
      else {
        izTwistRoundedFlange(flangeHeight, flangeRadius, roundover);
        for (i = [0:3])
          rotate([0, 0, i * 90]) izTwistHook(profile, roundover);
      }
    }
    translate([0, 0, -fudgeFactor])
      cylinder(h = length + 2 * fudgeFactor, d = bore);
    if (side == "screw")
      for (i = [0:3])
        rotate([0, 0, i * 90])
        translate([radius, 0, -fudgeFactor])
        if (threaded)
          ScrewThread(
            outer_diam = 1.01 * profile[iIzTwistScrewDiameter] + 1.25 * 0.4,
            height = profile[iIzTwistCarrierThickness] + 2 * fudgeFactor,
            pitch = profile[iIzTwistPitch],
            tolerance = 0.4);
        else
          cylinder(h = profile[iIzTwistCarrierThickness] + 2 * fudgeFactor,
            d = profile[iIzTwistScrewDiameter]);
  }
}

module IzTwistConnector(
  nominalDiameter = 63.5,
  side = "screw",
  length = 20,
  wallThickness = 3,
  threaded = true,
  help = false
) {
  profile = izTwistProfile(nominalDiameter);
  assert(side == "screw" || side == "hook", "IzTwist side must be screw or hook");
  assert(is_num(length) && length >= izTwistMinimumLength(nominalDiameter, side, wallThickness),
    str("IzTwist connector is too short; minimum is ", izTwistMinimumLength(nominalDiameter, side, wallThickness), " mm"));
  assert(is_bool(threaded), "IzTwist threaded must be boolean");
  assert(izTwistNeckOuterDiameter(nominalDiameter, wallThickness) < profile[iIzTwistRootDiameter],
    "IzTwist wall thickness would interfere with the fixed mating profile");
  assert(profile[iIzTwistSlotWidth] > profile[iIzTwistScrewDiameter] &&
    profile[iIzTwistSlotWidth] < profile[iIzTwistHeadDiameter],
    "IzTwist slot must clear the screw shank and retain its head");
  assert(profile[iIzTwistBoltCircle] - profile[iIzTwistHeadDiameter] > profile[iIzTwistRootDiameter],
    "IzTwist root ring must clear the screw heads during entry");
  translate([0, 0, length])
  rotate([180, 0, 0])
    izTwistFaceBody(profile, side, length, wallThickness, threaded);
  if (help)
    echo("IzTwist preset", inches = profile[iIzTwistSize],
      bore = profile[iIzTwistBore], boltCircle = profile[iIzTwistBoltCircle],
      screw = profile[iIzTwistScrewDiameter], pitch = profile[iIzTwistPitch]);
}

// Bed-oriented TPU face seal; the outer skirt locates around the screw carrier.
module IzTwistGasket(nominalDiameter = 63.5) {
  profile = izTwistProfile(nominalDiameter);
  thickness = 2;
  skirt = 3;
  clearance = 0.3;
  outer = profile[iIzTwistCatchDiameter];
  radius = profile[iIzTwistBoltCircle] / 2;
  difference() {
    union() {
      cylinder(h = thickness, d = outer);
      translate([0, 0, thickness])
        cylinder(h = skirt, d = outer);
    }
    translate([0, 0, -fudgeFactor])
      cylinder(h = thickness + skirt + 2 * fudgeFactor, d = profile[iIzTwistBore]);
    translate([0, 0, thickness])
      cylinder(h = skirt + fudgeFactor, d = profile[iIzTwistCarrierDiameter] + clearance);
    for (i = [0:3])
      rotate([0, 0, i * 90])
      translate([radius, 0, -fudgeFactor])
        cylinder(h = thickness + 2 * fudgeFactor, d = profile[iIzTwistScrewDiameter] + 0.5);
  }
}

// Preview only: adjustable screw projection supplies gasket compression.
module IzTwistHardware(nominalDiameter = 63.5) {
  profile = izTwistProfile(nominalDiameter);
  radius = profile[iIzTwistBoltCircle] / 2;
  projection = profile[iIzTwistPlateHeight] + 1.5;
  for (i = [0:3])
    rotate([0, 0, i * 90])
    translate([radius, 0, -projection])
      union() {
        cylinder(h = profile[iIzTwistScrewLength], d = profile[iIzTwistScrewDiameter]);
        translate([0, 0, -profile[iIzTwistHeadHeight]])
          cylinder(h = profile[iIzTwistHeadHeight], d = profile[iIzTwistHeadDiameter]);
      }
}
