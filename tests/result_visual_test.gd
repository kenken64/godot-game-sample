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
    if OS.get_cmdline_user_args().has("gameover"):
        level.finished = true
        level.game_over = true
        level._game_over_after_animation()
    else:
        level._on_exit(level.p1)
    await create_timer(1.6).timeout
    var suffix = "gameover" if level.game_over else "victory"
    root.get_texture().get_image().save_png("/tmp/forge-result-" + suffix + ".png")
    quit()
