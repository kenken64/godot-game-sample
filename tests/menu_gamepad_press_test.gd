extends SceneTree

const PAD := 7
var failures := 0

func _initialize() -> void:
    call_deferred("run_checks")

func check(ok: bool, description: String) -> bool:
    if ok:
        print("PASS: " + description)
    else:
        failures += 1
        push_error("FAIL: " + description)
    return ok

func button(index: int, pressed: bool) -> void:
    var event := InputEventJoypadButton.new()
    event.device = PAD
    event.button_index = index
    event.pressed = pressed
    Input.parse_input_event(event)
    await process_frame

func run_checks() -> void:
    var start = load("res://scenes/StartMenu.tscn").instantiate()
    root.add_child(start)
    current_scene = start
    await process_frame
    await process_frame
    var menu = start.get_node("UI/AdventureMenu")
    await button(JOY_BUTTON_DPAD_DOWN, true)
    # Keep the direction held while A is pressed, as with a real controller.
    await button(JOY_BUTTON_A, true)
    if not check(menu.page == "multiplayer", "Xbox A opens the selected submenu on press while a direction is held"):
        await button(JOY_BUTTON_A, false)
        await button(JOY_BUTTON_DPAD_DOWN, false)
        quit(1)
        return
    await button(JOY_BUTTON_DPAD_DOWN, false)
    await create_timer(0.2).timeout
    check(menu.page == "multiplayer", "holding confirm does not activate a second control")
    await button(JOY_BUTTON_A, false)
    check(menu.page == "multiplayer", "releasing confirm does not activate the next page")
    await button(JOY_BUTTON_B, true)
    await button(JOY_BUTTON_B, false)
    check(menu.page == "home", "Xbox B returns to the main menu")
    await button(JOY_BUTTON_DPAD_DOWN, true)
    await button(JOY_BUTTON_DPAD_DOWN, false)
    await button(JOY_BUTTON_DPAD_DOWN, true)
    await button(JOY_BUTTON_DPAD_DOWN, false)
    await button(JOY_BUTTON_A, true)
    var controls = start.get_node("UI/ControlsMenu")
    check(controls.visible, "Xbox A opens Controls before the button is released")
    await button(JOY_BUTTON_A, false)
    check(controls.visible and controls.awaiting_action.is_empty(), "the opening press does not activate Back or capture a binding")
    await button(JOY_BUTTON_B, true)
    await button(JOY_BUTTON_B, false)
    check(menu.visible and menu.page == "home", "Xbox B returns from Controls")
    var game = root.get_node("Game")
    var audio_path := "user://audio.cfg"
    var existed := FileAccess.file_exists(audio_path)
    var original := FileAccess.get_file_as_bytes(audio_path) if existed else PackedByteArray()
    var original_enabled: bool = game.sound_enabled
    menu._audio()
    await button(JOY_BUTTON_DPAD_DOWN, true)
    await button(JOY_BUTTON_DPAD_DOWN, false)
    await button(JOY_BUTTON_A, true)
    check(game.sound_enabled != original_enabled, "confirm toggles sound on press")
    var selected: bool = game.sound_enabled
    await create_timer(0.2).timeout
    await button(JOY_BUTTON_A, false)
    check(game.sound_enabled == selected and menu.sound_button.button_pressed == selected, "holding and releasing confirm does not toggle sound twice")
    await button(JOY_BUTTON_A, true)
    await button(JOY_BUTTON_A, false)
    check(game.sound_enabled == original_enabled, "a new confirm press toggles sound once")
    if existed:
        var saved := FileAccess.open(audio_path, FileAccess.WRITE)
        saved.store_buffer(original)
        saved.close()
    else:
        DirAccess.remove_absolute(ProjectSettings.globalize_path(audio_path))
    print("Gamepad confirm press checks: ", "passed" if failures == 0 else "failed")
    quit(1 if failures else 0)
