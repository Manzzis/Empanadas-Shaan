extends Node3D

@export var mi_dialogo : DialogueResource


var ya_activado := false

func _on_area_3d_area_entered(area: Area3D) -> void:
	if ya_activado:
		return
	ya_activado = true
	DialogueManager.show_dialogue_balloon(mi_dialogo)
