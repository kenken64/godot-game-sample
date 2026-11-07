extends Area2D

@export var splash_scene: PackedScene
var splashed := false

func _ready() -> void:
    body_entered.connect(_on_body_entered)

func _on_body_entered(body) -> void:
    if body.is_in_group("heroes") and body.active:
        body.hurt()
    elif body.is_in_group("boulders") and not splashed:
        splashed = true
        body.linear_damp = 8.0
        if splash_scene:
            var splash = splash_scene.instantiate()
            get_tree().current_scene.add_child(splash)
            splash.global_position = body.global_position
