extends Control

const GamepadBindings = preload("res://scripts/GamepadBindings.gd")
const SAVE_PATH := "user://controls.cfg"
const ACTIONS := {
    "P1 • Move left":"p1_left", "P1 • Move right":"p1_right",
    "P1 • Jump":"p1_jump", "P1 • Crouch":"p1_crouch", "P1 • Roll":"p1_roll",
    "P1 • Attack":"p1_attack", "P1 • Interact":"p1_interact",
    "P2 • Move left":"p2_left", "P2 • Move right":"p2_right",
    "P2 • Jump":"p2_jump", "P2 • Crouch":"p2_crouch", "P2 • Roll":"p2_roll",
    "P2 • Attack":"p2_attack", "P2 • Interact":"p2_interact",
    "Join player 2":"toggle_coop", "Pause / controls":"pause", "Restart":"restart"
}

var default_keys: Dictionary = {}
var pad_overrides: Dictionary = {}
var key_buttons: Dictionary = {}
var pad_buttons: Dictionary = {}
var awaiting_action := ""
var awaiting_kind := ""
var was_paused := false
var status: Label
var close_button: Button
@onready var level = get_parent().get_parent()

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    _build_menu()
    for action in ACTIONS.values():
        var setting = ProjectSettings.get_setting("input/" + action, {})
        for event in setting.get("events", []):
            if event is InputEventKey:
                default_keys[action] = _key_spec(event)
                break
    _load_settings()
    hide()

func _build_menu() -> void:
    var dim = ColorRect.new()
    dim.color = Color(0.02, 0.07, 0.05, 0.92)
    dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(dim)
    var panel = PanelContainer.new()
    panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    panel.offset_left = 145
    panel.offset_right = -145
    panel.offset_top = 28
    panel.offset_bottom = -28
    add_child(panel)
    var margin = MarginContainer.new()
    for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
        margin.add_theme_constant_override(side, 18)
    panel.add_child(margin)
    var column = VBoxContainer.new()
    column.add_theme_constant_override("separation", 8)
    margin.add_child(column)
    var title = Label.new()
    title.text = "CONTROLS & GAMEPAD"
    title.add_theme_font_size_override("font_size", 26)
    column.add_child(title)
    var help = Label.new()
    help.text = "Select a binding, then press a key or gamepad button / stick. Esc cancels."
    help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    column.add_child(help)
    status = Label.new()
    status.text = "Changes save on this device. Pause opens this menu."
    status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    column.add_child(status)
    var heading = HBoxContainer.new()
    column.add_child(heading)
    for heading_text in ["ACTION", "KEYBOARD", "GAMEPAD"]:
        var header = Label.new()
        header.text = heading_text
        if heading_text == "ACTION":
            header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        else:
            header.custom_minimum_size.x = 230
            header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        heading.add_child(header)
    var scroll = ScrollContainer.new()
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    scroll.follow_focus = true
    column.add_child(scroll)
    var rows = VBoxContainer.new()
    rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    scroll.add_child(rows)
    for label_text in ACTIONS:
        var action: String = ACTIONS[label_text]
        var row = HBoxContainer.new()
        rows.add_child(row)
        var action_label = Label.new()
        action_label.text = label_text
        action_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        row.add_child(action_label)
        var key = Button.new()
        key.custom_minimum_size = Vector2(230, 34)
        key.pressed.connect(_begin_capture.bind(action, "keyboard"))
        row.add_child(key)
        key_buttons[action] = key
        var pad = Button.new()
        pad.custom_minimum_size = Vector2(230, 34)
        pad.pressed.connect(_begin_capture.bind(action, "gamepad"))
        row.add_child(pad)
        pad_buttons[action] = pad
    var footer = HBoxContainer.new()
    column.add_child(footer)
    var reset = Button.new()
    reset.text = "Restore defaults"
    reset.pressed.connect(_restore_defaults)
    footer.add_child(reset)
    var spacer = Control.new()
    spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    footer.add_child(spacer)
    close_button = Button.new()
    close_button.text = "Close / Resume"
    close_button.pressed.connect(close_menu)
    footer.add_child(close_button)

func open_menu() -> void:
    if visible:
        return
    was_paused = get_tree().paused
    get_tree().paused = true
    show()
    _refresh()
    close_button.grab_focus()

func close_menu() -> void:
    awaiting_action = ""
    awaiting_kind = ""
    hide()
    get_tree().paused = was_paused

func _begin_capture(action: String, kind: String) -> void:
    awaiting_action = action
    awaiting_kind = kind
    status.text = "Press a %s for %s. Escape cancels." % [kind, _action_label(action)]

func _input(event: InputEvent) -> void:
    if not visible or awaiting_action.is_empty():
        return
    if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
        awaiting_action = ""
        awaiting_kind = ""
        status.text = "Binding cancelled."
        get_viewport().set_input_as_handled()
        return
    var binding: Dictionary = {}
    if awaiting_kind == "keyboard" and event is InputEventKey and event.pressed and not event.echo:
        binding = _key_spec(event)
    elif awaiting_kind == "gamepad" and event is InputEventJoypadButton and event.pressed:
        binding = {"type":"button", "button":event.button_index}
    elif awaiting_kind == "gamepad" and event is InputEventJoypadMotion and absf(event.axis_value) >= 0.75:
        binding = {"type":"axis", "axis":event.axis, "direction":1.0 if event.axis_value > 0 else -1.0}
    if binding.is_empty():
        return
    get_viewport().set_input_as_handled()
    var conflict = _find_conflict(awaiting_action, awaiting_kind, binding)
    if not conflict.is_empty():
        status.text = "Already used by %s. Try another input, or press Escape to cancel." % conflict
        return
    if awaiting_kind == "keyboard":
        _set_keyboard(awaiting_action, binding)
    else:
        pad_overrides[awaiting_action] = binding
        _apply_gamepads()
    status.text = "%s updated and saved." % _action_label(awaiting_action)
    awaiting_action = ""
    awaiting_kind = ""
    _save_settings()
    _refresh()

func _unhandled_input(event: InputEvent) -> void:
    if visible and awaiting_action.is_empty() and event.is_action_pressed("ui_cancel"):
        get_viewport().set_input_as_handled()
        close_menu()

func _key_spec(event: InputEventKey) -> Dictionary:
    return {"physical":int(event.physical_keycode), "logical":int(event.keycode) if event.physical_keycode == 0 else 0}

func _set_keyboard(action: String, binding: Dictionary) -> void:
    if not InputMap.has_action(action):
        InputMap.add_action(action)
    for old in InputMap.action_get_events(action):
        if old is InputEventKey:
            InputMap.action_erase_event(action, old)
    var key = InputEventKey.new()
    key.physical_keycode = int(binding.get("physical", 0))
    key.keycode = int(binding.get("logical", 0))
    InputMap.action_add_event(action, key)

func _find_conflict(action: String, kind: String, binding: Dictionary) -> String:
    for other in ACTIONS.values():
        if other == action:
            continue
        if kind == "keyboard":
            for event in InputMap.action_get_events(other):
                if event is InputEventKey and _key_spec(event) == binding:
                    return _action_label(other)
        elif not (action.begins_with("p1_") and other.begins_with("p2_")) and not (action.begins_with("p2_") and other.begins_with("p1_")):
            for existing in GamepadBindings.specs_for(other):
                if existing == binding:
                    return _action_label(other)
    return ""

func _action_label(action: String) -> String:
    for label_text in ACTIONS:
        if ACTIONS[label_text] == action:
            return label_text
    return action

func _refresh() -> void:
    for action in ACTIONS.values():
        key_buttons[action].text = "Unassigned"
        for event in InputMap.action_get_events(action):
            if event is InputEventKey:
                key_buttons[action].text = event.as_text().replace(" - Physical", "")
                break
        pad_buttons[action].text = GamepadBindings.describe(action)

func _apply_gamepads() -> void:
    GamepadBindings.set_overrides(pad_overrides)
    if not level.is_node_ready():
        return
    level.p1_pad = -2
    level.p2_pad = -2
    level.system_pad = -2
    level._assign_gamepads()

func _save_settings() -> void:
    var config = ConfigFile.new()
    for action in ACTIONS.values():
        for event in InputMap.action_get_events(action):
            if event is InputEventKey:
                config.set_value("keyboard", action, _key_spec(event))
                break
        if pad_overrides.has(action):
            config.set_value("gamepad", action, pad_overrides[action])
    var error = config.save(SAVE_PATH)
    if error != OK:
        status.text = "Could not save controls (error %d)." % error

func _load_settings() -> void:
    var config = ConfigFile.new()
    if config.load(SAVE_PATH) == OK:
        for action in ACTIONS.values():
            var key = config.get_value("keyboard", action, {})
            if key is Dictionary and (int(key.get("physical", 0)) != 0 or int(key.get("logical", 0)) != 0):
                _set_keyboard(action, key)
            var pad = config.get_value("gamepad", action, {})
            if pad is Dictionary and pad.get("type", "") in ["button", "axis"]:
                pad_overrides[action] = pad
    _apply_gamepads()
    _refresh()

func _restore_defaults() -> void:
    for action in default_keys:
        _set_keyboard(action, default_keys[action])
    pad_overrides.clear()
    _apply_gamepads()
    _save_settings()
    _refresh()
    status.text = "Default keyboard and gamepad bindings restored."
