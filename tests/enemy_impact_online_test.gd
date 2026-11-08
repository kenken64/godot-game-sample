extends SceneTree
func _initialize() -> void:
    call_deferred("run_checks")
func fail(message: String) -> void:
    push_error(message)
    quit(1)
func run_checks() -> void:
    var host = OS.get_cmdline_user_args().has("host")
    var level = load("res://scenes/Main.tscn").instantiate()
    root.add_child(level)
    current_scene = level
    var online = level.get_node("Online")
    online.relay_url = OS.get_environment("FORGE_TEST_RELAY_URL")
    await create_timer(0.2).timeout
    if host:
        online.host_room()
        for i in range(100):
            if online.code != "": break
            await create_timer(0.1).timeout
        if online.code == "":
            fail("Host failed to open a room")
            return
        var file = FileAccess.open(OS.get_environment("FORGE_TEST_ROOM_FILE"), FileAccess.WRITE)
        file.store_string(online.code)
        file.close()
        for i in range(100):
            if level.p2.remote_controlled: break
            await create_timer(0.1).timeout
        if not level.p2.remote_controlled:
            fail("Guest did not join")
            return
        await create_timer(0.7).timeout
        var enemy = level.get_node("Enemies/Thornling")
        enemy.hit(1, enemy.global_position.x - 100.0)
        print("PASS: host applied enemy hit")
        await create_timer(0.6).timeout
        enemy.hit(1, enemy.global_position.x - 100.0)
        await create_timer(1.0).timeout
    else:
        var code = ""
        for i in range(120):
            if FileAccess.file_exists(OS.get_environment("FORGE_TEST_ROOM_FILE")):
                code = FileAccess.get_file_as_string(OS.get_environment("FORGE_TEST_ROOM_FILE"))
                break
            await create_timer(0.1).timeout
        online.join_room(code)
        var saw_damage := false
        var saw_red := false
        var saw_number := false
        for i in range(150):
            var enemy = level.get_node_or_null("Enemies/Thornling")
            if enemy:
                saw_damage = saw_damage or enemy.health_points == 1
                saw_red = saw_red or enemy.sprite.self_modulate.g < 0.3
            for child in level.get_children():
                if child is Label and child.name.begins_with("DamageNumber") and child.text == "1":
                    saw_number = true
            if saw_damage and saw_red and saw_number: break
            await create_timer(0.03).timeout
        if not saw_damage or not saw_red or not saw_number:
            fail("Guest missed the enemy damage, red flash or damage number: %s %s %s" % [saw_damage, saw_red, saw_number])
            return
        print("PASS: guest saw enemy damage, red flash, and damage number")
        var saw_lethal_flash := false
        var removed := false
        for i in range(100):
            var enemy = level.get_node_or_null("Enemies/Thornling")
            if not enemy:
                removed = true
                break
            if enemy.health_points <= 0 and enemy.sprite.self_modulate.g < 0.3:
                saw_lethal_flash = true
            await create_timer(0.03).timeout
        if not saw_lethal_flash or not removed:
            fail("Guest missed lethal hit flash or enemy removal")
            return
        print("PASS: guest saw lethal hit flash and enemy removal")
    quit(0)
