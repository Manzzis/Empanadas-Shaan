extends Estados_de_jugador
#Lógica del estado CAER del jugador

func on_physics_process(_delta: float) -> void:
	if jugador.is_on_floor():
		var velocidad_horizontal = Vector3(jugador.velocity.x, 0, jugador.velocity.z).length()
		if velocidad_horizontal > 0.5:
			mi_maquina_de_estados.cambiar_a(jugador.estados.Caminar)
			jugador.direccion_delantera = true
		else:
			EVENT_BUS_JUGADOR.aumentar_pde_del_jugador.emit()
			mi_maquina_de_estados.cambiar_a(jugador.estados.Idle)
	




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
