extends Button

var main_menu_scene: PackedScene = load("uid://eoir8cgl4x6i")
func _on_pressed() -> void:
	get_tree().change_scene_to_packed(main_menu_scene)