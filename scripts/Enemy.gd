extends CharacterBody2D

@export var boss := false
@export var health_points := 2
@export var speed := 65.0
@export var patrol_left := -90.0
@export var patrol_right := 90.0
@export var attack_range := 65.0
@export var loot_scene: PackedScene
@export var knockback_speed := 230.0
@export var hit_bounce := 115.0
var origin_x := 0.0
var direction := 1.0
var attack_wait := 0.0
var hit_flash_time := 0.0
var knockback_time := 0.0
var knockback_velocity := 0.0
var defeated := false
var base_tint := Color.WHITE
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
    add_to_group("damageable")
    origin_x = global_position.x
    base_tint = sprite.self_modulate

func _physics_process(delta: float) -> void:
    attack_wait = maxf(0.0, attack_wait - delta)
    hit_flash_time = maxf(0.0, hit_flash_time - delta)
    _set_hit_flash(hit_flash_time > 0.0)
    if defeated and hit_flash_time <= 0.0:
        queue_free()
        return
    velocity.y += 1100.0 * delta if not is_on_floor() else 0.0
    if knockback_time > 0.0:
        knockback_time = maxf(0.0, knockback_time - delta)
        velocity.x = knockback_velocity
        move_and_slide()
        return
    if defeated:
        velocity.x = 0.0
        move_and_slide()
        return
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

func hit(amount: int = 1, attacker_x: float = INF) -> void:
    if defeated or amount <= 0:
        return
    health_points -= amount
    Game.play_sound("enemy_hit")
    hit_flash_time = 0.24
    knockback_time = 0.20
    var away := signf(global_position.x - attacker_x) if is_finite(attacker_x) else -direction
    if is_zero_approx(away):
        away = -direction
    knockback_velocity = away * knockback_speed * (0.45 if boss else 1.0)
    velocity.y = -hit_bounce * (0.6 if boss else 1.0)
    _set_hit_flash(true)
    _show_damage_number(amount)
    if health_points <= 0:
        defeated = true
        remove_from_group("damageable")
        $CollisionShape2D.set_deferred("disabled", true)
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

func _set_hit_flash(active: bool) -> void:
    sprite.self_modulate = base_tint * Color(1.0, 0.18, 0.18) if active else base_tint

func _show_damage_number(amount: int) -> void:
    var number := Label.new()
    number.name = "DamageNumber"
    number.text = str(amount)
    number.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    number.mouse_filter = Control.MOUSE_FILTER_IGNORE
    number.size = Vector2(100, 42)
    number.z_index = 100
    number.add_theme_font_size_override("font_size", 30)
    number.add_theme_color_override("font_color", Color("fff0b0"))
    number.add_theme_color_override("font_outline_color", Color("512118"))
    number.add_theme_constant_override("outline_size", 5)
    get_tree().current_scene.add_child(number)
    number.global_position = global_position + Vector2(-50, -150)
    var animation := number.create_tween().set_parallel(true)
    animation.tween_property(number, "position:y", number.position.y - 55.0, 0.75).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
    animation.tween_property(number, "modulate:a", 0.0, 0.35).set_delay(0.4)
    animation.chain().tween_callback(number.queue_free)
