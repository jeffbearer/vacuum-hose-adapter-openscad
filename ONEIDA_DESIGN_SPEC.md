# Oneida Quick Clamp Connector Design Specification

## Overview
The Oneida Quick Clamp connector is designed to interface with Oneida's proprietary quick-connect ducting system. The connector must match the exact geometry requirements for proper sealing and mechanical connection.

## Critical Design Requirements

### 1. Bead Geometry (Primary Constraint)
- **Bead Diameter**: 6.7mm (fixed, non-negotiable)
- **Bead Shape**: Circular but with a flat on the bottom that is roughly 1.2mm wide for 3d printing bed adhesion. On the top there is a transition curve to connection to the adapter. There should be a smooth angle from the inside edge of the bead to the inside diameter of the pipe.   No sharp edges or overhangs.
- Override Capability: Allow user to specify different bead dimensions if needed, allow user to disable 3d printing flat.
- **Bead Position**: Inner edge of bead must be tangent to the specified inner diameter


### 2. Clearance Constraint (Secondary Constraint)
- **Clearance Distance**: 6.5mm minimum from outer edge of bead to outer wall
- **Purpose**: Ensures proper fit within Oneida clamp mechanism
- **Critical**: This clearance must never be violated

### 3. Wall Thickness Requirements
- **Default Thickness**: 1.8mm (system default)
- **Override Capability**: Allow user to specify different thickness 
- **Consistency**: Wall thickness must be maintained throughout the connector
- This may make the inside diameter of the main body smaller than the specified inner diameter,  this is ok so that the clearance constraint and wall thickness is maintained.  

### 4. Dimensional Chain (Constraint Resolution Order)

#### Step 1: Establish Bead Geometry
```
beadRadius = 6.7mm / 2 = 3.35mm (fixed)

```

#### Step 2: Position Bead Relative to Inner Diameter
```
beadCenterRadius = (innerEndDiameter / 2) + beadRadius
```
This ensures the inner edge of the bead is tangent to the specified inner diameter.

#### Step 3: Calculate Required Outer Wall Position
```
beadOuterRadius = beadCenterRadius + beadRadius
outerWallRadius = beadOuterRadius - 6.5mm (clearance constraint)
```

#### Step 4: Determine Compensated Inner Diameter
```
compensatedInnerRadius = outerWallRadius - wallThickness
compensatedInnerDiameter = compensatedInnerRadius * 2
```

### 5. Geometry Construction

#### Profile-Based Implementation
**CRITICAL LESSON**: Use a unified 2D profile with rotate_extrude for optimal geometry. The profile should contain:
- Bead circle with 3D printing flat
- Wall rectangle that stops at bottom of bead (no overlap)
- Seamless transition polygon connecting wall to bead

#### Wall Rectangle Calculation
```
wallHeight = beadCenterZ - beadRadius  // Stop where bead starts
```
The wall rectangle extends from Z=0 to wallHeight, ensuring no overlap with bead geometry.

#### Main Pipe Body
- Positioned by HoseAdapter library at translate([0, 0, con[iLength]+con[iStopLength]])
- connector1Length controls spacing between transition walls and connector
- Use minimal connector1Length (1-11mm) for seamless connection

#### Bead Construction
- Positioned at Z = length - (beadWidth/2) (centers bead at pipe end)
- Created using rotate_extrude of circular profile
- Circle center at [beadCenterRadius, beadCenterZ] in profile view
- Includes 1.2mm flat for 3D printing (removable via compensate3DPrint parameter)

#### Transition Geometry (Critical for Printability)
Uses mathematically calculated tangent points for smooth transitions:
```
// Calculate tangent from wall corner to bead circle
tangentAngle = asin(beadRadius / distToCenter)
tangentPointAngle = centerAngle - tangentAngle + 180
```

### 6. Profile Orientation and Library Integration

#### 180-Degree Rotation Fix
**CRITICAL LESSON**: The profile must be rotated 180 degrees before rotate_extrude to correct orientation:
```
rotate([0, 0, 180]) {
    // Profile geometry here
}
```
This ensures beads face the correct direction when used in library system.

#### Library Positioning System
The HoseAdapter library positions connectors using:
```
translate([0, 0, con[iLength]+con[iStopLength]])
```
Where con[iLength] is the connector1Length parameter, creating intentional spacing.

#### tessellation Quality
Use high-resolution settings for smooth STL output:
```
$fs = 0.1;  // Fine fragments
$fa = 1;    // Small angle steps
$fn = 128;  // High resolution for rotate_extrude
```

### 7. Mathematical Precision

#### Seamless Transition Polygon
The transition polygon uses four precisely calculated points:
```
point1: [innerWallRadius, wallHeight]          // Top of wall
point2: [tangentPointX, tangentPointY]         // Tangent to bead  
point3: [beadCenterRadius, beadBottom]         // Bottom of bead
point4: [innerWallRadius, beadBottom]          // Back to wall level
```

#### Wall Height Calculation
**CRITICAL**: Wall rectangle height must account for bead positioning:
```
wallHeight = beadCenterZ - beadRadius
```
This prevents overlap between wall rectangle and bead circle.

### 8. Implementation Architecture

#### Profile-Based Design Pattern
Use unified 2D profile with rotate_extrude containing:
1. **Bead circle** - Main sealing feature
2. **Wall rectangle** - Structural support (height = wallHeight)
3. **Transition polygon** - Smooth connection between wall and bead
4. **3D printing flat** - Removable via difference() operation

#### Library Integration Points
- oneidaMinLength: Controls default connector length in library
- 180-degree rotation: Corrects profile orientation for library system
- High tessellation: Ensures smooth curves in final STL

#### File Organization
```
modules/connector_oneida.scad - Main connector implementation
oneida_7to6_example.scad - Working example of 7" to 6" adapter
ONEIDA_DESIGN_SPEC.md - This specification document
```

### 8. Validation Criteria

#### Dimensional Validation
- Bead diameter exactly 6.7mm
- Clearance exactly 6.5mm from bead outer edge to wall
- Wall thickness consistent throughout

#### Geometric Validation
- No self-intersections
- Smooth transitions
- Proper polygon closure

#### Functional Validation
- Bead positioned for proper sealing
- Clearance allows clamp mechanism operation
- Inner diameter matches specification

## Implementation Notes

### Integration with HoseAdapter System
**CRITICAL LESSON**: The OneidaQuickClampConnector should **NOT** create the main pipe body. The HoseAdapter system handles all main pipe geometry, and the Oneida connector only creates the bead at the specified position. This prevents overlapping geometry (the "blue cylinder" problem).

```
// Only create the bead - HoseAdapter system handles main pipe body
translate([0, 0, length - beadWidth/2])
OneidaBead(...);
```

### Bead Positioning Strategy  
**CRITICAL LESSON**: Position the bead at the connector terminus using `translate([0, 0, length - beadWidth/2])` to center the bead at the end of the connector length. This ensures the bead is exactly where it needs to be for the Oneida clamp mechanism.

### Debugging Features
- Echo statements for all critical dimensions
- Visual indicators for partial rotation during development
- Coordinate verification for polygon points

### Modularity
- Separate bead module for reusability
- Parameterized design for different sizes
- Override capability for special cases
- Use other connector modules to inform how the Oneida connector should be designed
- use and mimic established patterns in existing connector libraries as much as possible.


### Testing Protocol
1. Verify constraint resolution mathematics
2. Check polygon geometry for printability
3. Validate clearance requirements
4. Test with actual Oneida clamp hardware

## Common Pitfalls to Avoid

1. **Don't modify bead diameter** - It's fixed at 6.7mm
2. **Don't violate clearance constraint** - 6.5mm is minimum
3. **Don't create overhangs** - Transition must be printable
4. **Don't ignore wall thickness consistency** - Maintain throughout
5. **DON'T create main pipe in connector** - Let HoseAdapter system handle it
6. **DON'T slope transition polygon outward** - Must slope inward from bead to wall
7. **DON'T over-iterate working geometry** - Preserve stable, tested implementations

## Success Criteria

The connector is successful when:

- Oneida clamp fits properly with correct clearance
- Bead seals against mating connector
- Part prints without supports
- Wall thickness is consistent
- No geometric violations or self-intersections
- No overlapping geometry between connector and main pipe
- Smooth inward transition from bead to inner wall

## Development Lessons Learned

### Constraint Resolution Works
The mathematical constraint resolution approach (Steps 1-4) successfully eliminates geometry conflicts and ensures all requirements are met simultaneously.

### HoseAdapter Integration is Critical  
Separating concerns between the HoseAdapter system (main pipe) and connector (specialized termination) prevents overlapping geometry and simplifies debugging.

### Transition Geometry Must Slope Inward
The transition polygon **must** slope from the wider bead radius inward to the narrower inner wall radius. Outward slopes create overhangs and printing problems.

### Stability Over Iteration

Once working geometry is achieved, resist the urge to "improve" it further. Stable, tested geometry is more valuable than theoretical optimizations.