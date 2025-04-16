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
var is_sliding: bool = false

var last_horizontal_direction: float = 1

var jump_init: bool = false

var crouching: bool = false

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("admin"):
		if Engine.time_scale == 1:
			Engine.time_scale = 0.1
		else:
			Engine.time_scale = 1

func _physics_process(delta: float) -> void:
	velocity = Vector2.ZERO

	var input_direction: Vector2 = Vector2(Input.get_axis("left", "right"), Input.get_axis("up", "down"))

	do_jump_logic()

	do_gravity(delta)

	if is_on_floor():
		air_dashes = 1

	do_crouch_and_slide_logic()

	do_left_right_movement(input_direction)

	do_dash(input_direction, delta)

	cap_speed() # -------------------------------------------------------

	flip_sprite_h()

	set_animation()

	set_ghost_emitter()

	move_and_slide()

var gravity_velocity: Vector2 = Vector2.ZERO
func do_gravity(delta: float) -> void:
	if not is_on_floor():
		gravity_velocity += get_gravity() * delta
	elif gravity_velocity.y > 0:
		gravity_velocity.y = 0

	velocity += gravity_velocity

func do_jump_logic() -> void:
	if Input.is_action_just_pressed("jump") and is_on_floor():
		gravity_velocity.y = jump_velocity
		jump_init = true
	if Input.is_action_just_released("jump") and velocity.y < 0:
		gravity_velocity.y = max(gravity_velocity.y, jump_release_velocity_cutoff)
		jump_init = false
	if gravity_velocity.y >= 0:
		jump_init = false

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

var current_dash_velocity: Vector2 = Vector2.ZERO
func do_dash(input_direction: Vector2, delta: float) -> void:
	var current_horizontal_direction: float = last_horizontal_direction
	if input_direction.x < 0: current_horizontal_direction = -1
	elif input_direction.x > 0: current_horizontal_direction = 1

	if Input.is_action_just_pressed("dash") and not is_dashing and not crouching and (is_on_floor() or air_dashes > 0):
		var dash_direction: Vector2 = input_direction.normalized()
		if dash_direction == Vector2.ZERO:
			dash_direction = Vector2(last_horizontal_direction, 0)
		
		if sign(dash_direction.x) == sign(current_dash_velocity.x):
			current_dash_velocity.x += dash_velocity * current_horizontal_direction
		else:
			current_dash_velocity.x = dash_velocity * current_horizontal_direction

		is_dashing = true
		if not is_on_floor():
			air_dashes -= 1
	if current_dash_velocity.x != 0:
		current_dash_velocity.x -= dash_deceleration * sign(current_dash_velocity.x) * delta
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

func set_animation() -> void:
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

func set_ghost_emitter() -> void:
	if abs(velocity.x) > speed:
		ghost_emitter.emitting = true
	else:
		ghost_emitter.emitting = false
