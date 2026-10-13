# Rải sơn

Reference: [Nintendo's Turf War introduction](https://splatoon.nintendo.com/en/how-to-play/).
Paint coverage scoring is simplified into a one-minute playground: walk to
paint, overwrite other players' trails, punch nearby players to interrupt their
painting and push them away. Current ownership at the deadline determines rank;
repeated coverage of your own color does not increase the score.

The master keeps a 56 x 56 ownership grid for a 28 m square arena, uses swept
brush strokes, transfers cell counts on overwrite, and validates attack range,
facing and cooldown. Airborne/stunned players cannot paint; interrupted strokes
restart at the feet instead of filling the gap. Simultaneous overlap precedence
rotates across participants. Only the target's owner applies knockback; all
clients present attack/stun events once by serial. Characters remain able to
run away during the short painting interruption.

A single dynamic texture colors the authored floor. Score cards and name tags
use the same palette. The arena, floor material, collision, camera and compact
HUD were authored with Godot MCP. Detailed instructions live in the guide;
the pre-round message has only the objective and controls.

Validation: ten rule tests and `tests/run_paint.gd` cover overwrite, sustained
strokes, teleport gaps, bounds, cooldown, serialization, ranking, airborne
painting, shared session deadline and player restoration. A Forward+ GPU
preview verifies the floor shader. Real Photon multi-client play is untested.
