extends SceneTree
func _initialize() -> void:
    call_deferred("capture")
func capture() -> void:
    var scene = load("res://scenes/StartMenu.tscn").instantiate()
    root.add_child(scene)
    current_scene = scene
    await process_frame
    var menu = scene.get_node("UI/AdventureMenu")
    var which = OS.get_cmdline_user_args()
    if which.has("audio"):
        menu._audio()
    elif which.has("controls"):
        menu._controls()
    await create_timer(0.6).timeout
    var suffix = "audio" if which.has("audio") else ("controls" if which.has("controls") else "home")
    root.get_texture().get_image().save_png("/tmp/tsg-settings-" + suffix + ".png")
    quit()
