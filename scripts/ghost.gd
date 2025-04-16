extends Sprite2D
class_name Ghost

static var CURVE: Curve = null

static func _static_init() -> void:
	if CURVE != null:
		print("WTF")
	CURVE = Curve.new()
	CURVE.add_point(Vector2(0, 0.5))
	CURVE.add_point(Vector2(1, 0))

var max_time: float = 1
var time_left: float = 1
var curve: Curve = CURVE

func _init(ghost_transform: Transform2D, flipped: bool, time: float, sprite: Texture2D, ghost_color: Color = Color.WHITE, curve_override: Curve = null) -> void:
	global_transform = ghost_transform
	flip_h = flipped
	self_modulate = ghost_color
	max_time = time
	time_left = time
	texture = sprite
	curve = curve_override if curve_override != null else curve

func _process(delta: float) -> void:
	self_modulate = Color(self_modulate.r, self_modulate.g, self_modulate.b, curve.sample(1 - time_left / max_time))

	time_left -= delta

	if time_left <= 0:
		queue_free()
