extends Node2D

var stages: Array[PackedScene] = [
	#preload("res://scenes/stages/stage1.tscn"),
	preload("res://scenes/stages/stage2.tscn"),
]

func _process(delta: float) -> void:
	debug_actions() # TODO: Remove this

	if transitioning:
		if transition_time_left > 0:
			do_transition(delta)
		if transition_time_left <= 0: # this can not be an "else" statement because it would introduce a 1 frame delay :((
			end_transition()
	
func debug_actions() -> void:
	if Input.is_action_just_pressed("admin"):
		if Engine.time_scale == 1:
			Engine.time_scale = 0.1
		else:
			Engine.time_scale = 1
	if Input.is_action_just_pressed("reload"):
		get_tree().change_scene_to_file("uid://b6wn33katc0y5")
	if Input.is_action_just_pressed("fullscreen"):
		var current_mode: DisplayServer.WindowMode = DisplayServer.window_get_mode()
		if current_mode == DisplayServer.WINDOW_MODE_FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

@onready var game_size: Vector2i = get_viewport_rect().size

func freak_out() -> void:
	printerr("THE VIEWPORT SHOULD *NOT* BE CHANGING SIZE EVERRRRRRR")

func _ready() -> void:
	load_stage_if_missing()

	get_viewport().size_changed.connect(freak_out)

var stage_id: int = -1
var current_stage_direction: int = 1
func load_stage_if_missing() -> void:
	var children: Array[Node] = get_children()
	var has_stage: bool = false
	for child: Node in children:
		if child.name == "CurrentStage":
			has_stage = true
			break
	if not has_stage:
		var id: int = randi_range(0, stages.size() - 1)
		var stage: TileMapLayer = stages[id].instantiate()
		stage.name = "CurrentStage"
		print(stage.get_node("StageEnd"))
		(stage.get_node("StageEnd") as Area2D).area_entered.connect(change_stage)
		add_child(stage)
		current_stage_direction = 1
		player.position = initial_player_position_left # + Vector2(0, 1024)

func change_stage(area: Area2D) -> void:
	if area.get_parent() == null or area.get_parent().name != "Player": # janky hack, i dont care
		return
	var id: int = randi_range(0, stages.size() - 1)
	var new_stage: TileMapLayer = stages[id].instantiate()
	new_stage.name = "NextStage"
	new_stage.position.y = - game_size.y

	new_stage.scale.x = - current_stage_direction
	new_stage.position.x = 0 if current_stage_direction == -1 else game_size.x

	call_deferred("add_child", new_stage)
	next_stage = new_stage

	start_stage_transition()

var current_stage: TileMapLayer = null
var next_stage: TileMapLayer = null
@onready var player: Player = $Player
var player_start_position: Vector2 = Vector2.ZERO
var player_target_position: Vector2 = Vector2.ZERO
@onready var camera: Camera2D = $Camera2D

const transition_time: float = 2
var transition_time_left: float = 0
var transitioning: bool = false

const initial_player_position_left: Vector2 = Vector2(64, 530)
const initial_player_position_right: Vector2 = Vector2(960, 530) # janky hack, i dont care
func start_stage_transition() -> void:
	current_stage = get_node("CurrentStage")
	transition_time_left = transition_time
	transitioning = true
	player.movement_enabled = false
	player_start_position = player.position
	player_target_position = initial_player_position_left if current_stage_direction == -1 else initial_player_position_right
	
func do_transition(delta: float) -> void:
	transition_time_left -= delta
	if transition_time_left <= 0: return
	var transition_progress_linear: float = 1 - (transition_time_left / transition_time)
	var transition_progress_smooth: float = smootherstep(transition_progress_linear)
	camera.position.y = game_size.y / 2.0 - game_size.y * transition_progress_smooth
	player.position = player_start_position * (1 - transition_progress_smooth) + player_target_position * (transition_progress_smooth)
	
func smootherstep(x: float) -> float:
	if x <= 0: return 0
	if x >= 1: return 1
	return 6 * (x ** 5) - 15 * (x ** 4) + 10 * (x ** 3) # smootherstep function from https://en.wikipedia.org/wiki/Smoothstep

func end_transition() -> void:
	current_stage.name = "OldStage"
	current_stage.queue_free()
	next_stage.name = "CurrentStage"
	(next_stage.get_node("StageEnd") as Area2D).area_entered.connect(change_stage)
	transition_time_left = 0
	transitioning = false
	next_stage.position.y += game_size.y
	camera.position.y += game_size.y
	player.position.y += game_size.y
	player.movement_enabled = true


######## TODO: Fix player position during and after the transition
######## TODO: Fix the flickering at the end of the transition, likely from physics interpolation if i had to guess