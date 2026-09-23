extends Estados_de_jugador
#Lógica del estado de Idle

#Cada estado debe tener 2 partes: 
#	1: su funcionamiento lógico
#	2: su cambio hacia otro estado

#debe tener los métodos de procesamiento comunes pero seguidos de un "on_",
#de esta manera, se asegura de que el unico proceso consultando cosas 60 veces x frame
#sea el de la máquina de estados

# el estado se cambia con:
# mi_maquina_de_estados.cambiar_a(jugador.estados.elegimosEstado)

func on_process(_delta: float) -> void:
	pass

func on_physics_process(delta: float) -> void:
	calcular_friccion(delta)
	comprobar_velocidad()

func on_input(_event: InputEvent) -> void:
	pass

func on_unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("Adelante"):
		mi_maquina_de_estados.cambiar_a(jugador.estados.Caminar)
		jugador.direccion_delantera = true
	
	if event.is_action_pressed("Atras"):
		mi_maquina_de_estados.cambiar_a(jugador.estados.Caminar)
		jugador.direccion_delantera = false
	
	if event.is_action_pressed("Salto"):
		mi_maquina_de_estados.cambiar_a(jugador.estados.Saltar)
		jugador.direccion_delantera = true
	
func on_unhandled_key_input(_event: InputEvent) -> void:
	pass


#######################################################################################

func calcular_friccion(delta):
	# 1. Extraemos la velocidad horizontal global actual
	var vel_global := Vector3(jugador.velocity.x, 0, jugador.velocity.z)
	
	# 2. Traducimos la velocidad global a espacio LOCAL del jugador
	# x_local será el movimiento lateral y z_local el movimiento adelante/atrás
	var x_local := vel_global.dot(jugador.transform.basis.x)
	var z_local := vel_global.dot(jugador.transform.basis.z)
	
	# 3. Aplicamos fricciones locales independientes
	# En unos rollers, la fricción lateral suele ser más alta que la del rodamiento
	var friccion_lateral := jugador.friccion_lateral  # Frena rápido el desplazamiento de lado
	var friccion_rodamiento := jugador.friccion      # Frena más lento el avance
	
	x_local = move_toward(x_local, 0.0, friccion_lateral * delta)
	z_local = move_toward(z_local, 0.0, friccion_rodamiento * delta)
	
	# 4. Reconstruimos el vector reconstruyendo los ejes locales en el espacio del mundo
	var nueva_vel_global := (jugador.transform.basis.x * x_local) + (jugador.transform.basis.z * z_local)
	
	# 5. Asignamos de vuelta al jugador conservando su gravedad intacta
	jugador.velocity.x = nueva_vel_global.x
	jugador.velocity.z = nueva_vel_global.z

func comprobar_velocidad():
	var velocidad_horizontal = Vector3(jugador.velocity.x, 0, jugador.velocity.z).length()
	if velocidad_horizontal < 5.0:
		EVENT_BUS_JUGADOR.reducir_pde_del_jugador.emit()
