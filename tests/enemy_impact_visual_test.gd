extends SceneTree
func _initialize() -> void:
    call_deferred("capture")
func capture() -> void:
    var level = load("res://scenes/Main.tscn").instantiate()
    root.add_child(level)
    current_scene = level
    await create_timer(0.4).timeout
    var enemy = level.get_node("Enemies/Thornling")
    enemy.set_physics_process(false)
    enemy.global_position = level.p1.global_position + Vector2(135, 0)
    enemy.hit(2, level.p1.global_position.x)
    await create_timer(0.12).timeout
    root.get_texture().get_image().save_png("/tmp/forge-enemy-impact.png")
    quit()
