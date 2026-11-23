include <../../modules/vacuum-hose-adapter.scad>

styles = ["iztwist_screw", "iztwist_hook"];
nominals = [2.5, 4, 6];
outputEnds = ["end1", "end2", "end3"];

function endNumber(outputEnd) =
  outputEnd == "end1" ? 1
  : outputEnd == "end2" ? 2
  : 3;

function testConnector(connectorNumber, outputEnd, style, nominalInch) =
  connectorNumber == endNumber(outputEnd)
    ? UserConnectorSettings(
      connector = connectorNumber,
      style = style,
      diameter = [0, nominalInch],
      wallThickness = 3,
      length = [1, 0]
    )
    : undef;

for (styleIndex = [0:len(styles)-1])
  for (nominalIndex = [0:len(nominals)-1])
    for (endIndex = [0:len(outputEnds)-1]) {
      x = styleIndex * 280 + nominalIndex * 90;
      y = endIndex * 130;
      translate([x, y, 0])
      HoseAdapter(
        connector1 = testConnector(1, outputEnds[endIndex], styles[styleIndex], nominals[nominalIndex]),
        connector2 = testConnector(2, outputEnds[endIndex], styles[styleIndex], nominals[nominalIndex]),
        connector3 = testConnector(3, outputEnds[endIndex], styles[styleIndex], nominals[nominalIndex]),
        transitionBendPipeDiameter = "custom",
        transitionCustomBendPipeDiameter = 0,
        outputMode = "iztwist_gasket",
        outputEnd = outputEnds[endIndex]
      );
    }
