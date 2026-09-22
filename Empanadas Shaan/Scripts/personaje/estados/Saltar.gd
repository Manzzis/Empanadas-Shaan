extends Estados_de_jugador
#Lógica del estado SALTAR del jugador

func iniciar() -> void:
	jugador = nodo_controlador
	
	# Aplicamos el impulso vertical
	jugador.velocity.y = jugador.fuerza_salto

func on_physics_process(_delta: float) -> void:
	if jugador.velocity.y < 0:
		mi_maquina_de_estados.cambiar_a("Caer")
	



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
