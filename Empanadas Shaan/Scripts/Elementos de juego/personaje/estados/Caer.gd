extends Estados_de_jugador
#Lógica del estado CAER del jugador

# Control en el aire (1.0 = igual que en el suelo, menos = menos control)
@export var control_aereo: float = 0.6

func on_physics_process(delta: float) -> void:
	moverse(delta)
	#print("CAER | coyote: ", snapped(jugador.coyote_timer, 0.01))
	
	# Coyote time: saltar poco después de dejar el suelo
	if Input.is_action_just_pressed("Salto") and jugador.puede_saltar_coyote():
		mi_maquina_de_estados.cambiar_a(jugador.estados.Saltar)
		return
	
	if jugador.is_on_floor():
		var velocidad_horizontal = Vector3(jugador.velocity.x, 0, jugador.velocity.z).length()
		if velocidad_horizontal > 0.5:
			mi_maquina_de_estados.cambiar_a(jugador.estados.Caminar)
		else:
			EVENT_BUS_JUGADOR.aumentar_pde_del_jugador.emit()
			mi_maquina_de_estados.cambiar_a(jugador.estados.Idle)

func moverse(delta: float) -> void:
	# Calculamos la dirección según el input (adelante = 1, atrás = -1)
	var direccion := Input.get_axis("Atras", "Adelante")
	
	if direccion != 0.0:
		var adelante := jugador.get_adelante()
		
		var direccion_objetivo := adelante.normalized() * direccion
		var velocidad_objetivo := direccion_objetivo * jugador.velocidad
		
		var velocidad_horizontal_actual := Vector3(jugador.velocity.x, 0, jugador.velocity.z)
		var velocidad_horizontal_objetivo := Vector3(velocidad_objetivo.x, 0, velocidad_objetivo.z)
		
		var nueva_velocidad_horizontal := velocidad_horizontal_actual.move_toward(
			velocidad_horizontal_objetivo,
			jugador.aceleracion * control_aereo * delta
		)
		
		jugador.velocity.x = nueva_velocidad_horizontal.x
		jugador.velocity.z = nueva_velocidad_horizontal.z
	# Sin input: conservamos el impulso horizontal (no cambiamos a Idle en el aire)

func on_unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("Dash"):
		EVENT_BUS_JUGADOR.usar_dash.emit()
	# Cambiar dirección mientras caminamos
	if event.is_action_pressed("Adelante"):
		jugador.direccion_delantera = true
	if event.is_action_pressed("Atras"):
		jugador.direccion_delantera = false


func _on_grind_area_area_entered(area: Area3D) -> void:
	if mi_maquina_de_estados == null or mi_maquina_de_estados.estado_actual != self:
		return
	
	# 2. Consultamos si Grindear tiene el cooldown activo
	var estado_grind = mi_maquina_de_estados.get_node_or_null("Grindear")
	if estado_grind and not estado_grind.puede_grindear:
		return

	# 3. Lógica original para entrar al riel
	if area.is_in_group("RailPath") and jugador.velocity.y <= 0:
		var parent_path = area.get_parent()
		if parent_path is Path3D:
			jugador.riel_actual = parent_path
			mi_maquina_de_estados.cambiar_a("Grindear")
