extends Node

@export var pickup_scene: PackedScene
@onready var timer: Timer = $Timer
@onready var markers = $"../SpawnPoints".get_children()
@onready var bonus = $"../BonusPickups"

func _ready() -> void:
    timer.timeout.connect(_spawn)

func _spawn() -> void:
    if pickup_scene == null or markers.is_empty() or bonus.get_child_count() >= 5:
        return
    var marker = markers.pick_random()
    var item = pickup_scene.instantiate()
    item.name = Game.next_pickup_name()
    item.kind = "heart" if randi_range(0, 3) == 0 else "coin"
    bonus.add_child(item)
    item.global_position = marker.global_position
