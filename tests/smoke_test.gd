extends SceneTree

func _initialize() -> void:
    call_deferred("run_checks")

func check(ok: bool, description: String) -> void:
    if not ok:
        push_error("FAIL: " + description)
        quit(1)
        assert(ok, description)
    print("PASS: " + description)

func run_checks() -> void:
    var level = load("res://scenes/Main.tscn").instantiate()
    root.add_child(level)
    current_scene = level
    var game = root.get_node("Game")
    await create_timer(0.2).timeout
    var p1 = level.get_node("Player1")
    var start_x = p1.position.x
    Input.action_press("p1_right")
    await create_timer(1.5).timeout
    Input.action_release("p1_right")
    check(p1.position.x > start_x + 150, "keyboard movement")
    check(game.collected > 0, "collect a coin through collision")
    var join_event = InputEventAction.new()
    join_event.action = "toggle_coop"
    join_event.pressed = true
    Input.parse_input_event(join_event)
    await create_timer(0.1).timeout
    join_event.pressed = false
    Input.parse_input_event(join_event)
    await create_timer(0.1).timeout
    check(level.p2.active and level.p2.visible, "activate local player two")
    var heart = load("res://scenes/Pickup.tscn").instantiate()
    heart.kind = "heart"
    level.get_node("BonusPickups").add_child(heart)
    check(heart.get_node("Sprite2D").texture == heart.heart_texture, "show heart art for a spawned health pickup")
    heart.queue_free()
    p1.position = level.shop.position + Vector2(0, 45)
    await create_timer(0.2).timeout
    game.coins = 10
    level._trade("buy", p1)
    check(game.attack_bonus == 1 and game.coins == 2, "buy gear while at the shop")
    level._trade("sell", p1)
    check(game.attack_bonus == 0 and game.coins == 6, "sell gear")
    var boss = level.get_node("Boss")
    boss.hit(8)
    await process_frame
    check(game.boss_defeated, "defeat the boss")
    game.collected = 20
    level._on_exit(p1)
    check(level.finished and level.get_node("UI/Finale").visible, "unlock the ending after 20 coins and boss")
    level._choose("return")
    check(game.ending == "return" and game.records.size() > 0, "choose ending and save a run")
    print("All sample checks passed.")
    quit(0)
