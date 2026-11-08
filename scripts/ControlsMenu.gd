extends Control

signal menu_closed

const GamepadBindings = preload("res://scripts/GamepadBindings.gd")
const MenuNavigation = preload("res://scripts/MenuNavigation.gd")
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

func _menu_box(fill: Color, border: Color, radius: int = 10) -> StyleBoxFlat:
    var box := StyleBoxFlat.new()
    box.bg_color = fill
    box.border_color = border
    box.set_border_width_all(1)
    box.set_corner_radius_all(radius)
    return box

func _style_button(button: Button, primary: bool = false) -> void:
    button.add_theme_font_size_override("font_size", 15)
    button.add_theme_color_override("font_color", Color("1a2c20") if primary else Color("edf1df"))
    button.add_theme_color_override("font_focus_color", Color("1a2c20") if primary else Color("edf1df"))
    button.add_theme_color_override("font_hover_color", Color("1a2c20") if primary else Color.WHITE)
    button.add_theme_color_override("font_pressed_color", Color("1a2c20") if primary else Color.WHITE)
    button.add_theme_stylebox_override("normal", _menu_box(Color("e5c86e") if primary else Color("203b30"), Color("e5c86e") if primary else Color("526e5e")))
    button.add_theme_stylebox_override("hover", _menu_box(Color("f4dc8f") if primary else Color("315a44"), Color("f7e3a0")))
    button.add_theme_stylebox_override("focus", _menu_box(Color(0, 0, 0, 0), Color("fff1b4")))
    button.add_theme_stylebox_override("pressed", _menu_box(Color("c6aa5f") if primary else Color("142b23"), Color("f7e3a0")))

func _build_menu() -> void:
    var dim := ColorRect.new()
    dim.color = Color(0.015, 0.035, 0.03, 0.88)
    dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(dim)
    var panel := PanelContainer.new()
    panel.set_anchors_preset(Control.PRESET_CENTER)
    panel.offset_left = -460
    panel.offset_right = 460
    panel.offset_top = -325
    panel.offset_bottom = 325
    panel.add_theme_stylebox_override("panel", _menu_box(Color("142b23"), Color("8f8652"), 22))
    add_child(panel)
    var margin := MarginContainer.new()
    for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
        margin.add_theme_constant_override(side, 26)
    panel.add_child(margin)
    var column := VBoxContainer.new()
    column.add_theme_constant_override("separation", 10)
    margin.add_child(column)
    var eyebrow := Label.new()
    eyebrow.text = "T H E   S L E E P I N G   G R O V E"
    eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    eyebrow.add_theme_font_size_override("font_size", 12)
    eyebrow.add_theme_color_override("font_color", Color("b7c5ad"))
    column.add_child(eyebrow)
    var title := Label.new()
    title.text = "CONTROLS & GAMEPAD"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 30)
    title.add_theme_color_override("font_color", Color("f4d98b"))
    column.add_child(title)
    var help := Label.new()
    help.text = "Select a binding to replace it. × or Delete clears; gamepad Y clears a focused binding."
    help.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    help.add_theme_color_override("font_color", Color("c5d0b5"))
    column.add_child(help)
    status = Label.new()
    status.text = "Your controls are saved on this device."
    status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    status.add_theme_font_size_override("font_size", 13)
    status.add_theme_color_override("font_color", Color("b7c5ad"))
    status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    column.add_child(status)
    var heading := HBoxContainer.new()
    heading.add_theme_constant_override("separation", 8)
    column.add_child(heading)
    for heading_text in ["ACTION", "KEYBOARD", "GAMEPAD"]:
        var header := Label.new()
        header.text = heading_text
        header.add_theme_font_size_override("font_size", 12)
        header.add_theme_color_override("font_color", Color("c5d0b5"))
        if heading_text == "ACTION":
            header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        else:
            header.custom_minimum_size.x = 240
            header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        heading.add_child(header)
    var scroll := ScrollContainer.new()
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    scroll.follow_focus = true
    scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    column.add_child(scroll)
    var rows := VBoxContainer.new()
    rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    rows.add_theme_constant_override("separation", 6)
    scroll.add_child(rows)
    var focus_rows: Array = []
    for label_text in ACTIONS:
        var action: String = ACTIONS[label_text]
        var row := HBoxContainer.new()
        row.add_theme_constant_override("separation", 8)
        rows.add_child(row)
        var action_label := Label.new()
        action_label.text = label_text
        action_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        action_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
        action_label.add_theme_font_size_override("font_size", 15)
        row.add_child(action_label)
        var key := Button.new()
        key.custom_minimum_size = Vector2(200, 40)
        _style_button(key)
        key.pressed.connect(_begin_capture.bind(action, "keyboard"))
        _binding_cell(row, key, action, "keyboard")
        key_buttons[action] = key
        var pad := Button.new()
        pad.custom_minimum_size = Vector2(200, 40)
        _style_button(pad)
        pad.pressed.connect(_begin_capture.bind(action, "gamepad"))
        _binding_cell(row, pad, action, "gamepad")
        pad_buttons[action] = pad
        focus_rows.append([key, pad])
    var footer := HBoxContainer.new()
    footer.add_theme_constant_override("separation", 12)
    column.add_child(footer)
    var reset := Button.new()
    reset.text = "RESTORE DEFAULTS"
    reset.custom_minimum_size = Vector2(200, 44)
    _style_button(reset)
    reset.pressed.connect(_restore_defaults)
    footer.add_child(reset)
    var spacer := Control.new()
    spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    footer.add_child(spacer)
    close_button = Button.new()
    close_button.text = "BACK"
    close_button.custom_minimum_size = Vector2(200, 44)
    _style_button(close_button, true)
    close_button.pressed.connect(close_menu)
    footer.add_child(close_button)
    focus_rows.append([reset, close_button])
    MenuNavigation.configure(focus_rows)

func _binding_cell(row: HBoxContainer, binding_button: Button, action: String, kind: String) -> void:
    var cell := HBoxContainer.new()
    cell.add_theme_constant_override("separation", 8)
    row.add_child(cell)
    cell.add_child(binding_button)
    var clear := Button.new()
    clear.name = "Clear_%s_%s" % [action, kind]
    clear.text = "×"
    clear.custom_minimum_size = Vector2(32, 40)
    clear.focus_mode = Control.FOCUS_NONE
    clear.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
    clear.tooltip_text = "Clear %s binding for %s" % [kind, _action_label(action)]
    _style_button(clear)
    clear.pressed.connect(_clear_binding.bind(action, kind))
    cell.add_child(clear)

func _focused_binding() -> Dictionary:
    var focused := get_viewport().gui_get_focus_owner()
    for action in ACTIONS.values():
        if focused == key_buttons[action]:
            return {"action": action, "kind": "keyboard"}
        if focused == pad_buttons[action]:
            return {"action": action, "kind": "gamepad"}
    return {}

func _clear_binding(action: String, kind: String) -> void:
    awaiting_action = ""
    awaiting_kind = ""
    if kind == "keyboard":
        _set_keyboard(action, {})
    else:
        pad_overrides[action] = {"type": "none"}
        _apply_gamepads()
    status.text = "%s %s binding cleared and saved." % [_action_label(action), kind]
    _save_settings()
    _refresh()
    var button: Button = key_buttons[action] if kind == "keyboard" else pad_buttons[action]
    if button.is_visible_in_tree():
        button.grab_focus()

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
    menu_closed.emit()

func _begin_capture(action: String, kind: String) -> void:
    awaiting_action = action
    awaiting_kind = kind
    status.text = "Press a %s for %s. Delete clears; Esc / Select cancels." % [kind, _action_label(action)]

func _input(event: InputEvent) -> void:
    if not visible:
        return
    var delete_pressed: bool = event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_DELETE
    var clear_pad_pressed: bool = awaiting_action.is_empty() and event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_Y
    if delete_pressed or clear_pad_pressed:
        var selected := _focused_binding() if awaiting_action.is_empty() else {"action": awaiting_action, "kind": awaiting_kind}
        if not selected.is_empty():
            get_viewport().set_input_as_handled()
            _clear_binding(selected["action"], selected["kind"])
            return
    if awaiting_action.is_empty():
        return
    var cancel_capture := event.is_action_pressed("ui_cancel") and (awaiting_kind == "keyboard" or event is InputEventKey)
    if event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_BACK:
        cancel_capture = true
    if cancel_capture:
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
        # Keep navigation from moving focus while a binding is being captured.
        if event is InputEventKey or event is InputEventJoypadButton or event is InputEventJoypadMotion:
            get_viewport().set_input_as_handled()
        return
    get_viewport().set_input_as_handled()
    var reassigned := PackedStringArray()
    for other in _conflicting_actions(awaiting_action, awaiting_kind, binding):
        if awaiting_kind == "keyboard":
            _set_keyboard(other, {})
        else:
            var remaining := GamepadBindings.specs_for(other).duplicate(true)
            remaining.erase(binding)
            pad_overrides[other] = remaining[0] if not remaining.is_empty() else {"type": "none"}
        reassigned.append(_action_label(other))
    if awaiting_kind == "keyboard":
        _set_keyboard(awaiting_action, binding)
    else:
        pad_overrides[awaiting_action] = binding
        _apply_gamepads()
    status.text = "%s updated and saved." % _action_label(awaiting_action)
    if not reassigned.is_empty():
        status.text += " Input reassigned from " + ", ".join(reassigned) + "."
    awaiting_action = ""
    awaiting_kind = ""
    _save_settings()
    _refresh()

func _unhandled_input(event: InputEvent) -> void:
    if visible and awaiting_action.is_empty() and (event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause")):
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
    if key.physical_keycode != 0 or key.keycode != 0:
        InputMap.action_add_event(action, key)

func _conflicting_actions(action: String, kind: String, binding: Dictionary) -> Array[String]:
    var conflicts: Array[String] = []
    for other in ACTIONS.values():
        if other == action:
            continue
        if kind == "keyboard":
            for event in InputMap.action_get_events(other):
                if event is InputEventKey and _key_spec(event) == binding:
                    conflicts.append(other)
                    break
        elif not (action.begins_with("p1_") and other.begins_with("p2_")) and not (action.begins_with("p2_") and other.begins_with("p1_")):
            for existing in GamepadBindings.specs_for(other):
                if existing == binding:
                    conflicts.append(other)
                    break
    return conflicts

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
        key_buttons[action].tooltip_text = key_buttons[action].text + " — select to rebind; Delete or Y clears."
        pad_buttons[action].tooltip_text = pad_buttons[action].text + " — select to rebind; Delete or Y clears."

func _apply_gamepads() -> void:
    GamepadBindings.set_overrides(pad_overrides)
    if not level.is_node_ready() or not level.has_method("_assign_gamepads"):
        return
    level.p1_pad = -2
    level.p2_pad = -2
    level.system_pad = -2
    level._assign_gamepads()

func _save_settings() -> void:
    var config = ConfigFile.new()
    for action in ACTIONS.values():
        var saved_key := {"physical": 0, "logical": 0}
        for event in InputMap.action_get_events(action):
            if event is InputEventKey:
                saved_key = _key_spec(event)
                break
        config.set_value("keyboard", action, saved_key)
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
            if key is Dictionary and config.has_section_key("keyboard", action):
                _set_keyboard(action, key)
            var pad = config.get_value("gamepad", action, {})
            if pad is Dictionary and pad.get("type", "") in ["button", "axis", "none"]:
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
