# The Sleeping Grove — Godot sample game

A playable 2D forest adventure built for the Godot Forge Final Game lesson. Open `project.godot` in Godot 4.7.2 and run the project with F5. The game starts in fullscreen at `scenes/StartMenu.tscn`; the level is `scenes/Main.tscn`.

Download the [latest desktop builds for Linux, Windows and macOS](https://github.com/kenken64/godot-game-sample/releases/latest). The source project and full starter artwork are included in this repository.

Choose **Start Adventure** for solo play, or use **Multiplayer**, **Controls**, **Sound**, **Progress & Scores**, and **Quit Game**. The in-game **Menu** button and Escape open the pause menu. The compact HUD shows coins, score, health and online room status. A living player can finish the level by reaching the portal; collecting coins and defeating enemies are optional.

Enemies recoil away from the attacker, flash red and display the damage amount when hit. The boss has reduced knockback. Hearts restore health, the shop sells healing and gear, and the level includes hazards, pickups, a recessed pool and a falling boulder. Achievements and scores are saved locally when earned.

- Player 1: A/D move, W jump (press twice for a double jump), S crouch, Space attack, E roll and F heal at the shop.
- Player 2: press C to join locally, then use Left/Right to move, Up to jump, Down to crouch, Control to roll, Shift to attack and Enter to heal.
- Escape or gamepad Start opens the pause menu; R restarts. Change keyboard and gamepad bindings under **Controls**; they are saved to `user://controls.cfg`. **Sound** has a master volume, on/off switch and test cue; settings are saved separately to `user://audio.cfg`. The game generates short cues for key actions.
- Navigate menus with the D-pad or left stick, confirm with A / Cross, and go back with B / Circle. Menu buttons activate when pressed, including while a direction is held. Start also resumes a paused game. In the binding editor, Escape or Back / Select cancels capture; B / Circle also cancels keyboard capture.
- In **Controls**, assigning an occupied input reassigns it from the conflicting action. Clear a keyboard or gamepad binding with its **×** button or Delete; gamepad Y clears a focused binding. Cleared bindings stay unassigned after restarting. **Restore Defaults** brings back the original bindings.

## Online play

Choose **Multiplayer** to host or join a new run. The host shares the six-character room code shown in the HUD. Both players must enter the same WebSocket relay address. The default `ws://127.0.0.1:3000/ws/final-game` works only when the relay is running on the same computer; different computers need a shared reachable `ws://` or `wss://` relay. The host owns game state; the guest sees enemy movement, hit flashes, damage numbers and the ending.

## Desktop builds

The Godot export presets use `tsg-game-macos.app` and `tsg-game-windows.exe`. Install the matching Godot 4.7.2 export templates and choose **Project → Export**. The Windows preset embeds the game data in the executable; it targets 64-bit Intel/AMD Windows. The macOS export supports Apple Silicon and Intel and is ad-hoc signed for local testing. It is not notarized; the Windows build is unsigned and should be tested on Windows before distribution.

The `Linux` preset exports `tsg-game-linux.x86_64` for 64-bit Intel/AMD Linux, with the game data embedded in the executable. With the matching Linux export templates installed, build it using `"/Applications/Godot.app/Contents/MacOS/Godot" --headless --path . --export-release "Linux" "../GodotForgeSample-export/tsg-game-linux.x86_64"` on this Mac, or select **Project → Export → Linux** in the editor. On Linux, run `chmod +x tsg-game-linux.x86_64` if needed, then `./tsg-game-linux.x86_64`. The Linux build should be tested on a Linux desktop before distribution.

All three presets retain the full starter asset library. Desktop releases are also packaged as `.tar.xz` archives using lossless compression, with a `.zip` alternative for Windows. Extract the package before launching the game. These archives reduce download size; the extracted files and image quality are unchanged.

After exporting macOS, run `python3 tools/package_macos.py /path/to/tsg-game-macos.app` to include the native startup executable and controller profile, then create the release archive. This developer packaging step requires Apple's command line build tools and produces an ad-hoc signed universal app. Players can open the packaged app normally.

## micro:bit gamepad on macOS

Connect the tested Bluetooth `micro:bit Gamepad` (`1209:0001`) before opening **tsg-game-macos.app**, then double-click the app normally. Its native startup executable detects the connected micro:bit and selects the compatible controller backend and mapping before Godot initializes. No Terminal or external launcher is needed. When no micro:bit is connected, the app retains the normal controller backend. If the micro:bit is connected after the game is already running, reopen the app.

The package also includes optional compatibility and diagnostic tools. Run `tools/check_microbit_macos.command` from this repository, or `check_microbit_macos.command` beside the extracted app, to inspect live input. **Escape** or the window's close button exits the checker. The checker requires the Godot editor at `/Applications/Godot.app`, or set `GODOT_EDITOR` to its executable; playing the exported game does not require the editor. The older `play_microbit_macos.command` remains available for manual compatibility testing.

The mapping reserves raw button 6 for stick-click and raw button 7 for Start. In the physical test, 535 Bluetooth HID reports contained axis motion and ordinary button slots 0–5, but no stick-click bit. The controller firmware or switch wiring must supply that event before the game can bind it.

## Tests and artwork

`tests/smoke_test.gd`, `tests/menu_portal_test.gd`, `tests/menu_gamepad_test.gd`, `tests/menu_gamepad_press_test.gd`, `tests/enemy_impact_test.gd`, `tests/controls_test.gd`, `tests/controls_clear_test.gd` and `tests/health_animation_test.gd` can run with Godot's `--headless --path <project> --script res://tests/<name>.gd`. The online tests need a running relay, `FORGE_TEST_RELAY_URL`, and a fresh shared `FORGE_TEST_ROOM_FILE`. Some tests write normal Godot progress data for this sample.

Art is grouped by lesson under `assets/`; `asset_catalog.json` records sources. Generated final-game artwork and prompts are in `assets/final-game/`. The accompanying tutorial documents the scene setup and explains how to change these systems.
