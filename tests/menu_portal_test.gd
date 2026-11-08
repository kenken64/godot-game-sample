extends SceneTree

func _initialize() -> void:
    call_deferred("run_checks")

func check(ok: bool, message: String) -> void:
    if not ok:
        push_error("FAIL: " + message)
        quit(1)
        assert(ok, message)
    print("PASS: " + message)

func run_checks() -> void:
    var start = load("res://scenes/StartMenu.tscn").instantiate()
    root.add_child(start)
    current_scene = start
    await process_frame
    var menu = start.get_node("UI/AdventureMenu")
    var controls = start.get_node("UI/ControlsMenu")
    check(menu.visible and not menu.is_game, "launch menu opens")
    menu._controls()
    check(controls.visible and not menu.visible, "open controls from launch menu")
    controls.close_menu()
    check(menu.visible and not paused, "return from controls to launch menu")
    menu._progress()
    check(menu.page == "progress", "open achievements and scores")
    menu._multiplayer()
    menu.room_field.text = "bad"
    menu._join()
    check(menu.status.text.contains("six-character"), "invalid room code is rejected")
    menu.relay_field.text = "invalid"
    menu._host()
    check(menu.status.text.contains("ws://"), "invalid relay address is rejected")
    menu._home()
    menu._start_solo()
    await create_timer(0.3).timeout
    var level = current_scene
    check(level.scene_file_path == "res://scenes/Main.tscn", "start adventure opens the level")
    menu = level.get_node("UI/AdventureMenu")
    menu.open_menu()
    check(paused and menu.visible, "in-game menu pauses play")
    menu._controls()
    controls = level.get_node("UI/ControlsMenu")
    check(controls.visible and not menu.visible, "open controls from paused game")
    controls.close_menu()
    check(menu.visible and paused, "close controls returns to paused menu")
    menu._resume()
    check(not paused and not menu.visible, "resume returns to play")
    var game = root.get_node("Game")
    game.collected = 0
    game.boss_defeated = false
    check(level.get_node("Enemies").get_child_count() > 0, "enemies are still alive for portal test")
    level._on_exit(level.p1)
    check(level.finished and level.finale.visible, "portal finishes with no coins, boss and enemies alive")
    print("All menu and portal checks passed.")
    quit(0)
