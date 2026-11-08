extends SceneTree

func _initialize() -> void:
    call_deferred("run_checks")

func run_checks() -> void:
    var level = load("res://scenes/Main.tscn").instantiate()
    root.add_child(level)
    current_scene = level
    await create_timer(0.2).timeout
    var game = root.get_node("Game")
    game.collected = 0
    game.boss_defeated = false
    level.p1.global_position = level.exit_area.global_position
    level.p1.velocity = Vector2.ZERO
    for i in range(40):
        if level.finished: break
        await physics_frame
    if not level.finished or not level.finale.visible:
        push_error("Portal collision did not trigger victory")
        quit(1)
        return
    print("PASS: entering portal physically ends level without coins or enemy defeats")
    quit(0)
