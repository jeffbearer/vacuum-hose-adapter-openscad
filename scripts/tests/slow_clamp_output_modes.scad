include <../../modules/vacuum-hose-adapter.scad>

epsilon = 0.0001;
function approx(a, b, tolerance = epsilon) = abs(a - b) <= tolerance;

nominal5 = 5 * 25.4;
nominal6 = 6 * 25.4;
dims5 = oneidaQuickClampDimensions(nominalDiameter = nominal5, wallThickness = 2.4, fitAdjustment = 0);
dims6FitPlus = oneidaQuickClampDimensions(nominalDiameter = nominal6, wallThickness = 2.4, fitAdjustment = 0.5);
dims5FitMinus = oneidaQuickClampDimensions(nominalDiameter = nominal5, wallThickness = 2.4, fitAdjustment = -0.5);

assert(approx(oneidaSlowClampBeadOuterDiameterFromNeckOuterDiameter(dims5[iOneidaDimensionNeckOuterDiameter]), dims5[iOneidaDimensionBeadOuterDiameter]));
assert(approx(oneidaSlowClampBeadOuterDiameterFromNeckOuterDiameter(dims6FitPlus[iOneidaDimensionNeckOuterDiameter]), dims6FitPlus[iOneidaDimensionBeadOuterDiameter]));
assert(approx(oneidaSlowClampBeadOuterDiameterFromNeckOuterDiameter(dims5FitMinus[iOneidaDimensionNeckOuterDiameter]), dims5FitMinus[iOneidaDimensionBeadOuterDiameter]));

resolvedEnd2 = getConnectorSettings(
  userSettings = OneidaConnectorSettings(
    connector = 2,
    diameter = [0, 6],
    wallThickness = 2.4,
    length = [20,0],
    fitAdjustment = 0.5),
  slipRingSettings = [[0,0], 2.4, 2.4, 0],
  alignmentDepth = 0,
  alignmentUpperWidth = 0,
  alignmentLowerWidth = 0,
  alignmentSideClearance = 0,
  alignmentDepthClearance = 0,
  adapterColor = ["SkyBlue", 1],
  con1Measurement = "outer",
  con1OuterEndDiameter = 100,
  con1WallThickness = 2.4);
assert(approx(resolvedEnd2[iInterfaceOuterDiameter], dims6FitPlus[iOneidaDimensionNeckOuterDiameter]));

resolvedEnd3 = getConnectorSettings(
  userSettings = OneidaConnectorSettings(
    connector = 3,
    diameter = [0, 5],
    wallThickness = 2.4,
    length = [20,0],
    fitAdjustment = -0.5),
  slipRingSettings = [[0,0], 2.4, 2.4, 0],
  alignmentDepth = 0,
  alignmentUpperWidth = 0,
  alignmentLowerWidth = 0,
  alignmentSideClearance = 0,
  alignmentDepthClearance = 0,
  adapterColor = ["Purple", 1],
  con1Measurement = "outer",
  con1OuterEndDiameter = 100,
  con1WallThickness = 2.4);
assert(approx(resolvedEnd3[iInterfaceOuterDiameter], dims5FitMinus[iOneidaDimensionNeckOuterDiameter]));

resolvedEnd1WithExtension = getConnectorSettings(
  userSettings = OneidaConnectorSettings(settings = UserConnectorSettings(
    connector = 1,
    style = "oneida",
    diameter = [0,5],
    wallThickness = 2.4,
    length = [20,0],
    extensionExitDiameter = 160
  ), fitAdjustment = 0),
  slipRingSettings = [[0,0], 2.4, 2.4, 0],
  alignmentDepth = 0,
  alignmentUpperWidth = 0,
  alignmentLowerWidth = 0,
  alignmentSideClearance = 0,
  alignmentDepthClearance = 0,
  adapterColor = ["LightPink", 1],
  con1Measurement = "outer",
  con1OuterEndDiameter = 100,
  con1WallThickness = 2.4);
assert(approx(resolvedEnd1WithExtension[iOuterEndDiameter], dims5[iOneidaDimensionNeckOuterDiameter]));
assert(approx(resolvedEnd1WithExtension[iInnerEndDiameter] + 2 * resolvedEnd1WithExtension[iWallThickness], dims5[iOneidaDimensionNeckOuterDiameter]));
assert(resolvedEnd1WithExtension[iInterfaceOuterDiameter] > resolvedEnd1WithExtension[iOuterEndDiameter] + 40);

resolvedEnd1WithSlipRingAndExtension = getConnectorSettings(
  userSettings = OneidaConnectorSettings(settings = UserConnectorSettings(
    connector = 1,
    style = "oneida",
    diameter = [0,5],
    wallThickness = 2.4,
    length = [20,0],
    extensionExitDiameter = 160,
    extensionSlipRing = "outer"
  ), fitAdjustment = 0),
  slipRingSettings = calculate_slipring_size(slipring = "outer", width = 5),
  alignmentDepth = 0,
  alignmentUpperWidth = 0,
  alignmentLowerWidth = 0,
  alignmentSideClearance = 0,
  alignmentDepthClearance = 0,
  adapterColor = ["LightPink", 1],
  con1Measurement = "outer",
  con1OuterEndDiameter = 100,
  con1WallThickness = 2.4);
assert(approx(resolvedEnd1WithSlipRingAndExtension[iOuterEndDiameter], dims5[iOneidaDimensionNeckOuterDiameter]));
assert(approx(resolvedEnd1WithSlipRingAndExtension[iInnerEndDiameter] + 2 * resolvedEnd1WithSlipRingAndExtension[iWallThickness], dims5[iOneidaDimensionNeckOuterDiameter]));
assert(resolvedEnd1WithSlipRingAndExtension[iInterfaceOuterDiameter] > resolvedEnd1WithSlipRingAndExtension[iOuterEndDiameter] + 40);

translate([-260, 0, 0])
HoseAdapter(
  connector1 = UserConnectorSettings(connector = 1, style = "mag", measurement = "outer", diameter = [100,0], length = [20,0], magnetBorder = 2),
  connector2 = UserConnectorSettings(connector = 2, style = "mag", measurement = "outer", diameter = [100,0], length = [20,0], magnetBorder = 2),
  drawAlignmentRing = "end1",
  outputMode = "adapter");

translate([-120, 0, 0])
HoseAdapter(
  connector1 = UserConnectorSettings(connector = 1, style = "mag", measurement = "outer", diameter = [100,0], length = [20,0], magnetBorder = 2),
  connector2 = UserConnectorSettings(connector = 2, style = "mag", measurement = "outer", diameter = [100,0], length = [20,0], magnetBorder = 2),
  outputMode = "alignment_ring",
  outputEnd = "end2");

translate([20, 0, 0])
HoseAdapter(
  connector1 = OneidaConnectorSettings(connector = 1, diameter = [0,5], wallThickness = 2.4, length = [20,0], fitAdjustment = 0),
  connector2 = UserConnectorSettings(connector = 2, style = "not_a_real_style", diameter = [50,0], length = [20,0]),
  transitionBendPipeDiameter = "custom",
  transitionCustomBendPipeDiameter = 0,
  outputMode = "slowclamp",
  outputEnd = "end1");

translate([160, 0, 0])
HoseAdapter(
  connector1 = UserConnectorSettings(connector = 1, style = "hose", measurement = "outer", diameter = [100,0], length = [20,0]),
  connector2 = OneidaConnectorSettings(connector = 2, diameter = [0,6], wallThickness = 2.4, length = [20,0], fitAdjustment = 0.5),
  connector3 = UserConnectorSettings(connector = 3, style = "not_a_real_style", diameter = [40,0], length = [20,0]),
  transitionBendPipeDiameter = "custom",
  transitionCustomBendPipeDiameter = 0,
  outputMode = "slowclamp",
  outputEnd = "end2");

translate([300, 0, 0])
HoseAdapter(
  connector1 = UserConnectorSettings(connector = 1, style = "hose", measurement = "outer", diameter = [100,0], length = [20,0]),
  connector2 = UserConnectorSettings(connector = 2, style = "not_a_real_style", diameter = [50,0], length = [20,0]),
  connector3 = OneidaConnectorSettings(connector = 3, diameter = [0,5], wallThickness = 2.4, length = [20,0], fitAdjustment = -0.5),
  transitionBendPipeDiameter = "custom",
  transitionCustomBendPipeDiameter = 0,
  outputMode = "slowclamp",
  outputEnd = "end3");

translate([440, 0, 0])
HoseAdapter(
  connector1 = OneidaConnectorSettings(settings = UserConnectorSettings(
    connector = 1,
    style = "oneida",
    diameter = [0,5],
    wallThickness = 2.4,
    length = [20,0],
    extensionExitDiameter = 160
  ), fitAdjustment = 0),
  connector2 = UserConnectorSettings(connector = 2, style = "not_a_real_style", diameter = [50,0], length = [20,0]),
  transitionBendPipeDiameter = "custom",
  transitionCustomBendPipeDiameter = 0,
  outputMode = "slowclamp",
  outputEnd = "end1");
