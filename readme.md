# PartyBash

A 3D online multiplayer party game built with Godot 4.7.1, GDScript, and Photon Fusion 3 using Shared Authority.

> This project is currently under active development and redesign. The main gameplay direction is a board-game-style party experience with an interactive lobby, party-board rounds, and short multiplayer minigames.

## Features

- Online multiplayer through Photon Fusion Shared Authority
- Interactive 3D lobby with:
  - Player movement and character selection
  - Dynamic lighting and lobby customization
  - Chess, Xiangqi, and Gomoku/Caro board objects
  - Dice, cards, darts, basketball, chicken racing, and other interactive activities
- Party-board gameplay framework with turn ordering, board state, items, cups, and round flow
- Extensible minigame architecture
- Tank Battle minigame currently implemented as the phase-three minigame
- Scene-based networking with replicated state and master-client authority
- Late-join synchronization for shared room state
- Reusable multiplayer patterns documented in `GUIDE.md`

## Technology

| Component | Version / Mode |
|---|---|
| Engine | Godot 4.7.1 |
| Language | GDScript |
| Networking | Photon Fusion Godot 3.0.0 Preview 555 |
| Networking mode | Shared Authority |
| Rendering | Forward Plus |
| Default viewport | 1280 × 720 |
| Default Photon region | Asia |

## Project Structure

```text
.
├── addons/          # Godot plugins, including the physics placer
├── asset/           # Imported game assets and sound packs
├── autoload/        # Global systems such as NetManager
├── board/           # Party-board scenes and game rules
├── builds/          # Exported or local build files
├── lobby/           # Interactive multiplayer lobby and lobby objects
├── materials/       # Shared Godot materials
├── minigame/        # Minigame scenes and shared minigame framework
├── net/             # Networked state and multiplayer scenes
├── player/          # Player scenes, character models, movement, and camera
├── ui/              # Menus, HUD, board panels, and victory screens
├── main.gd          # Application and gameplay-flow coordinator
├── main.tscn        # Main scene
├── project.godot    # Godot project configuration
├── GUIDE.md         # Photon Fusion and multiplayer implementation notes
├── MINIGAME.md      # Minigame architecture and design constraints
├── ROADMAP.md       # Project direction and development roadmap
├── CREDITS.md       # Asset, SDK, tutorial, and AI credits
```

## Requirements

- Godot 4.7.1 or a compatible 4.7 build
- Photon Fusion Godot SDK 3.0.0 Preview 555 installed under `addons/`
- A Photon Fusion application ID
- An internet connection for Photon Cloud multiplayer

The project uses Photon Cloud and is configured for Shared Authority. The Photon application ID is configured through the Fusion settings in `project.godot`; do not publish private credentials or production configuration in public builds.

## Getting Started

1. Clone the repository:

   ```bash
   git clone https://github.com/khang-ngo4444/Partyyy.git
   cd Partyyy
   ```

2. Install or restore the Photon Fusion Godot SDK in `addons/`.

3. Open the project in Godot 4.7.1.

4. In Project Settings → Fusion → Connection, configure your Photon application ID and region.

5. Import the project. If Godot does not recognize newly added `class_name` scripts, rebuild the editor cache:

   ```bash
   godot --headless --path . --import
   ```

6. Run `main.tscn` from the editor or press F6/F5.

7. Start a second instance to test multiplayer behavior. Networking changes should be tested with at least two clients.

## Controls

The exact key bindings are configured in `project.godot`. The project currently includes input actions for:

- Movement: forward, back, left, and right
- Jumping
- Interaction and dropping held objects
- Card-game actions
- Board and minigame interactions
- Character-model changes

Use the Godot Project Settings → Input Map panel to inspect or customize the bindings.

## Multiplayer Architecture

PartyBash uses a shared-authority model rather than a dedicated server:

- Every client runs the same gameplay scripts.
- The master client owns and validates shared room state.
- Player objects are spawned by each client and synchronized through Photon Fusion.
- Shared state is replicated as properties so late joiners can receive the current state.
- RPCs are used for discrete events rather than continuous per-frame state.
- Scene objects in the lobby can use Fusion replication without being dynamically spawned.

The most important networking guidance and tested implementation patterns are documented in `GUIDE.md`.

## Current Gameplay Direction

The intended gameplay loop is:

```text
Interactive lobby → party board round → minigame → next party-board round
```

The project distinguishes between two kinds of activities:

- Lobby activities: Persistent objects placed in the lobby scene. They are available for casual interaction and do not produce a winner or ranking.
- Phase-three minigames: Temporary games loaded during a round. They have a time limit, involve the participating players, and must produce a deterministic ranking.

See `MINIGAME.md` for the current architecture, synchronization strategies, planned minigame families, and known design decisions.

## Development Notes

- Test networking features with two or more clients.
- Keep persistent gameplay state in replicated state objects rather than local variables.
- Use RPCs for events, not high-frequency transforms or per-frame updates.
- In Shared Authority mode, clearly distinguish between:
  - The object owner, who may write to that object
  - The master client, who controls shared room rules
  - Remote clients, which should generally read and display state
- Avoid starting Photon connections directly while the scene tree is still inside `_ready()`; the networking guide documents the required initialization flow.
- Keep node names unique for replicated scene objects because their names contribute to deterministic network identity.

## Roadmap and Documentation

- `ROADMAP.md` — project direction, implementation status, open decisions, and development plan
- `GUIDE.md` — Photon Fusion networking guide based on this project
- `GUIDE_PARTYGAME.md` — planned minigame concepts and scene layouts
- `MINIGAME.md` — minigame contracts, synchronization models, and implementation roadmap
- `ASSET-CAN-THEM.md` — missing assets and temporary geometry inventory
- `CREDITS.md` — third-party assets, networking SDK, tutorials, and AI assistance credits

## Known Limitations

- The project is not a finished release and may contain incomplete or experimental systems.
- The board-game rules and final victory conditions are still being refined.
- Additional minigames, UI, audio, character animation integration, and final art assets remain in progress.
- Shared Authority is suitable for this project and its intended audience, but it is not designed as a cheat-resistant competitive backend.
- Some assets and systems are intentionally represented by placeholder geometry while gameplay is being validated.

## Assets and Credits

This project uses assets and technology from Kenney, KayKit, Photon/Exit Games, and other credited contributors. Please read `CREDITS.md` before redistributing the project or its assets. License files are retained with the relevant asset packs where applicable.

## Contributing

Contributions and feedback are welcome while the project is being developed. Before making a change:

1. Read the relevant project guide.
2. Keep gameplay rules, networking, scene layout, and UI responsibilities separated.
3. Test multiplayer changes with at least two clients.
4. Update the documentation and credits when adding new systems or assets.

## License

No project-wide license has been specified yet. Third-party assets retain their original licenses; see `CREDITS.md` and the license files inside the asset directories for details.
