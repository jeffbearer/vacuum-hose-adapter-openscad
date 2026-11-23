include <../../modules/vacuum-hose-adapter.scad>

translate([-180, 0, 0])
HoseAdapter(
  connector1 = UserConnectorSettings(connector = 1, style = "mag", measurement = "outer", diameter = [50, 0], wallThickness = 2, length = [15, 0], magnetCount = 8, magnetDiameter = 10.5, magnetThickness = 2.5, magnetBorder = 2, magnetFlangeThickness = 6),
  connector2 = UserConnectorSettings(connector = 2, style = "hose", measurement = "outer", diameter = [40, 0], wallThickness = 2, length = [20, 0]),
  transitionLength = 10,
  drawAlignmentRing = "end1",
  outputMode = "adapter"
);

translate([0, 0, 0])
HoseAdapter(
  connector1 = UserConnectorSettings(connector = 1, style = "mag", measurement = "outer", diameter = [50, 0], wallThickness = 2, length = [15, 0], magnetCount = 8, magnetDiameter = 10.5, magnetThickness = 2.5, magnetBorder = 2, magnetFlangeThickness = 6),
  connector2 = UserConnectorSettings(connector = 2, style = "mag", measurement = "outer", diameter = [50, 0], wallThickness = 2, length = [15, 0], magnetCount = 8, magnetDiameter = 10.5, magnetThickness = 2.5, magnetBorder = 2, magnetFlangeThickness = 6),
  outputMode = "alignment_ring",
  outputEnd = "end2"
);

translate([180, 0, 0])
HoseAdapter(
  connector1 = UserConnectorSettings(connector = 1, style = "hose", measurement = "outer", diameter = [50, 0], wallThickness = 2, length = [30, 0]),
  connector2 = UserConnectorSettings(connector = 2, style = "hose", measurement = "outer", diameter = [40, 0], wallThickness = 2, length = [30, 0]),
  outputMode = "adapter"
);
