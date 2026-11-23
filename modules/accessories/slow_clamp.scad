function slowClampBeadRadius(beadCrossSection=5.58) =
  assert(is_num(beadCrossSection) && beadCrossSection > 0, "beadCrossSection must be > 0")
  beadCrossSection / 2;

function slowClampDraftSlope(draftAngle=45) =
  assert(is_num(draftAngle) && draftAngle > 0 && draftAngle < 90, "draftAngle must satisfy 0 < draftAngle < 90")
  tan(draftAngle);

function slowClampSeatingRadius(
  beadOuterDiameter,
  beadCrossSection,
  draftAngle=45,
  jointGap=0
) =
  assert(is_num(beadOuterDiameter) && beadOuterDiameter > 0, "beadOuterDiameter must be > 0")
  assert(is_num(beadCrossSection) && beadCrossSection > 0, "beadCrossSection must be > 0")
  assert(is_num(jointGap) && jointGap >= 0, "jointGap must be >= 0")
  let(
    b = slowClampBeadRadius(beadCrossSection),
    centerR = beadOuterDiameter / 2 - b,
    upperCenterZ = b + jointGap / 2,
    slope = slowClampDraftSlope(draftAngle)
  )
  centerR + slope * upperCenterZ + b * sqrt(1 + slope * slope);

function slowClampGrooveInnerRadius(
  z,
  beadOuterDiameter,
  beadCrossSection,
  radialClearance=0.35,
  draftAngle=45,
  jointGap=0,
  grooveFlatWidth=6
) =
  assert(is_num(radialClearance) && radialClearance > 0, "radialClearance must be > 0")
  assert(is_num(grooveFlatWidth) && grooveFlatWidth >= 0, "grooveFlatWidth must be >= 0")
  slowClampSeatingRadius(
    beadOuterDiameter=beadOuterDiameter,
    beadCrossSection=beadCrossSection,
    draftAngle=draftAngle,
    jointGap=jointGap
  ) + radialClearance - max(abs(z), grooveFlatWidth / 2) * slowClampDraftSlope(draftAngle);

function slowClampBandOuterRadius(
  beadOuterDiameter,
  beadCrossSection,
  bandWall=5,
  radialClearance=0.35,
  draftAngle=45,
  jointGap=0,
  grooveFlatWidth=6
) =
  assert(is_num(bandWall) && bandWall > 0, "bandWall must be > 0")
  slowClampGrooveInnerRadius(
    z=0,
    beadOuterDiameter=beadOuterDiameter,
    beadCrossSection=beadCrossSection,
    radialClearance=radialClearance,
    draftAngle=draftAngle,
    jointGap=jointGap,
    grooveFlatWidth=grooveFlatWidth
  ) + bandWall;

function slowClampScrewAxisX(
  beadOuterDiameter,
  beadCrossSection,
  bandWall=5,
  radialClearance=0.35,
  draftAngle=45,
  jointGap=0,
  earProjection=14,
  grooveFlatWidth=6
) =
  slowClampBandOuterRadius(
    beadOuterDiameter=beadOuterDiameter,
    beadCrossSection=beadCrossSection,
    bandWall=bandWall,
    radialClearance=radialClearance,
    draftAngle=draftAngle,
    jointGap=jointGap,
    grooveFlatWidth=grooveFlatWidth
  ) + earProjection / 2;

function slowClampNutPocketDepth(
  nutThickness=4,
  hardwareClearance=0.3
) =
  assert(is_num(nutThickness) && nutThickness > 0, "nutThickness must be > 0")
  assert(is_num(hardwareClearance) && hardwareClearance >= 0, "hardwareClearance must be >= 0")
  nutThickness + hardwareClearance;

function slowClampTotalWidth(bandWidth=14, edgeSupport=3) =
  assert(is_num(bandWidth) && bandWidth > 0, "bandWidth must be > 0")
  assert(is_num(edgeSupport) && edgeSupport >= 0, "edgeSupport must be >= 0")
  bandWidth + 2 * edgeSupport;

function _slowClampCornerRadius(width, height, radius=2) =
  max(0, min(radius, width/2 - 0.001, height/2 - 0.001));

function _slowClampSegmentRadius(a, b) =
  let(
    delta = b - a,
    t = max(0, min(1, -(a * delta) / (delta * delta)))
  )
  norm(a + t * delta);

function _slowClampEarRootProfile(
  outerRadius,
  bandWall,
  splitGap,
  earThickness,
  earProjection,
  earRootChamfer
) =
  assert(is_num(earRootChamfer) && earRootChamfer > 0, "earRootChamfer profile requires a positive chamfer")
  let(
    y = splitGap / 2 + earThickness,
    xMin = outerRadius - bandWall,
    xMax = outerRadius + earProjection,
    cornerR = _slowClampCornerRadius(xMax - xMin, earThickness)
  )
  assert(y < outerRadius, "earRootChamfer requires the ear outer side to intersect the band circle")
  let(
    rootX = sqrt(outerRadius * outerRadius - y * y),
    start = [rootX + earRootChamfer, y],
    sumXY = start.x + start.y
  )
  assert(rootX >= xMin + cornerR,
    "earRootChamfer requires the band junction on the ear's flat outer side; reduce splitGap/earThickness or increase bandWall")
  assert(start.x <= xMax - cornerR,
    "earRootChamfer must start on the ear's flat outer side before its rounded tip")
  assert(y < outerRadius / sqrt(2) && sumXY < sqrt(2) * outerRadius,
    "earRootChamfer exceeds the available 45-degree circle intersection")
  let(
    chord = sqrt(2 * outerRadius * outerRadius - sumXY * sumXY),
    circleEnd = [(sumXY + chord) / 2, (sumXY - chord) / 2],
    overlap = min(0.25, bandWall / 4, earThickness / 4, (circleEnd.x - circleEnd.y) / 4),
    // Extend along the same diagonal into the band, and below the flat ear side.
    bandEnd = circleEnd + [-overlap, overlap],
    earBase = [rootX, y - overlap]
  )
  assert(_slowClampSegmentRadius(earBase, bandEnd) > xMin,
    "earRootChamfer overlap must remain outside the V-groove; reduce earRootChamfer or increase bandWall")
  [start, bandEnd, earBase];

module _slowClampRoundedRect2D(width, height, radius=2) {
  r = _slowClampCornerRadius(width, height, radius);
  if (r > 0)
    offset(r=r) offset(delta=-r)
      square([width, height], center=true);
  else
    square([width, height], center=true);
}

module _slowClampEar2D(
  outerRadius,
  bandWall,
  splitGap,
  earThickness,
  earProjection,
  side,
  earRootChamfer=3
) {
  xMin = outerRadius - bandWall;
  xMax = outerRadius + earProjection;
  yCenter = side * (splitGap / 2 + earThickness / 2);
  translate([(xMin + xMax) / 2, yCenter])
    _slowClampRoundedRect2D(
      width=xMax - xMin,
      height=earThickness,
      radius=2
    );
  if (earRootChamfer > 0)
    scale([1, side])
      polygon(_slowClampEarRootProfile(
        outerRadius, bandWall, splitGap, earThickness, earProjection, earRootChamfer));
}

module _slowClampBody(
  bandWidth,
  beadOuterDiameter,
  beadCrossSection,
  bandWall,
  radialClearance,
  draftAngle,
  jointGap,
  splitGap,
  earThickness,
  earProjection,
  edgeSupport=3,
  earRootChamfer=3,
  grooveFlatWidth=6,
  $fn=128
) {
  bandHalf = bandWidth / 2;
  totalWidth = slowClampTotalWidth(bandWidth, edgeSupport);
  slope = slowClampDraftSlope(draftAngle);
  seatR = slowClampSeatingRadius(
    beadOuterDiameter=beadOuterDiameter,
    beadCrossSection=beadCrossSection,
    draftAngle=draftAngle,
    jointGap=jointGap
  );
  innerLipR = seatR + radialClearance - bandHalf * slope;
  innerFlatR = slowClampGrooveInnerRadius(0, beadOuterDiameter, beadCrossSection,
    radialClearance, draftAngle, jointGap, grooveFlatWidth);
  outerR = innerFlatR + bandWall;

  union() {
    rotate_extrude($fn=$fn)
      polygon(concat([
        [innerLipR, 0],
        [outerR, 0],
        [outerR, totalWidth],
        [innerLipR, totalWidth]
      ],
      edgeSupport > 0 ? [[innerLipR, totalWidth - edgeSupport]] : [],
      grooveFlatWidth > 0 ? [
        [innerFlatR, (totalWidth + grooveFlatWidth) / 2],
        [innerFlatR, (totalWidth - grooveFlatWidth) / 2]
      ] : [[innerFlatR, totalWidth / 2]],
      edgeSupport > 0 ? [[innerLipR, edgeSupport]] : []));

    linear_extrude(height=totalWidth)
      union() {
        _slowClampEar2D(
          outerRadius=outerR,
          bandWall=bandWall,
          splitGap=splitGap,
          earThickness=earThickness,
          earProjection=earProjection,
          side=1,
          earRootChamfer=earRootChamfer
        );
        _slowClampEar2D(
          outerRadius=outerR,
          bandWall=bandWall,
          splitGap=splitGap,
          earThickness=earThickness,
          earProjection=earProjection,
          side=-1,
          earRootChamfer=earRootChamfer
        );
      }
  }
}

module _slowClampCuts(
  bandWidth,
  beadOuterDiameter,
  beadCrossSection,
  bandWall,
  radialClearance,
  draftAngle,
  jointGap,
  splitGap,
  screwDiameter,
  screwClearance,
  nutAcrossFlats,
  nutThickness,
  hardwareClearance,
  earThickness,
  earProjection,
  edgeSupport=3,
  grooveFlatWidth=6,
  $fn=96
) {
  eps = 0.05;
  totalWidth = slowClampTotalWidth(bandWidth, edgeSupport);
  outerR = slowClampBandOuterRadius(
    beadOuterDiameter=beadOuterDiameter,
    beadCrossSection=beadCrossSection,
    bandWall=bandWall,
    radialClearance=radialClearance,
    draftAngle=draftAngle,
    jointGap=jointGap,
    grooveFlatWidth=grooveFlatWidth
  );
  screwX = outerR + earProjection / 2;
  screwHoleD = screwDiameter + screwClearance;
  pocketDepth = slowClampNutPocketDepth(nutThickness=nutThickness, hardwareClearance=hardwareClearance);
  nutAF = nutAcrossFlats + hardwareClearance;
  posOuterY = splitGap / 2 + earThickness;
  pocketYMin = posOuterY - pocketDepth;
  earOuterX = outerR + earProjection;

  translate([0, -splitGap/2, -eps])
    cube([outerR + earProjection + eps, splitGap, totalWidth + 2 * eps]);

  translate([screwX, 0, totalWidth / 2])
    rotate([90, 0, 0])
      cylinder(d=screwHoleD, h=splitGap + 2 * earThickness + 2, center=true, $fn=48);

  translate([screwX, (pocketYMin + posOuterY)/2, totalWidth/2])
    rotate([90, 0, 0])
      cylinder(h=pocketDepth + eps, d=2 * (nutAF / sqrt(3)), center=true, $fn=6);

  translate([screwX, pocketYMin - eps/2, totalWidth/2 - nutAF/2])
    cube([earOuterX - screwX + eps, pocketDepth + eps, nutAF]);
}

module _slowClampValidate(
  beadOuterDiameter,
  beadCrossSection,
  neckOuterDiameter,
  bandWidth,
  bandWall,
  radialClearance,
  draftAngle,
  jointGap,
  splitGap,
  screwDiameter,
  screwClearance,
  nutAcrossFlats,
  nutThickness,
  hardwareClearance,
  earThickness,
  earProjection,
  part,
  edgeSupport=3,
  earRootChamfer=3,
  grooveFlatWidth=6
) {
  assert(is_num(beadOuterDiameter) && beadOuterDiameter > 0, "beadOuterDiameter must be > 0");
  assert(is_num(beadCrossSection) && beadCrossSection > 0, "beadCrossSection must be > 0");
  assert(is_num(neckOuterDiameter) && neckOuterDiameter > 0, "neckOuterDiameter must be > 0");
  assert(is_num(bandWidth) && bandWidth > 0, "bandWidth must be > 0");
  assert(is_num(bandWall) && bandWall > 0, "bandWall must be > 0");
  assert(is_num(radialClearance) && radialClearance > 0, "radialClearance must be > 0");
  assert(is_num(draftAngle) && draftAngle > 0 && draftAngle < 90, "draftAngle must satisfy 0 < draftAngle < 90");
  assert(is_num(jointGap) && jointGap >= 0, "jointGap must be >= 0");
  assert(is_num(splitGap) && splitGap > 0, "splitGap must be > 0");
  assert(is_num(screwDiameter) && screwDiameter > 0, "screwDiameter must be > 0");
  assert(is_num(screwClearance) && screwClearance >= 0, "screwClearance must be >= 0");
  assert(is_num(nutAcrossFlats) && nutAcrossFlats > 0, "nutAcrossFlats must be > 0");
  assert(is_num(nutThickness) && nutThickness > 0, "nutThickness must be > 0");
  assert(is_num(hardwareClearance) && hardwareClearance >= 0, "hardwareClearance must be >= 0");
  assert(is_num(earThickness) && earThickness > 0, "earThickness must be > 0");
  assert(is_num(earProjection) && earProjection > 0, "earProjection must be > 0");
  assert(is_num(edgeSupport) && edgeSupport >= 0, "edgeSupport must be >= 0");
  assert(is_num(earRootChamfer) && earRootChamfer >= 0, "earRootChamfer must be >= 0");
  assert(is_num(grooveFlatWidth) && grooveFlatWidth >= 0, "grooveFlatWidth must be >= 0");
  assert(part == "clamp" || part == "hardware" || part == "all", "part must be one of: clamp, hardware, all");

  slope = slowClampDraftSlope(draftAngle);
  b = slowClampBeadRadius(beadCrossSection);
  seatR = slowClampSeatingRadius(beadOuterDiameter, beadCrossSection, draftAngle, jointGap);
  bandHalf = bandWidth / 2;
  totalWidth = slowClampTotalWidth(bandWidth, edgeSupport);
  contactZ = (b + jointGap / 2) + b * slope / sqrt(1 + slope * slope);
  innerLipR = seatR + radialClearance - bandHalf * slope;
  innerFlatR = slowClampGrooveInnerRadius(0, beadOuterDiameter, beadCrossSection,
    radialClearance, draftAngle, jointGap, grooveFlatWidth);
  outerR = innerFlatR + bandWall;
  nutAF = nutAcrossFlats + hardwareClearance;
  screwHoleR = (screwDiameter + screwClearance) / 2;
  screwX = outerR + earProjection / 2;

  assert(bandHalf > contactZ,
    str("bandWidth/2 must exceed contactZ. bandHalf=", bandHalf, " contactZ=", contactZ));
  assert(grooveFlatWidth / 2 < contactZ,
    "grooveFlatWidth/2 must remain inside contactZ to preserve the bead-contact slopes");
  assert(innerFlatR > beadOuterDiameter / 2 + radialClearance,
    "groove flat must clear the bead outer radius plus radialClearance");
  assert(innerLipR > neckOuterDiameter / 2 + radialClearance,
    str("inner groove lip radius must exceed neckOuterDiameter/2 + radialClearance. innerLipR=", innerLipR));
  assert(innerLipR > 0, "inner groove lip radius must remain positive");
  assert(neckOuterDiameter < beadOuterDiameter, "neckOuterDiameter must be less than beadOuterDiameter");
  assert((earThickness - (nutThickness + hardwareClearance)) > 0,
    str("earThickness must exceed nut pocket depth. remaining ligament=", earThickness - (nutThickness + hardwareClearance)));
  assert(nutAF < totalWidth,
    str("nutAcrossFlats + hardwareClearance must be less than total width. value=", nutAF, " totalWidth=", totalWidth));
  assert((outerR + earProjection) > (outerR - bandWall), "ear extents must produce positive radial width");
  assert(screwX - screwHoleR > outerR,
    "screw hole must stay outside the clamping V-groove wall");
  if (earRootChamfer > 0) {
    rootProfile = _slowClampEarRootProfile(
      outerR, bandWall, splitGap, earThickness, earProjection, earRootChamfer);
    // The unchanged screw cutter extends 1 mm beyond each outer ear face.
    assert(rootProfile[0].x <= screwX - screwHoleR + 1,
      "earRootChamfer must leave the existing screw clearance path unobstructed");
  }
}

module SlowClampHardware(
  beadOuterDiameter=136,
  beadCrossSection=5.58,
  neckOuterDiameter=123,
  bandWidth=14, // Axial width of the tapered bead-contact region only.
  bandWall=5,
  radialClearance=0.35,
  draftAngle=45,
  jointGap=0,
  splitGap=12,
  screwDiameter=5,
  screwClearance=0.5,
  nutAcrossFlats=8,
  nutThickness=4,
  hardwareClearance=0.3,
  earThickness=8,
  earProjection=14,
  help=false,
  edgeSupport=3, // Straight axial support beyond each end of the taper.
  earRootChamfer=3, // Added 45-degree ear-root gussets in plan view; zero disables.
  grooveFlatWidth=6, // Axial flat at the groove bottom; zero restores the pointed profile.
  $fn=64
) {
  _slowClampValidate(
    beadOuterDiameter=beadOuterDiameter,
    beadCrossSection=beadCrossSection,
    neckOuterDiameter=neckOuterDiameter,
    bandWidth=bandWidth,
    bandWall=bandWall,
    radialClearance=radialClearance,
    draftAngle=draftAngle,
    jointGap=jointGap,
    splitGap=splitGap,
    screwDiameter=screwDiameter,
    screwClearance=screwClearance,
    nutAcrossFlats=nutAcrossFlats,
    nutThickness=nutThickness,
    hardwareClearance=hardwareClearance,
    earThickness=earThickness,
    earProjection=earProjection,
    part="hardware",
    edgeSupport=edgeSupport,
    earRootChamfer=earRootChamfer,
    grooveFlatWidth=grooveFlatWidth
  );

  outerR = slowClampBandOuterRadius(
    beadOuterDiameter=beadOuterDiameter,
    beadCrossSection=beadCrossSection,
    bandWall=bandWall,
    radialClearance=radialClearance,
    draftAngle=draftAngle,
    jointGap=jointGap,
    grooveFlatWidth=grooveFlatWidth
  );
  screwX = outerR + earProjection / 2;
  shaftD = screwDiameter;
  nutAF = nutAcrossFlats;
  pocketDepth = slowClampNutPocketDepth(nutThickness=nutThickness, hardwareClearance=hardwareClearance);
  posOuterY = splitGap / 2 + earThickness;
  negOuterY = -posOuterY;
  shaftStart = negOuterY - 1;
  shaftEnd = posOuterY + 1;
  shaftLen = shaftEnd - shaftStart;
  totalWidth = slowClampTotalWidth(bandWidth, edgeSupport);

  color("silver")
  translate([screwX, (shaftStart + shaftEnd)/2, totalWidth/2])
    rotate([90, 0, 0])
      cylinder(d=shaftD, h=shaftLen, center=true, $fn=48);

  // A 10 mm OD M5 washer clears the default ear-root gusset.
  color("gainsboro")
  translate([screwX, negOuterY - 0.5, totalWidth/2])
    rotate([90, 0, 0])
      cylinder(d=max(shaftD * 2.0, 10), h=1, center=true, $fn=48);

  color("gray")
  translate([screwX, negOuterY - 2.75, totalWidth/2])
    rotate([90, 0, 0])
      cylinder(d=max(shaftD * 2.0, 9), h=4.5, center=true, $fn=48);

  color("dimgray")
  translate([screwX, posOuterY - pocketDepth / 2, totalWidth / 2])
    rotate([90, 0, 0])
      cylinder(h=nutThickness, d=2 * (nutAF / sqrt(3)), center=true, $fn=6);

  if (help) {
    echo("SlowClampHardware preview only: washer/head dimensions are simplified; verify with physical hardware.");
    echo("Default M5 washer reference is 10 mm OD; check actual hardware clearance when changing the ear-root chamfer.");
  }
}

module SlowClamp(
  beadOuterDiameter=136,
  beadCrossSection=5.58,
  neckOuterDiameter=123,
  bandWidth=14, // Axial width of the tapered bead-contact region only.
  bandWall=5,
  radialClearance=0.35,
  draftAngle=45,
  jointGap=0,
  splitGap=12,
  screwDiameter=5,
  screwClearance=0.5,
  nutAcrossFlats=8,
  nutThickness=4,
  hardwareClearance=0.3,
  earThickness=8,
  earProjection=14,
  part="clamp",
  help=false,
  edgeSupport=3, // Straight axial support beyond each end of the taper.
  earRootChamfer=3, // Added 45-degree ear-root gussets in plan view; zero disables.
  grooveFlatWidth=6, // Axial flat at the groove bottom; zero restores the pointed profile.
  $fn=128
) {
  _slowClampValidate(
    beadOuterDiameter=beadOuterDiameter,
    beadCrossSection=beadCrossSection,
    neckOuterDiameter=neckOuterDiameter,
    bandWidth=bandWidth,
    bandWall=bandWall,
    radialClearance=radialClearance,
    draftAngle=draftAngle,
    jointGap=jointGap,
    splitGap=splitGap,
    screwDiameter=screwDiameter,
    screwClearance=screwClearance,
    nutAcrossFlats=nutAcrossFlats,
    nutThickness=nutThickness,
    hardwareClearance=hardwareClearance,
    earThickness=earThickness,
    earProjection=earProjection,
    part=part,
    edgeSupport=edgeSupport,
    earRootChamfer=earRootChamfer,
    grooveFlatWidth=grooveFlatWidth
  );

  if (part == "clamp" || part == "all") {
    difference() {
      _slowClampBody(
        bandWidth=bandWidth,
        beadOuterDiameter=beadOuterDiameter,
        beadCrossSection=beadCrossSection,
        bandWall=bandWall,
        radialClearance=radialClearance,
        draftAngle=draftAngle,
        jointGap=jointGap,
        splitGap=splitGap,
        earThickness=earThickness,
        earProjection=earProjection,
        edgeSupport=edgeSupport,
        earRootChamfer=earRootChamfer,
        grooveFlatWidth=grooveFlatWidth,
        $fn=$fn
      );
      _slowClampCuts(
        bandWidth=bandWidth,
        beadOuterDiameter=beadOuterDiameter,
        beadCrossSection=beadCrossSection,
        bandWall=bandWall,
        radialClearance=radialClearance,
        draftAngle=draftAngle,
        jointGap=jointGap,
        splitGap=splitGap,
        screwDiameter=screwDiameter,
        screwClearance=screwClearance,
        nutAcrossFlats=nutAcrossFlats,
        nutThickness=nutThickness,
        hardwareClearance=hardwareClearance,
        earThickness=earThickness,
        earProjection=earProjection,
        edgeSupport=edgeSupport,
        grooveFlatWidth=grooveFlatWidth,
        $fn=max(48, floor($fn/2))
      );
    }
  }

  if (part == "hardware" || part == "all")
    SlowClampHardware(
      beadOuterDiameter=beadOuterDiameter,
      beadCrossSection=beadCrossSection,
      neckOuterDiameter=neckOuterDiameter,
      bandWidth=bandWidth,
      bandWall=bandWall,
      radialClearance=radialClearance,
      draftAngle=draftAngle,
      jointGap=jointGap,
      splitGap=splitGap,
      screwDiameter=screwDiameter,
      screwClearance=screwClearance,
      nutAcrossFlats=nutAcrossFlats,
      nutThickness=nutThickness,
      hardwareClearance=hardwareClearance,
      earThickness=earThickness,
      earProjection=earProjection,
      help=help,
      edgeSupport=edgeSupport,
      earRootChamfer=earRootChamfer,
      grooveFlatWidth=grooveFlatWidth,
      $fn=max(48, floor($fn/2))
    );

  if (help) {
    outerR = slowClampBandOuterRadius(
      beadOuterDiameter=beadOuterDiameter,
      beadCrossSection=beadCrossSection,
      bandWall=bandWall,
      radialClearance=radialClearance,
      draftAngle=draftAngle,
      jointGap=jointGap,
      grooveFlatWidth=grooveFlatWidth
    );
    echo(str("SlowClamp prototype: physical test fit only; not load-rated; no FEA/material safety claims."));
    echo(str("SlowClamp derived values: seatR=", slowClampSeatingRadius(beadOuterDiameter, beadCrossSection, draftAngle, jointGap),
      " outerR=", outerR,
      " outerDiameter=", outerR * 2,
      " grooveFlatWidth=", grooveFlatWidth,
      " taperedWidth=", bandWidth,
      " totalWidth=", slowClampTotalWidth(bandWidth, edgeSupport),
      " screwAxisX=", outerR + earProjection/2,
      " nutPocketDepth=", slowClampNutPocketDepth(nutThickness, hardwareClearance)));
  }
}
