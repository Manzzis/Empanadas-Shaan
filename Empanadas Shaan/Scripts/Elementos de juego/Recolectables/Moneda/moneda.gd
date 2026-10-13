extends Area3D

@export var velocidad_rotacion = 2.0


func _process(delta):
	rotate_y(velocidad_rotacion * delta)

func _on_body_entered(body):
	if body.has_method("sumar_moneda"):
		body.sumar_moneda()
		EmisorDeSonidos.emitir_sonido.emit("Monedas")
		queue_free()
