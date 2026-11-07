extends CharacterBody2D

@export var boss := false
@export var health_points := 2
@export var speed := 65.0
@export var patrol_left := -90.0
@export var patrol_right := 90.0
@export var attack_range := 65.0
@export var loot_scene: PackedScene
var origin_x := 0.0
var direction := 1.0
var attack_wait := 0.0
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
    add_to_group("damageable")
    origin_x = global_position.x

func _physics_process(delta: float) -> void:
    attack_wait = maxf(0.0, attack_wait - delta)
    velocity.y += 1100.0 * delta if not is_on_floor() else 0.0
    var target = null
    var closest := 320.0 if boss else 190.0
    for hero in get_tree().get_nodes_in_group("heroes"):
        if not hero.active or hero.health <= 0:
            continue
        var distance = global_position.distance_to(hero.global_position)
        if distance < closest:
            closest = distance
            target = hero
    if target:
        direction = 1.0 if target.global_position.x > global_position.x else -1.0
    elif global_position.x < origin_x + patrol_left:
        direction = 1.0
    elif global_position.x > origin_x + patrol_right:
        direction = -1.0
    var phase_speed = speed * (1.5 if boss and health_points <= 4 else 1.0)
    velocity.x = direction * phase_speed
    move_and_slide()
    sprite.flip_h = direction < 0.0
    if sprite.sprite_frames and sprite.sprite_frames.has_animation("run"):
        sprite.play("run")
    if target and closest < attack_range and attack_wait <= 0.0:
        target.hurt()
        attack_wait = 1.0 if boss else 1.4

func hit(amount: int = 1) -> void:
    health_points -= amount
    if health_points <= 0:
        if not boss and loot_scene:
            var container = get_tree().get_first_node_in_group("loot_container")
            if container:
                for i in range(randi_range(1, 3)):
                    var loot = loot_scene.instantiate()
                    loot.name = Game.next_pickup_name()
                    loot.kind = "coin"
                    container.add_child(loot)
                    loot.global_position = global_position + Vector2(randf_range(-24, 24), -20)
        Game.defeat_enemy(boss)
        queue_free()
