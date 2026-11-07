extends Area2D

@export var kind := "coin":
    set(value):
        kind = value
        if is_node_ready():
            _update_texture()
@export var heart_texture: Texture2D
@onready var coin_texture: Texture2D = $Sprite2D.texture

func _ready() -> void:
    _update_texture()
    body_entered.connect(_on_body_entered)

func _update_texture() -> void:
    $Sprite2D.texture = heart_texture if kind == "heart" and heart_texture else coin_texture

func _on_body_entered(body) -> void:
    if not body.is_in_group("heroes") or not body.active:
        return
    if kind == "coin":
        Game.collect_coin()
    elif kind == "heart":
        if body.health <= 0 or body.health >= 3:
            return
        Game.unlock("heart_restored")
        body.heal()
    queue_free()
