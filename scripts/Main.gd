extends Node2D

const GamepadBindings = preload("res://scripts/GamepadBindings.gd")
@onready var p1 = $Player1
@onready var p2 = $Player2
@onready var shop: Area2D = $Shop
@onready var exit_area: Area2D = $Exit
@onready var finale: Control = $UI/Finale
@onready var online = $Online
@onready var controls_menu = $UI/ControlsMenu
var finished := false
var game_over := false
var p1_pad := -2
var p2_pad := -2
var system_pad := -2

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    $UI.process_mode = Node.PROCESS_MODE_ALWAYS
    for branch in ["Pickups", "BonusPickups", "Spawner", "Hazards", "Water", "Boulder", "Enemies", "Boss", "Player1", "Player2", "Shop", "Exit", "Online"]:
        get_node(branch).process_mode = Node.PROCESS_MODE_PAUSABLE
    Game.start_run()
    $BonusPickups.add_to_group("loot_container")
    p2.active = false
    p2.hide()
    # The hidden second player must not block the first player.
    p1.add_collision_exception_with(p2)
    p2.add_collision_exception_with(p1)
    Input.joy_connection_changed.connect(_on_joy_connection_changed)
    _assign_gamepads()
    finale.hide()
    _setup_finale()
    $UI/HUD/ShopPanel.hide()
    exit_area.body_entered.connect(_on_exit)
    $UI/HUD/ControlsButton.pressed.connect(controls_menu.open_menu)
    $UI/HUD/Volume.min_value = 0.0
    $UI/HUD/Volume.max_value = 1.0
    $UI/HUD/Volume.step = 0.05
    $UI/HUD/Volume.value = 1.0
    $UI/HUD/Volume.value_changed.connect(_volume_changed)
    $UI/Finale/KeepButton.pressed.connect(func(): _choose("keep"))
    $UI/Finale/ReturnButton.pressed.connect(func(): _choose("return"))
    $UI/Finale/RestartButton.pressed.connect(_restart)
    $UI/HUD/HostButton.pressed.connect(online.host_room)
    $UI/HUD/JoinButton.pressed.connect(func(): online.join_room($UI/HUD/RoomCode.text))
    $UI/HUD/ShopPanel/BuyButton.pressed.connect(func(): _trade("buy"))
    $UI/HUD/ShopPanel/SellButton.pressed.connect(func(): _trade("sell"))
    $UI/HUD/ShopPanel/SalvageButton.pressed.connect(func(): _trade("salvage"))
    $UI/HUD/Story.text = "The forest relic is missing. Find it beyond the guardian."

func _process(_delta: float) -> void:
    _assign_gamepads()
    if controls_menu.visible:
        return
    if Input.is_action_just_pressed("pause"):
        controls_menu.open_menu()
        return
    if get_tree().paused:
        return
    if Input.is_action_just_pressed("restart"):
        _restart()
    if online.is_client:
        _update_hud()
        return
    if Input.is_action_just_pressed("toggle_coop") and not p2.active:
        p2.active = true
        p2.show()
        _assign_gamepads()
    if not finished:
        $UI/HUD/ShopPanel.visible = _shop_player() != null
        for body in shop.get_overlapping_bodies():
            if body == p1 and Input.is_action_just_pressed("p1_interact"):
                Game.buy_heal(p1)
            if body == p2 and p2.active and not p2.remote_controlled and Input.is_action_just_pressed("p2_interact"):
                Game.buy_heal(p2)
        if p1.health <= 0 and (not p2.active or p2.health <= 0):
            finished = true
            game_over = true
            _game_over_after_animation()
    _update_hud()

func _on_joy_connection_changed(_device: int, _connected: bool) -> void:
    _assign_gamepads()

func _assign_gamepads() -> void:
    var pads := Input.get_connected_joypads()
    var first := pads[0] if pads.size() > 0 else -1
    var second := pads[1] if pads.size() > 1 else -1
    var local_coop: bool = p2.active and not p2.remote_controlled and not online.is_client
    var next_p1 := second if local_coop else first
    var next_p2 := first if local_coop else -1
    if next_p1 != p1_pad:
        GamepadBindings.bind_player(1, next_p1)
        p1_pad = next_p1
    if next_p2 != p2_pad:
        GamepadBindings.bind_player(2, next_p2)
        p2_pad = next_p2
    if first != system_pad:
        GamepadBindings.bind_system(first)
        system_pad = first

func _update_hud() -> void:
    $UI/HUD/Stats.text = "Coins %d / 20  Wallet %d  Score %d  Materials %d  Blade %s" % [Game.collected, Game.coins, Game.score, Game.materials, "yes" if Game.attack_bonus > 0 else "no"]
    $UI/HUD/Player1Health.value = p1.health
    $UI/HUD/Player2Health.value = p2.health
    $UI/HUD/Player2Health.visible = p2.active
    $UI/HUD/Player2HealthLabel.visible = p2.active
    $UI/HUD/Hint.text = "Press jump twice for a double jump. Controls: change keys or gamepad. Boss: %s  Room: %s" % ["done" if Game.boss_defeated else "alive", online.code]
    $UI/HUD/Achievements.text = "Badges: " + ", ".join(Game.achievements.keys())
    var lines := []
    for record in Game.records:
        lines.append("%d (%s)" % [record["score"], record["ending"]])
    $UI/HUD/Leaderboard.text = "Top runs: " + ", ".join(lines)

func _shop_player():
    for body in shop.get_overlapping_bodies():
        if body.is_in_group("heroes") and body.active:
            return body
    return null

func _trade(action: String, player = null) -> void:
    if online.is_client:
        online.send_trade(action)
        return
    if player == null:
        player = _shop_player()
    if player == null or not shop.get_overlapping_bodies().has(player):
        return
    var success := false
    match action:
        "buy": success = Game.buy_gear()
        "sell": success = Game.sell_gear()
        "salvage": success = Game.salvage_gear()
    $UI/HUD/Story.text = "%s %s. Gear: %s. Materials: %d" % [action.capitalize(), "complete" if success else "unavailable", ", ".join(Game.inventory), Game.materials]

# Set up a consistent full-screen result overlay for victory and defeat.
func _setup_finale() -> void:
    finale.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    finale.clip_contents = false
    var backdrop: ColorRect = $UI/Finale/Backdrop
    backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    backdrop.color = Color(0.015, 0.035, 0.03, 0.82)
    var panel: Panel = $UI/Finale/Background
    _place_finale_control(panel, Rect2(-310, -280, 620, 560))
    panel.add_theme_stylebox_override("panel", _finale_box(Color("142b23"), Color("8f8652"), 2, 22))
    _place_finale_control($UI/Finale/VictoryArt, Rect2(-88, -258, 176, 132))
    _place_finale_control($UI/Finale/DefeatIcon, Rect2(-88, -252, 176, 126))
    _place_finale_control($UI/Finale/Eyebrow, Rect2(-260, -126, 520, 25))
    _place_finale_control($UI/Finale/VictoryTitle, Rect2(-270, -100, 540, 55))
    _place_finale_control($UI/Finale/Result, Rect2(-245, -43, 490, 55))
    _place_finale_control($UI/Finale/Score, Rect2(-245, 12, 490, 35))
    _place_finale_control($UI/Finale/KeepButton, Rect2(-220, 63, 210, 47))
    _place_finale_control($UI/Finale/ReturnButton, Rect2(10, 63, 210, 47))
    _place_finale_control($UI/Finale/Credits, Rect2(-240, 52, 480, 76))
    _place_finale_control($UI/Finale/RestartButton, Rect2(-155, 145, 310, 56))
    for label in [$UI/Finale/DefeatIcon, $UI/Finale/Eyebrow, $UI/Finale/VictoryTitle, $UI/Finale/Result, $UI/Finale/Score, $UI/Finale/Credits]:
        label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
        label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    $UI/Finale/DefeatIcon.text = "♥"
    $UI/Finale/DefeatIcon.add_theme_font_size_override("font_size", 86)
    $UI/Finale/DefeatIcon.add_theme_color_override("font_color", Color("e69b91"))
    $UI/Finale/Eyebrow.text = "T H E   S L E E P I N G   G R O V E"
    $UI/Finale/Eyebrow.add_theme_font_size_override("font_size", 13)
    $UI/Finale/Eyebrow.add_theme_color_override("font_color", Color("b7c5ad"))
    $UI/Finale/VictoryTitle.add_theme_font_size_override("font_size", 40)
    $UI/Finale/Result.add_theme_font_size_override("font_size", 19)
    $UI/Finale/Result.add_theme_color_override("font_color", Color("edf1df"))
    $UI/Finale/Result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    $UI/Finale/Score.add_theme_font_size_override("font_size", 15)
    $UI/Finale/Score.add_theme_color_override("font_color", Color("c5d0b5"))
    $UI/Finale/Credits.add_theme_font_size_override("font_size", 14)
    $UI/Finale/Credits.add_theme_color_override("font_color", Color("c5d0b5"))
    for button in [$UI/Finale/KeepButton, $UI/Finale/ReturnButton, $UI/Finale/RestartButton]:
        var primary: bool = button == $UI/Finale/RestartButton
        button.add_theme_font_size_override("font_size", 18)
        button.add_theme_color_override("font_color", Color("1a2c20") if primary else Color("edf1df"))
        button.add_theme_color_override("font_hover_color", Color("1a2c20") if primary else Color.WHITE)
        button.add_theme_stylebox_override("normal", _finale_box(Color("e5c86e") if primary else Color("203b30"), Color("e5c86e") if primary else Color("668671"), 1, 10))
        button.add_theme_stylebox_override("hover", _finale_box(Color("f4dc8f") if primary else Color("315a44"), Color("f7e3a0"), 2, 10))
        button.add_theme_stylebox_override("pressed", _finale_box(Color("c6a84f") if primary else Color("142b23"), Color("f7e3a0"), 2, 10))
        button.add_theme_stylebox_override("focus", _finale_box(Color(0, 0, 0, 0), Color("fff1b4"), 2, 10))
    $UI/Finale/RestartButton.text = "PLAY AGAIN"

func _place_finale_control(control: Control, bounds: Rect2) -> void:
    control.anchor_left = 0.5
    control.anchor_top = 0.5
    control.anchor_right = 0.5
    control.anchor_bottom = 0.5
    control.offset_left = bounds.position.x
    control.offset_top = bounds.position.y
    control.offset_right = bounds.end.x
    control.offset_bottom = bounds.end.y

func _finale_box(fill: Color, border: Color, border_width: int, radius: int) -> StyleBoxFlat:
    var box := StyleBoxFlat.new()
    box.bg_color = fill
    box.border_color = border
    box.set_border_width_all(border_width)
    box.set_corner_radius_all(radius)
    return box

func _on_exit(body) -> void:
    if finished or not body.is_in_group("heroes") or not body.active:
        return
    if Game.collected < 20 or not Game.boss_defeated:
        $UI/HUD/Story.text = "The exit needs 20 coins and the defeated guardian."
        return
    finished = true
    p1.active = false
    p2.active = false
    _show_result("You found the relic. Keep it or return it?", true, true)

func _game_over_after_animation() -> void:
    await get_tree().create_timer(0.9).timeout
    _show_result("Your adventure is not over. Try again!", false)

func _show_result(message: String, choices: bool, passed: bool = false) -> void:
    var art: TextureRect = $UI/Finale/VictoryArt
    var title: Label = $UI/Finale/VictoryTitle
    var already_celebrating := finale.visible and art.visible
    var was_visible := finale.visible
    finale.show()
    if not was_visible:
        finale.modulate.a = 0.0
        create_tween().tween_property(finale, "modulate:a", 1.0, 0.35)
    art.visible = passed
    $UI/Finale/DefeatIcon.visible = not passed and game_over
    $UI/Finale/Score.text = "COINS  %d / 20       SCORE  %d" % [Game.collected, Game.score]
    title.add_theme_color_override("font_color", Color("f4d98b") if passed else Color("f3b0a3"))
    title.text = "LEVEL PASSED!" if passed else ("GAME OVER" if game_over else "RESULT")
    title.show()
    $UI/Finale/Result.text = message
    $UI/Finale/KeepButton.visible = choices
    $UI/Finale/ReturnButton.visible = choices
    $UI/Finale/Credits.text = ""
    if passed and not already_celebrating:
        art.pivot_offset = art.size / 2.0
        art.scale = Vector2(0.35, 0.35)
        art.rotation = -0.25
        art.modulate.a = 0.0
        title.pivot_offset = title.size / 2.0
        title.scale = Vector2(0.8, 0.8)
        title.modulate.a = 0.0
        var celebration := create_tween().set_parallel(true)
        celebration.tween_property(art, "scale", Vector2.ONE, 0.7).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
        celebration.tween_property(art, "rotation", 0.0, 0.7).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
        celebration.tween_property(art, "modulate:a", 1.0, 0.3)
        celebration.tween_property(title, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
        celebration.tween_property(title, "modulate:a", 1.0, 0.4)
    elif not passed:
        title.scale = Vector2.ONE
        title.modulate.a = 1.0

func _choose(choice: String) -> void:
    Game.finish(choice)
    $UI/Finale/Result.text = "You chose to %s the relic. Final score: %d" % [choice, Game.score]
    $UI/Finale/KeepButton.hide()
    $UI/Finale/ReturnButton.hide()
    var result_label: Label = $UI/Finale/Result
    result_label.modulate.a = 0.0
    create_tween().tween_property(result_label, "modulate:a", 1.0, 1.0)
    $UI/Finale/Score.text = "COINS  %d / 20       SCORE  %d" % [Game.collected, Game.score]
    var roll: Label = $UI/Finale/Credits
    roll.text = "CREDITS\nDesign: your name  ·  Art: credited lesson assets\nBuilt with Godot"
    roll.modulate.a = 0.0
    create_tween().tween_property(roll, "modulate:a", 1.0, 1.0)

func _volume_changed(value: float) -> void:
    AudioServer.set_bus_volume_db(0, linear_to_db(maxf(value, 0.001)))

func _restart() -> void:
    get_tree().paused = false
    get_tree().reload_current_scene()
