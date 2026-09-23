extends Estados_de_jugador
# Lógica del estado de Caminar

var direccion : int

func iniciar():
	jugador = nodo_controlador
	#enviamos señal al event bus del jugador
	mas_puntos_de_estilo.emit()

func on_process(_delta: float) -> void:
	if jugador.direccion_delantera:
		direccion = 1
	else:
		direccion = -1


# Reemplaza esta función en tu script de Caminar
func on_physics_process(delta: float) -> void:
	moverse(delta)
	comprobar_riel()
	comprobar_velocidad()

func on_input(_event: InputEvent) -> void:
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
	
	if event.is_action_pressed("Salto"):
		mi_maquina_de_estados.cambiar_a(jugador.estados.Saltar)


func on_unhandled_key_input(_event: InputEvent) -> void:
	pass

#######################################################################
func moverse(delta):
	if Input.is_action_pressed("Adelante") or Input.is_action_pressed("Atras"):
		# Dirección hacia adelante del jugador
		var adelante := jugador.transform.basis.z
		
		# Dirección objetivo (normalizada para asegurar consistencia)
		var direccion_objetivo := adelante.normalized() * direccion
		var velocidad_objetivo := direccion_objetivo * jugador.velocidad
		
		# Creamos un vector temporal solo para el movimiento horizontal actual
		var velocidad_horizontal_actual := Vector3(jugador.velocity.x, 0, jugador.velocity.z)
		var velocidad_horizontal_objetivo := Vector3(velocidad_objetivo.x, 0, velocidad_objetivo.z)
		
		# Aplicamos la aceleración a todo el vector horizontal al mismo tiempo
		var nueva_velocidad_horizontal = velocidad_horizontal_actual.move_toward(
			velocidad_horizontal_objetivo,
			jugador.aceleracion * delta
		)
		
		# Asignamos de vuelta los valores al jugador sin alterar la gravedad (Y)
		jugador.velocity.x = nueva_velocidad_horizontal.x
		jugador.velocity.z = nueva_velocidad_horizontal.z
	else:
		mi_maquina_de_estados.cambiar_a(jugador.estados.Idle)

func comprobar_riel():
	if jugador.riel_actual != null:
		mi_maquina_de_estados.cambiar_a(jugador.estados.Grindear)

func comprobar_velocidad():
	if jugador.riel_actual != null:
		return
	var velocidad_horizontal = Vector3(jugador.velocity.x, 0, jugador.velocity.z).length()
	if velocidad_horizontal < 5.0:
		menos_puntos_de_estilo.emit()
