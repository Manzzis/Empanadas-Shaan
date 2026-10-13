class_name Rampa extends Area3D

var jugador : Jugador


func _on_body_entered(body: Node3D) -> void:
	if body is Jugador:
		EmisorDeSonidos.emitir_sonido.emit("Rampa")
		jugador = body
		jugador.rampa_actual = self


func _on_body_exited(body: Node3D) -> void:
	if body is Jugador:
		body.rampa_actual = null
