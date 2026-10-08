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
	
	if event.is_action_pressed("Dash"):
		EVENT_BUS_JUGADOR.usar_dash.emit()
		jugador.direccion_delantera = true
	
func on_unhandled_key_input(_event: InputEvent) -> void:
	pass


#######################################################################################

func calcular_friccion(delta):
	var vel_global := Vector3(jugador.velocity.x, 0, jugador.velocity.z)
	
	# Usar GLOBAL_transform.basis para coincidir con la velocity global
	var basis_x := jugador.global_transform.basis.x
	var basis_z := jugador.global_transform.basis.z
	
	var x_local := vel_global.dot(basis_x)
	var z_local := vel_global.dot(basis_z)
	
	var friccion_lateral := jugador.friccion_lateral  
	var friccion_rodamiento := jugador.friccion      
	
	x_local = move_toward(x_local, 0.0, friccion_lateral * delta)
	z_local = move_toward(z_local, 0.0, friccion_rodamiento * delta)
	
	# Reconstruimos usando los mismos basis globales
	var nueva_vel_global := (basis_x * x_local) + (basis_z * z_local)
	
	jugador.velocity.x = nueva_vel_global.x
	jugador.velocity.z = nueva_vel_global.z


func comprobar_velocidad():
	var velocidad_horizontal = Vector3(jugador.velocity.x, 0, jugador.velocity.z).length()
	if velocidad_horizontal < 5.0:
		EVENT_BUS_JUGADOR.reducir_pde_del_jugador.emit()
