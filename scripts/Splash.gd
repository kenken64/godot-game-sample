extends Node2D

func _ready() -> void:
    scale = Vector2(0.5, 0.5)
    modulate.a = 0.0
    var fade = create_tween()
    fade.tween_property(self, "modulate:a", 1.0, 0.15)
    fade.tween_property(self, "modulate:a", 0.0, 0.6)
    fade.tween_callback(queue_free)
    create_tween().tween_property(self, "scale", Vector2.ONE, 0.4)
