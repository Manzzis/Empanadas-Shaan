extends Estados_de_jugador
# Lógica del estado de Caminar

var direccion : int


func on_process(delta: float) -> void:
	if jugador.direccion_delantera:
		direccion = 1
	else:
		direccion = -1


func on_physics_process(delta: float) -> void:
	handle_gravity(delta)
	
	# Dirección hacia adelante del jugador
	var adelante := jugador.transform.basis.z
	
	# Dirección objetivo
	var velocidad_objetivo := adelante * jugador.velocidad * direccion
	
	# Aceleración hacia esa dirección
	jugador.velocity.x = move_toward(
		jugador.velocity.x,
		velocidad_objetivo.x,
		jugador.aceleracion * delta
	)
	
	jugador.velocity.z = move_toward(
		jugador.velocity.z,
		velocidad_objetivo.z,
		jugador.aceleracion * delta
	)


func on_input(event: InputEvent) -> void:
	pass


func on_unhandled_input(event: InputEvent) -> void:

	# Cambiar dirección mientras caminamos
	
	if event.is_action_pressed("Adelante"):
		jugador.direccion_delantera = true
	
	if event.is_action_pressed("Atras"):
		jugador.direccion_delantera = false
	
	
	# Dejar de caminar
	
	if jugador.direccion_delantera:
		if event.is_action_released("Adelante"):
			mi_maquina_de_estados.cambiar_a(jugador.estados.Idle)
	else:
		if event.is_action_released("Atras"):
			mi_maquina_de_estados.cambiar_a(jugador.estados.Idle)


func on_unhandled_key_input(event: InputEvent) -> void:
	pass
