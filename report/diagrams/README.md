# PartyBash Mermaid diagrams

All diagram text is in English. The diagrams describe source baseline `3c156b5`, which is the baseline cited in the reports. They do not claim to document later source changes.

Each diagram has three representations:

- `.mmd`: editable Mermaid source. Paste it into a Mermaid editor or use a Mermaid capable Markdown preview.
- `.svg`: scalable export suitable for slides and other documents.
- `.png`: high resolution export embedded in the Word reports.

## Diagram index

| Diagram | Purpose | Used in |
| --- | --- | --- |
| [Game loop overview](game_loop_overview.mmd) | Read the main loop at a glance | Final report and Week 2 |
| [Architecture overview](architecture_overview.mmd) | Identify the main implementation responsibilities | Final report and Week 3 |
| [Readiness and board turns](board_flow_detailed.mmd) | Follow readiness cancellation, movement, tile resolution and round completion | Final Appendix A1 and Week 2 Appendix A1 |
| [Minigame and match result](match_flow_detailed.mmd) | Follow ranking, rewards, another round, victory and restart | Final Appendix A2 and Week 2 Appendix A2 |
| [Detailed system architecture](system_architecture_detailed.mmd) | Trace the room, board and minigame responsibilities | Final Appendix B and Week 3 Appendix A |
| [Multiplayer sequence](multiplayer_sequence.mmd) | Follow board events and the 3D arena ranking path | Final Appendix C |

## Reading the diagrams

The architecture chart describes responsibilities and dependencies. Arrows do not imply that every connected class inherits from another class. Networking is Shared Authority: Photon transports events and replicated values; the project code resolves gameplay rules.

The sequence chart shows the common 3D arena path, rather than claiming that every minigame uses identical messages. In particular, Tank has its own implementation. Board state is sent through RPCs, whereas MatchState has replicated room properties. The charts do not assert complete recovery of an ongoing board match after late join or master changes.

## Editing and exporting

Edit the `.mmd` file, render it with a Mermaid compatible renderer, and replace the corresponding `.svg` and `.png`. The Word reports contain rendered images rather than an executable Mermaid component. Image descriptions identify the source filename so the matching Mermaid source is easy to locate.

Use the detailed pages for technical explanation, and the shorter overview diagrams for the initial presentation. Avoid shrinking the detailed charts into a small slide corner. The report uses dedicated diagram pages and selects portrait or landscape orientation to keep labels readable.
