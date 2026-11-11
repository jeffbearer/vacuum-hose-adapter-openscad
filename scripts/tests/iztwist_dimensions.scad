include <../../modules/connectors/connector_iztwist.scad>

epsilon = 0.0001;

function approx(a, b, tolerance = epsilon) = abs(a - b) <= tolerance;

expectedNominals = [2.5, 4, 6];
assert(izTwistSupportedNominalsInch() == expectedNominals);

expectedProfiles = [
  [2.5, 56, 100, 84, 5.4, 75, 8, 5, 12, 96, 10, 5, 0.8, 8.5, 5, 20],
  [4, 90, 160, 134.4, 10.5, 112, 10.25, 6.4, 19.2, 153.6, 16, 10, 1.5, 16, 10, 30],
  [6, 135, 240.6, 202.104, 12.5, 180.45, 15.416, 9.624, 28.872, 230.976, 24.06, 10, 1.5, 16, 10, 35]
];

for (i = [0 : len(expectedProfiles) - 1]) {
  expected = expectedProfiles[i];
  nominalMm = expected[iIzTwistSize] * 25.4;
  actual = izTwistProfile(nominalDiameter = nominalMm);
  assert(len(actual) == len(expected));
  for (j = [0 : len(expected) - 1])
    assert(approx(actual[j], expected[j]));

  assert(approx(actual[iIzTwistBore], expected[iIzTwistBore]));
  assert(approx(actual[iIzTwistCatchDiameter], expected[iIzTwistCatchDiameter]));
  assert(approx(actual[iIzTwistBoltCircle], expected[iIzTwistBoltCircle]));
  assert(approx(actual[iIzTwistPlateHeight], expected[iIzTwistPlateHeight]));
  assert(approx(actual[iIzTwistSlotWidth], expected[iIzTwistSlotWidth]));
  assert(approx(actual[iIzTwistHeadDiameter], expected[iIzTwistHeadDiameter]));
  assert(actual[iIzTwistSlotWidth] > actual[iIzTwistScrewDiameter]);
  assert(actual[iIzTwistSlotWidth] < actual[iIzTwistHeadDiameter]);
  assert(izTwistForkCornerRadius() > 0);
  assert(izTwistForkCornerRadius() < actual[iIzTwistRampRun] / 2);
  assert(actual[iIzTwistBoltCircle] - actual[iIzTwistHeadDiameter] > actual[iIzTwistRootDiameter]);
  rootRadius = actual[iIzTwistRootDiameter] / 2;
  cornerY = actual[iIzTwistRampRun];
  innerX = izTwistHookInnerExtent(actual);
  assert(innerX * innerX + cornerY * cornerY < rootRadius * rootRadius,
    "Catch root must overlap the round flange across its full width");
  leadIn = izTwistHookLeadInTip(actual);
  slotInnerRadius = (actual[iIzTwistBoltCircle] - actual[iIzTwistSlotWidth]) / 2;
  assert(approx(leadIn.y, cornerY));
  assert(approx(leadIn.x * leadIn.x + leadIn.y * leadIn.y, slotInnerRadius * slotInnerRadius),
    "Entry sweep must terminate at the inner slot mouth, not widen the working slot");
  leadRoot = izTwistHookLeadInRoot(actual);
  assert(approx(leadRoot.x * leadRoot.x + leadRoot.y * leadRoot.y, rootRadius * rootRadius));
  assert(leadRoot.y > leadIn.y && leadRoot.x < leadIn.x,
    "Entry sweep must extend forward from the mouth toward the round flange");
  assert(approx(leadRoot.x + leadRoot.y, leadIn.x + leadIn.y),
    "Forward lead-in must have the intended 45-degree orientation");
  mouth = izTwistHookOuterMouth(actual);
  slotOuterRadius = (actual[iIzTwistBoltCircle] + actual[iIzTwistSlotWidth]) / 2;
  assert(approx(mouth.y, cornerY));
  assert(approx(mouth.x * mouth.x + mouth.y * mouth.y, slotOuterRadius * slotOuterRadius));
  assert(izTwistMouthChamferSize() > 0 && izTwistMouthChamferSize() < cornerY / 2);
  outerCornerX = sqrt(pow(actual[iIzTwistCatchDiameter] / 2, 2) - cornerY * cornerY);
  assert(mouth.x + 2 * izTwistMouthChamferSize() < outerCornerX,
    "Entrance chamfer must leave material on the outer fork arm");
}

for (nominalInch = expectedNominals) {
  nominalMm = nominalInch * 25.4;
  profile = izTwistProfile(nominalDiameter = nominalMm);
  for (wall = [3, 4]) {
    assert(approx(izTwistNeckInnerDiameter(nominalDiameter = nominalMm), profile[iIzTwistBore]));
    assert(approx(izTwistNeckOuterDiameter(nominalDiameter = nominalMm, wallThickness = wall), profile[iIzTwistBore] + 2 * wall));
    assert(approx(
      izTwistMinimumLength(nominalDiameter = nominalMm, side = "screw", wallThickness = wall),
      profile[iIzTwistCarrierThickness] + wall));
    assert(approx(
      izTwistMinimumLength(nominalDiameter = nominalMm, side = "hook", wallThickness = wall),
      profile[iIzTwistPlateHeight] + wall));
  }
}

assert(approx(
  izTwistMinimumLength(nominalDiameter = 6 * 25.4, side = "screw", wallThickness = 3),
  27.06));

cube([1,1,1]);
