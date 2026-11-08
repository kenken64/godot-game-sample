extends SceneTree
func _initialize() -> void:
    call_deferred("capture")
func capture() -> void:
    var game_view = OS.get_cmdline_user_args().has("hud")
    var scene = load("res://scenes/Main.tscn" if game_view else "res://scenes/StartMenu.tscn").instantiate()
    root.add_child(scene)
    current_scene = scene
    if OS.get_cmdline_user_args().has("multiplayer"):
        scene.get_node("UI/AdventureMenu")._multiplayer()
    await create_timer(1.3).timeout
    var suffix = "hud" if game_view else ("multiplayer" if OS.get_cmdline_user_args().has("multiplayer") else "menu")
    root.get_texture().get_image().save_png("/tmp/forge-" + suffix + ".png")
    quit()
