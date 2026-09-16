extends Estados_de_jugador
class_name Estado_Grindear

@export var velocidad_minima_grind := 8.0
@export var impulso_salto_salida := 10.0

var riel : Riel3D
var progreso_actual : float = 0.0
var direccion_grind : float = 1.0 # 1.0 hacia adelante, -1.0 hacia atrás
var velocidad_grind : float = 0.0

func iniciar() -> void:
	var jugador = nodo_controlador as Jugador
	riel = jugador.riel_actual

	if not riel:
		mi_maquina_de_estados.cambiar_a("Caer")
		return

	# 1. Encontrar el punto más cercano de la curva
	progreso_actual = riel.get_closest_progress(jugador.global_position)
	riel.path_follow.progress = progreso_actual

	# 2. Definir la velocidad (se conserva la inercia de entrada)
	var rapidez_entrada = Vector3(jugador.velocity.x, 0, jugador.velocity.z).length()
	velocidad_grind = max(rapidez_entrada, velocidad_minima_grind)

	# 3. Determinar el sentido del grind (según hacia dónde miraba el jugador)
	var tangente_riel = riel.curve.sample_baked_with_rotation(progreso_actual).basis.z
	var frente_jugador = -jugador.global_transform.basis.z

	if frente_jugador.dot(tangente_riel) < 0:
		direccion_grind = -1.0
	else:
		direccion_grind = 1.0

	# Anulamos la velocidad física convencional mientras grindea
	jugador.velocity = Vector3.ZERO

func on_physics_process(delta: float) -> void:
	var jugador = nodo_controlador as Jugador
	if not riel:
		mi_maquina_de_estados.cambiar_a("Caer")
		return

	# 1. Avanzar el progreso sobre el riel
	progreso_actual += velocidad_grind * direccion_grind * delta
	riel.path_follow.progress = progreso_actual

	# 2. Pegar la posición y rotación del jugador al PathFollow3D
	jugador.global_position = riel.path_follow.global_position
	jugador.global_rotation.y = riel.path_follow.global_rotation.y

	# 3. Salto opcional desde el riel (Espacio / ui_accept)
	if Input.is_action_just_pressed("ui_accept"):
		_salir_del_riel_con_salto(jugador)
		return

	# 4. Salida automática al terminar el recorrido
	var longitud_total = riel.curve.get_baked_length()
	if progreso_actual >= longitud_total or progreso_actual <= 0.0:
		_salir_del_riel(jugador)

func _salir_del_riel(jugador: Jugador) -> void:
	var direccion_salida = -jugador.global_transform.basis.z.normalized() * direccion_grind
	jugador.velocity = direccion_salida * velocidad_grind
	mi_maquina_de_estados.cambiar_a("Caer")

func _salir_del_riel_con_salto(jugador: Jugador) -> void:
	var direccion_salida = -jugador.global_transform.basis.z.normalized() * direccion_grind
	jugador.velocity = direccion_salida * velocidad_grind
	jugador.velocity.y = impulso_salto_salida
	mi_maquina_de_estados.cambiar_a("Saltar")
