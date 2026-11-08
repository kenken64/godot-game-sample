extends SceneTree
var failures := 0
func _initialize() -> void:
    call_deferred("run_checks")
func check(ok: bool, description: String) -> void:
    if ok:
        print("PASS: " + description)
    else:
        failures += 1
        push_error("FAIL: " + description)
func run_checks() -> void:
    var path = "user://audio.cfg"
    var existed = FileAccess.file_exists(path)
    var original = FileAccess.get_file_as_bytes(path) if existed else PackedByteArray()
    var game = root.get_node("Game")
    var original_enabled: bool = game.sound_enabled
    var original_volume: float = game.sound_volume
    var scene = load("res://scenes/StartMenu.tscn").instantiate()
    root.add_child(scene)
    current_scene = scene
    await process_frame
    var menu = scene.get_node("UI/AdventureMenu")
    menu._audio()
    var controls = scene.get_node("UI/ControlsMenu")
    check(menu.page == "audio" and controls.find_child("VolumeSlider", true, false) == null, "sound settings open separately from control mapping")
    var slider: HSlider = menu.content.find_child("VolumeSlider", true, false)
    check(slider != null and menu.sound_button.text.begins_with("SOUND:"), "volume and sound toggle are visible")
    game.set_sound_enabled(true)
    slider.value = 35.0
    check(is_equal_approx(game.sound_volume, 0.35) and is_equal_approx(AudioServer.get_bus_volume_linear(0), 0.35), "volume slider changes master audio")
    menu._toggle_sound()
    check(not game.sound_enabled and AudioServer.is_bus_mute(0) and menu.sound_button.text == "SOUND: OFF" and not menu.sound_button.button_pressed, "sound off mutes audio")
    slider.value = 55.0
    check(AudioServer.is_bus_mute(0) and is_equal_approx(game.sound_volume, 0.55), "volume can change while sound remains muted")
    game.sound_enabled = true
    game.sound_volume = 1.0
    game._load_audio_settings()
    check(not game.sound_enabled and is_equal_approx(game.sound_volume, 0.55) and AudioServer.is_bus_mute(0), "muted state and volume reload from disk")
    menu._toggle_sound()
    check(game.sound_enabled and not AudioServer.is_bus_mute(0) and menu.sound_button.button_pressed and is_equal_approx(AudioServer.get_bus_volume_linear(0), 0.55), "sound on restores the selected volume")
    var before = game.get_child_count()
    menu._test_sound()
    check(game.get_child_count() == before + 1, "test sound starts a real audio player")
    await create_timer(0.4).timeout
    check(game.get_child_count() == before, "test sound cleans itself up")
    menu._start_solo()
    await create_timer(0.2).timeout
    var level = current_scene
    var paused_menu = level.get_node("UI/AdventureMenu")
    paused_menu.open_menu()
    paused_menu._audio()
    check(paused and paused_menu.page == "audio" and is_equal_approx(game.sound_volume, 0.55), "sound settings are available from the pause menu")
    paused_menu._test_sound()
    check(game.get_child_count() == before + 1, "test sound plays while gameplay is paused")
    await create_timer(0.4).timeout
    check(game.get_child_count() == before, "paused test sound finishes and is freed")
    paused_menu._home()
    paused_menu._resume()
    if existed:
        var file = FileAccess.open(path, FileAccess.WRITE)
        file.store_buffer(original)
        file.close()
    else:
        DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
    game.sound_enabled = original_enabled
    game.sound_volume = original_volume
    game._apply_audio_settings()
    print("Audio settings checks: ", "passed" if failures == 0 else "failed")
    quit(0 if failures == 0 else 1)
