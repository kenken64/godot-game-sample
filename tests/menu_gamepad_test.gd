extends SceneTree

var failures := 0
const PAD := 7

func _initialize() -> void:
    call_deferred("run_checks")

func check(ok: bool, description: String) -> bool:
    if ok:
        print("PASS: " + description)
    else:
        failures += 1
        push_error("FAIL: " + description)
    return ok

func tap(button: int, device: int = PAD) -> void:
    var event := InputEventJoypadButton.new()
    event.device = device
    event.button_index = button
    event.pressed = true
    Input.parse_input_event(event)
    await process_frame
    event.pressed = false
    Input.parse_input_event(event)
    await process_frame

func tilt(axis: int, direction: float) -> void:
    var event := InputEventJoypadMotion.new()
    event.device = PAD
    event.axis = axis
    event.axis_value = direction
    Input.parse_input_event(event)
    await process_frame
    event.axis_value = 0.0
    Input.parse_input_event(event)
    await process_frame

func focused_text() -> String:
    var control = root.gui_get_focus_owner()
    return control.text if control is Button else ""

func run_checks() -> void:
    var game = root.get_node("Game")
    var start = load("res://scenes/StartMenu.tscn").instantiate()
    root.add_child(start)
    current_scene = start
    await process_frame
    await process_frame
    var menu = start.get_node("UI/AdventureMenu")
    check(focused_text() == "START ADVENTURE", "launch menu has initial focus")
    await tap(JOY_BUTTON_DPAD_DOWN)
    check(focused_text() == "MULTIPLAYER", "D-pad moves to multiplayer")
    await tap(JOY_BUTTON_A)
    if not check(menu.page == "multiplayer", "gamepad confirm opens a submenu"):
        quit(1)
        return
    await tap(JOY_BUTTON_DPAD_DOWN)
    check(focused_text() == "HOST A GAME", "D-pad leaves a text field for the host button")
    await tap(JOY_BUTTON_B)
    check(menu.page == "home" and focused_text() == "START ADVENTURE", "gamepad back restores home focus")
    await tilt(JOY_AXIS_LEFT_Y, 1.0)
    check(focused_text() == "MULTIPLAYER", "left stick moves through the menu")
    await tap(JOY_BUTTON_DPAD_DOWN)
    check(focused_text() == "CONTROLS", "D-pad reaches controls")
    await tap(JOY_BUTTON_DPAD_RIGHT)
    check(focused_text() == "SOUND", "D-pad navigates across a menu row")
    await tap(JOY_BUTTON_A)
    check(menu.page == "audio" and root.gui_get_focus_owner() is HSlider, "gamepad confirm opens sound settings")
    await tap(JOY_BUTTON_DPAD_DOWN)
    check(focused_text().begins_with("SOUND:"), "D-pad leaves the volume slider for the sound toggle")
    await tap(JOY_BUTTON_B)
    await tap(JOY_BUTTON_DPAD_DOWN)
    await tap(JOY_BUTTON_DPAD_DOWN)
    await tap(JOY_BUTTON_A)
    var controls = start.get_node("UI/ControlsMenu")
    check(controls.visible and focused_text() == "BACK", "gamepad opens the controls menu")
    await tap(JOY_BUTTON_DPAD_UP)
    check(root.gui_get_focus_owner() == controls.pad_buttons["restart"], "controls navigation reaches the last binding through the scroll list")
    var actions: Array = controls.ACTIONS.values()
    for index in range(actions.size() - 2, -1, -1):
        await tap(JOY_BUTTON_DPAD_UP)
        check(root.gui_get_focus_owner() == controls.pad_buttons[actions[index]], "scroll to gamepad binding: " + actions[index])
    await tap(JOY_BUTTON_DPAD_LEFT)
    check(root.gui_get_focus_owner() == controls.key_buttons[actions[0]], "controls navigation switches between binding columns")
    await tap(JOY_BUTTON_A)
    check(controls.awaiting_kind == "keyboard", "gamepad can select a keyboard binding")
    await tap(JOY_BUTTON_B)
    check(controls.visible and controls.awaiting_action.is_empty(), "gamepad back cancels keyboard binding capture")
    await tap(JOY_BUTTON_DPAD_RIGHT)
    await tap(JOY_BUTTON_A)
    check(controls.awaiting_kind == "gamepad", "gamepad can select a controller binding")
    await tap(JOY_BUTTON_BACK)
    check(controls.visible and controls.awaiting_action.is_empty(), "Select cancels controller binding capture")
    await tap(JOY_BUTTON_B)
    check(menu.visible and menu.page == "home" and not paused, "gamepad closes controls and restores the launch menu")
    await tap(JOY_BUTTON_A, 3)
    await process_frame
    await process_frame
    var level = current_scene
    if not check(level.scene_file_path == "res://scenes/Main.tscn", "a different gamepad can start the adventure"):
        quit(1)
        return
    # Bind the synthetic device without depending on connected hardware.
    load("res://scripts/GamepadBindings.gd").bind_system(PAD)
    await tap(JOY_BUTTON_START)
    menu = level.get_node("UI/AdventureMenu")
    check(paused and menu.visible and focused_text() == "RESUME", "Start opens and focuses the pause menu")
    await tap(JOY_BUTTON_DPAD_DOWN)
    await tap(JOY_BUTTON_B)
    check(not paused and not menu.visible, "gamepad back resumes play")
    await tap(JOY_BUTTON_START)
    await tap(JOY_BUTTON_START)
    check(not paused and not menu.visible, "Start also closes the pause menu")
    level._on_exit(level.p1)
    await process_frame
    check(level.finale.visible and focused_text() == "PLAY AGAIN", "result menu has controller focus")
    await tap(JOY_BUTTON_DPAD_UP)
    check(root.gui_get_focus_owner() == level.get_node("UI/Finale/KeepButton"), "gamepad reaches the ending choices")
    await tap(JOY_BUTTON_DPAD_RIGHT)
    check(root.gui_get_focus_owner() == level.get_node("UI/Finale/ReturnButton"), "gamepad switches ending choices")
    var save_path := "user://final_save.json"
    var existed := FileAccess.file_exists(save_path)
    var original := FileAccess.get_file_as_bytes(save_path) if existed else PackedByteArray()
    await tap(JOY_BUTTON_A)
    check(game.ending == "return" and focused_text() == "PLAY AGAIN", "confirming an ending restores focus to play again")
    if existed:
        var saved := FileAccess.open(save_path, FileAccess.WRITE)
        saved.store_buffer(original)
        saved.close()
    else:
        DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))
    paused = false
    await create_timer(1.1).timeout
    print("Menu gamepad checks: ", "passed" if failures == 0 else "failed")
    quit(1 if failures else 0)
