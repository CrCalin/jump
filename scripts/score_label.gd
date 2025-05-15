extends RichTextLabel
class_name ScoreLabel

var score: int:
	get():
		return score
	set(new_value):
		score = new_value
		text = "SCORE: " + str(score)

func _ready() -> void:
	score = 0

signal increment_time_multiplier()
func increment_score() -> void:
	score = score + 1
	if score % 5 == 0:
		increment_time_multiplier.emit()