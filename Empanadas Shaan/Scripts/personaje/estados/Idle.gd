extends Estados_de_jugador
#Lógica del estado de Idle

func on_physics_process(delta):
	handle_gravity(delta)

func on_input(event):
	if Input.is_action_pressed("ui_left") or Input.is_action_pressed("ui_right"):
		mi_maquina_de_estados.cambiar_a(jugador.estados.Caminar)
