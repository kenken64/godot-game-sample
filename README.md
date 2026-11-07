# Godot Forge: The Sleeping Grove

A local sample built from the Final Game lesson and the Godot Forge starter artwork. Open `project.godot` in Godot 4 and press **Run Project** (F5). The starting scene is `scenes/Main.tscn`; the reusable scenes and their scripts are under `scenes/` and `scripts/`. The level uses a simple collision floor and repeated background art so the complete example is easy to inspect and adapt.

Collect 20 coins, defeat the guardian and enter the exit to choose what happens to the relic. Visit the shop and use the on-screen buttons to trade. The level includes hazards, bonus spawns, a falling boulder, two ordinary enemies, a boss, local co-op, saved achievements and scores, and online room controls.

- Player 1: A/D move, W jump (press twice to double jump), S crouch, Space attack, E roll, F heal at the shop.
- Player 2: press C to join, then use Left/Right to move, Up to jump, Down to crouch, Control to roll, Shift to attack, and Enter to heal.
- Escape pauses/resumes; R restarts. Gamepads can be assigned when connected.
- To test online on this Mac, run the tutorial server on port 3000, start two independent copies of this project, host in one, then enter its room code in the other. For a different computer or cloud editor, set `Online.relay_url` in the Inspector to a relay address both machines can reach. A loopback address such as `127.0.0.1` only reaches the current machine.

The tutorial's `final-game/README.md` records the problems found during the sample build and the corresponding fixes. `tests/smoke_test.gd` checks movement, pickups, co-op activation, shop transactions, the boss and ending in headless Godot. `tests/network_test.gd` is a two-process local relay check; the tutorial server must be running and `FORGE_TEST_ROOM_FILE` must name a fresh temporary file shared by the two processes. The tests write normal Godot progress data for this sample.

The art is grouped by tutorial module under `assets/`; see `asset_catalog.json` for its source information. To replace the sample graphics, assign your own textures and SpriteFrames in Godot.

## macOS application export

The `macOS` export preset builds a universal app for Apple Silicon and Intel Macs. In Godot, open **Project → Export**, select **macOS**, and choose **Export Project**. The matching Godot 4.7.2 macOS export template must be installed; the project enables **Rendering → Textures → VRAM Compression → Import ETC2 ASTC**, which the universal export requires. The current local build is in the sibling `GodotForgeSample-export` folder. The app is ad-hoc signed for local testing; it is not Apple Developer ID signed or notarized for distribution.

The app runs the game without the Godot editor. Its default online room address is `127.0.0.1:3000`, so online multiplayer needs the tutorial server on the same computer. For players on different computers, change the Online node's relay URL to a reachable shared server and export again.

## Windows application export

The `Windows Desktop` export preset creates a 64-bit Windows `.exe` with the game data embedded, so no separate `.pck` file is needed. Install the matching Godot 4.7.2 Windows export templates, then select **Project → Export → Windows Desktop → Export Project**. The build is intended for Intel/AMD 64-bit Windows; native Windows on ARM requires its own export template and preset. This local test build is unsigned. A Windows signing certificate is needed if you want to sign builds for distribution.

Like the macOS build, online play defaults to a local relay at `127.0.0.1:3000`. Use a shared reachable relay URL and export again for players on separate computers.

## Controls and health

Select **Controls** or press the pause action (Escape or gamepad Start by default) to open the controls menu. Select a keyboard or gamepad binding and press the replacement key, button, or stick direction. Escape cancels capture; Close / Resume leaves the menu. Conflicting bindings are rejected, and Restore defaults resets the configuration. Choices persist in `user://controls.cfg` on this device. Controller bindings follow the existing solo/co-op player assignment when devices reconnect. The on-screen bars show health; taking damage and dying play the hero's hurt and death animations.

The generated portal, shop, and ground artwork and their prompts are under `assets/final-game/`. The desktop export files must be rebuilt after editing this project.

Three hearts are placed along the level and restore one health each. They remain available when health is full. The shallow pool is recessed into the ground and the boulder falls into it; the player can jump out.
