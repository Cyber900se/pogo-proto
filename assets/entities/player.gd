extends CharacterBody2D
class_name Player

const SQUASH_PER_CHARGE := 10.0
const LANDING_REF_SPEED := 600.0
const WALL_MIN_NORMAL_X := 0.6
const WALL_MAX_NORMAL_Y := 0.6
const FLOOR_MIN_DOT := 0.7

@export var jump_power: float = 300.0
@export var max_charge: float = 1.5
@export var charge_speed: float = 1.0
@export var max_tilt_deg: float = 80.0
@export var tilt_speed_air: float = 6.5
@export var tilt_speed_ground: float = 4.0
@export var ground_collision_layer: int = 1

@export var land_squash_strength: float = 10.0
@export var land_bounce_strength: float = 0.4

@export var wall_attach_duration: float = 2
@export var wall_push_off_strength: float = 10.0

var can_control: bool = true
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var charge := 0.0
var is_charging := false
var current_angle := 0.0
var grounded := false
var was_grounded := false
var is_wall_attached := false
var wall_normal: Vector2 = Vector2.ZERO


var ground_collider: Node = null
var ground_collider_prev_pos: Vector2 = Vector2.ZERO

var landing_anim_timer := 0.0
var landing_anim_duration := 0.1
var landing_impact_factor := 1.0

var sprite_base_height_offset: float = 0.0
var ground_pivot_offset: Vector2 = Vector2.ZERO

@onready var visuals: Node2D = $Visuals
@onready var top_sprite: Sprite2D = $Visuals/Top
@onready var bottom_sprite: Sprite2D = $Visuals/Bottom
@onready var collider: CollisionShape2D = $CollisionShape2D
@onready var camera: Camera2D = $Camera2D
@onready var wall_attach_timer: Timer = $WallAttachTimer

func _ready():
	top_sprite.centered = true
	bottom_sprite.centered = true
	top_sprite.z_index = 2
	bottom_sprite.z_index = 1

	var circle := collider.shape as CircleShape2D
	if circle:
		ground_pivot_offset = collider.position + Vector2(0, circle.radius)
	else:
		printerr("Player: collider.shape is not CircleShape2D")
		ground_pivot_offset = Vector2.ZERO

	bottom_sprite.position.y = 0.0
	top_sprite.position.y = - sprite_base_height_offset

	if wall_attach_timer:
		wall_attach_timer.wait_time = wall_attach_duration
		wall_attach_timer.one_shot = true
		if not wall_attach_timer.timeout.is_connected(_on_wall_attach_timer_timeout):
			wall_attach_timer.timeout.connect(_on_wall_attach_timer_timeout)
	else:
		printerr("Player: WallAttachTimer missing")

func _physics_process(delta: float) -> void:
	
	if not can_control:
		return

	was_grounded = grounded
	grounded = _check_if_on_ground()

	if grounded and ground_collider and ground_collider is Node2D:
		var current_platform_pos := (ground_collider as Node2D).global_position

		if not was_grounded:
			ground_collider_prev_pos = current_platform_pos
		else:
			var platform_delta := current_platform_pos - ground_collider_prev_pos
			if platform_delta != Vector2.ZERO:
				global_position += platform_delta

		ground_collider_prev_pos = current_platform_pos
	else:
		ground_collider = null
		ground_collider_prev_pos = Vector2.ZERO

	if is_wall_attached:
		velocity = Vector2.ZERO
	elif not grounded:
		velocity.y += gravity * delta

	if grounded or is_wall_attached:
		var mouse_pos = get_global_mouse_position()
		var to_mouse = (mouse_pos - global_position).normalized()
		var target_angle = clamp(to_mouse.angle_to(Vector2.UP), deg_to_rad( - max_tilt_deg), deg_to_rad(max_tilt_deg))
		current_angle = lerp_angle(current_angle, - target_angle, delta * tilt_speed_ground)

		var pivot_local = ground_pivot_offset
		var pivot_before = global_transform * pivot_local
		rotation = current_angle
		var pivot_after = global_transform * pivot_local
		global_position += (pivot_before - pivot_after)
	else:
		current_angle += Input.get_axis("spin_left", "spin_right") * tilt_speed_air * delta
		current_angle = wrapf(current_angle, -PI, PI)
		rotation = current_angle

	var can_charge = grounded or is_wall_attached
	if is_charging and not can_charge:
		is_charging = false
		charge = 0.0
		_reset_sprites()
	if Input.is_action_just_pressed("jump") and can_charge:
		is_charging = true
		charge = 0.0
		_update_compression()
	elif Input.is_action_pressed("jump") and can_charge and is_charging:
		charge = clamp(charge + charge_speed * delta, 0.0, max_charge)
		_update_compression()
	elif Input.is_action_just_released("jump") and is_charging and can_charge:
		_jump()
		is_charging = false
		charge = 0.0
		_reset_sprites()
	
	if is_charging and not can_charge:
		is_charging = false
		charge = 0.0
		_reset_sprites()

	move_and_slide()
	_handle_collision_events()
	_update_land_animation(delta)

func _handle_collision_events() -> void:
	if grounded and not was_grounded:
		if is_wall_attached:
			_stop_wall_attach()
		if not is_charging:
			velocity.x = 0
		_start_land_animation()
		return

	var found_wall := false
	var wall_n := Vector2.ZERO
	for i in range(get_slide_collision_count()):
		var col = get_slide_collision(i)
		if not col:
			continue
		var n = col.get_normal()
		if abs(n.x) > WALL_MIN_NORMAL_X and abs(n.y) < WALL_MAX_NORMAL_Y:
			found_wall = true
			wall_n = n
			break

	if not is_wall_attached:
		if found_wall and not grounded:
			is_wall_attached = true
			wall_normal = wall_n
			if wall_attach_timer and wall_attach_timer.is_stopped():
				wall_attach_timer.start()
			velocity = Vector2.ZERO
			_reset_sprites()
	else:
		if found_wall:
			wall_normal = wall_n
		else:
			if wall_attach_timer:
				if wall_attach_timer.is_stopped():
					_stop_wall_attach()
			else:
				_stop_wall_attach()

func _stop_wall_attach() -> void:
	if is_wall_attached:
		is_wall_attached = false
		velocity = wall_normal * wall_push_off_strength
		wall_normal = Vector2.ZERO
		if wall_attach_timer and not wall_attach_timer.is_stopped():
			wall_attach_timer.stop()
		_reset_sprites()

func _on_wall_attach_timer_timeout() -> void:
	_stop_wall_attach()

func _jump() -> void:
	var strength := jump_power * (1.0 + charge)
	var direction: Vector2
	if is_wall_attached:
		direction = (wall_normal + Vector2.UP).normalized()
		_stop_wall_attach()
	else:
		direction = Vector2.UP.rotated(rotation).normalized()
	velocity = direction * strength
	grounded = false
	was_grounded = false
	ground_collider = null
	ground_collider_prev_pos = Vector2.ZERO

func _update_compression() -> void:
	var squash_offset = SQUASH_PER_CHARGE * charge
	top_sprite.position.y = bottom_sprite.position.y - sprite_base_height_offset + squash_offset

func _reset_sprites() -> void:
	top_sprite.position.y = bottom_sprite.position.y - sprite_base_height_offset

func _start_land_animation() -> void:
	var impact_speed = max(abs(velocity.y), abs(velocity.x))
	landing_impact_factor = clamp(impact_speed / LANDING_REF_SPEED, 0.4, 1.8)
	landing_anim_timer = landing_anim_duration
	var squash := land_squash_strength * landing_impact_factor
	top_sprite.position.y = bottom_sprite.position.y - sprite_base_height_offset + squash

func _update_land_animation(delta: float) -> void:
	if landing_anim_timer > 0.0:
		landing_anim_timer -= delta
		var t: float = clamp(1.0 - (landing_anim_timer / landing_anim_duration), 0.0, 1.0)
		var squash_progress := sin(t * PI) * land_squash_strength * landing_impact_factor
		var bounce_offset := - sin(t * PI * 2.0) * land_squash_strength * land_bounce_strength * landing_impact_factor
		top_sprite.position.y = bottom_sprite.position.y - sprite_base_height_offset + squash_progress + bounce_offset
	elif not is_charging:
		_reset_sprites()

func _check_if_on_ground() -> bool:
	ground_collider = null

	for i in range(get_slide_collision_count()):
		var col := get_slide_collision(i)
		if not col:
			continue

		# Только поверхности, похожие на пол (стены и потолок не считаются)
		if col.get_normal().dot(Vector2.UP) < FLOOR_MIN_DOT:
			continue

		var body := col.get_collider()
		if not body:
			continue

		var physics_body := body as PhysicsBody2D
		if physics_body:
			if (physics_body.collision_layer & ground_collision_layer) == 0:
				continue
			var parent := physics_body.get_parent()
			if parent is Node2D and parent.is_in_group("moving_platform"):
				ground_collider = parent
			else:
				ground_collider = physics_body

		return true

	return is_on_floor()

func handle_danger() -> void:
	if not can_control:
		return
	visible = false
	can_control = false
	velocity = Vector2.ZERO
	collider.set_deferred("disabled", true)
	await get_tree().create_timer(1.0).timeout
	reset_player()

func reset_player() -> void:
	if is_wall_attached:
		_stop_wall_attach()
	is_charging = false
	charge = 0.0
	velocity = Vector2.ZERO
	current_angle = 0.0
	rotation = 0.0
	grounded = false
	was_grounded = false
	ground_collider = null
	ground_collider_prev_pos = Vector2.ZERO
	landing_anim_timer = 0.0
	_reset_sprites()
	if LevelManager.loaded_level:
		global_position = LevelManager.loaded_level.level_start_position.global_position
	collider.set_deferred("disabled", false)
	visible = true
	can_control = true
