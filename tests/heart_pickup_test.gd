extends SceneTree
var failures := 0
func _initialize() -> void:
    call_deferred("run_checks")
func check(ok: bool, description: String) -> void:
    if ok: print("PASS: ", description)
    else:
        failures += 1
        push_error("FAIL: " + description)
func run_checks() -> void:
    var level = load("res://scenes/Main.tscn").instantiate()
    root.add_child(level)
    current_scene = level
    await create_timer(0.2).timeout
    var hearts = []
    for item in level.get_node("Pickups").get_children():
        if item.kind == "heart": hearts.append(item)
    check(hearts.size() >= 3, "three visible heart pickups are placed along the level")
    if hearts.is_empty():
        quit(1)
        return
    var hero = level.p1
    var heart = hearts[0]
    var game = root.get_node("Game")
    game.achievements["heart_restored"] = true
    hero.health = 3
    hero.position = heart.position
    await create_timer(0.2).timeout
    check(is_instance_valid(heart) and not heart.is_queued_for_deletion(), "full-health player does not consume a heart")
    hero.position = heart.position + Vector2(-100, 0)
    await create_timer(0.2).timeout
    hero.health = 2
    hero.position = heart.position
    await create_timer(0.2).timeout
    check(hero.health == 3, "touching a heart restores missing health")
    check(not is_instance_valid(heart) or heart.is_queued_for_deletion(), "heart disappears after healing")
    check(level.get_node("UI/HUD/Player1Health").value == 3, "health bar updates after healing")
    print("Heart pickup checks: ", "passed" if failures == 0 else "failed")
    quit(1 if failures else 0)
