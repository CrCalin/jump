extends Area2D
class_name DashArea

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		body.dash_areas.append(self)

func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		body.dash_areas.erase(self)

const default_cooldown: float = 1.5
var cooldown: float = 0

func use() -> void:
	cooldown = default_cooldown

@onready var sprite: Sprite2D = $Sprite2D

func _process(delta: float) -> void:
	if cooldown > 0:
		cooldown -= delta
	if cooldown <= 0:
		cooldown = 0
	sprite.self_modulate = Color(1, (1 - cooldown / default_cooldown) if cooldown > 0 else 0.5, 1 if cooldown <= 0 else 0)
