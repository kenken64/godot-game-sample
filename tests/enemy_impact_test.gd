extends SceneTree
func _initialize() -> void:
    call_deferred("run_checks")
func check(ok: bool, message: String) -> void:
    if not ok:
        push_error("FAIL: " + message)
        quit(1)
        assert(ok, message)
    print("PASS: " + message)
func damage_labels(level: Node) -> Array:
    var result := []
    for child in level.get_children():
        if child is Label and child.name.begins_with("DamageNumber"):
            result.append(child)
    return result
func run_checks() -> void:
    var level = load("res://scenes/Main.tscn").instantiate()
    root.add_child(level)
    current_scene = level
    var game = root.get_node("Game")
    await create_timer(0.2).timeout
    var enemy = level.get_node("Enemies/Thornling")
    enemy.set_physics_process(false)
    enemy.global_position = level.p1.global_position + Vector2(60, 0)
    enemy.health_points = 5
    enemy.speed = 0.0
    enemy.attack_wait = 100.0
    game.attack_bonus = 1
    level.p1.facing = 1
    var attack := InputEventAction.new()
    attack.action = "p1_attack"
    attack.pressed = true
    Input.parse_input_event(attack)
    await create_timer(0.05).timeout
    attack.pressed = false
    Input.parse_input_event(attack)
    check(enemy.health_points == 3, "player attack deals the upgraded amount")
    check(enemy.sprite.self_modulate.g < 0.3, "enemy flashes red after damage")
    check(enemy.knockback_velocity > 0.0 and enemy.velocity.y < 0.0, "enemy is knocked away and upward")
    var labels = damage_labels(level)
    check(labels.size() == 1 and labels[0].text == "2", "floating damage number shows actual damage")
    enemy.set_physics_process(true)
    var initial_x = enemy.global_position.x
    var initial_y = labels[0].global_position.y
    await create_timer(0.12).timeout
    check(enemy.global_position.x > initial_x + 5.0, "knockback moves enemy away from the player")
    check(labels[0].global_position.y < initial_y, "damage number floats upward")
    await create_timer(0.25).timeout
    check(enemy.sprite.self_modulate == enemy.base_tint, "enemy returns to its original color")
    enemy.hit(1, enemy.global_position.x + 100.0)
    check(enemy.knockback_velocity < 0.0, "enemy is knocked left when attacked from the right")
    await create_timer(0.3).timeout
    enemy.hit(20, enemy.global_position.x - 100.0)
    check(enemy.defeated and enemy.sprite.self_modulate.g < 0.3, "lethal hits still flash before removal")
    var score_after_kill = game.score
    enemy.hit(20, enemy.global_position.x - 100.0)
    check(game.score == score_after_kill, "repeated damage cannot award defeat twice")
    await create_timer(0.35).timeout
    check(not is_instance_valid(enemy), "defeated enemy disappears after the hit flash")
    await create_timer(0.6).timeout
    check(damage_labels(level).is_empty(), "floating damage numbers clean themselves up")
    print("All enemy impact checks passed.")
    quit(0)
