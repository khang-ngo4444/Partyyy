# KayKit sources and reusable project references

Checked on 2026-10-14. This is a source catalog, not a claim that every listed pack has been downloaded or integrated. No game code or third-party project-created art was copied for this research.

## Prefer the creator's free releases

[Kay Lousberg's official catalog](https://kaylousberg.com/game-assets) and [official GitHub account](https://github.com/KayKit-Game-Assets) establish provenance. The GitHub account currently publishes ten asset-pack repositories. Their license files say CC0 even where GitHub's license detector returns `NOASSERTION`.

| Pack | Free assets useful here | Source |
| --- | --- | --- |
| Adventurers 2.0 | Knight, Mage, Ranger, Rogue, Barbarian; hooded Rogue variant; handheld equipment | [Current free release](https://kaylousberg.itch.io/kaykit-adventurers) |
| Skeletons 1.1 | Four skeleton characters, swords, shields, axe, crossbow, arrows, staff | [Current free release](https://kaylousberg.itch.io/kaykit-skeletons) |
| Character Animations 1.1 | Medium and Large rigs; movement, melee/ranged combat, reactions, death, interaction | [Current free release](https://kaylousberg.itch.io/kaykit-character-animations) |
| Platformer | Floors, walls, ramps, rails, signs, flags, finish line, buttons, hearts, stars, bombs | [Free tier](https://kaylousberg.itch.io/kaykit-platformer) |
| Medieval Hexagon | Simple landscape silhouettes, trees, rocks, wooden/stone fences, colored buildings | [Official repository](https://github.com/KayKit-Game-Assets/KayKit-Medieval-Hexagon-Pack-1.0) |
| Dungeon Remastered | Modular room walls, pillars, arches, banners, torches, chests, floor tiles | [Official repository](https://github.com/KayKit-Game-Assets/KayKit-Dungeon-Remastered-1.0) |
| Halloween Bits | Orange/yellow trees, friendly pumpkins, fences; graveyard props for a deliberately spooky theme | [Official repository](https://github.com/KayKit-Game-Assets/KayKit-Halloween-Bits-1.0) |
| Space Base Bits | Space buildings/props and rocks for laser or tank arenas | [Official repository](https://github.com/KayKit-Game-Assets/KayKit-Space-Base-Bits-1.0) |

The creator's public catalog identifies Adventurers and Skeletons as the two character packs. A preview image of another character does not grant access to that character. EXTRA, SOURCE, monthly Patreon characters, and paid bonuses must not be treated as part of the free tier. In particular, Skeleton Golem and Necromancer are paid extras; Platformer hammer traps, conveyors and sawblades are listed under EXTRA.

The old official Adventurers/Skeletons GitHub repositories are version 1.0; use current itch.io 2.0/1.1 releases for compatibility with our existing animation binder. Keep the supplied license beside each imported pack. CC0 allows personal/commercial reuse without mandatory attribution; retain creator/source notices for provenance.

## Verified projects using KayKit

| Project | Open-source status | Useful reference | Asset policy |
| --- | --- | --- | --- |
| [KenneyNL/KayKit-Hexagons](https://github.com/KenneyNL/KayKit-Hexagons) | [MIT code](https://github.com/KenneyNL/KayKit-Hexagons/blob/main/LICENSE) | Godot GridMap landscape, scene composition and terrain silhouettes | KayKit Medieval Builder models are separately CC0; example is Godot 3.3.2, so inspect composition rather than importing legacy scripts wholesale |
| [sketchpunklabs/kaykit_halloween](https://github.com/sketchpunklabs/kaykit_halloween) | [MIT code](https://github.com/sketchpunklabs/kaykit_halloween/blob/main/LICENSE) | Small coherent diorama; `src/assets.json` lists models and `src/grid.json` records placements; skeleton animation and lighting | README links official Halloween, Dungeon, Skeletons and Spooktober packs; acquire those originals instead of assuming every derivative is covered by the root MIT license |
| [doctor-g/KayKitAnimationInGodot](https://github.com/doctor-g/KayKitAnimationInGodot) | [MIT code](https://github.com/doctor-g/KayKitAnimationInGodot/blob/master/LICENSE) | Historical proof of KayKit bone-attachment animation setup | Godot 3.x/old FBX workflow; useful history, unsuitable as our Godot 4 animation pipeline |
| [PhuocNG0308/C-Sharp-Learning-Project](https://github.com/PhuocNG0308/C-Sharp-Learning-Project) | [MIT code](https://github.com/PhuocNG0308/C-Sharp-Learning-Project/blob/main/LICENSE) | Movement, combat and utility AI with Adventurers/Skeletons in Unity/Latios | README credits four official KayKit packs; source engine differs from ours, so use only as visual/mechanic reference |

Public visibility is not itself an open-source license. A project's code license does not automatically cover its models, screenshots, music, generated props or extra assets. MIT code copied later would require its copyright/license notice. This catalog intentionally prefers creator downloads over third-party mirrors.

## Concrete official asset paths

The paths below were checked through the official GitHub tree API. For immutable downloads replace `main` in `https://raw.githubusercontent.com/KayKit-Game-Assets/<repo>/main/<path>` with the commit recorded below. Full source archives are available at `https://codeload.github.com/KayKit-Game-Assets/<repo>/zip/<commit>`.

| Repository and checked commit | Example paths relative to repository root |
| --- | --- |
| `KayKit-Medieval-Hexagon-Pack-1.0` — `84fa4e91af6a88989be7c99e0891cede11f2ca38` | `addons/kaykit_medieval_hexagon_pack/Assets/gltf/buildings/neutral/fence_wood_straight.gltf`; `.../fence_stone_straight.gltf`; `addons/kaykit_medieval_hexagon_pack/Assets/gltf/decoration/nature/rock_single_A.gltf`; `.../tree_single_A.gltf`; `.../hills_A_trees.gltf`; `.../mountain_A_grass_trees.gltf` |
| `KayKit-Dungeon-Remastered-1.0` — `b0ca9bd96a8072ab36a3a5464f00ed1e06a16d07` | `addons/kaykit_dungeon_remastered/Assets/gltf/chest.glb`; `.../chest_gold.glb`; `.../banner_blue.gltf.glb`; `.../floor_tile_large.gltf.glb`; `.../floor_tile_small.gltf.glb`; texture: `addons/kaykit_dungeon_remastered/Assets/texture/dungeon_texture.png` |
| `KayKit-Halloween-Bits-1.0` — `6dc69bf6b2fa766a985754f35ec6a0324090e6c6` | `addons/kaykit_halloween_bits/Assets/gltf/tree_pine_orange_small.gltf`; `.../tree_pine_yellow_medium.gltf`; `.../pumpkin_orange_small.gltf`; `.../fence.gltf`; texture: `addons/kaykit_halloween_bits/Assets/gltf/halloweenbits_texture.png` |
| `KayKit-Character-Pack-Skeletons-1.0` — `15b62b9bad122f72926c10fb14d622c73819fa54` | `addons/kaykit_character_pack_skeletons/Assets/gltf/Skeleton_Crossbow.gltf`; `.../Skeleton_Shield_Small_A.gltf`; `.../Skeleton_Staff.gltf`; prefer current 1.1 itch release for animated characters |
| `KayKit-Space-Base-Bits-1.0` — `6dfbcac9927d06283752c4defd4882cfe0d29666` | `addons/kaykit_space_base_bits/Assets/gltf/rock_A.gltf`; `.../rocks_A.gltf`; texture: `addons/kaykit_space_base_bits/Assets/gltf/spacebits_texture.png` |

For `.gltf`, retain the referenced `.bin` and texture paths; downloading the JSON model alone is incomplete. Inspect GLB image URIs too: a GLB container can still reference external textures. The Dungeon repo uses some double extensions (`.gltf.glb`); preserve the real filenames. Every listed repository has a root `LICENSE.txt`, plus a pack-local copy.

## Minimal subset for PartyBash

1. Keep all free character choices, but ship only the glTF/GLB formats and textures actually used. Keep source ZIPs outside `res://` so FBX/OBJ duplicates are not imported.
2. Start backdrops with Medieval rocks/trees/fences and Platformer rails/flags/signs. About 8–12 reusable models can theme many arenas without whole-city scenes.
3. Use Dungeon walls/banners/torches for Spotlight and indoor arenas. Keep scenery outside collision/play bounds and preserve blackout isolation.
4. Use a few actual 3D props near players and a simple sky/far silhouette. Flat illustrated side walls suit a long fixed-view road; a freely moving or rotating camera exposes their flatness. A large texture can cost more memory than several small meshes, so measure imported texture sizes rather than equating “2D” with “cheap”.
5. No generated asset is needed for this research. Existing-source intake and any future generated content should be logged separately from implementation-authored primitive props.
