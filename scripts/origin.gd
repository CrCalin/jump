extends Node2D
class_name Origin

var stages: Array[PackedScene] = [
	load("uid://cvohhxtn70wyt"), # stage1.tscn
	load("uid://vd84uqce1we8"), # stage2.tscn
	load("uid://cwkv1hsfw0pxb"), # stage3.tscn
	load("uid://cobws6lpellr1"), # stage4.tscn
	load("uid://gj7k4blhtlj8"), # stage5.tscn
]

func _process(delta: float) -> void:
	#debug_actions() # TODO: Remove this

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
	if Input.is_action_just_pressed("reset_timer"):
		(get_node("%Timer") as Timer).start(3)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.is_pressed() and event.button_mask & MOUSE_BUTTON_RIGHT:
		player.position = get_local_mouse_position()

const game_size: Vector2i = Vector2i(1024, 576);

func _ready() -> void:
	load_stage_if_missing()

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
		(stage.get_node("StageEnd") as Area2D).area_entered.connect(change_stage)
		add_child(stage)
		current_stage_direction = 1
		player.position = initial_player_position_left

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

const transition_time: float = 1
var transition_time_left: float = 0
var transitioning: bool = false

const initial_player_position_left: Vector2 = Vector2(64, 530)
const initial_player_position_right: Vector2 = Vector2(960, 530) # janky hack, i dont care
signal pause_timer()
signal increment_score()
func start_stage_transition() -> void:
	current_stage = get_node("CurrentStage")
	transition_time_left = transition_time
	transitioning = true
	player.movement_enabled = false
	player_start_position = player.position
	player_target_position = initial_player_position_left if current_stage_direction == -1 else initial_player_position_right
	pause_timer.emit()
	increment_score.emit()
	
func do_transition(delta: float) -> void:
	transition_time_left -= delta
	if transition_time_left <= 0: return
	var transition_progress_linear: float = 1 - (transition_time_left / transition_time)
	var transition_progress_smooth: float = smootherstep(transition_progress_linear)
	current_stage.position.y = 0 + game_size.y * transition_progress_smooth
	next_stage.position.y = - game_size.y + game_size.y * transition_progress_smooth
	player.position = player_start_position * (1 - transition_progress_smooth) + player_target_position * (transition_progress_smooth)
	
func smootherstep(x: float) -> float:
	if x <= 0: return 0
	if x >= 1: return 1
	return 6 * (x ** 5) - 15 * (x ** 4) + 10 * (x ** 3) # smootherstep function from https://en.wikipedia.org/wiki/Smoothstep

signal resume_timer()
func end_transition() -> void:
	current_stage.name = "OldStage"
	current_stage.queue_free()
	next_stage.name = "CurrentStage"
	(next_stage.get_node("StageEnd") as Area2D).area_entered.connect(change_stage)
	transition_time_left = 0
	transitioning = false
	current_stage_direction = - current_stage_direction
	player.checkpoint = player.position
	player.movement_enabled = true
	resume_timer.emit()

var game_over_scene: PackedScene = load("uid://b8riyhh7x50sd")
func _on_game_over() -> void:
	var game_over_object: Control = game_over_scene.instantiate()
	(game_over_object.get_node("%ScoreLabel") as RichTextLabel).text = "SCORE: " + str((get_node("%ScoreLabel") as ScoreLabel).score)
	get_node("UILayer").add_child(game_over_object)

# TODO: Add credits
# TODO: Make levels!!!!