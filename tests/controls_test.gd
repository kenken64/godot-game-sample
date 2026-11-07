extends SceneTree
var failures := 0
func _initialize() -> void:
    call_deferred("run_checks")
func check(ok: bool, label: String) -> void:
    if ok:
        print("PASS: " + label)
    else:
        failures += 1
        push_error("FAIL: " + label)
func key_for(action: String) -> int:
    for event in InputMap.action_get_events(action):
        if event is InputEventKey:
            return event.physical_keycode if event.physical_keycode else event.keycode
    return 0
func run_checks() -> void:
    var path = "user://controls.cfg"
    var existed = FileAccess.file_exists(path)
    var original = FileAccess.get_file_as_bytes(path) if existed else PackedByteArray()
    var level = load("res://scenes/Main.tscn").instantiate()
    root.add_child(level)
    current_scene = level
    var menu = level.get_node("UI/ControlsMenu")
    menu._restore_defaults()
    menu.open_menu()
    check(paused and menu.visible, "open controls pauses game")
    menu._begin_capture("p1_left", "keyboard")
    var key = InputEventKey.new()
    key.pressed = true
    key.physical_keycode = KEY_SPACE
    menu._input(key)
    check(key_for("p1_left") == KEY_A and menu.awaiting_action == "p1_left", "reject conflicting keyboard key")
    key.physical_keycode = KEY_Q
    menu._input(key)
    check(key_for("p1_left") == KEY_Q and menu.awaiting_action == "", "remap keyboard key")
    menu._begin_capture("p1_jump", "gamepad")
    var joy = InputEventJoypadButton.new()
    joy.pressed = true
    joy.button_index = JOY_BUTTON_RIGHT_SHOULDER
    menu._input(joy)
    check(not menu.pad_overrides.has("p1_jump"), "reject conflicting gamepad button")
    joy.button_index = JOY_BUTTON_LEFT_SHOULDER
    menu._input(joy)
    menu._begin_capture("p1_left", "gamepad")
    var axis = InputEventJoypadMotion.new()
    axis.axis = JOY_AXIS_LEFT_Y
    axis.axis_value = -1.0
    menu._input(axis)
    check(menu.pad_overrides.get("p1_left", {}).get("type") == "axis", "capture a gamepad stick direction")
    var bindings = load("res://scripts/GamepadBindings.gd")
    bindings.bind_player(1, 7)
    var found = false
    for event in InputMap.action_get_events("p1_jump"):
        if event is InputEventJoypadButton and event.device == 7 and event.button_index == JOY_BUTTON_LEFT_SHOULDER:
            found = true
    check(found, "apply gamepad remap to assigned device")
    found = false
    for event in InputMap.action_get_events("p1_left"):
        if event is InputEventJoypadMotion and event.device == 7 and event.axis == JOY_AXIS_LEFT_Y and event.axis_value == -1.0:
            found = true
    check(found, "apply stick direction to the assigned device")
    menu.close_menu()
    check(not paused, "close controls resumes game")
    level.queue_free()
    await process_frame
    level = load("res://scenes/Main.tscn").instantiate()
    root.add_child(level)
    current_scene = level
    menu = level.get_node("UI/ControlsMenu")
    check(key_for("p1_left") == KEY_Q and menu.pad_overrides.has("p1_jump"), "restore saved settings on a new run")
    bindings.bind_player(1, 8)
    found = false
    for event in InputMap.action_get_events("p1_jump"):
        if event is InputEventJoypadButton and event.device == 8 and event.button_index == JOY_BUTTON_LEFT_SHOULDER:
            found = true
    check(found, "preserve gamepad choice after device reassignment")
    menu._restore_defaults()
    check(key_for("p1_left") == KEY_A and menu.pad_overrides.is_empty(), "restore defaults")
    if existed:
        var saved = FileAccess.open(path, FileAccess.WRITE)
        saved.store_buffer(original)
        saved.close()
    else:
        DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
    print("Controls checks: ", "passed" if failures == 0 else "failed")
    quit(1 if failures else 0)
