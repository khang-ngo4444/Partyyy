# Minigame scenery

The 13 active 3D minigames share `theme_backdrop.tscn`. Tank 1990 remains a 2D arcade board with its existing border and HUD. The inactive Temporal Trails also has a compatible theme configuration.

The backdrop uses three thin decorative walls, a camera-specific procedural sky, and eight existing low-poly props. There is no front wall, no new collider, and no landing surface: the scenic ground sits below the falling elimination threshold. Imported mesh bounds keep every prop outside the playable route. Scenery is freed with its arena.

| Game | Presentation |
| --- | --- |
| Falling Floor | Lavender toy stage and castle pillars |
| Laser Leap | Blue arcade stage |
| Spotlight | Dark theatre; lit materials obey the existing blackout |
| Explosive | Pastel woodland playground |
| Magma | Volcanic rock pillars around the lava island |
| Crown | Pastel royal stage |
| Word Wars | Classroom shelves |
| Count Animals | Farm woodland |
| Rockslide | Mountain corridor; rocks follow the slope height |
| Toy Factory | Workshop shelves |
| Wave Shelter | Coastal palms outside the island |
| Minefield | Woodland road with open camera access |
| Paint | Lavender art studio |

## Asset report

Reused existing local Kenney assets: Nature Kit `tree_pineRoundC.glb`, `rock_tallH.glb`, `tree_palmShort.glb`; Castle Kit `wall-pillar.glb`; Furniture Kit `bookcaseOpen.glb`. Their original pack licenses remain beside the assets.

New items authored through Godot MCP: the backdrop prefab, three unit wall meshes, one scenic ground mesh, a vertical gradient texture, and a procedural sky/environment resource. Runtime code only instantiates the authored prefab and changes transforms, visibility, and palette copies. No AI-generated image or model was used, and no external generation service was called.

For fixed arena cameras, flat walls plus a small number of 3D props keep scenery predictable. A detailed splash-art wall can replace the gradient later when a suitable licensed illustration is available; the current change does not invent a downloaded artwork source.

Validation: `tests/run_theme_backdrop.gd`, existing Spotlight/Magma/Minefield/Paint/Rockslide/Factory/Wave runtime suites, MCP viewport inspection, and GPU captures of Minefield, Paint, Word Wars, Magma and Rockslide. Live Photon multiplayer has not been exercised by this scenery change.
