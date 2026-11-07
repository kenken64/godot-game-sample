extends SceneTree

func _initialize() -> void:
    call_deferred("capture")

func capture() -> void:
    var level = load("res://scenes/Main.tscn").instantiate()
    root.add_child(level)
    current_scene = level
    await create_timer(0.4).timeout
    var game = root.get_node("Game")
    game.collected = 20
    game.boss_defeated = true
    level._on_exit(level.p1)
    await create_timer(1.3).timeout
    root.get_texture().get_image().save_png("/tmp/forge-victory-screen.png")
    quit()
