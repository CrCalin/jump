extends Control

var game_scene: PackedScene = load("uid://b6wn33katc0y5")
func _on_restart_button_pressed() -> void:
	get_tree().change_scene_to_packed(game_scene)

var main_menu_scene: PackedScene = load("uid://eoir8cgl4x6i")
func _on_back_to_title_button_pressed() -> void:
	get_tree().change_scene_to_packed(main_menu_scene)
