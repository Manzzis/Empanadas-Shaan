extends Control




func _on_comenzar_pressed() -> void:
	get_tree().change_scene_to_file("res://Escenas/Nivel layout/NIVEL GREY BOX.tscn")

func _on_salir_pressed() -> void:
	get_tree().quit()
