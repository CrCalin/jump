extends Node2D
class_name GhostEmitter

@onready var origin: Node2D = get_node("/root/Origin")

var emitting: bool = false

var delta_time: float = 0.04
var _current_time: float = delta_time

var ghost_lifetime: float = 0.3

var sprite_frames: SpriteFrames = null

var ghost_color: Color = Color.from_string("4da6ff", Color.BLACK)
@onready var parent: Node2D = get_parent()
func _ready() -> void:
	if parent is AnimatedSprite2D:
		sprite_frames = parent.sprite_frames

@onready var _old_transform: Transform2D = parent.global_transform
func _physics_process(delta: float) -> void:
	if not emitting:
		_current_time = delta_time
	else:
		_current_time -= delta
		if _current_time <= 0:
			var sprite: Texture2D = null
			if parent is AnimatedSprite2D:
				sprite = sprite_frames.get_frame_texture(parent.animation, parent.frame)
			elif parent is Sprite2D:
				sprite = parent.texture
			else:
				print("GhostEmitter must be the direct child of a (Animated)Sprite2D")
			var ghost: Ghost = Ghost.new(_old_transform, parent.flip_h, ghost_lifetime, sprite, ghost_color)
			origin.add_child(ghost)
			_current_time = delta_time

	_old_transform = parent.global_transform
