# KayKit character animation sources

Downloaded from the official free releases on 2026-10-13:

- [Character Animations 1.1](https://kaylousberg.itch.io/kaykit-character-animations)
  `KayKit_Character_Animations_1.1.zip`, SHA-256
  `65882f31f905ad2e953819648a59287cdeab8f623908d5ef701971d3758be20f`.
- [Adventurers 2.0 FREE](https://kaylousberg.itch.io/kaykit-adventurers)
  `KayKit_Adventurers_2.0_FREE.zip`, SHA-256
  `abe48f4763fba0896bab486ee9e6d08ca6b5b3884b9601f235c8847ae94dc479`.

The original CC0 license is included. Only the eight Medium rig GLB animation
categories are included here. The existing Adventurers GLBs matched the fresh
download byte for byte. The playable roster is Knight, Mage, Ranger,
Rogue_Hooded and Barbarian; Barbarian replaces the old Skeleton roster entry.
All five use the same compatible 23-bone Medium rig.

`player/kaykit_animations.gd` caches a shared normalized library and binds it to
the AnimationPlayer authored in each character scene. It rewrites bone paths
and removes root translation so physics controls the avatar position. The
source GLBs remain unmodified; unused imported animation tracks are excluded
from the runtime aliases. No paid Blender files or external retargeting tool
is required.

Movement: idle, walk, sprint, jump, fall, land. Actions: punch, kick, magic shot.
Reactions: Hit_A, looping Hit_B for stun (no dedicated stun clip in the pack),
Death_B for knockdown, Death_A/dead pose, Spawn_Ground and Lie_StandUp.
Reaction priority prevents locomotion/attacks from overriding stun or death.
Board snapshots carry serial reaction events even when HP is immediately
restored; checkpoint presentation waits for death. Minigame attacks present
stun/knockdown on all clients receiving the existing attack broadcast.

Validation: `tests/run_kaykit.gd` checks aliases/bone targets and actual walk
motion on all five models, reaction priority/recovery, shielded damage,
lethal damage with restored HP, board event deduplication, phase 3 attack/stun,
and phase 2 checkpoint delay. `-- --capture` saves an ignored GPU roster preview.
Live Photon multi-client animation timing has not been verified.
