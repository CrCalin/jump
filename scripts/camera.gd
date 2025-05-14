extends Camera2D

const initial_strength: float = 20
const shake_fade: float = 5

var rng: RandomNumberGenerator = RandomNumberGenerator.new()

var shake_strength: float = 0

func shake() -> void:
	shake_strength = initial_strength

func _process(delta: float) -> void:
	if shake_strength > 0:
		shake_strength = lerpf(shake_strength, 0, shake_fade * delta)

		offset = random_offset()

func random_offset() -> Vector2:
	return Vector2(rng.randf_range(-1, 1), rng.randf_range(-1, 1)).normalized() * shake_strength