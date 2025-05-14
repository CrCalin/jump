extends HBoxContainer
class_name HeartContainer

const max_lives: int = 3 # do not change this unless you also chage the UI
var lives: int = 3

var hearts: Array[TextureRect] = []

const full_heart_texture: Texture2D = preload("uid://dgktivuk8b8ri")
const empty_heart_texture: Texture2D = preload("uid://b1imm8hqa7l17")

func _ready() -> void:
	for i: int in range(max_lives):
		hearts.append(get_node("Heart" + str(i)))

signal game_over()
func set_lives(new_value: int) -> bool: # returns true if the player has reached 0 lives
	if new_value < 0:
		return true
	for i: int in range(new_value):
		hearts[i].texture = full_heart_texture
	for i: int in range(new_value, max_lives):
		hearts[i].texture = empty_heart_texture
	lives = new_value
	if lives == 0:
		game_over.emit()
	return new_value == 0

func decrement_lives() -> bool: # returns true if the player has reached 0 lives
	return set_lives(lives - 1)