extends SceneTree
var failures := 0
func _initialize() -> void:
    call_deferred("run_checks")
func check(ok: bool, label: String) -> void:
    if ok: print("PASS: ", label)
    else:
        failures += 1
        push_error("FAIL: " + label)
func run_checks() -> void:
    var level = load("res://scenes/Main.tscn").instantiate()
    root.add_child(level)
    current_scene = level
    await create_timer(0.2).timeout
    var hero = level.p1
    var enemy = level.get_node("Enemies/Thornling")
    hero.position = enemy.position + Vector2(-45, 0)
    hero.health = 3
    await create_timer(0.3).timeout
    check(hero.health == 2, "monster contact reduces player health")
    check(hero.sprite.animation == "hurt", "damage plays hurt animation")
    check(level.get_node("UI/HUD/Player1Health").value == 2, "health bar reflects damage")
    enemy.set_physics_process(false)
    hero.hurt_wait = 0
    hero.hurt()
    hero.hurt_wait = 0
    hero.hurt()
    await process_frame
    check(hero.health == 0 and hero.sprite.animation == "death", "zero health plays death animation")
    await create_timer(0.2).timeout
    check(level.finished and not level.finale.visible, "death animation remains visible before game over")
    await create_timer(0.9).timeout
    check(level.finale.visible and level.get_node("UI/HUD/Player1Health").value == 0, "game over follows death animation and health bar is empty")
    # Allow the short game-over cue to finish before the headless test exits.
    await create_timer(0.4).timeout
    print("Health and animation checks: ", "passed" if failures == 0 else "failed")
    quit(1 if failures else 0)
