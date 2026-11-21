extends Node3D

@export var mi_dialogo : DialogueResource


var ya_activado := false


func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.is_in_group("Player"):
		if ya_activado:
			return
		ya_activado = true
		DialogueManager.show_dialogue_balloon(mi_dialogo)
