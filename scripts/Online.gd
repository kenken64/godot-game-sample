extends Node

@export var relay_url := "ws://127.0.0.1:3000/ws/final-game"
var socket := WebSocketPeer.new()
var code := ""
var is_client := false
var is_host := false
var pending := ""
var join_code := ""
var sent := false
var tick := 0.0
var last_ending := ""
var last_splash := false
var connection_status := ""
@onready var level = get_parent()

func host_room() -> void:
    _connect("host", "")

func join_room(room_code: String) -> void:
    _connect("join", room_code.strip_edges().to_upper())

func _connect(role: String, room_code: String) -> void:
    if socket.get_ready_state() == WebSocketPeer.STATE_OPEN:
        socket.close()
    socket = WebSocketPeer.new()
    pending = role
    join_code = room_code
    code = ""
    is_host = false
    is_client = false
    sent = false
    connection_status = "Connecting…"
    var error := socket.connect_to_url(relay_url)
    if error != OK:
        connection_status = "Could not connect to the relay."
        pending = ""

func _process(delta: float) -> void:
    socket.poll()
    if socket.get_ready_state() != WebSocketPeer.STATE_OPEN:
        if socket.get_ready_state() == WebSocketPeer.STATE_CLOSED and not pending.is_empty():
            connection_status = "Connection closed. Check the relay or room."
            pending = ""
        return
    if not sent:
        _send({"type": pending, "code": join_code})
        sent = true
    while socket.get_available_packet_count() > 0:
        var message = JSON.parse_string(socket.get_packet().get_string_from_utf8())
        if message is Dictionary:
            _receive(message)
    # A peer-left message can close the socket while processing packets.
    if socket.get_ready_state() != WebSocketPeer.STATE_OPEN:
        return
    if is_client:
        _send({"type": "input", "axis": Input.get_axis("p1_left", "p1_right"),
            "jump": Input.is_action_just_pressed("p1_jump"),
            "roll": Input.is_action_just_pressed("p1_roll"),
            "crouch": Input.is_action_pressed("p1_crouch"),
            "attack": Input.is_action_just_pressed("p1_attack"),
            "interact": Input.is_action_just_pressed("p1_interact")})
    tick += delta
    if tick < 0.05:
        return
    tick = 0.0
    if is_host:
        _send({"type": "state", "p1": _player(level.p1), "p2": _player(level.p2),
            "coins": Game.coins, "collected": Game.collected, "score": Game.score,
            "materials": Game.materials, "gear": Game.inventory, "attack_bonus": Game.attack_bonus,
            "boss": Game.boss_defeated, "boss_data": _actor(level.get_node_or_null("Boss")),
            "ending": Game.ending, "finished": level.finished, "game_over": level.game_over,
            "shop_open": level.shop.get_overlapping_bodies().has(level.p2),
            "boulder": {"x": level.get_node("Boulder").global_position.x,
                "y": level.get_node("Boulder").global_position.y},
            "water_splashed": level.get_node("Water").splashed,
            "pickups": _remaining("Pickups"), "bonus": _bonus(),
            "enemies": _actors("Enemies")})

func _send(data: Dictionary) -> void:
    socket.send_text(JSON.stringify(data))

func send_trade(action: String) -> void:
    if is_client:
        _send({"type": "trade", "action": action})

func _player(hero) -> Dictionary:
    return {"x": hero.global_position.x, "y": hero.global_position.y,
        "health": hero.health, "active": hero.active,
        "animation": str(hero.sprite.animation), "flip_h": hero.sprite.flip_h, "crouched": hero.crouching}

func _remaining(parent_name: String) -> Array:
    var names := []
    for child in level.get_node(parent_name).get_children():
        names.append(child.name)
    return names

func _actor(actor) -> Dictionary:
    if not is_instance_valid(actor):
        return {}
    return {"x": actor.global_position.x, "y": actor.global_position.y,
        "hp": actor.health_points, "hit_flash": actor.hit_flash_time > 0.0}

func _actors(parent_name: String) -> Dictionary:
    var result := {}
    for actor in level.get_node(parent_name).get_children():
        result[actor.name] = _actor(actor)
    return result

func _bonus() -> Dictionary:
    var result := {}
    for item in level.get_node("BonusPickups").get_children():
        result[item.name] = {"x": item.global_position.x,
            "y": item.global_position.y, "kind": item.kind}
    return result

func _receive(message: Dictionary) -> void:
    match message.get("type", ""):
        "joined":
            code = str(message.get("code", ""))
            connection_status = "ROOM  " + code
            is_host = pending == "host"
            is_client = pending == "join"
            if is_client:
                level.p1.set_physics_process(false)
                level.p2.set_physics_process(false)
                level.get_node("Spawner").set_process(false)
                level.get_node("Spawner/Timer").stop()
                level.get_node("Boulder").freeze = true
                level.get_node("Water").monitoring = false
                for enemy in level.get_tree().get_nodes_in_group("damageable"):
                    enemy.set_physics_process(false)
                for parent_name in ["Pickups", "Hazards"]:
                    for area in level.get_node(parent_name).get_children():
                        area.monitoring = false
                level.shop.monitoring = false
                level.exit_area.monitoring = false
        "error":
            connection_status = str(message.get("message", "Could not join the room."))
            pending = ""
            socket.close()
        "peer_joined":
            level.p2.active = true
            level.p2.show()
            level.p2.remote_controlled = true
        "peer_left":
            if is_host:
                level.p2.remote_axis = 0.0
                level.p2.remote_jump = false
                level.p2.remote_roll = false
                level.p2.remote_crouch = false
                level.p2.remote_attack = false
                level.p2.remote_controlled = false
                level.p2.active = false
                level.p2.hide()
            elif is_client:
                level.finished = true
                level._show_result("The host left the room. Restart to play again.", false)
                socket.close()
        "input":
            if is_host:
                level.p2.remote_axis = clampf(float(message.get("axis", 0)), -1.0, 1.0)
                level.p2.remote_jump = level.p2.remote_jump or bool(message.get("jump", false))
                level.p2.remote_roll = level.p2.remote_roll or bool(message.get("roll", false))
                level.p2.remote_crouch = bool(message.get("crouch", false))
                level.p2.remote_attack = level.p2.remote_attack or bool(message.get("attack", false))
                if bool(message.get("interact", false)) and level.shop.get_overlapping_bodies().has(level.p2):
                    Game.buy_heal(level.p2)
        "trade":
            if is_host:
                level._trade(str(message.get("action", "")), level.p2)
        "state":
            if is_client:
                _apply_state(message)

func _apply_state(state: Dictionary) -> void:
    for key in ["p1", "p2"]:
        var hero = level.p1 if key == "p1" else level.p2
        var data = state.get(key, {})
        hero.global_position = Vector2(float(data.get("x", 0)), float(data.get("y", 0)))
        hero.health = int(data.get("health", 3))
        hero.active = bool(data.get("active", false))
        hero.visible = hero.active
        var animation = str(data.get("animation", "idle"))
        hero.sprite.flip_h = bool(data.get("flip_h", false))
        hero._apply_crouch_visual(bool(data.get("crouched", false)) and hero.health > 0)
        if hero.sprite.sprite_frames and hero.sprite.sprite_frames.has_animation(animation):
            hero.sprite.play(animation)
    Game.coins = int(state.get("coins", 0))
    Game.collected = int(state.get("collected", 0))
    Game.score = int(state.get("score", 0))
    Game.materials = int(state.get("materials", 0))
    Game.inventory.assign(state.get("gear", []))
    Game.attack_bonus = int(state.get("attack_bonus", 0))
    Game.boss_defeated = bool(state.get("boss", false))
    Game.ending = str(state.get("ending", ""))
    level.get_node("UI/HUD/ShopPanel").visible = bool(state.get("shop_open", false))
    var boulder_data = state.get("boulder", {})
    level.get_node("Boulder").global_position = Vector2(float(boulder_data.get("x", 0)), float(boulder_data.get("y", 0)))
    if bool(state.get("water_splashed", false)) and not last_splash:
        last_splash = true
        var splash = preload("res://scenes/Splash.tscn").instantiate()
        level.add_child(splash)
        splash.global_position = level.get_node("Boulder").global_position
    _remove_missing("Pickups", state.get("pickups", []))
    _sync_bonus(state.get("bonus", {}))
    _sync_actors("Enemies", state.get("enemies", {}))
    _sync_actor(level.get_node_or_null("Boss"), state.get("boss_data", {}))
    if Game.ending != "" and Game.ending != last_ending:
        last_ending = Game.ending
        level.finished = true
        level._show_result("Host chose to %s the relic." % Game.ending, false, true)
    elif bool(state.get("finished", false)) and not level.finished:
        level.finished = true
        if bool(state.get("game_over", false)):
            level.game_over = true
            level._game_over_after_animation()
        else:
            level._show_result("Host reached the relic. Waiting for their choice…", false, true)

func _remove_missing(parent_name: String, names: Array) -> void:
    for child in level.get_node(parent_name).get_children():
        if not names.has(child.name):
            child.queue_free()

func _sync_bonus(items: Dictionary) -> void:
    var parent = level.get_node("BonusPickups")
    for child in parent.get_children():
        if not items.has(child.name):
            child.queue_free()
    for item_name in items:
        var item = parent.get_node_or_null(item_name)
        if item == null:
            item = preload("res://scenes/Pickup.tscn").instantiate()
            item.name = item_name
            parent.add_child(item)
            item.monitoring = false
        var data = items[item_name]
        item.kind = str(data.get("kind", "coin"))
        item.global_position = Vector2(float(data.get("x", 0)), float(data.get("y", 0)))

func _sync_actors(parent_name: String, actors: Dictionary) -> void:
    for actor in level.get_node(parent_name).get_children():
        _sync_actor(actor, actors.get(actor.name, {}))

func _sync_actor(actor, data: Dictionary) -> void:
    if not is_instance_valid(actor):
        return
    if data.is_empty():
        actor.queue_free()
        return
    actor.global_position = Vector2(float(data.get("x", 0)), float(data.get("y", 0)))
    var hp := int(data.get("hp", 1))
    if actor.has_meta("received_health") and hp < actor.health_points:
        actor._show_damage_number(actor.health_points - hp)
        Game.play_sound("enemy_hit")
    actor.set_meta("received_health", true)
    actor.health_points = hp
    actor._set_hit_flash(bool(data.get("hit_flash", false)))
