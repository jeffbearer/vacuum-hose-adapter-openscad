// Inspired by our favorite South Carolina inventor.
// Experimental prototype; GPL-compatible licensing permission remains unresolved.
// Reference design: HybridHobbyist (@IceDeck_241588) on Printables.
// https://www.printables.com/model/332587 (CC BY-NC-SA 4.0).
include <../modules/vacuum-hose-adapter.scad>

/* [IzTwist Demo Part] */
Support_Part = "pair"; // [screw,hook,gasket,pair,fit-pair,assembly,adapter]
UserNominal_Size = 2.5; // [2.5,4,6]
Adapter_Connector_Style = "hook"; // [hook,screw]

/* [Adapter Hose End] */
Hose_Diameter = [0,2.5];
Hose_Length = 35;
Transition_Length = 30;

/* [Connector Settings] */
Wall_Thickness = 3;
Connector_Length = 32;

/* [Assembly Preview] */
Hook_Position = "locked"; // [locked,entry]
Lock_Rotation = 0;
Entry_Rotation = 30;
Show_Hardware = "preview only"; // [disable,enable,preview only]

$fn = 180;

/* [Hidden] */
module end_of_customizer_opts() {}

nominalDiameter = UserNominal_Size * 25.4;
profile = izTwistProfile(nominalDiameter = nominalDiameter);
catchOuterDiameter = profile[iIzTwistCatchDiameter];
connectorLength = Connector_Length;
fitLength = max(
  izTwistMinimumLength(nominalDiameter, "screw", Wall_Thickness),
  izTwistMinimumLength(nominalDiameter, "hook", Wall_Thickness)
);
hookRotation = Hook_Position == "entry" ? Entry_Rotation : Lock_Rotation;

module PrintedConnector(side = "screw", partLength = connectorLength) {
  translate([0, 0, partLength])
    rotate([180, 0, 0])
      IzTwistConnector(
        nominalDiameter = nominalDiameter,
        side = side,
        length = partLength,
        wallThickness = Wall_Thickness
      );
}

// Face-at-z0 carrier orientation for assembly previews.
module FaceOrientedCarrier() {
  translate([0, 0, connectorLength])
    rotate([180, 0, 0])
      IzTwistConnector(
        nominalDiameter = nominalDiameter,
        side = "screw",
        length = connectorLength,
        wallThickness = Wall_Thickness
      );
}

// Hook face at z=-1.5 for compressed gasket preview.
module FaceOrientedHook(rotationZ = 0) {
  rotate([0, 0, rotationZ])
    translate([0, 0, -1.5 - connectorLength])
      IzTwistConnector(
        nominalDiameter = nominalDiameter,
        side = "hook",
        length = connectorLength,
        wallThickness = Wall_Thickness
      );
}

module AssemblyPreview() {
  FaceOrientedCarrier();
  translate([0, 0, -2]) color("Orange", 0.85) IzTwistGasket(nominalDiameter = nominalDiameter);
  FaceOrientedHook(rotationZ = hookRotation);

  if (renderModeEnabled(Show_Hardware)) {
    color("Silver", 0.6)
      if ($preview || Show_Hardware == "enable")
        %IzTwistHardware(nominalDiameter = nominalDiameter);
  }
}

if (Support_Part == "screw")
  PrintedConnector(side = "screw");
else if (Support_Part == "hook")
  PrintedConnector(side = "hook");
else if (Support_Part == "gasket")
  IzTwistGasket(nominalDiameter = nominalDiameter);
else if (Support_Part == "pair") {
  separation = catchOuterDiameter + 10;
  translate([-separation / 2, 0, 0]) PrintedConnector(side = "screw");
  translate([separation / 2, 0, 0]) PrintedConnector(side = "hook");
}
else if (Support_Part == "fit-pair") {
  separation = catchOuterDiameter + 10;
  translate([-separation / 2, 0, 0]) PrintedConnector(side = "screw", partLength = fitLength);
  translate([separation / 2, 0, 0]) PrintedConnector(side = "hook", partLength = fitLength);
}
else if (Support_Part == "assembly")
  AssemblyPreview();
else if (Support_Part == "adapter")
  HoseAdapter(
    connector1 = UserConnectorSettings(
      connector = 1,
      style = str("iztwist_", Adapter_Connector_Style),
      diameter = [0, UserNominal_Size],
      length = [connectorLength, 0],
      wallThickness = Wall_Thickness
    ),
    connector2 = UserConnectorSettings(
      connector = 2,
      style = "hose",
      measurement = "outer",
      diameter = Hose_Diameter,
      length = [Hose_Length, 0],
      wallThickness = Wall_Thickness
    ),
    transitionLength = Transition_Length
  );
else
  assert(false, str("Unsupported Support_Part: ", Support_Part));
