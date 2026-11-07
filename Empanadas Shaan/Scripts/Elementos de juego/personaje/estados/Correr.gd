extends Estados_de_jugador
# Estado PARED: deslizarse por un muro caminable y saltar desde él

var muro_actual : Dictionary = {}
var lado_muro : float = 0.0     # +1 = muro a la izquierda, -1 = a la derecha
var tiempo_en_pared : float = 0.0

func iniciar() -> void:
	jugador = nodo_controlador
	jugador.en_pared = true
	jugador.coyote_timer = 0.0
	tiempo_en_pared = 0.0
	lado_muro = 0.0

	muro_actual = jugador.caminar_paredes.buscar_muro()
	if not muro_actual.is_empty():
		var n : Vector3 = muro_actual.normal
		# basis.x es la izquierda del personaje (su frente es +z).
		# Se calcula una sola vez, antes de que el cuerpo empiece a girar.
		lado_muro = signf((-n).dot(jugador.global_basis.x))

	EVENT_BUS_JUGADOR.aumentar_pde_del_jugador.emit()

func finalizar() -> void:
	if jugador:
		jugador.en_pared = false

func on_physics_process(delta: float) -> void:
	var hacia_muro : Vector3 = Vector3.ZERO
	if not muro_actual.is_empty():
		hacia_muro = -(muro_actual.normal as Vector3)
	var muro := jugador.caminar_paredes.buscar_muro(hacia_muro)

	# Perdimos el muro o tocamos el piso
	if muro.is_empty() or jugador.is_on_floor():
		mi_maquina_de_estados.cambiar_a(jugador.estados.Caer)
		return

	# Para seguir pegado hay que girar hacia el muro
	tiempo_en_pared += delta
	if tiempo_en_pared > jugador.caminar_paredes.gracia_entrada \
			and not jugador.caminar_paredes.mantiene_agarre(lado_muro):
		jugador.caminar_paredes.soltar_muro()
		mi_maquina_de_estados.cambiar_a(jugador.estados.Caer)
		return

	muro_actual = muro
	jugador.caminar_paredes.deslizar_en_muro(muro, delta)
	jugador.caminar_paredes.alinear_frente(muro, delta)

func on_unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("Salto") and not muro_actual.is_empty():
		jugador.caminar_paredes.saltar_de_muro(muro_actual)
		mi_maquina_de_estados.cambiar_a(jugador.estados.Caer)
		return

	if event.is_action_pressed("Dash"):
		EVENT_BUS_JUGADOR.usar_dash.emit()
