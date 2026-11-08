# The Sleeping Grove — Godot sample game

A playable 2D forest adventure built for the Godot Forge Final Game lesson. Open `project.godot` in Godot 4.7.2 and run the project with F5. The game starts in fullscreen at `scenes/StartMenu.tscn`; the level is `scenes/Main.tscn`.

Choose **Start Adventure** for solo play, or use **Multiplayer**, **Controls & Gamepad**, **Progress & Scores**, and **Quit Game**. The in-game **Menu** button and Escape open the pause menu. The compact HUD shows coins, score, health and online room status. A living player can finish the level by reaching the portal; collecting coins and defeating enemies are optional.

Enemies recoil away from the attacker, flash red and display the damage amount when hit. The boss has reduced knockback. Hearts restore health, the shop sells healing and gear, and the level includes hazards, pickups, a recessed pool and a falling boulder. Achievements and scores are saved locally when earned.

- Player 1: A/D move, W jump (press twice for a double jump), S crouch, Space attack, E roll and F heal at the shop.
- Player 2: press C to join locally, then use Left/Right to move, Up to jump, Down to crouch, Control to roll, Shift to attack and Enter to heal.
- Escape or gamepad Start opens the pause menu; R restarts. Change keyboard and gamepad bindings and volume under **Controls & Gamepad**. Bindings are saved to `user://controls.cfg`.

## Online play

Choose **Multiplayer** to host or join a new run. The host shares the six-character room code shown in the HUD. Both players must enter the same WebSocket relay address. The default `ws://127.0.0.1:3000/ws/final-game` works only when the relay is running on the same computer; different computers need a shared reachable `ws://` or `wss://` relay. The host owns game state; the guest sees enemy movement, hit flashes, damage numbers and the ending.

## Desktop builds

The Godot export presets use `tsg-game-macos.app` and `tsg-game-windows.exe`. Install the matching Godot 4.7.2 export templates and choose **Project → Export**. The Windows preset embeds the game data in the executable; it targets 64-bit Intel/AMD Windows. The macOS export supports Apple Silicon and Intel and is ad-hoc signed for local testing. It is not notarized; the Windows build is unsigned and should be tested on Windows before distribution.

## Tests and artwork

`tests/smoke_test.gd`, `tests/menu_portal_test.gd`, `tests/enemy_impact_test.gd`, `tests/controls_test.gd` and `tests/health_animation_test.gd` can run with Godot's `--headless --path <project> --script res://tests/<name>.gd`. The online tests need a running relay, `FORGE_TEST_RELAY_URL`, and a fresh shared `FORGE_TEST_ROOM_FILE`. Some tests write normal Godot progress data for this sample.

Art is grouped by lesson under `assets/`; `asset_catalog.json` records sources. Generated final-game artwork and prompts are in `assets/final-game/`. The accompanying tutorial documents the scene setup and explains how to change these systems.
