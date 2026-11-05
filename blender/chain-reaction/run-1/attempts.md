# Chain reaction — attempts

Angles are measured from world vertical using evaluated world quaternions. A fall is the first crossing of 45 degrees. All 240 frames of every attempt are retained under data/sim/. Causes describe the numerical diagnosis; geometry/contact explanations are informed by the build and preview sheets.

## Attempt 1
Initial continuous gate chute intersected the broad final domino; reverse cascade began at domino 18 on frame 2 and ejected ball.
Next change / outcome: Split chute and rails around gate.
Fall frames (tiles 1–18): [25, 24, 23, 22, 20, 18, 16, 14, 11, 10, 8, 7, 5, 3, 3, 3, 2, 2]
Ball final position: [-134.392578125, -98.9303207397461, -363.60272216796875]; last-second displacement: 73.222277606 m.

## Attempt 2
Chain stopped at 10; domino 16 was disturbed early by the adjacent release lane. Ball remained at gate.
Next change / outcome: Increase traction; separate release lane; lighten balls.
Fall frames (tiles 1–18): [48, 48, 48, 49, 52, 55, 58, 63, 69, 80, None, None, None, None, None, 18, None, None]
Ball final position: [6.20545768737793, 2.6269590854644775, 0.8736859560012817]; last-second displacement: 0.000035032 m.

## Attempt 3
Chain reached the final gate but its base jammed against the downstream ramp; dominoes 15–18 never reached 45°.
Next change / outcome: Replace broad tile with a T-shaped gate that clears the ramp below.
Fall frames (tiles 1–18): [91, 91, 95, 99, 104, 108, 111, 115, 119, 123, 126, 130, 134, 137, None, None, None, None]
Ball final position: [5.954806804656982, 2.8569588661193848, 0.8946617841720581]; last-second displacement: 0.000036388 m.

## Attempt 4
All tiles crossed 45°, but first two tied; second ball lodged in the split-ramp gap.
Next change / outcome: Continuous floor under T-gate; higher launch endpoint to strike first tile above its center.
Fall frames (tiles 1–18): [76, 76, 77, 82, 86, 89, 93, 97, 101, 105, 108, 112, 116, 120, 123, 126, 127, 128]
Ball final position: [6.038075923919678, 3.1774792671203613, 0.7607962489128113]; last-second displacement: 0.000039147 m.

## Attempt 5
All tiles fell in strict frame order; ball stopped against fallen gate arm near lane coordinate 1.10m.
Next change / outcome: Thin gate arm.
Fall frames (tiles 1–18): [63, 66, 70, 74, 78, 82, 86, 90, 94, 97, 101, 105, 108, 112, 116, 118, 119, 120]
Ball final position: [6.89931583404541, 3.760709524154663, 0.5509933829307556]; last-second displacement: 0.000689080 m.

## Attempt 6
Ball still obstructed by gate arm; moving 0.0416m in last second, outside cup.
Next change / outcome: Thin arm in both dimensions and reduce its friction.
Fall frames (tiles 1–18): [63, 66, 70, 74, 78, 82, 86, 90, 94, 97, 101, 105, 108, 112, 115, 118, 119, 120]
Ball final position: [6.971068859100342, 3.8092734813690186, 0.5278893113136292]; last-second displacement: 0.041572176 m.

## Attempt 7
Thin gate still obstructed ball outside cup.
Next change / outcome: Redesign as transverse retaining lane so final tile falls sideways out of lane.
Fall frames (tiles 1–18): [63, 66, 70, 74, 78, 82, 86, 90, 93, 97, 101, 105, 108, 112, 115, 117, 118, 120]
Ball final position: [7.203522682189941, 3.7021164894104004, 0.49257102608680725]; last-second displacement: 0.000088688 m.

## Attempt 8
Elevated transverse lane obstructed penultimate tile; cascade stopped at domino 12.
Next change / outcome: Lower lane and rails, narrow gate and gap, lower cup rim.
Fall frames (tiles 1–18): [63, 66, 70, 74, 78, 82, 86, 90, 94, 97, 101, 105, None, None, None, None, None, None]
Ball final position: [6.932371616363525, 1.7621948719024658, 1.1700338125228882]; last-second displacement: 0.000834457 m.

## Attempt 9
All tiles fell, but ball was deflected sideways by release and left plinth; dominoes 16/17 tied.
Next change / outcome: Place a recessed cup along measured trajectory and slightly increase final approach spacing.
Fall frames (tiles 1–18): [63, 66, 70, 74, 78, 82, 86, 90, 93, 97, 101, 105, 108, 112, 116, 118, 118, 121]
Ball final position: [10.36607551574707, 4.046925067901611, -4.704864978790283]; last-second displacement: 4.950965926 m.

## Attempt 10
Cascade completed in order; released ball stopped short/lateral to small cup.
Next change / outcome: Widen and move receiving cup closer to cover measured trajectory variation.
Fall frames (tiles 1–18): [62, 65, 69, 73, 77, 81, 85, 89, 92, 96, 100, 103, 107, 110, 114, 117, 118, 121]
Ball final position: [7.375326633453369, 1.8270617723464966, 0.20000000298023224]; last-second displacement: 0.070568504 m.

## Attempt 11
Ball captured, but still rolling 0.194m during last second; 16/17 crossed within same sampled frame, interpolated in order.
Next change / outcome: Increase damping and final approach spacing.
Fall frames (tiles 1–18): [62, 65, 69, 73, 77, 81, 85, 89, 92, 96, 99, 103, 106, 110, 114, 118, 118, 121]
Ball final position: [8.599023818969727, 2.1720542907714844, -0.18999998271465302]; last-second displacement: 0.194131293 m.

## Attempt 12
Final gate fell prematurely backwards (frame 36), propagating a reverse cascade.
Next change / outcome: Add stabilizing hinge.
Fall frames (tiles 1–18): [62, 65, 69, None, None, None, None, None, None, None, None, 69, 64, 59, 55, 51, 42, 36]
Ball final position: [6.821585178375244, 2.178755760192871, 0.5732075572013855]; last-second displacement: 0.000108317 m.

## Attempt 13
Same reverse failure as attempt 12; the one-object hinge did not constrain the gate effectively.
Next change / outcome: Force cache invalidation, inspect constraint and increase substeps.
Fall frames (tiles 1–18): [62, 65, 69, None, None, None, None, None, None, None, None, 69, 64, 59, 55, 51, 42, 36]
Ball final position: [6.821585178375244, 2.178755760192871, 0.5732075572013855]; last-second displacement: 0.000108317 m.

## Attempt 14
Reverse cascade confirmed after explicit cache reset; final tile fell on frame 37.
Next change / outcome: Add explicit passive hinge anchor and one-way limit.
Fall frames (tiles 1–18): [63, 65, None, None, None, None, None, None, None, None, None, 67, 64, 60, 56, 51, 43, 37]
Ball final position: [6.821656703948975, 2.178804397583008, 0.5732075572013855]; last-second displacement: 0.000091520 m.

## Attempt 15
Ball captured and nearly stationary, but gate constrained in wrong direction; cascade jammed at 14.
Next change / outcome: Reverse hinge angular limit sign.
Fall frames (tiles 1–18): [63, 66, 70, 74, 77, 81, 85, 88, 93, 97, 100, 104, 107, 110, None, None, None, None]
Ball final position: [7.559038162231445, 2.5607526302337646, -0.18999998271465302]; last-second displacement: 0.002166085 m.

## Attempt 16
Hinge/anchor produced an early reverse disturbance and final gate never fell.
Next change / outcome: Remove hinge assembly; restore free-gate geometry from attempt 11 and moderate damping.
Fall frames (tiles 1–18): [118, 118, 116, 53, 40, 36, 32, 28, 23, 19, 16, 16, 15, 15, 15, 15, 15, None]
Ball final position: [8.00467586517334, 2.4969754219055176, -0.18999998271465302]; last-second displacement: 0.016791732 m.

## Attempt 17
All tiles crossed 45° in interpolated order; ball captured, but last-second displacement 0.0254m and not sufficiently settled.
Next change / outcome: Increase damping from 0.4 to 0.6; retain geometry.
Fall frames (tiles 1–18): [62, 65, 69, 73, 77, 81, 85, 89, 92, 96, 100, 103, 107, 110, 114, 117, 117, 121]
Ball final position: [8.438668251037598, 2.891479969024658, -0.18999998271465302]; last-second displacement: 0.025364438 m.

## Attempt 18
SUCCESS: every tile crosses 45° on a strictly later integer frame; ball fully inside cup and final linear/angular speeds below explicit rest tolerances.
Next change / outcome: Bake physical cache; tracking camera; render.
Fall frames (tiles 1–18): [62, 65, 69, 73, 77, 81, 85, 89, 92, 96, 99, 103, 106, 110, 114, 117, 118, 120]
Ball final position: [8.158634185791016, 2.7627720832824707, -0.18999996781349182]; last-second displacement: 0.013756405 m.
