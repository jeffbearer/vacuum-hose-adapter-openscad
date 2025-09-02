// Oneida Quick Clamp Connector Module
// Uses profile-based rotate_extrude for seamless geometry
include <constants.scad>

/* [Hidden] */
oneidaVersion = "1.0";
oneidaMinLength = 1;        // Minimal length to eliminate gaps while preserving geometry
oneidaMeasurement = "inner";
oneidaWallThickness = 1.8;

oneidaSettings = ["oneida", [
  [iSettingsLength, oneidaMinLength],
  [iSettingsMeasurement, oneidaMeasurement],
  [iSettingsWallThickness, oneidaWallThickness],
  [iSettingsTaper, 0],
  [iSettingsVersion, oneidaVersion]
]];

module OneidaQuickClampConnector(innerEndDiameter, length = 25, wallThickness = 1.8, compensate3DPrint = true, help = false, $fn = 128) {
    // Oneida Quick Clamp specifications
    beadDiameter = 6.7;
    clearanceDistance = 6.5;
    beadWidth = 3.5;
    // Use parameter instead of overwriting it
    
    // Calculations
    beadRadius = beadDiameter / 2;  // 3.35mm
    beadInnerRadius = innerEndDiameter / 2;
    beadCenterRadius = beadInnerRadius + beadRadius;
    beadOuterRadius = beadInnerRadius + beadDiameter;
    outerWallRadius = beadOuterRadius - clearanceDistance;
    innerWallRadius = outerWallRadius - wallThickness;
    
    // Position bead at top
    beadCenterZ = length - beadWidth/2;
    
    // Calculate the actual wall height - from bottom to bottom of bead
    wallHeight = beadCenterZ - beadRadius;  // Stop where bead starts
    
    // Calculate where wall should be positioned 
    wallTopZ = wallHeight;  // Wall ends where bead begins
    wallBottomZ = 0;        // Wall starts at bottom
    
    // Calculate transition polygon points
    // Start at top left corner of rectangle (where wall ends)
    point1_x = innerWallRadius;
    point1_y = wallHeight;  // Top of wall, not bead center
    
    // Calculate tangent to bead circle from point1
    // Vector from point1 to bead center
    dx = beadCenterRadius - point1_x;
    dy = beadCenterZ - point1_y;  // This will be 0 since they're at same Y
    distToCenter = sqrt(dx*dx + dy*dy);
    
    // For tangent line going +x +y direction to TOP LEFT quadrant of circle
    tangentAngle = asin(beadRadius / distToCenter);
    centerAngle = atan2(dy, dx);
    
    // TOP LEFT quadrant - SUBTRACT the tangent angle and adjust to left side
    tangentPointAngle = centerAngle - tangentAngle + 180;  
    point2_x = beadCenterRadius + beadRadius * cos(tangentPointAngle);
    point2_y = beadCenterZ + beadRadius * sin(tangentPointAngle);
    
    // Point 3: Bottom of bead circle (coincident with circle)
    point3_x = beadCenterRadius;  // At circle center X
    point3_y = beadCenterZ - beadRadius;  // At bottom of circle
    
    // Point 4: straight left to same X as starting point
    point4_x = point1_x;
    point4_y = point3_y;
    
    // Create the 3D connector using rotate_extrude
    rotate_extrude() {
        // Rotate profile 180 degrees to fix inversion
        rotate([0, 0, 180]) {
            // Main bead circle with printing flat
            difference() {
                translate([beadCenterRadius, beadCenterZ])
                circle(r = beadRadius);
                
                // Printing flat - 1.2mm wide across TOP (+Y side) of circle
                translate([0, beadCenterZ + beadRadius - 1.2])
                square([beadCenterRadius + beadRadius + 1, 1.2]);
            }
            
            // Wall rectangle - only extends to where bead starts
            translate([innerWallRadius, 0])
            square([wallThickness, wallHeight]);
            
            // Seamless transition polygon with flat incorporated
            difference() {
                polygon([
                    [point1_x, point1_y],  // Top left corner of rectangle
                    [point2_x, point2_y],  // Tangent point to bead circle
                    [point3_x, point3_y],  // Bottom of bead circle
                    [point4_x, point4_y]   // Back to same X as start
                ]);
                
                // Remove the printing flat from transition polygon too
                translate([0, beadCenterZ + beadRadius - 1.2])
                square([beadCenterRadius + beadRadius + 1, 1.2]);
            }
        } // End of rotate([0, 0, 180])
    }
}

// Test with 7-inch inner diameter
if (false) {  // Set to true to test
    OneidaQuickClampConnector(innerEndDiameter = 177.8, length = 25);
}
