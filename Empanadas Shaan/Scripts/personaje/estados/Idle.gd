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

func on_process(delta: float) -> void:
	pass

func on_physics_process(delta: float) -> void:
	handle_gravity(delta)

func on_input(event: InputEvent) -> void:
	pass

func on_unhandled_input(event: InputEvent) -> void:
	pass

func on_unhandled_key_input(event: InputEvent) -> void:
	pass
