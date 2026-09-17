extends Estados_de_jugador
#Lógica del estado CAER del jugador

func on_physics_process(delta: float) -> void:
	if jugador.is_on_floor():
		var velocidad_horizontal = Vector3(jugador.velocity.x, 0, jugador.velocity.z).length()
		if velocidad_horizontal > 0.5:
			mi_maquina_de_estados.cambiar_a(jugador.estados.Caminar)
			jugador.direccion_delantera = true
		else:
			mi_maquina_de_estados.cambiar_a(jugador.estados.Idle)
	
	if jugador.riel_actual != null:
		mi_maquina_de_estados.cambiar_a(jugador.estados.Grindear)
