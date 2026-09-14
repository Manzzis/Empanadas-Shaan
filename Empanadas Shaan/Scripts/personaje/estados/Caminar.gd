extends Estados_de_jugador
#Lógica del estado de Caminar

func on_process(delta: float) -> void:
	pass

func on_physics_process(delta: float) -> void:
	handle_gravity(delta)
	
	jugador.velocity.z = move_toward(jugador.velocity.z,jugador.velocidad,jugador.aceleracion * delta)

func on_input(event: InputEvent) -> void:
	pass

func on_unhandled_input(event: InputEvent) -> void:
	if event.is_action_released("Adelante"):
		mi_maquina_de_estados.cambiar_a(jugador.estados.Idle)

func on_unhandled_key_input(event: InputEvent) -> void:
	pass
