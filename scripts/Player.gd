extends CharacterBody2D

@export var slot := 1
@export var speed := 220.0
@export var jump_speed := -430.0
@export_range(1, 4) var max_jumps := 2
var active := true
var remote_controlled := false
var remote_axis := 0.0
var remote_jump := false
var jumps_used := 0
var remote_roll := false
var remote_crouch := false
var remote_attack := false
var health := 3
var facing := 1
var attack_wait := 0.0
var roll_time := 0.0
var roll_cooldown := 0.0
var hurt_wait := 0.0
var hurt_animation_time := 0.0
var crouching := false
var standing_shape_size := Vector2.ZERO
var standing_shape_position := Vector2.ZERO
var standing_sprite_scale := Vector2.ONE
var standing_sprite_position := Vector2.ZERO
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
    add_to_group("heroes")
    standing_sprite_scale = sprite.scale
    standing_sprite_position = sprite.position
    if hitbox.shape is RectangleShape2D:
        hitbox.shape = hitbox.shape.duplicate()
        standing_shape_size = hitbox.shape.size
        standing_shape_position = hitbox.position

func _physics_process(delta: float) -> void:
    if not active or health <= 0:
        return
    attack_wait = maxf(0.0, attack_wait - delta)
    roll_time = maxf(0.0, roll_time - delta)
    roll_cooldown = maxf(0.0, roll_cooldown - delta)
    hurt_wait = maxf(0.0, hurt_wait - delta)
    hurt_animation_time = maxf(0.0, hurt_animation_time - delta)
    var prefix = "p1_" if slot == 1 else "p2_"
    var axis = remote_axis if remote_controlled else Input.get_axis(prefix + "left", prefix + "right")
    var jump_now = remote_jump if remote_controlled else Input.is_action_just_pressed(prefix + "jump")
    var roll_now = remote_roll if remote_controlled else Input.is_action_just_pressed(prefix + "roll")
    var attack_now = remote_attack if remote_controlled else Input.is_action_just_pressed(prefix + "attack")
    var crouch_now = remote_crouch if remote_controlled else Input.is_action_pressed(prefix + "crouch")
    _set_crouching(crouch_now and is_on_floor() and roll_time <= 0.0)
    remote_jump = false
    remote_roll = false
    remote_attack = false
    velocity.y += 1100.0 * delta if not is_on_floor() else 0.0
    if axis != 0.0 and roll_time <= 0.0:
        facing = 1 if axis > 0.0 else -1
    if roll_now and not crouching and roll_cooldown <= 0.0 and is_on_floor():
        roll_time = 0.28
        roll_cooldown = 0.7
    velocity.x = facing * speed * 1.65 if roll_time > 0.0 else (0.0 if crouching else axis * speed)
    if is_on_floor():
        jumps_used = 0
    elif jumps_used == 0:
        # Walking off an edge uses the grounded jump; one air jump remains.
        jumps_used = 1
    if jump_now and not crouching and jumps_used < max_jumps:
        velocity.y = jump_speed
        jumps_used += 1
    sprite.flip_h = facing < 0
    if attack_now and attack_wait <= 0.0:
        attack_wait = 0.4
        for target in get_tree().get_nodes_in_group("damageable"):
            var gap = target.global_position - global_position
            if absf(gap.x) < 75.0 and absf(gap.y) < 55.0 and gap.x * facing > -10.0:
                target.hit(1 + Game.attack_bonus)
    move_and_slide()
    var animation = "jump" if not is_on_floor() else ("run" if absf(axis) > 0.1 else "idle")
    if crouching and sprite.sprite_frames and sprite.sprite_frames.has_animation("crouch"):
        animation = "crouch"
    if roll_time > 0.0:
        animation = "roll" if sprite.sprite_frames and sprite.sprite_frames.has_animation("roll") else "run"
    if attack_wait > 0.25:
        animation = "attack"
    if hurt_animation_time > 0.0 and sprite.sprite_frames and sprite.sprite_frames.has_animation("hurt"):
        animation = "hurt"
    if sprite.sprite_frames and sprite.sprite_frames.has_animation(animation):
        sprite.play(animation)

func _set_crouching(requested: bool) -> void:
    if requested == crouching:
        return
    var height_change = standing_shape_size.y * 0.4
    if not requested and crouching and height_change > 0.0 and test_move(global_transform, Vector2(0, -height_change)):
        return
    crouching = requested
    if hitbox.shape is RectangleShape2D and standing_shape_size.y > 0.0:
        hitbox.shape.size = Vector2(standing_shape_size.x, standing_shape_size.y * (0.6 if crouching else 1.0))
        hitbox.position = standing_shape_position + Vector2(0, height_change / 2.0 if crouching else 0.0)
    _apply_crouch_visual(crouching)

func _apply_crouch_visual(value: bool) -> void:
    var has_crouch = sprite.sprite_frames and sprite.sprite_frames.has_animation("crouch")
    var factor = 0.6 if value and not has_crouch else 1.0
    sprite.scale = Vector2(standing_sprite_scale.x, standing_sprite_scale.y * factor)
    var frame_height = 256.0
    if sprite.sprite_frames and sprite.sprite_frames.has_animation("idle") and sprite.sprite_frames.get_frame_count("idle") > 0:
        frame_height = sprite.sprite_frames.get_frame_texture("idle", 0).get_height()
    sprite.position = standing_sprite_position + Vector2(0, frame_height * standing_sprite_scale.y * (1.0 - factor) / 2.0)

func hurt() -> void:
    if hurt_wait > 0.0 or health <= 0:
        return
    health -= 1
    hurt_wait = 1.0
    if health <= 0:
        _apply_crouch_visual(false)
        velocity.x = 0.0
        if sprite.sprite_frames and sprite.sprite_frames.has_animation("death"):
            sprite.play("death")
    else:
        hurt_animation_time = 0.5
        if sprite.sprite_frames and sprite.sprite_frames.has_animation("hurt"):
            sprite.play("hurt")

func heal() -> void:
    health = mini(3, health + 1)
