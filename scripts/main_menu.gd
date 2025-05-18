extends Node2D

func _on_quit_button_pressed() -> void:
	get_tree().quit()

var tutorial_scene: PackedScene = load("uid://cfmecmiirtbry")
func _on_tutorial_button_pressed() -> void:
	get_tree().change_scene_to_packed(tutorial_scene)

var game_scene: PackedScene = load("uid://b6wn33katc0y5")
func _on_play_button_pressed() -> void:
	get_tree().change_scene_to_packed(game_scene)

var about_scene: PackedScene = load("uid://08swlkr5ykyb")
func _on_about_button_pressed() -> void:
	get_tree().change_scene_to_packed(about_scene)
