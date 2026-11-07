extends SceneTree
var failures := 0
func _initialize() -> void:
    call_deferred("run_checks")
func check(ok: bool, message: String) -> void:
    if ok: print("PASS: ", message)
    else:
        failures += 1
        push_error("FAIL: " + message)
func run_checks() -> void:
    var level = load("res://scenes/Main.tscn").instantiate()
    root.add_child(level)
    current_scene = level
    var water = level.get_node("Water")
    var rock = level.get_node("Boulder")
    var shop = level.get_node("Shop")
    check(absf(shop.position.x - water.position.x) >= 500, "pool is separated from the shop")
    check(level.has_node("Terrain/UnderPoolSoil") and level.has_node("Terrain/Ground/PoolBottomCollision"), "pool has soil beneath and a recessed collision floor")
    check(level.has_node("Hazards/Thorns/SpikeArtwork"), "spike uses the generated artwork")
    var hero = level.p1
    hero.position = Vector2(1300, 575)
    await create_timer(0.2).timeout
    Input.action_press("p1_right")
    await create_timer(0.5).timeout
    Input.action_release("p1_right")
    check(hero.health < 3, "walking into spikes causes damage")
    hero.position = Vector2(1600, 575)
    await create_timer(2.5).timeout
    check(water.splashed and rock.position.y > 580 and rock.position.y < 643, "boulder splashes and settles below ground level")
    hero.health = 3
    hero.hurt_wait = 0
    hero.position = Vector2(2050, 640)
    await create_timer(0.3).timeout
    check(hero.is_on_floor() and hero.position.y > 600, "player can stand on the pool floor")
    Input.action_press("p1_right")
    var jump = InputEventAction.new()
    jump.action = "p1_jump"
    jump.pressed = true
    Input.parse_input_event(jump)
    await create_timer(0.1).timeout
    jump.pressed = false
    Input.parse_input_event(jump)
    await create_timer(0.55).timeout
    Input.action_release("p1_right")
    check(hero.position.x > 2120 and hero.position.y <= 585, "player can jump out of the pool")
    print("Forest hazard checks: ", "passed" if failures == 0 else "failed")
    quit(1 if failures else 0)
