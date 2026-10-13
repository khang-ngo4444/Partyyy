# PartyBash workflow

- Keep code readable: descriptive names, named constants, small focused functions, and separate game rules from presentation.
- Read the relevant Godot MCP tool documentation before use. Inspect node properties or ClassDB metadata before setting them.
- Author scene trees, meshes, materials, collisions, cameras and UI with Godot MCP node/resource tools. Save scenes explicitly.
- Do not use executable GDScript, game_eval, or shell-generated scene text to control the editor or construct authored scene trees.
- GDScript is for gameplay logic. Instantiate authored PackedScenes for runtime objects rather than generating their visual nodes in gameplay scripts.
- Validate with focused rule tests, fresh CLI runtime checks and MCP visual inspection. Report multiplayer checks that have not been performed.
- Preserve user scratch files and unrelated changes. Follow the user's established GitHub push rules when a push is requested.
- After completing and validating each requested part, make a separate conventional commit with the established human author and no AI attribution. Keep unfinished work out of completed commits.
