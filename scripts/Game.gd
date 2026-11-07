extends Node

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
    if FileAccess.file_exists("user://final_save.json"):
        var data = JSON.parse_string(FileAccess.get_file_as_string("user://final_save.json"))
        if data is Dictionary:
            achievements = data.get("achievements", {})
            records = data.get("records", [])

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
