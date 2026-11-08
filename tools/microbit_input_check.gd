extends SceneTree

class Reader extends Node:
    const BUTTON_NAMES := {
        JOY_BUTTON_A: "A / confirm", JOY_BUTTON_B: "B / back",
        JOY_BUTTON_X: "X", JOY_BUTTON_Y: "Y",
        JOY_BUTTON_BACK: "Back / Select", JOY_BUTTON_START: "Start",
        JOY_BUTTON_LEFT_STICK: "Left stick click",
        JOY_BUTTON_RIGHT_STICK: "Right stick click",
        JOY_BUTTON_LEFT_SHOULDER: "Left shoulder",
        JOY_BUTTON_RIGHT_SHOULDER: "Right shoulder"
    }
    var label: Label
    var last_button := "none"
    var observed: Dictionary = {}

    func _input(event: InputEvent) -> void:
        if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
            get_viewport().set_input_as_handled()
            print("INPUT_CHECK_EXIT: Escape")
            get_tree().quit()
            return
        if event is InputEventJoypadButton:
            var description: String = BUTTON_NAMES.get(event.button_index, "Button %d" % event.button_index)
            last_button = description + (" pressed" if event.pressed else " released")
            if event.pressed:
                observed[description] = true
            print("INPUT_CHECK_BUTTON ", event.device, " ", event.button_index, " ", last_button)

    func _process(_delta: float) -> void:
        var lines := PackedStringArray([
            "MICRO:BIT INPUT CHECK", "",
            "Move the stick and press each button.",
            "Press Escape or close the window to exit.", ""
        ])
        var devices := Input.get_connected_joypads()
        if devices.is_empty():
            lines.append("No gamepad detected. Check Bluetooth connection.")
        for device in devices:
            lines.append(Input.get_joy_name(device) + "  |  mapped: " + str(Input.is_joy_known(device)))
            lines.append("Stick X: %.2f     Y: %.2f" % [Input.get_joy_axis(device, JOY_AXIS_LEFT_X), Input.get_joy_axis(device, JOY_AXIS_LEFT_Y)])
            var held := PackedStringArray()
            for button in range(JOY_BUTTON_MAX):
                if Input.is_joy_button_pressed(device, button):
                    held.append(BUTTON_NAMES.get(button, "Button %d" % button))
            lines.append("Held: " + (", ".join(held) if not held.is_empty() else "none"))
        lines.append("")
        lines.append("Last button: " + last_button)
        lines.append("Observed: " + ", ".join(observed.keys()))
        label.text = "\n".join(lines)

func _initialize() -> void:
    call_deferred("run_check")

func run_check() -> void:
    root.title = "micro:bit gamepad input check — Esc to exit"
    root.size = Vector2i(800, 500)
    var label := Label.new()
    label.position = Vector2(24, 24)
    label.size = Vector2(752, 452)
    label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    label.add_theme_font_size_override("font_size", 18)
    root.add_child(label)
    var reader := Reader.new()
    reader.label = label
    root.add_child(reader)
    for device in Input.get_connected_joypads():
        print("INPUT_CHECK_DEVICE ", Input.get_joy_name(device), " mapped=", Input.is_joy_known(device), " guid=", Input.get_joy_guid(device))
