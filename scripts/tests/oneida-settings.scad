include <../../modules/vacuum-hose-adapter.scad>

for (connector = [1:3])
  for (wall = [2.4, 4]) {
    settings = getConnectorSettings(
      userSettings = UserConnectorSettings(
        connector = connector,
        style = "oneida",
        measurement = "outer",
        diameter = [124.84, 0],
        length = [20, 0],
        wallThickness = wall),
      slipRingSettings = calculate_slipring_size(slipring = "disabled", width = 5),
      alignmentDepth = 2,
      alignmentUpperWidth = 3,
      alignmentLowerWidth = 0.5,
      alignmentSideClearance = 0.25,
      alignmentDepthClearance = 0.75,
      adapterColor = ["", 1],
      con1OuterEndDiameter = 123,
      con1Measurement = "inner",
      con1WallThickness = wall);

    expectedBore = oneidaQuickClampNeckInnerDiameter(124.84, wall);
    assert(settings[iWallThickness] == wall, "Oneida must honor caller wall thickness");
    assert(settings[iInterfaceWallThickness] == wall, "Oneida interface wall must match its connector");
    assert(abs(settings[iInnerEndDiameter] - expectedBore) < 0.001, "Oneida bore must match the standalone fit ring");
    assert(abs(settings[iInterfaceInnerDiameter] - expectedBore) < 0.001, "Oneida transition bore must match its connector");
    assert(abs(settings[iOuterEndDiameter] - 123) < 0.001, "Oneida neck OD must remain fixed when wall thickness changes");
    assert(abs(settings[iInterfaceOuterDiameter] - 123) < 0.001, "Oneida transition OD must match its connector");
    assert(settings[iMeasurement] == "inner" && settings[iTaper] == 0, "Oneida must use its specialized measurement and taper");
    assert(settings[iLength] == 20, "Oneida must preserve caller neck length");
  }

cube(1);
