extends SceneTree
var failures := 0
func _initialize() -> void:
    call_deferred("run_checks")
func check(ok: bool, message: String) -> void:
    if ok: print("PASS: ", message)
    else:
        failures += 1
        push_error("FAIL: " + message)
func bound_to(action: String, code: int) -> bool:
    for event in InputMap.action_get_events(action):
        if event is InputEventKey and event.physical_keycode == code:
            return true
    return false
func run_checks() -> void:
    var level = load("res://scenes/Main.tscn").instantiate()
    root.add_child(level)
    current_scene = level
    await create_timer(0.2).timeout
    var hero = level.p1
    check(bound_to("p1_jump", KEY_W) and bound_to("p1_attack", KEY_SPACE) and bound_to("p1_roll", KEY_E) and bound_to("p1_crouch", KEY_S) and bound_to("p1_interact", KEY_F), "requested keyboard defaults")
    var standing = hero.hitbox.shape.size.y
    Input.action_press("p1_crouch")
    await create_timer(0.2).timeout
    check(hero.crouching and hero.hitbox.shape.size.y < standing and hero.sprite.animation == "crouch", "crouching changes the pose and collision height")
    var ceiling = StaticBody2D.new()
    var collider = CollisionShape2D.new()
    var shape = RectangleShape2D.new()
    shape.size = Vector2(100, 8)
    collider.shape = shape
    ceiling.add_child(collider)
    level.add_child(ceiling)
    ceiling.position = hero.position + Vector2(0, -70)
    await create_timer(0.1).timeout
    Input.action_release("p1_crouch")
    await create_timer(0.2).timeout
    check(hero.crouching, "stay crouched under a low ceiling")
    ceiling.queue_free()
    await create_timer(0.2).timeout
    check(not hero.crouching and is_equal_approx(hero.hitbox.shape.size.y, standing), "stand after the ceiling clears")
    var menu = level.get_node("UI/ControlsMenu")
    check(menu.key_buttons.has("p1_crouch") and menu.pad_buttons.has("p1_crouch"), "crouch appears in the remapping menu")
    print("Crouch checks: ", "passed" if failures == 0 else "failed")
    quit(1 if failures else 0)
