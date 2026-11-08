extends SceneTree

func _initialize() -> void:
    call_deferred("run_checks")

func check(ok: bool, message: String) -> void:
    if not ok:
        push_error("FAIL: " + message)
        quit(1)
        assert(ok, message)
    print("PASS: " + message)

func run_checks() -> void:
    var level = load("res://scenes/Main.tscn").instantiate()
    root.add_child(level)
    current_scene = level
    var game = root.get_node("Game")
    await create_timer(0.2).timeout
    game.collected = 0
    game.boss_defeated = false
    level.p1.health = 0
    level._on_exit(level.p1)
    check(not level.finished and not level.finale.visible, "a defeated player cannot trigger the portal")
    level.p1.health = 3
    level._on_exit(level.p1)
    var art = level.get_node("UI/Finale/VictoryArt")
    var title = level.get_node("UI/Finale/VictoryTitle")
    var replay = level.get_node("UI/Finale/RestartButton")
    check(level.finished and level.finale.visible and art.visible and title.text == "LEVEL PASSED!", "victory displays generated art and title")
    check(replay.visible and level.get_node("UI/Finale/KeepButton").visible, "replay and optional ending choices are available")
    check(art.scale.x < 0.5, "victory crest starts small")
    await create_timer(0.9).timeout
    check(art.scale.distance_to(Vector2.ONE) < 0.05 and art.modulate.a > 0.99, "victory crest finishes its animation")
    replay.pressed.emit()
    await create_timer(0.2).timeout
    check(current_scene != level and not current_scene.finished and not current_scene.finale.visible and game.collected == 0, "Play Again starts a clean run")
    print("All victory checks passed.")
    quit(0)
