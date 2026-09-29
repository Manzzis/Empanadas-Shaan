class_name Rampa extends Area3D

var jugador : Jugador

func _on_body_entered(body: Node3D) -> void:
	if body is Jugador:
		jugador = body
		jugador.rampa_actual = self
		print("funcó", jugador.rampa_actual)
