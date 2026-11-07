extends SceneTree

func _initialize() -> void:
    call_deferred("run_checks")

func run_checks() -> void:
    var host = OS.get_cmdline_user_args().has("host")
    var level = load("res://scenes/Main.tscn").instantiate()
    root.add_child(level)
    current_scene = level
    var online = level.get_node("Online")
    var test_relay = OS.get_environment("FORGE_TEST_RELAY_URL")
    if not test_relay.is_empty(): online.relay_url = test_relay
    var game = root.get_node("Game")
    await create_timer(0.2).timeout
    if host:
        game.coins = 17
        online.host_room()
        for i in range(100):
            if online.code != "": break
            await create_timer(0.1).timeout
        if online.code == "":
            push_error("Host failed to create a room")
            quit(1)
            return
        var file = FileAccess.open(OS.get_environment("FORGE_TEST_ROOM_FILE"), FileAccess.WRITE)
        file.store_string(online.code)
        file.close()
        for i in range(100):
            if level.p2.remote_controlled: break
            await create_timer(0.1).timeout
        var x = level.p2.position.x
        level.p1.hurt()
        var saw_double_jump = false
        for i in range(120):
            saw_double_jump = saw_double_jump or level.p2.jumps_used == 2
            if saw_double_jump and level.p2.crouching and level.p2.position.x >= x + 80: break
            await create_timer(0.05).timeout
        if not level.p2.remote_controlled or level.p2.position.x < x + 80:
            push_error("Host did not receive guest movement")
            quit(1)
            return
        print("PASS: host received guest movement")
        if not saw_double_jump:
            push_error("Host did not receive guest double jump")
            quit(1)
            return
        print("PASS: host received guest double jump")
        if not level.p2.crouching:
            push_error("Host did not receive guest crouch")
            quit(1)
            return
        print("PASS: host received guest crouch")
        level.p1.health = 1
        level.p1.hurt_wait = 0
        level.p1.hurt()
        level.p2.health = 1
        level.p2.hurt_wait = 0
        level.p2.hurt()
        await create_timer(1.5).timeout
    else:
        var code = ""
        for i in range(100):
            if FileAccess.file_exists(OS.get_environment("FORGE_TEST_ROOM_FILE")):
                code = FileAccess.get_file_as_string(OS.get_environment("FORGE_TEST_ROOM_FILE"))
                break
            await create_timer(0.1).timeout
        online.join_room(code)
        for i in range(100):
            if online.is_client and game.coins == 17 and level.p2.active: break
            await create_timer(0.1).timeout
        if not online.is_client or game.coins != 17 or not level.p2.active:
            push_error("Guest did not receive the host state")
            quit(1)
            return
        print("PASS: guest joined and received host state")
        for i in range(20):
            if level.p1.health == 2 and level.p1.sprite.animation == "hurt": break
            await create_timer(0.05).timeout
        if level.p1.health != 2 or level.p1.sprite.animation != "hurt":
            push_error("Guest did not see the host hurt animation")
            quit(1)
            return
        print("PASS: guest received health and hurt animation")
        Input.action_press("p1_right")
        await create_timer(1.5).timeout
        Input.action_release("p1_right")
        var jump = InputEventAction.new()
        jump.action = "p1_jump"
        jump.pressed = true
        Input.parse_input_event(jump)
        await create_timer(0.1).timeout
        jump.pressed = false
        Input.parse_input_event(jump)
        await create_timer(0.1).timeout
        jump.pressed = true
        Input.parse_input_event(jump)
        await create_timer(0.1).timeout
        jump.pressed = false
        Input.parse_input_event(jump)
        Input.action_press("p1_crouch")
        for i in range(120):
            if level.game_over: break
            await create_timer(0.05).timeout
        Input.action_release("p1_crouch")
        if not level.game_over or level.p1.sprite.animation != "death":
            push_error("Guest did not see the game-over death animation")
            quit(1)
            return
        await create_timer(1.0).timeout
        if not level.finale.visible or not level.get_node("UI/Finale/Result").text.begins_with("Game over"):
            push_error("Guest did not see the game-over panel")
            quit(1)
            return
        print("PASS: guest received death animation and game over")
    quit(0)
