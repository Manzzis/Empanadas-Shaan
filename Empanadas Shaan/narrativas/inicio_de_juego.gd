extends Node3D

@export var mi_dialogo: DialogueResource
@export var cinematica: CinematicaEmpanadas

var ya_activado := false

func _on_area_3d_body_entered(body: Node3D) -> void:
	if ya_activado or not body.is_in_group("Player"):
		return
	body.velocity.x = 0.0
	body.velocity.y = 0.0
	body.velocity.z = 0.0
	ya_activado = true
	await cinematica.iniciar(body)
	DialogueManager.show_dialogue_balloon(mi_dialogo, "", [cinematica])
