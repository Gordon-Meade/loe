# Legends of Éire — Godot 3D vertical slice

The existing GitHub Pages browser demo remains at the repository root. This new native 3D prototype lives in `godot/` on a feature branch.

## Open and play
1. Install Godot 4.3 or newer.
2. Import `godot/project.godot`, open the project and press F6/F5.
3. On desktop use WASD/arrow keys. On mobile use the on-screen buttons.
4. Approach the guardian, use Attack and Dodge. Open Runeweaving, swap adjacent tiles to form groups of 3, charge your magic, and cast near the guardian. After victory, reach the illuminated swans.

The prototype uses real Godot 3D meshes, a tracking camera, fog-coloured atmosphere, animation loops, collision-bounded arena, enemy AI, melee hit distance, dodge invulnerability, deterministic rune swaps, health, story dialogue and a victory state.

No external art or paid SDK. **This is a gameplay vertical slice with procedural placeholder models, not a commercially polished 3D game.** Replace models, animation rigs, VFX and environment art before testing commercial quality.

## Verification
Run `godot --headless --path godot --quit` for engine import/syntax checks and test on a physical phone; neither is available in the authoring environment here. Mobile builds require Android SDK and signing.
