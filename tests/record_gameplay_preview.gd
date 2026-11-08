extends SceneTree

func _initialize() -> void:
    call_deferred("record")

func record() -> void:
    var level = load("res://scenes/Main.tscn").instantiate()
    root.add_child(level)
    current_scene = level
    await create_timer(0.5).timeout
    var hero = level.p1
    hero.remote_controlled = true
    hero.remote_axis = 1.0
    var enemy = level.get_node("Enemies/Thornling")
    enemy.set_physics_process(false)
    enemy.global_position = Vector2(535, hero.global_position.y)
    enemy.health_points = 2
    enemy.attack_wait = 100.0
    level.exit_area.global_position.x = 1050.0
    var output_dir := OS.get_temp_dir().path_join("tsg-game-preview")
    DirAccess.make_dir_recursive_absolute(output_dir)
    var attacked := false
    var enemy_released := false
    for frame in range(84):
        await process_frame
        if not attacked and hero.global_position.x > 465.0:
            hero.remote_attack = true
            attacked = true
        if attacked and not enemy_released and enemy.health_points < 2:
            enemy.set_physics_process(true)
            enemy_released = true
        if enemy_released and is_instance_valid(enemy) and not enemy.defeated and hero.attack_wait <= 0.0 and absf(enemy.global_position.x - hero.global_position.x) < 75.0:
            hero.remote_attack = true
        if level.finished:
            hero.remote_axis = 0.0
        await RenderingServer.frame_post_draw
        var image := root.get_texture().get_image()
        image.resize(720, 405, Image.INTERPOLATE_BILINEAR)
        image.save_png(output_dir.path_join("preview_%03d.png" % frame))
    print("Saved preview frames to ", output_dir, ". Frames: 84; attack: ", attacked, "; enemy hit: ", enemy_released, "; portal reached: ", level.finished)
    quit()
