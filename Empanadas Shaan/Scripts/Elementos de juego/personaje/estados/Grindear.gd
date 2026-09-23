extends Estados_de_jugador
class_name Estado_Grindear

@export var velocidad_minima_grind := 8.0
@export var impulso_salto_salida := 10.0

var riel : Path3D
var path_follow : PathFollow3D
var progreso_actual : float = 0.0
var direccion_grind : float = 1.0 
var velocidad_grind : float = 0.0

var puede_grindear : bool = true

func activar_cooldown() -> void:
	puede_grindear = false
	await get_tree().create_timer(0.3).timeout
	puede_grindear = true

func iniciar() -> void:
	super.iniciar()
	
	# LA MAGIA: Apagamos el _physics_process del Jugador. 
	# Esto desactiva su gravedad y move_and_slide temporalmente.
	jugador.set_physics_process(false) 

	riel = jugador.riel_actual as Path3D
	if not riel:
		mi_maquina_de_estados.cambiar_a(jugador.estados.Saltar)
		return

	path_follow = riel.get_node_or_null("PathFollow3D")
	if not path_follow:
		mi_maquina_de_estados.cambiar_a(jugador.estados.Caer)
		return

	path_follow.loop = false
	# Calcula la entrada al riel
	var posicion_local = riel.to_local(jugador.global_position)
	progreso_actual = riel.curve.get_closest_offset(posicion_local)
	path_follow.progress = progreso_actual
	
	# 1. Aislamos la velocidad puramente horizontal (ignoramos la gravedad)
	var vel_horizontal = Vector3(jugador.velocity.x, 0, jugador.velocity.z)
	var rapidez_entrada = vel_horizontal.length()
	velocidad_grind = max(rapidez_entrada, velocidad_minima_grind)

	# 2. Calculamos la dirección de entrada basados solo en el plano horizontal
	var direccion_entrada : Vector3
	if rapidez_entrada > 0.1:
		direccion_entrada = vel_horizontal.normalized()
	else:
		# Si cae totalmente quieto en vertical, usamos hacia dónde está mirando el modelo
		direccion_entrada = -jugador.global_transform.basis.z
	
	var frente_riel = -path_follow.global_transform.basis.z
	if direccion_entrada.dot(frente_riel) >= 0.0:
		direccion_grind = 1.0
	else:
		direccion_grind = -1.0
	jugador.velocity = Vector3.ZERO
	EVENT_BUS_JUGADOR.aumentar_pde_del_jugador.emit()


# NUEVO: Función que se ejecuta al salir del estado.
# (Si en tu máquina de estados se llama de otra forma, como exit(), cámbiale el nombre).
func finalizar() -> void:
	# Al salir del grindeo, volvemos a encender las físicas del jugador.
	if jugador:
		jugador.set_physics_process(true)


func on_physics_process(delta: float) -> void:
	if not riel or not path_follow:
		_salir_del_riel()
		return

	progreso_actual += velocidad_grind * direccion_grind * delta
	path_follow.progress = progreso_actual
	jugador.global_position = path_follow.global_position

	if direccion_grind > 0:
		jugador.global_rotation.y = path_follow.global_rotation.y + PI
	else:
		jugador.global_rotation.y = path_follow.global_rotation.y

	# Asegúrate de usar la acción de salto correcta aquí ("ui_accept" o la tuya)
	if Input.is_action_just_pressed("ui_accept"): 
		_salir_del_riel_con_salto()
		return

	var longitud_total = riel.curve.get_baked_length()
	if progreso_actual >= longitud_total or progreso_actual <= 0.0:
		_salir_del_riel()

func _obtener_direccion_avance() -> Vector3:
	var frente_riel = -path_follow.global_transform.basis.z
	return (frente_riel * direccion_grind).normalized()

func _salir_del_riel() -> void:
	activar_cooldown()
	var dir_salida = _obtener_direccion_avance()
	jugador.velocity = dir_salida * velocidad_grind
	jugador.velocity.y = 2.0 
	mi_maquina_de_estados.cambiar_a(jugador.estados.Caer)

func _salir_del_riel_con_salto() -> void:
	activar_cooldown()
	var dir_salida = _obtener_direccion_avance()
	jugador.velocity = dir_salida * velocidad_grind
	jugador.velocity.y = impulso_salto_salida
	mi_maquina_de_estados.cambiar_a(jugador.estados.Saltar)
