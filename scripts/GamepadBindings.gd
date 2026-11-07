extends RefCounted

static var overrides: Dictionary = {}

static func set_overrides(mapping: Dictionary) -> void:
    overrides = mapping.duplicate(true)

static func bind_player(slot: int, device: int) -> void:
    var prefix := "p1_" if slot == 1 else "p2_"
    for suffix in ["left", "right", "jump", "roll", "crouch", "attack", "interact"]:
        _clear_pad_events(prefix + suffix)
    if device < 0:
        return
    _axis(prefix + "left", device, -1.0)
    _axis(prefix + "right", device, 1.0)
    _button(prefix + "left", device, JOY_BUTTON_DPAD_LEFT)
    _button(prefix + "right", device, JOY_BUTTON_DPAD_RIGHT)
    _axis(prefix + "crouch", device, 1.0, JOY_AXIS_LEFT_Y)
    _button(prefix + "crouch", device, JOY_BUTTON_DPAD_DOWN)
    _button(prefix + "jump", device, JOY_BUTTON_A)
    _button(prefix + "roll", device, JOY_BUTTON_B)
    _button(prefix + "attack", device, JOY_BUTTON_X)
    _button(prefix + "interact", device, JOY_BUTTON_Y)
    for suffix in ["left", "right", "jump", "roll", "crouch", "attack", "interact"]:
        _apply_override(prefix + suffix, device)

static func bind_system(device: int) -> void:
    for action in ["toggle_coop", "pause", "restart"]:
        _clear_pad_events(action)
    if device < 0:
        return
    _button("toggle_coop", device, JOY_BUTTON_BACK)
    _button("pause", device, JOY_BUTTON_START)
    _button("restart", device, JOY_BUTTON_RIGHT_SHOULDER)
    for action in ["toggle_coop", "pause", "restart"]:
        _apply_override(action, device)

static func _clear_pad_events(action: String) -> void:
    if not InputMap.has_action(action):
        InputMap.add_action(action, 0.25)
    for event in InputMap.action_get_events(action):
        if event is InputEventJoypadButton or event is InputEventJoypadMotion:
            InputMap.action_erase_event(action, event)

static func _axis(action: String, device: int, direction: float, axis: int = JOY_AXIS_LEFT_X) -> void:
    if overrides.has(action):
        return
    var event := InputEventJoypadMotion.new()
    event.device = device
    event.axis = axis
    event.axis_value = direction
    InputMap.action_set_deadzone(action, 0.25)
    InputMap.action_add_event(action, event)

static func _button(action: String, device: int, button: int) -> void:
    if overrides.has(action):
        return
    var event := InputEventJoypadButton.new()
    event.device = device
    event.button_index = button
    InputMap.action_add_event(action, event)


static func _apply_override(action: String, device: int) -> void:
    if not overrides.has(action):
        return
    var binding: Dictionary = overrides[action]
    var event: InputEvent
    if binding.get("type") == "axis":
        event = InputEventJoypadMotion.new()
        event.axis = int(binding.get("axis", 0))
        event.axis_value = float(binding.get("direction", 1.0))
        InputMap.action_set_deadzone(action, 0.25)
    elif binding.get("type") == "button":
        event = InputEventJoypadButton.new()
        event.button_index = int(binding.get("button", 0))
    else:
        return
    event.device = device
    InputMap.action_add_event(action, event)

static func specs_for(action: String) -> Array:
    if overrides.has(action):
        return [overrides[action]]
    var name = action.trim_prefix("p1_").trim_prefix("p2_")
    match name:
        "left": return [{"type":"axis", "axis":JOY_AXIS_LEFT_X, "direction":-1.0}, {"type":"button", "button":JOY_BUTTON_DPAD_LEFT}]
        "right": return [{"type":"axis", "axis":JOY_AXIS_LEFT_X, "direction":1.0}, {"type":"button", "button":JOY_BUTTON_DPAD_RIGHT}]
        "crouch": return [{"type":"axis", "axis":JOY_AXIS_LEFT_Y, "direction":1.0}, {"type":"button", "button":JOY_BUTTON_DPAD_DOWN}]
        "jump": return [{"type":"button", "button":JOY_BUTTON_A}]
        "roll": return [{"type":"button", "button":JOY_BUTTON_B}]
        "attack": return [{"type":"button", "button":JOY_BUTTON_X}]
        "interact": return [{"type":"button", "button":JOY_BUTTON_Y}]
        "toggle_coop": return [{"type":"button", "button":JOY_BUTTON_BACK}]
        "pause": return [{"type":"button", "button":JOY_BUTTON_START}]
        "restart": return [{"type":"button", "button":JOY_BUTTON_RIGHT_SHOULDER}]
    return []

static func describe(action: String) -> String:
    var button_names = {
        JOY_BUTTON_A:"A / Cross", JOY_BUTTON_B:"B / Circle",
        JOY_BUTTON_X:"X / Square", JOY_BUTTON_Y:"Y / Triangle",
        JOY_BUTTON_BACK:"Back / Select", JOY_BUTTON_START:"Start / Options",
        JOY_BUTTON_LEFT_SHOULDER:"Left shoulder", JOY_BUTTON_RIGHT_SHOULDER:"Right shoulder",
        JOY_BUTTON_DPAD_LEFT:"D-pad left", JOY_BUTTON_DPAD_RIGHT:"D-pad right",
        JOY_BUTTON_DPAD_UP:"D-pad up", JOY_BUTTON_DPAD_DOWN:"D-pad down"
    }
    var labels: Array[String] = []
    for binding in specs_for(action):
        if binding["type"] == "axis":
            var axis_name = "Left stick X" if binding["axis"] == JOY_AXIS_LEFT_X else ("Left stick Y" if binding["axis"] == JOY_AXIS_LEFT_Y else "Axis %d" % binding["axis"])
            labels.append("%s %s" % [axis_name, "+" if binding["direction"] > 0 else "−"])
        else:
            labels.append(button_names.get(binding["button"], "Button %d" % binding["button"]))
    return " / ".join(labels) if not labels.is_empty() else "Unassigned"
