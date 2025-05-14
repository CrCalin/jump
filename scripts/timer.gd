extends Timer

@onready var text: RichTextLabel = $Text

func _ready() -> void:
	one_shot = true
	start(30)

func _process(_delta: float) -> void:
	set_color()
	set_text()

func set_text() -> void:
	var minutes: int = int(time_left / 60)
	var seconds: int = int(time_left) - minutes * 60
	var milliseconds: int = int((time_left - seconds - minutes * 60) * 1000)
	var timer_text: String = ""
	if minutes < 10:
		timer_text += "0"
	timer_text += str(minutes)
	timer_text += ":"
	if seconds < 10:
		timer_text += "0"
	timer_text += str(seconds)
	timer_text += "."
	if milliseconds < 10:
		timer_text += "00"
	elif milliseconds < 100:
		timer_text += "0"
	timer_text += str(milliseconds)
	text.text = timer_text

func set_color() -> void:
	if time_left >= 5:
		text.add_theme_color_override("default_color", Color8(255, 255, 255))
	else:
		var new_color: int = int(time_left / 5 * 255)
		text.add_theme_color_override("default_color", Color8(255, new_color, new_color))

func _on_timeout() -> void:
	print('timeout')

func _on_add_time_signal(time: float) -> void:
	start(time_left + time)

func _on_pause_timer() -> void:
	paused = true

func _on_resume_timer() -> void:
	paused = false
