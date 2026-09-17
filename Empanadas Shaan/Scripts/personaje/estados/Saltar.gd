extends Estados_de_jugador
#Lógica del estado SALTAR del jugador

func iniciar() -> void:
	jugador = nodo_controlador
	# Aplicamos el impulso vertical
	jugador.velocity.y = jugador.fuerza_salto

func on_physics_process(delta: float) -> void:
	if jugador.velocity.y < 0:
		mi_maquina_de_estados.cambiar_a(jugador.estados.Caer)
	
	if jugador.riel_actual != null:
		mi_maquina_de_estados.cambiar_a(jugador.estados.Grindear)
