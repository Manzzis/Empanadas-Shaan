extends Node
## Autoload "Metrics" (Project Settings > Globals > Autoload).
##
## Observa al jugador (nodo del grupo "Player") y guarda cada evento como una
## línea de texto en user://metricas/sesion_<número>.jsonl
##
## Cada línea es: {"tipo": "...", "nivel": "...", "t": segundos, "datos": {...}}
##
## Para agregar una métrica: escribí un método medir_xxx() y llamalo en
## _physics_process. Dentro, usá registrar("nombre", {datos}).


# ---------- Configuración: lo único que quizás quieras tocar ----------

const ACCION_GIRAR_IZQ := "Girar_izq"
const ACCION_GIRAR_DER := "Girar_der"
const ACCION_FRENO := "Atras"            # poné acá el nombre real de tu tecla S

const SEGUNDOS_ENTRE_MUESTRAS := 3.0     # mapa de calor
const IMPULSO_SALTO := 1.0               # velocity.y mínima para contar un salto
const VELOCIDAD_QUIETO := 0.1            # m/s: por debajo, está quieto
const SEGUNDOS_MINIMOS_QUIETO := 0.25    # ignora pausas más cortas que esto
const VELOCIDAD_ACOMODO := 0.5           # m/s: por debajo, cuenta como "casi quieto"
const SEGUNDOS_ENTRE_ACOMODOS := 3.0
const SEGUNDOS_PARA_DUDA := 2.0          # tiempo quieto que activa la duda...
const VENTANA_DUDA := 3.0                # ...y plazo para saltar desde entonces
const SEGUNDOS_RECUPERACION := 3.0       # cuánto se mide tras aterrizar
const SEGUNDOS_ENTRE_RECUPERACION := 0.5


# ---------- Estado (lo que el script recuerda de un frame al otro) ----------

var jugador: Jugador
var nivel := ""
var segundos_nivel := 0.0

var velocidad := Vector3.ZERO            # calculada con la posición, no con velocity
var posicion_anterior := Vector3.ZERO
var hubo_teletransporte := false         # evita un pico de velocidad al reaparecer

var archivo: FileAccess

var reloj_muestra := 0.0

var estaba_en_suelo := true
var en_salto := false
var id_salto := 0
var posicion_salto := Vector3.ZERO

var segundos_quieto := 0.0
var segundos_desde_duda := 999.0         # tiempo desde que llevaba SEGUNDOS_PARA_DUDA quieto
var segundos_desde_acomodo := 999.0

var tocando_pared := false
var segundos_pared := 0.0

var segundos_desde_aterrizaje := 999.0
var reloj_recuperacion := 0.0


func _ready() -> void:
	process_physics_priority = 100  # corre DESPUÉS de que el jugador se movió


func _physics_process(delta: float) -> void:
	_buscar_jugador()
	if jugador == null:
		return

	# Velocidad real: cuánto se movió desde el frame anterior.
	if hubo_teletransporte:
		velocidad = Vector3.ZERO
		hubo_teletransporte = false
	else:
		velocidad = (jugador.global_position - posicion_anterior) / delta
	posicion_anterior = jugador.global_position
	segundos_nivel += delta

	medir_muestras(delta)
	medir_saltos()
	medir_quieto(delta)
	medir_acomodo(delta)
	medir_pared(delta)
	medir_recuperacion(delta)


# =====================================================================
#  MÉTRICAS
# =====================================================================

## MAPA DE CALOR + VELOCIDAD: guarda posición y velocidad cada pocos segundos.
func medir_muestras(delta: float) -> void:
	reloj_muestra += delta
	if reloj_muestra < SEGUNDOS_ENTRE_MUESTRAS:
		return
	reloj_muestra = 0.0
	registrar("muestra", {
		"pos": _punto(jugador.global_position),
		"vel": _punto(velocidad),
	})


## MAPA DE SALTOS: registra el despegue y el aterrizaje de cada salto.
## También comprueba la DUDA: si se saltó poco después de estar quieto.
func medir_saltos() -> void:
	var en_suelo := jugador.is_on_floor()
	var despego := estaba_en_suelo and not en_suelo and jugador.velocity.y > IMPULSO_SALTO
	var aterrizo := not estaba_en_suelo and en_suelo and en_salto
	estaba_en_suelo = en_suelo

	if despego:
		en_salto = true
		id_salto += 1
		posicion_salto = jugador.global_position
		registrar("salto", {"id": id_salto, "pos": _punto(posicion_salto)})
		if segundos_desde_duda < VENTANA_DUDA:
			registrar("duda", {"pos": _punto(posicion_salto)})
			segundos_desde_duda = 999.0  # no contar dos veces la misma duda

	if aterrizo:
		en_salto = false
		segundos_desde_aterrizaje = 0.0   # activa medir_recuperacion
		reloj_recuperacion = 0.0
		registrar("aterrizaje", {
			"id": id_salto,
			"pos": _punto(jugador.global_position),
			"desde": _punto(posicion_salto),   # el visor une ambos con una línea
		})


## MUERTES Y CAÍDAS: la llama la fall zone (u otra causa de muerte) ANTES de
## mover al jugador, para guardar dónde murió.
func registrar_muerte(causa: String = "fall_zone") -> void:
	registrar("muerte", {
		"pos": _punto(jugador.global_position),
		"causa": causa,
		"tras_salto": en_salto,   # true = azul, false = amarillo en el visor
	})
	en_salto = false
	estaba_en_suelo = true
	hubo_teletransporte = true


## TIEMPO QUIETO: suma segundos mientras está en el suelo sin moverse.
## También arma el reloj de la DUDA cuando lleva SEGUNDOS_PARA_DUDA quieto.
func medir_quieto(delta: float) -> void:
	segundos_desde_duda += delta
	var esta_quieto := jugador.is_on_floor() and _rapidez() < VELOCIDAD_QUIETO

	if esta_quieto:
		var antes := segundos_quieto
		segundos_quieto += delta
		if antes < SEGUNDOS_PARA_DUDA and segundos_quieto >= SEGUNDOS_PARA_DUDA:
			segundos_desde_duda = 0.0
	elif segundos_quieto > 0.0:
		if segundos_quieto >= SEGUNDOS_MINIMOS_QUIETO:
			registrar("quieto", {
				"segundos": snappedf(segundos_quieto, 0.01),
				"pos": _punto(jugador.global_position),
			})
		segundos_quieto = 0.0


## ACOMODO: tocar A o D en el suelo, casi quieto o con S apretada,
## con al menos SEGUNDOS_ENTRE_ACOMODOS desde el acomodo anterior.
func medir_acomodo(delta: float) -> void:
	segundos_desde_acomodo += delta
	var toco_giro := Input.is_action_just_pressed(ACCION_GIRAR_IZQ) \
			or Input.is_action_just_pressed(ACCION_GIRAR_DER)
	var frenando := InputMap.has_action(ACCION_FRENO) and Input.is_action_pressed(ACCION_FRENO)
	var poca_velocidad := _rapidez() < VELOCIDAD_ACOMODO

	if toco_giro and jugador.is_on_floor() and (poca_velocidad or frenando) \
			and segundos_desde_acomodo >= SEGUNDOS_ENTRE_ACOMODOS:
		segundos_desde_acomodo = 0.0
		registrar("acomodo", {"pos": _punto(jugador.global_position)})


## PARED: un evento por cada contacto, con cuánto duró.
## Cantidad de choques = cantidad de eventos. Tiempo en pared = suma de "segundos".
func medir_pared(delta: float) -> void:
	if jugador.is_on_wall():
		tocando_pared = true
		segundos_pared += delta
	elif tocando_pared:
		registrar("pared", {
			"segundos": snappedf(segundos_pared, 0.01),
			"pos": _punto(jugador.global_position),
		})
		tocando_pared = false
		segundos_pared = 0.0


## RECUPERACIÓN DE VELOCIDAD: tras aterrizar, guarda posición y velocidad
## cada SEGUNDOS_ENTRE_RECUPERACION durante SEGUNDOS_RECUPERACION.
func medir_recuperacion(delta: float) -> void:
	if segundos_desde_aterrizaje >= SEGUNDOS_RECUPERACION:
		return
	segundos_desde_aterrizaje += delta
	reloj_recuperacion += delta
	if reloj_recuperacion >= SEGUNDOS_ENTRE_RECUPERACION:
		reloj_recuperacion = 0.0
		registrar("recuperacion", {
			"pos": _punto(jugador.global_position),
			"vel": _punto(velocidad),
			"desde_aterrizaje": snappedf(segundos_desde_aterrizaje, 0.01),
		})


## TIEMPO DEL NIVEL (parte 1): empieza cuando aparece el jugador en una escena.
func _iniciar_nivel() -> void:
	var escena := get_tree().current_scene
	nivel = escena.name if escena else "sin_nivel"
	segundos_nivel = 0.0
	id_salto = 0
	en_salto = false
	posicion_anterior = jugador.global_position
	registrar("volumen_inicial", {"buses": _volumenes()})


## TIEMPO DEL NIVEL (parte 2): llamala cuando el jugador llega a la meta.
func al_terminar_nivel() -> void:
	registrar("nivel_completado", {"segundos": snappedf(segundos_nivel, 0.01)})
	registrar("volumen_final", {"buses": _volumenes()})


## VOLUMEN: llamala desde el slider de sonido (señal drag_ended).
## Cantidad de cambios = cantidad de eventos "volumen_cambio".
func al_cambiar_volumen(bus: String, porcentaje: float) -> void:
	registrar("volumen_cambio", {"bus": bus, "porcentaje": snappedf(porcentaje, 0.1)})


## Volumen actual de cada bus de audio, en porcentaje.
func _volumenes() -> Dictionary:
	var buses := {}
	for i in AudioServer.bus_count:
		var lineal := db_to_linear(AudioServer.get_bus_volume_db(i))
		buses[AudioServer.get_bus_name(i)] = snappedf(lineal * 100.0, 0.1)
	return buses


# =====================================================================
#  UTILIDADES (no son métricas)
# =====================================================================

## Escribe un evento en el archivo. Se guarda al instante, no hay que "cerrar".
func registrar(tipo: String, datos: Dictionary) -> void:
	if archivo == null:
		DirAccess.make_dir_recursive_absolute("user://metricas")
		var ruta := "user://metricas/sesion_%d.jsonl" % int(Time.get_unix_time_from_system())
		archivo = FileAccess.open(ruta, FileAccess.WRITE)
		print("Métricas en: ", ProjectSettings.globalize_path(ruta))
	archivo.store_line(JSON.stringify({
		"tipo": tipo,
		"nivel": nivel,
		"t": snappedf(segundos_nivel, 0.01),
		"datos": datos,
	}))
	archivo.flush()


## Busca al jugador por su grupo. Si cambia de escena, lo vuelve a buscar.
func _buscar_jugador() -> void:
	if is_instance_valid(jugador):
		return
	jugador = get_tree().get_first_node_in_group("Player") as Jugador
	if jugador != null:
		_iniciar_nivel()


func _rapidez() -> float:
	return Vector2(velocidad.x, velocidad.z).length()


## Vector3 -> lista [x, y, z] redondeada, para guardarla en el archivo.
func _punto(v: Vector3) -> Array:
	return [snappedf(v.x, 0.01), snappedf(v.y, 0.01), snappedf(v.z, 0.01)]
