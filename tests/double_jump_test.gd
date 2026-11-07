extends SceneTree
var failures := 0
func _initialize() -> void:
    call_deferred("run_checks")
func check(ok: bool, message: String) -> void:
    if ok: print("PASS: ", message)
    else:
        failures += 1
        push_error("FAIL: " + message)
func press_jump() -> void:
    var event = InputEventAction.new()
    event.action = "p1_jump"
    event.pressed = true
    Input.parse_input_event(event)
func release_jump() -> void:
    var event = InputEventAction.new()
    event.action = "p1_jump"
    event.pressed = false
    Input.parse_input_event(event)
func run_checks() -> void:
    var level = load("res://scenes/Main.tscn").instantiate()
    root.add_child(level)
    current_scene = level
    await create_timer(0.2).timeout
    var hero = level.p1
    var floor_y = hero.position.y
    check(hero.is_on_floor(), "player starts on the floor")
    press_jump()
    await create_timer(0.1).timeout
    release_jump()
    check(hero.position.y < floor_y and hero.jumps_used == 1, "first jump launches from the floor")
    await create_timer(0.1).timeout
    var before = hero.velocity.y
    press_jump()
    await create_timer(0.05).timeout
    release_jump()
    check(hero.jumps_used == 2 and hero.velocity.y < before - 30, "second press triggers an airborne jump")
    await create_timer(0.1).timeout
    before = hero.velocity.y
    press_jump()
    await create_timer(0.05).timeout
    release_jump()
    check(hero.jumps_used == 2 and hero.velocity.y > before, "third press does not add another jump")
    await create_timer(1.5).timeout
    check(hero.is_on_floor() and hero.jumps_used == 0, "landing restores both jumps")
    press_jump()
    await create_timer(0.1).timeout
    release_jump()
    check(hero.jumps_used == 1 and not hero.is_on_floor(), "can jump again after landing")
    print("Double-jump checks: ", "passed" if failures == 0 else "failed")
    quit(1 if failures else 0)
