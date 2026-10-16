# Dò mìn

Shared free movement field, two hearts, 28 m forward progress, maximum 60 seconds.
Four columns make the playable road 8 m wide. Mines are sampled randomly across
the entire danger area at 65% density (31 of 48 danger cells), using the shared
round seed. No route is carved: any lane can have gaps or clusters, and a row
can be fully mined. The first two rows are safe. Right-click reveals nearby mines and safe cells without number
labels, with a 0.7 second cooldown and a brief pulse at the scan origin. Standing
or moving never scans automatically. Reveals and cleared mines are shared.
The cloud roller waits two seconds, accelerates, and crosses the finish at
23 seconds; it ignores hearts
and mine immunity. Finished players are protected. The round also ends when all
participants finish, leave, or are eliminated.

The master resolves swept movement, mine damage, scanner reveals, distance and
ranking in the replicated objective snapshot. Mine hits grant 1.2 seconds of
immunity and briefly stop movement. Scores retain maximum forward progress,
including progress earned before elimination. Ties use earliest finish, hearts,
then player ID; departed players rank last. A mine-free route to the finish is
not guaranteed; distance ranking still resolves rounds where nobody finishes.
Spawn rows are safe. Jump settings and player transforms are
restored on exit. The camera follows the local player, then a living player.

Reference: Machine Party's Minefield, described in
[Destructoid's minigame guide](https://www.destructoid.com/all-machine-party-minigames-and-how-to-win/).
This version uses one round, two hearts and original pastel fruit mines/cloud
roller assets. All scene nodes, primitives, materials and colliders were authored
through Godot MCP. No third-party Machine Party assets are included.

Validation: `tests/run_minefield.gd` exercises ten rule tests (including seeded
random generation, density, all row mine counts and unrestricted edge placement
across 100 seeds), instantiated arena collision, first hit,
roller elimination, shared session ranking/early completion and cleanup.
Optional `-- --capture` saves an ignored GPU preview. Real Photon multi-client
play and master migration during this minigame have not been exercised live.
