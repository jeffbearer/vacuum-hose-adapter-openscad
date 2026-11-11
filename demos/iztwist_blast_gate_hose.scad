// Inspired by our favorite South Carolina inventor.
// Experimental example; GPL-compatible licensing permission remains unresolved.
// Reference design: HybridHobbyist (@IceDeck_241588) on Printables.
// https://www.printables.com/model/332587 (CC BY-NC-SA 4.0).
include <../modules/vacuum-hose-adapter.scad>

/* [View] */
Part = "pair"; // [pair: Both adapters, gate: Screw side for blast gate, hose: Hook side for hose, gasket: TPU seal, assembly: Mated preview]
Show_Hardware = true;

/* [Powermatic blast gate - provisional fit] */
// Guessed outside diameter of the printed spigot that slips INSIDE the gate port.
Gate_Spigot_Outer_Diameter = 100; //0.1
// Check the gate's actual bore and available depth before printing.
Gate_Insertion_Length = 25; //0.1

/* [4 inch vacuum hose] */
// Outside diameter of the spigot that fits INSIDE the hose.
Hose_Spigot_Outer_Diameter = 101.6; //0.1
Hose_Clamp_Length = 50; //0.1

/* [Adapter body] */
Wall_Thickness = 3; //0.1
Connector_Length = 32; //0.1
Transition_Length = 25; //0.1
Resolution = 128; // [64:16:192]

/* [Hidden] */
module end_of_customizer_opts() {}

$fn = Resolution;
nominalDiameter = 4 * 25.4;
profile = izTwistProfile(nominalDiameter);
separation = profile[iIzTwistCatchDiameter] + 15;

assert(Part == "pair" || Part == "gate" || Part == "hose" || Part == "gasket" || Part == "assembly",
  "Part must be pair, gate, hose, gasket, or assembly");
assert(is_bool(Show_Hardware), "Show_Hardware must be boolean");
assert(Wall_Thickness > 0 && Transition_Length > 0, "Wall and transition lengths must be positive");
assert(Gate_Insertion_Length > 0 && Hose_Clamp_Length > 0, "Spigot lengths must be positive");
assert(Gate_Spigot_Outer_Diameter > 2 * Wall_Thickness &&
  Hose_Spigot_Outer_Diameter > 2 * Wall_Thickness, "Spigots must retain an open bore");

module GateHoseAdapter(side, spigotDiameter, spigotLength, tint) {
  HoseAdapter(
    connector1 = UserConnectorSettings(
      connector = 1,
      style = str("iztwist_", side),
      diameter = [0, 4],
      length = [Connector_Length, 0],
      wallThickness = Wall_Thickness),
    connector2 = UserConnectorSettings(
      connector = 2,
      style = "hose",
      measurement = "outer",
      diameter = [spigotDiameter, 0],
      length = [spigotLength, 0],
      wallThickness = Wall_Thickness,
      taper = 0),
    transitionLength = Transition_Length,
    end1Color = [tint, 1],
    end2Color = [tint, 1],
    transitionColor = [tint, 1]);
}

module BlastGateAdapter() {
  GateHoseAdapter("screw", Gate_Spigot_Outer_Diameter, Gate_Insertion_Length, "SteelBlue");
}

module VacuumHoseAdapter() {
  GateHoseAdapter("hook", Hose_Spigot_Outer_Diameter, Hose_Clamp_Length, "SeaGreen");
}

if (Part == "gate")
  BlastGateAdapter();
else if (Part == "hose")
  VacuumHoseAdapter();
else if (Part == "gasket")
  IzTwistGasket(nominalDiameter);
else if (Part == "assembly") {
  BlastGateAdapter();
  translate([0, 0, -1.5])
  rotate([180, 0, 0])
    VacuumHoseAdapter();
  color("Orange")
  translate([0, 0, -2])
    IzTwistGasket(nominalDiameter);
  if ($preview && Show_Hardware)
    %color("Silver") IzTwistHardware(nominalDiameter);
} else {
  translate([-separation / 2, 0, 0])
    BlastGateAdapter();
  translate([separation / 2, 0, 0])
    VacuumHoseAdapter();
}
