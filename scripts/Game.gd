extends Node

const BUILD_ID := "2026.11.08.3"
const AUDIO_SETTINGS_PATH := "user://audio.cfg"
var sound_enabled := true
var sound_volume := 0.8

var menu_role := ""
var menu_room := ""
var menu_relay := ""
var coins := 0
var collected := 0
var score := 0
var boss_defeated := false
var ending := ""
var inventory: Array[String] = []
var materials := 0
var attack_bonus := 0
var spawn_index := 0
var achievements: Dictionary = {}
var records: Array = []

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    get_tree().root.title = "The Sleeping Grove — " + BUILD_ID
    _load_audio_settings()
    if FileAccess.file_exists("user://final_save.json"):
        var data = JSON.parse_string(FileAccess.get_file_as_string("user://final_save.json"))
        if data is Dictionary:
            achievements = data.get("achievements", {})
            records = data.get("records", [])

func _exit_tree() -> void:
    for child in get_children():
        if child is AudioStreamPlayer:
            child.stop()
            child.stream = null

func _load_audio_settings() -> void:
    var config := ConfigFile.new()
    if config.load(AUDIO_SETTINGS_PATH) == OK:
        sound_enabled = bool(config.get_value("audio", "enabled", true))
        sound_volume = clampf(float(config.get_value("audio", "volume", 0.8)), 0.0, 1.0)
    _apply_audio_settings()

func set_sound_enabled(enabled: bool) -> void:
    sound_enabled = enabled
    _apply_audio_settings()
    _save_audio_settings()

func set_sound_volume(volume: float) -> void:
    sound_volume = clampf(volume, 0.0, 1.0)
    _apply_audio_settings()
    _save_audio_settings()

func _apply_audio_settings() -> void:
    AudioServer.set_bus_volume_linear(0, sound_volume)
    AudioServer.set_bus_mute(0, not sound_enabled)

func _save_audio_settings() -> void:
    var config := ConfigFile.new()
    config.set_value("audio", "enabled", sound_enabled)
    config.set_value("audio", "volume", sound_volume)
    var error := config.save(AUDIO_SETTINGS_PATH)
    if error != OK:
        push_warning("Could not save audio settings (error %d)." % error)

# Small synthesized cues need no external audio files and use the Master bus.
func play_sound(kind: String) -> void:
    if not sound_enabled or sound_volume <= 0.0:
        return
    var frequency := 440.0
    var duration := 0.12
    match kind:
        "coin": frequency = 660.0
        "attack": frequency = 260.0
        "enemy_hit": frequency = 340.0
        "hurt": frequency = 185.0
        "victory":
            frequency = 520.0
            duration = 0.28
        "defeat":
            frequency = 160.0
            duration = 0.24
    var rate := 22050
    var count := int(rate * duration)
    var data := PackedByteArray()
    data.resize(count * 2)
    for i in range(count):
        var t := float(i) / float(rate)
        var envelope := minf(t / 0.01, 1.0) * pow(1.0 - t / duration, 2.0)
        var wave := sin(TAU * frequency * t) + 0.25 * sin(TAU * frequency * 1.5 * t)
        data.encode_s16(i * 2, int(clampf(wave * envelope * 0.22, -1.0, 1.0) * 32767.0))
    var stream := AudioStreamWAV.new()
    stream.format = AudioStreamWAV.FORMAT_16_BITS
    stream.mix_rate = rate
    stream.data = data
    var player := AudioStreamPlayer.new()
    player.process_mode = Node.PROCESS_MODE_ALWAYS
    player.stream = stream
    player.finished.connect(player.queue_free)
    add_child(player)
    player.play()

func start_run() -> void:
    coins = 0
    collected = 0
    score = 0
    boss_defeated = false
    ending = ""
    inventory.clear()
    materials = 0
    attack_bonus = 0
    spawn_index = 0

func next_pickup_name() -> String:
    spawn_index += 1
    return "Bonus_%d" % spawn_index

func collect_coin() -> void:
    play_sound("coin")
    coins += 1
    collected += 1
    score += 10
    if collected >= 20:
        unlock("coin_collector")

func buy_heal(player) -> bool:
    if coins < 5 or player.health >= 3:
        return false
    coins -= 5
    player.heal()
    unlock("first_purchase")
    return true

func buy_gear() -> bool:
    if coins < 8 or inventory.has("Forest Blade"):
        return false
    coins -= 8
    inventory.append("Forest Blade")
    attack_bonus = 1
    unlock("first_purchase")
    return true

func sell_gear() -> bool:
    if not inventory.has("Forest Blade"):
        return false
    inventory.erase("Forest Blade")
    coins += 4
    attack_bonus = 0
    return true

func salvage_gear() -> bool:
    if coins < 2 or not inventory.has("Forest Blade"):
        return false
    coins -= 2
    inventory.erase("Forest Blade")
    materials += 1
    attack_bonus = 0
    unlock("first_salvage")
    return true

func defeat_enemy(is_boss: bool) -> void:
    score += 100 if is_boss else 20
    if is_boss:
        boss_defeated = true
        unlock("boss_breaker")

func unlock(id: String) -> void:
    if achievements.has(id):
        return
    achievements[id] = true
    save_progress()

func finish(choice: String) -> void:
    ending = choice
    score += 50
    unlock("finished_game")
    records.append({"score": score, "ending": choice})
    records.sort_custom(func(a, b): return a["score"] > b["score"])
    records = records.slice(0, 5)
    save_progress()

func save_progress() -> void:
    var file = FileAccess.open("user://final_save.json", FileAccess.WRITE)
    if file:
        file.store_string(JSON.stringify({"achievements": achievements, "records": records}))
