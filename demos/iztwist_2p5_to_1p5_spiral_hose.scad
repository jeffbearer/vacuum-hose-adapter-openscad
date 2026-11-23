// Inspired by our favorite South Carolina inventor.
// Experimental screw-and-hook interface; GPL-compatible licensing permission remains unresolved.
// Reference design: HybridHobbyist (@IceDeck_241588) on Printables.
// https://www.printables.com/model/332587 (CC BY-NC-SA 4.0).
include <../modules/vacuum-hose-adapter.scad>

/* [Part] */
Support_Part = "adapter"; // [adapter,iztwist_hook_only,hose_only]

/* [IzTwist Side (fixed 2.5in female hook receiver)] */
IzTwist_Nominal_Size_In = 2.5; // [2.5]
IzTwist_Length = 32;
Wall_Thickness = 3;

/* [Threaded Hose Sleeve] */
Hose_Threaded_Length = 20;
Hose_Flat_Inside_Diameter = 40.4;
Thread_Base_Width = 2.5;
Thread_Ridge_Height = 2.5;
Thread_Pitch = 5;
Insertion_Handedness = "left_hand_counterclockwise_from_iztwist"; // [right_hand_clockwise_from_iztwist,left_hand_counterclockwise_from_iztwist]

/* [Transition] */
Transition_Length = 25;

Resolution = 128;
$fn = Resolution;

/* [Hidden] */
module end_of_customizer_opts() {}

nominalDiameter = IzTwist_Nominal_Size_In * 25.4;
threadToothAngle = atan(Thread_Base_Width / (2 * Thread_Ridge_Height));
// InternalHoseThread applies a 1.01 bore factor even with zero tolerance.
helperDiameter = Hose_Flat_Inside_Diameter / 1.01;
helperWallThickness = Wall_Thickness + (Hose_Flat_Inside_Diameter - helperDiameter) / 2;

assert(Thread_Pitch > 0 && Thread_Base_Width > 0 && Thread_Base_Width < Thread_Pitch,
  "Thread base width must be positive and smaller than pitch");
assert(Thread_Ridge_Height > 0 && Hose_Threaded_Length > 0 && Wall_Thickness > 0,
  "Thread height, sleeve length, and wall thickness must be positive");
assert(Hose_Flat_Inside_Diameter > 2 * Thread_Ridge_Height,
  "Thread must retain an open bore");
assert(Insertion_Handedness == "right_hand_clockwise_from_iztwist"
  || Insertion_Handedness == "left_hand_counterclockwise_from_iztwist",
  "Unsupported thread handedness");
assert(Support_Part == "adapter" || Support_Part == "iztwist_hook_only"
  || Support_Part == "hose_only", "Unsupported part");

module HoseSleeve() {
  InternalHoseThread(
    diameter = helperDiameter,
    wallThickness = helperWallThickness,
    height = Hose_Threaded_Length,
    tolerance = 0,
    pitch = Thread_Pitch,
    tooth_angle = threadToothAngle,
    // This helper uses tooth_height as the axial width of the inward tooth.
    tooth_height = Thread_Base_Width,
    reverse_thread = Insertion_Handedness == "left_hand_counterclockwise_from_iztwist");
}

if (Support_Part == "iztwist_hook_only")
  IzTwistConnector(
    nominalDiameter = nominalDiameter,
    side = "hook",
    length = IzTwist_Length,
    wallThickness = Wall_Thickness
  );
else if (Support_Part == "hose_only")
  HoseSleeve();
else {
  HoseAdapter(
    connector1 = UserConnectorSettings(
      connector = 1,
      style = "iztwist_hook",
      diameter = [0, IzTwist_Nominal_Size_In],
      length = [IzTwist_Length, 0],
      wallThickness = Wall_Thickness
    ),
    connector2 = UserConnectorSettings(
      connector = 2,
      style = "hose",
      measurement = "inner",
      diameter = Hose_Flat_Inside_Diameter,
      length = 0,
      wallThickness = Wall_Thickness,
      taper = 0,
      barbsCount = 0
    ),
    transitionLength = Transition_Length
  );
  translate([0, 0, IzTwist_Length + Transition_Length])
    HoseSleeve();
}
