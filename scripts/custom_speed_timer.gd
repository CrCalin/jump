extends Node
class_name CustomSpeedTimer

var time_left: float = 0
var speed: float = 1

var paused: bool = false

signal timeout()
func _process(delta: float) -> void:
	if paused: return
	if time_left <= 0: return

	time_left -= delta * speed

	if time_left <= 0:
		time_left = 0
		timeout.emit()

func start(time: float) -> void:
	time_left = time
