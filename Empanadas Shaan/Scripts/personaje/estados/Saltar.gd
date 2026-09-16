extends Estados_de_jugador

@export var fuerza_salto : float = 12.0

func iniciar() -> void:
	var jugador = nodo_controlador as Jugador
	# Aplicamos el impulso vertical
	jugador.velocity.y = fuerza_salto

func on_physics_process(delta: float) -> void:
	var jugador = nodo_controlador as Jugador

	# Mantenemos el control de giro en el aire
	jugador.girar(delta)

	# 1. Si detecta un riel mientras salta, pasa inmediatamente a grindear
	if jugador.riel_actual != null:
		mi_maquina_de_estados.cambiar_a("Grindear")
		return

	# 2. Transición a Caer cuando empieza a descender
	if jugador.velocity.y < 0:
		mi_maquina_de_estados.cambiar_a("Caer")
		return

	# 3. Transición a suelo si toca piso antes de tiempo
	if jugador.is_on_floor():
		var velocidad_horizontal = Vector3(jugador.velocity.x, 0, jugador.velocity.z).length()
		if velocidad_horizontal > 0.5:
			mi_maquina_de_estados.cambiar_a("Caminar")
		else:
			mi_maquina_de_estados.cambiar_a("Idle")
