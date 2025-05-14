extends Area2D

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		if body.heart_container.lives < body.heart_container.max_lives:
			body.heart_container.increment_lives()
			queue_free()
