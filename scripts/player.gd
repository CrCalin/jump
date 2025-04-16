extends CharacterBody2D
class_name Player

@onready var sprite: AnimatedSprite2D = $Sprite
@onready var ghost_emitter: GhostEmitter = %GhostEmitter
const ghost_scene: PackedScene = preload("uid://ddt05gpmv5elr")

var speed: float = 400.0
var crouch_speed: float = 150.0
var jump_velocity: float = -600.0
var jump_release_velocity_cutoff: float = -200.0
var dash_velocity: float = 1000
var max_speed: float = 4000
var dash_duration: float = 0.4 # in seconds
var dash_deceleration: float:
	get():
		return dash_velocity / dash_duration
	set(value):
		dash_duration = dash_velocity / value

var air_dashes: int = 0
var is_dashing: bool = false
var current_dash_velocity: Vector2 = Vector2.ZERO
var is_sliding: bool = false

var last_direction: float = 1

var jump_init: bool = false

var crouching: bool = false

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("admin"):
		if Engine.time_scale == 1:
			Engine.time_scale = 0.1
		else:
			Engine.time_scale = 1

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
	else:
		air_dashes = 1

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity
		jump_init = true
	if Input.is_action_just_released("jump") and velocity.y < 0:
		velocity.y = max(velocity.y, jump_release_velocity_cutoff)
		jump_init = false
	if velocity.y >= 0:
		jump_init = false

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

	var direction: float = Input.get_axis("left", "right")
	if direction and not is_dashing:
		velocity.x = direction * (speed if not crouching else crouch_speed)
	else:
		velocity.x = 0

	var current_direction: float = last_direction
	if direction < 0: current_direction = -1
	elif direction > 0: current_direction = 1

	if Input.is_action_just_pressed("dash") and not is_dashing and not crouching and (is_on_floor() or air_dashes > 0):
		
		if current_direction == sign(current_dash_velocity.x):
			current_dash_velocity.x += dash_velocity * current_direction
		else:
			current_dash_velocity.x = dash_velocity * current_direction
		is_dashing = true
		if not is_on_floor():
			air_dashes -= 1
	if current_dash_velocity.x != 0:
		current_dash_velocity.x -= dash_deceleration * sign(current_dash_velocity.x) * delta
		if current_dash_velocity.x * sign(current_dash_velocity.x) <= speed:
			is_dashing = false
			current_dash_velocity.x = 0

	velocity += current_dash_velocity

	if velocity.x > max_speed:
		velocity.x = max_speed
	if velocity.x < -max_speed:
			velocity.x = - max_speed
	if velocity.y > max_speed:
			velocity.y = max_speed
	if velocity.y < -max_speed:
			velocity.y = - max_speed

	if velocity.x < 0:
		sprite.flip_h = true
	elif velocity.x > 0:
		sprite.flip_h = false

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

	if abs(velocity.x) > speed:
		ghost_emitter.emitting = true
	else:
		ghost_emitter.emitting = false
	
	if sprite.animation != animation:
		sprite.play(animation)

	move_and_slide()

	last_direction = current_direction
