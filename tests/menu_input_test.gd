extends SceneTree
func _initialize() -> void:
    call_deferred("run_checks")
func tap_escape() -> void:
    var event := InputEventKey.new()
    event.keycode = KEY_ESCAPE
    event.physical_keycode = KEY_ESCAPE
    event.pressed = true
    Input.parse_input_event(event)
    await process_frame
    event.pressed = false
    Input.parse_input_event(event)
    await process_frame
func run_checks() -> void:
    var level = load("res://scenes/Main.tscn").instantiate()
    root.add_child(level)
    current_scene = level
    await process_frame
    await tap_escape()
    if not paused or not level.get_node("UI/AdventureMenu").visible:
        push_error("Escape did not open pause menu")
        quit(1)
        return
    await tap_escape()
    if paused or level.get_node("UI/AdventureMenu").visible:
        push_error("Escape did not resume")
        quit(1)
        return
    print("PASS: Escape opens and closes pause menu")
    quit(0)
