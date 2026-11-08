extends Control

const FOREST = preload("res://assets/parallax-tiling-map/images/parallax-far.webp")
const CREST = preload("res://assets/final-game/victory-crest.png")
const DEFAULT_RELAY = "ws://127.0.0.1:3000/ws/final-game"
var level: Node
var panel: PanelContainer
var column: VBoxContainer
var heading: Label
var content: VBoxContainer
var room_field: LineEdit
var relay_field: LineEdit
var status: Label
var is_game := false
var page := "home"

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    level = get_parent().get_parent()
    is_game = level.has_node("Online")
    _build()
    if is_game:
        hide()
    else:
        _home()

func _box(fill: Color, border: Color, radius: int = 14) -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = fill
    style.border_color = border
    style.set_border_width_all(1)
    style.set_corner_radius_all(radius)
    return style

func _build() -> void:
    if not is_game:
        var forest := TextureRect.new()
        forest.texture = FOREST
        forest.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        forest.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
        forest.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
        forest.mouse_filter = Control.MOUSE_FILTER_IGNORE
        add_child(forest)
    var shade := ColorRect.new()
    shade.color = Color(0.015, 0.035, 0.03, 0.82)
    shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(shade)
    panel = PanelContainer.new()
    panel.set_anchors_preset(Control.PRESET_CENTER)
    panel.offset_left = -300
    panel.offset_right = 300
    panel.offset_top = -300
    panel.offset_bottom = 300
    panel.add_theme_stylebox_override("panel", _box(Color("142b23"), Color("8f8652"), 22))
    add_child(panel)
    var margin := MarginContainer.new()
    for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
        margin.add_theme_constant_override(side, 26)
    panel.add_child(margin)
    column = VBoxContainer.new()
    column.add_theme_constant_override("separation", 10)
    margin.add_child(column)
    var art := TextureRect.new()
    art.texture = CREST
    art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    art.custom_minimum_size.y = 88
    column.add_child(art)
    var eyebrow := Label.new()
    eyebrow.text = "A   F O R E S T   A D V E N T U R E"
    eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    eyebrow.add_theme_font_size_override("font_size", 13)
    eyebrow.add_theme_color_override("font_color", Color("b7c5ad"))
    column.add_child(eyebrow)
    heading = Label.new()
    heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    heading.add_theme_font_size_override("font_size", 36)
    heading.add_theme_color_override("font_color", Color("f4d98b"))
    column.add_child(heading)
    content = VBoxContainer.new()
    content.size_flags_vertical = Control.SIZE_EXPAND_FILL
    content.alignment = BoxContainer.ALIGNMENT_CENTER
    content.add_theme_constant_override("separation", 10)
    column.add_child(content)

func _clear() -> void:
    for child in content.get_children():
        content.remove_child(child)
        child.queue_free()

func _button(text: String, action: Callable, primary: bool = false) -> Button:
    var button := Button.new()
    button.text = text
    button.custom_minimum_size.y = 48
    button.add_theme_font_size_override("font_size", 18)
    button.add_theme_color_override("font_color", Color("1a2c20") if primary else Color("edf1df"))
    button.add_theme_color_override("font_hover_color", Color("1a2c20") if primary else Color.WHITE)
    button.add_theme_color_override("font_focus_color", Color("1a2c20") if primary else Color("edf1df"))
    button.add_theme_color_override("font_pressed_color", Color("1a2c20") if primary else Color.WHITE)
    button.add_theme_stylebox_override("normal", _box(Color("e5c86e") if primary else Color("203b30"), Color("e5c86e") if primary else Color("668671"), 10))
    button.add_theme_stylebox_override("hover", _box(Color("f4dc8f") if primary else Color("315a44"), Color("f7e3a0"), 10))
    button.add_theme_stylebox_override("focus", _box(Color(0, 0, 0, 0), Color("fff1b4"), 10))
    button.pressed.connect(action)
    content.add_child(button)
    return button

func _home() -> void:
    _clear()
    page = "home"
    heading.text = "PAUSED" if is_game else "THE SLEEPING GROVE"
    var start = _button("RESUME" if is_game else "START ADVENTURE", _resume if is_game else _start_solo, true)
    _button("MULTIPLAYER", _multiplayer)
    _button("CONTROLS & GAMEPAD", _controls)
    _button("PROGRESS & SCORES", _progress)
    _button("QUIT GAME", _quit)
    start.grab_focus()

func open_menu() -> void:
    get_tree().paused = true
    show()
    _home()

func _resume() -> void:
    hide()
    get_tree().paused = false

func _controls() -> void:
    var controls = level.get_node("UI/ControlsMenu")
    controls.menu_closed.connect(_return_from_controls, CONNECT_ONE_SHOT)
    hide()
    controls.open_menu()

func _return_from_controls() -> void:
    show()
    _home()

func _quit() -> void:
    get_tree().paused = false
    get_tree().quit()

func _start_solo() -> void:
    Game.menu_role = ""
    get_tree().change_scene_to_file("res://scenes/Main.tscn")

func _field(placeholder: String, initial: String = "") -> LineEdit:
    var field := LineEdit.new()
    field.placeholder_text = placeholder
    field.text = initial
    field.custom_minimum_size.y = 40
    field.add_theme_font_size_override("font_size", 16)
    var normal := _box(Color("203b30"), Color("668671"), 8)
    var focused := _box(Color("203b30"), Color("f4d98b"), 8)
    normal.content_margin_left = 12
    focused.content_margin_left = 12
    field.add_theme_stylebox_override("normal", normal)
    field.add_theme_stylebox_override("focus", focused)
    content.add_child(field)
    return field

func _multiplayer() -> void:
    _clear()
    page = "multiplayer"
    heading.text = "MULTIPLAYER"
    var help := Label.new()
    help.text = "Host or join a room to start a new run."
    help.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    help.add_theme_color_override("font_color", Color("c5d0b5"))
    content.add_child(help)
    relay_field = _field("Relay server address", Game.menu_relay if not Game.menu_relay.is_empty() else DEFAULT_RELAY)
    _button("HOST A GAME", _host, true)
    room_field = _field("Six-character room code")
    room_field.max_length = 6
    _button("JOIN A GAME", _join)
    status = Label.new()
    status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    status.add_theme_color_override("font_color", Color("f3b0a3"))
    content.add_child(status)
    _button("BACK", _home)
    relay_field.grab_focus()

func _progress() -> void:
    _clear()
    page = "progress"
    heading.text = "YOUR PROGRESS"
    var badges := Label.new()
    badges.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    badges.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    var names := PackedStringArray()
    for key in Game.achievements:
        names.append(str(key).replace("_", " ").capitalize())
    badges.text = "Achievements: " + (", ".join(names) if not names.is_empty() else "None yet")
    content.add_child(badges)
    var scores := Label.new()
    scores.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    var lines := PackedStringArray()
    for record in Game.records:
        lines.append("%d  ·  %s" % [record["score"], record["ending"]])
    scores.text = "TOP SCORES\n" + ("\n".join(lines) if not lines.is_empty() else "No completed runs yet")
    content.add_child(scores)
    _button("BACK", _home).grab_focus()

func _host() -> void:
    _connect_room("host")

func _join() -> void:
    var code := room_field.text.strip_edges().to_upper()
    if code.length() != 6 or not code.is_valid_hex_number():
        status.text = "Enter the six-character room code."
        return
    _connect_room("join", code)

func _connect_room(role: String, code: String = "") -> void:
    var address := relay_field.text.strip_edges()
    if not (address.begins_with("ws://") or address.begins_with("wss://")):
        status.text = "Enter a ws:// or wss:// relay address."
        return
    Game.menu_role = role
    Game.menu_room = code
    Game.menu_relay = address
    get_tree().paused = false
    get_tree().change_scene_to_file("res://scenes/Main.tscn")

func _unhandled_input(event: InputEvent) -> void:
    if visible and event.is_action_pressed("ui_cancel"):
        get_viewport().set_input_as_handled()
        if page != "home":
            _home()
        elif is_game:
            _resume()
