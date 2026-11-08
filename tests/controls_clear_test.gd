extends SceneTree

var failures := 0

func _initialize() -> void:
    call_deferred("run_checks")

func check(ok: bool, description: String) -> void:
    if ok:
        print("PASS: " + description)
    else:
        failures += 1
        push_error("FAIL: " + description)

func has_keyboard(action: String) -> bool:
    return InputMap.action_get_events(action).any(func(event): return event is InputEventKey)

func has_pad(action: String) -> bool:
    return InputMap.action_get_events(action).any(func(event): return event is InputEventJoypadButton or event is InputEventJoypadMotion)

func tap(event: InputEvent) -> void:
    event.pressed = true
    if event is InputEventMouse:
        root.push_input(event, true)
    else:
        Input.parse_input_event(event)
    await process_frame
    event.pressed = false
    if event is InputEventMouse:
        root.push_input(event, true)
    else:
        Input.parse_input_event(event)
    await process_frame

func run_checks() -> void:
    var path := "user://controls.cfg"
    var existed := FileAccess.file_exists(path)
    var original := FileAccess.get_file_as_bytes(path) if existed else PackedByteArray()
    var start = load("res://scenes/StartMenu.tscn").instantiate()
    root.add_child(start)
    current_scene = start
    await process_frame
    var controls = start.get_node("UI/ControlsMenu")
    controls._restore_defaults()
    start.get_node("UI/AdventureMenu")._controls()
    controls.key_buttons["p1_jump"].grab_focus()
    var held := InputEventKey.new()
    held.keycode = KEY_W
    held.physical_keycode = KEY_W
    held.pressed = true
    Input.parse_input_event(held)
    await process_frame
    var remove := InputEventKey.new()
    remove.keycode = KEY_DELETE
    remove.physical_keycode = KEY_DELETE
    await tap(remove)
    check(not has_keyboard("p1_jump") and controls.key_buttons["p1_jump"].text == "Unassigned", "Delete clears only the focused keyboard binding")
    check(not Input.is_action_pressed("p1_jump"), "clearing releases an input that was already held")
    held.pressed = false
    Input.parse_input_event(held)
    controls.pad_buttons["p1_jump"].grab_focus()
    var clear_pad := InputEventJoypadButton.new()
    clear_pad.device = 7
    clear_pad.button_index = JOY_BUTTON_Y
    await tap(clear_pad)
    var bindings = load("res://scripts/GamepadBindings.gd")
    bindings.bind_player(1, 7)
    check(not has_pad("p1_jump") and controls.pad_buttons["p1_jump"].text == "Unassigned", "gamepad Y clears only the focused controller binding")
    check(has_keyboard("p1_right") and has_pad("p1_right"), "clearing leaves other actions available")
    var clear_key: Button = controls.find_child("Clear_p1_right_keyboard", true, false)
    var click := InputEventMouseButton.new()
    click.button_index = MOUSE_BUTTON_LEFT
    click.position = clear_key.get_global_rect().get_center()
    click.global_position = click.position
    var motion := InputEventMouseMotion.new()
    motion.position = click.position
    motion.global_position = click.position
    root.push_input(motion, true)
    await process_frame
    await tap(click)
    check(not has_keyboard("p1_right") and has_pad("p1_right"), "the visible clear button removes only its own keyboard binding")
    controls._begin_capture("p1_roll", "keyboard")
    await tap(remove)
    check(not has_keyboard("p1_roll") and controls.awaiting_action.is_empty(), "Delete also clears while capturing a replacement")
    controls.key_buttons["p1_interact"].grab_focus()
    var mac_delete := InputEventKey.new()
    mac_delete.keycode = KEY_BACKSPACE
    mac_delete.physical_keycode = KEY_BACKSPACE
    await tap(mac_delete)
    check(not has_keyboard("p1_interact"), "the Mac keyboard's backward Delete key also clears a binding")
    controls._begin_capture("p1_attack", "gamepad")
    var axis := InputEventJoypadMotion.new()
    axis.device = 7
    axis.axis = JOY_AXIS_LEFT_X
    axis.axis_value = -1.0
    Input.parse_input_event(axis)
    await process_frame
    axis.axis_value = 0.0
    Input.parse_input_event(axis)
    await process_frame
    bindings.bind_player(1, 7)
    check(InputMap.action_get_events("p1_attack").any(func(event): return event is InputEventJoypadMotion and event.axis == JOY_AXIS_LEFT_X), "an occupied stick direction can be reassigned")
    var left_events := InputMap.action_get_events("p1_left")
    check(not left_events.any(func(event): return event is InputEventJoypadMotion) and left_events.any(func(event): return event is InputEventJoypadButton and event.button_index == JOY_BUTTON_DPAD_LEFT), "reassignment preserves the displaced action's alternative D-pad binding")
    check(bindings.specs_for("p2_left").size() == 2, "player two keeps independent controller bindings")
    controls.close_menu()
    start.queue_free()
    await process_frame
    InputMap.load_from_project_settings()
    start = load("res://scenes/StartMenu.tscn").instantiate()
    root.add_child(start)
    current_scene = start
    await process_frame
    controls = start.get_node("UI/ControlsMenu")
    bindings.bind_player(1, 8)
    check(not has_keyboard("p1_jump") and not has_pad("p1_jump"), "cleared keyboard and controller bindings survive a new scene and device assignment")
    check(not has_keyboard("p1_right") and not has_keyboard("p1_roll"), "explicit clears reload after restoring the project's original input map")
    check(controls.key_buttons["p1_jump"].text == "Unassigned" and controls.pad_buttons["p1_jump"].text == "Unassigned", "saved cleared bindings stay visible as Unassigned")
    controls._restore_defaults()
    bindings.bind_player(1, 8)
    check(has_keyboard("p1_jump") and has_pad("p1_jump") and bindings.specs_for("p1_left").size() == 2, "Restore Defaults restores cleared and reassigned bindings")
    if existed:
        var saved := FileAccess.open(path, FileAccess.WRITE)
        saved.store_buffer(original)
        saved.close()
    else:
        DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
    print("Control clearing checks: ", "passed" if failures == 0 else "failed")
    quit(1 if failures else 0)
