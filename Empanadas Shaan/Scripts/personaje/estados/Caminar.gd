extends Estados_de_jugador
#Lógica del estado de Caminar


func on_input(event):
	if not Input.is_action_pressed("ui_left") and not Input.is_action_pressed("ui_right"):
		mi_maquina_de_estados.cambiar_a(jugador.estados.Idle)
