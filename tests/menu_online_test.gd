extends SceneTree

func _initialize() -> void:
    call_deferred("run_checks")

func fail(message: String) -> void:
    push_error(message)
    quit(1)

func run_checks() -> void:
    var host = OS.get_cmdline_user_args().has("host")
    var start = load("res://scenes/StartMenu.tscn").instantiate()
    root.add_child(start)
    current_scene = start
    await process_frame
    var menu = start.get_node("UI/AdventureMenu")
    menu._multiplayer()
    menu.relay_field.text = OS.get_environment("FORGE_TEST_RELAY_URL")
    if host:
        menu._host()
    else:
        var code = ""
        for i in range(150):
            if FileAccess.file_exists(OS.get_environment("FORGE_TEST_ROOM_FILE")):
                code = FileAccess.get_file_as_string(OS.get_environment("FORGE_TEST_ROOM_FILE"))
                break
            await create_timer(0.1).timeout
        if code.is_empty():
            fail("Host did not publish a code")
            return
        menu.room_field.text = code
        menu._join()
    await create_timer(0.2).timeout
    var level = current_scene
    if level.scene_file_path != "res://scenes/Main.tscn":
        fail("Menu did not start the level")
        return
    var online = level.get_node("Online")
    for i in range(100):
        if online.code != "": break
        await create_timer(0.1).timeout
    if online.code == "":
        fail("Room did not connect: " + online.connection_status)
        return
    if host:
        var file = FileAccess.open(OS.get_environment("FORGE_TEST_ROOM_FILE"), FileAccess.WRITE)
        file.store_string(online.code)
        file.close()
        for i in range(100):
            if level.p2.remote_controlled: break
            await create_timer(0.1).timeout
        if not level.p2.remote_controlled:
            fail("Guest did not join the host")
            return
        print("PASS: menu hosted a room and received guest")
        level._on_exit(level.p1)
        await create_timer(1.0).timeout
    else:
        for i in range(100):
            if level.finished: break
            await create_timer(0.1).timeout
        if not level.finished or not level.finale.visible:
            fail("Guest did not receive the host's portal victory")
            return
        print("PASS: menu joined room and saw portal victory")
    quit(0)
