extends CharacterBody2D
class_name Player

@onready var sprite: AnimatedSprite2D = $Sprite
@onready var ghost_emitter: GhostEmitter = %GhostEmitter
const ghost_scene: PackedScene = preload("uid://ddt05gpmv5elr")

const speed: float = 300.0
const crouch_speed: float = 150.0
const jump_velocity: float = -600.0
const jump_release_velocity_cutoff: float = -200.0
const dash_velocity: float = 600
const max_speed: float = 2000
const dash_duration: float = 0.5 # in seconds
var dash_deceleration: float:
	get():
		return dash_velocity / dash_duration

var air_dashes: int = 0
var is_dashing: bool = false
var is_sliding: bool = false

var last_horizontal_direction: float = 1

var jump_init: bool = false

var crouching: bool = false

var jump_areas: Array[JumpArea] = []
var dash_areas: Array[DashArea] = []

var movement_enabled: bool = true

func _physics_process(delta: float) -> void:
	# Movement
	velocity = Vector2.ZERO
	
	if not movement_enabled:
		set_animation("jump_ascend")
		set_ghost_emitter(true, false)
		move_and_slide()
		return

	var input_direction: Vector2 = Vector2(Input.get_axis("left", "right"), Input.get_axis("up", "down"))

	do_jump_logic(delta)

	do_gravity(delta)

	if is_on_floor():
		air_dashes = 1

	do_crouch_and_slide_logic()

	do_left_right_movement(input_direction)

	do_dash(input_direction, delta)

	cap_speed() # -------------------------------------------------------

	# Graphics
	flip_sprite_h()

	set_animation()

	set_ghost_emitter()

	# Physics
	move_and_slide()

var gravity_velocity: Vector2 = Vector2.ZERO
func do_gravity(delta: float) -> void:
	if not is_on_floor():
		gravity_velocity += get_gravity() * delta
	elif gravity_velocity.y > 0:
		gravity_velocity.y = 0

	velocity += gravity_velocity

const max_coyote_time: float = 0.07
var coyote_time: float = 0
var jumped_recently_timer: float = 0
var _old_is_on_floor: bool

func can_jump() -> bool:
	if is_on_floor():
		return true
	elif not jump_areas.is_empty():
		for jump_area: JumpArea in jump_areas:
			if jump_area.cooldown <= 0:
				jump_area.use()
				return true
		return false
	else:
		return false

func do_jump_logic(delta: float) -> void:
	sprite.self_modulate = Color(coyote_time / max_coyote_time, coyote_time / max_coyote_time, coyote_time / max_coyote_time)

	if coyote_time > 0:
		coyote_time -= delta
		if coyote_time < 0:
			coyote_time = 0
	if jumped_recently_timer > 0:
		jumped_recently_timer -= delta
		if jumped_recently_timer < 0:
			jumped_recently_timer = 0

	if jumped_recently_timer <= 0 and (_old_is_on_floor and not is_on_floor()):
		coyote_time = max_coyote_time
	_old_is_on_floor = is_on_floor()
	
	if Input.is_action_just_pressed("jump"):
		if coyote_time > 0:
			jump()
		elif can_jump():
			jump()
		coyote_time = 0
	if Input.is_action_just_released("jump") and jump_init:
		gravity_velocity.y = max(gravity_velocity.y, jump_release_velocity_cutoff)
		jump_init = false
	if is_on_ceiling() and not is_on_floor():
		gravity_velocity.y = 0
	if gravity_velocity.y >= 0:
		jump_init = false

func jump() -> void:
	gravity_velocity.y = jump_velocity
	jump_init = true
	jumped_recently_timer = max_coyote_time

func do_crouch_and_slide_logic() -> void:
	if Input.is_action_pressed("crouch") and is_on_floor() and not jump_init and not is_dashing:
		crouching = true
	elif Input.is_action_just_pressed("crouch") and abs(current_dash_velocity.x) > speed:
		# start sliding
		is_dashing = false
		is_sliding = true
	else:
		crouching = false
	if Input.is_action_just_released("crouch") and is_sliding:
		is_sliding = false
	if is_sliding and current_dash_velocity.x == 0:
		is_sliding = false

func do_left_right_movement(input_direction: Vector2) -> void:
	var left_right: float = 0
	if input_direction.x and not is_dashing:
		left_right = input_direction.x * (speed if not crouching else crouch_speed)
	else:
		left_right = 0
	
	velocity.x += left_right

func can_dash() -> bool:
	if is_dashing: return false
	if crouching: return false
	if is_on_floor(): return true
	if not dash_areas.is_empty():
		for dash_area: DashArea in dash_areas:
			if dash_area.cooldown <= 0:
				dash_area.use()
				return true
		return false
	if air_dashes > 0:
		air_dashes -= 1
		return true
	return false

var current_dash_velocity: Vector2 = Vector2.ZERO
func do_dash(input_direction: Vector2, delta: float) -> void:
	var current_horizontal_direction: float = last_horizontal_direction
	if input_direction.x < 0: current_horizontal_direction = -1
	elif input_direction.x > 0: current_horizontal_direction = 1

	if Input.is_action_just_pressed("dash") and can_dash():
		var dash_direction: Vector2 = input_direction.normalized()
		if dash_direction == Vector2.ZERO:
			dash_direction = Vector2(last_horizontal_direction, 0)
		
		if sign(dash_direction.x) == sign(current_dash_velocity.x):
			current_dash_velocity.x += dash_velocity * current_horizontal_direction
		else:
			current_dash_velocity.x = dash_velocity * current_horizontal_direction

		gravity_velocity = Vector2.ZERO

		is_dashing = true
	if current_dash_velocity.x != 0:
		current_dash_velocity.x -= dash_deceleration * sign(current_dash_velocity.x) * delta
		if is_on_wall():
			current_dash_velocity.x = 0
		if current_dash_velocity.x * sign(current_dash_velocity.x) <= speed:
			is_dashing = false
			current_dash_velocity.x = 0

	velocity += current_dash_velocity

	last_horizontal_direction = current_horizontal_direction

func cap_speed() -> void:
	if velocity.x > max_speed:
		velocity.x = max_speed
	if velocity.x < -max_speed:
			velocity.x = - max_speed
	if velocity.y > max_speed:
			velocity.y = max_speed
	if velocity.y < -max_speed:
			velocity.y = - max_speed

func flip_sprite_h() -> void:
	if velocity.x < 0:
		sprite.flip_h = true
	elif velocity.x > 0:
		sprite.flip_h = false

func set_animation(override: StringName = "") -> void:
	if override != "":
		if sprite.animation != override:
			sprite.play(override)
		return
	var animation: StringName

	if velocity.x != 0:
		animation = "run" if not crouching else "crouch_run"
	else:
		animation = "idle" if not crouching else "crouch_idle"

	if velocity.y != 0:
		if velocity.y < 0:
			if jump_init:
				animation = "jump_init"
			else:
				animation = "jump_ascend"
		else:
			animation = "jump_descend"

	if is_dashing:
		animation = "dash"

	if is_sliding:
		animation = "slide"

	if sprite.animation != animation:
		sprite.play(animation)

func set_ghost_emitter(override: bool = false, value: bool = false) -> void:
	if override:
		ghost_emitter.emitting = value
		return
	if abs(velocity.x) > speed:
		ghost_emitter.emitting = true
	else:
		ghost_emitter.emitting = false

func die() -> void:
	queue_free()

func _on_area_entered(area: Area2D) -> void:
	if area.name == "StageEnd":
		return
	die()

signal add_time_signal(time: float)
func add_time(time: float) -> void:
	add_time_signal.emit(time)