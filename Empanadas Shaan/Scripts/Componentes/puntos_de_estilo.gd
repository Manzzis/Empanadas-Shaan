class_name Puntos_de_estilo extends Node

@export var jugador : Jugador
@export var maquina_de_estados_del_jugador : Maquina_de_estados

@export_category("Configuración de PDE")
@export var segundos_por_pde_caminar: float = 1.0       # regeneración caminando
@export var segundos_por_pde_grindeo: float = 0.2       # regeneración grindeando
@export var segundos_por_pde_idle: float = 1.0          # degeneración en Idle
@export var segundos_por_pde_pared: float = 0.3         # degeneración en Pared (más rápida que Idle)
@export var segundos_por_gasto_correr: float = 0.5
@export var tiempo_espera_recarga: float = 1.0          # pausa tras dejar de correr
@export var multiplicador_base_grindeo: int = 2
@export var pde_acumulador: int = 1

var costo_dash : int = 4
var esta_grindeando: bool = false
var esta_corriendo: bool = false
var _respaldo_pde_acumulador: float = 0.0

var _tiempo_acumulado: float = 0.0   # progreso hacia el siguiente +1 / -1
var _modo_anterior: int = 0          # 1 = regenera, -1 = degenera, 0 = pausa
var _espera_recarga: float = 0.0     # cooldown tras correr


func _ready():
	_respaldo_pde_acumulador = pde_acumulador
	EVENT_BUS_JUGADOR.usar_dash.connect(calcular_pde)
	EVENT_BUS_JUGADOR.aumentar_pde_del_jugador_grindeo.connect(empezar_grindeo)
	EVENT_BUS_JUGADOR.terminar_grindeo.connect(terminar_grindeo)
	EVENT_BUS_JUGADOR.disminuir_pde_del_jugador.connect(empezar_correr)
	EVENT_BUS_JUGADOR.terminar_correr.connect(terminar_correr)


func _process(delta: float) -> void:
	if jugador == null or maquina_de_estados_del_jugador == null:
		return
	
	# Mientras corre, el consumo lo maneja TimerConsumo
	if esta_corriendo:
		_modo_anterior = 0
		return
	
	# Pausa tras dejar de correr
	if _espera_recarga > 0.0:
		_espera_recarga -= delta
		return
	
	var modo := _obtener_modo()
	
	# Si cambió el modo, reiniciamos el progreso para no arrastrar tiempo
	if modo != _modo_anterior:
		_tiempo_acumulado = 0.0
		_modo_anterior = modo
	
	if modo == 0:
		return
	
	_tiempo_acumulado += delta
	
	if modo == 1:
		var intervalo := segundos_por_pde_grindeo if _estado_actual_es(jugador.estados.Grindear) else segundos_por_pde_caminar
		if _tiempo_acumulado >= intervalo:
			_tiempo_acumulado -= intervalo
			_cambiar_pde(1)
	else:
		var intervalo_degeneracion := segundos_por_pde_pared if _estado_actual_es(jugador.estados.Pared) else segundos_por_pde_idle
		if _tiempo_acumulado >= intervalo_degeneracion:
			_tiempo_acumulado -= intervalo_degeneracion
			_cambiar_pde(-1)


# 1 = regenerar (Caminar/Grindear), -1 = degenerar (Idle/Pared), 0 = pausa
func _obtener_modo() -> int:
	if _estado_actual_es(jugador.estados.Caminar) or _estado_actual_es(jugador.estados.Grindear):
		return 1 if jugador.PDE < GlobalVar.pde_max else 0
	if _estado_actual_es(jugador.estados.Idle) or _estado_actual_es(jugador.estados.Pared):
		return -1 if jugador.PDE > 0 else 0
	return 0


func _estado_actual_es(nombre_estado) -> bool:
	var actual = maquina_de_estados_del_jugador.estado_actual
	if actual == null:
		return false
	return String(actual.name) == String(nombre_estado)


func _cambiar_pde(cantidad: int) -> void:
	var nuevo : int = clamp(jugador.PDE + cantidad, 0, GlobalVar.pde_max)
	if nuevo == jugador.PDE:
		return
	jugador.PDE = nuevo
	EVENT_BUS_JUGADOR.pde_actualizado.emit(jugador.PDE)


# --- DASH ---
func calcular_pde():
	if jugador.PDE >= costo_dash:
		jugador.PDE -= costo_dash
		maquina_de_estados_del_jugador.cambiar_a(jugador.estados.Dashear)
		EVENT_BUS_JUGADOR.pde_actualizado.emit(jugador.PDE)


# --- CORRER ---
func empezar_correr():
	if esta_corriendo or jugador.PDE <= 0:
		return
	esta_corriendo = true
	$TimerConsumo.wait_time = segundos_por_gasto_correr
	$TimerConsumo.start()


func _on_timer_consumo_timeout():
	if not esta_corriendo:
		$TimerConsumo.stop()
		return
	_cambiar_pde(-1)
	if jugador.PDE <= 0:
		terminar_correr()


func terminar_correr():
	if not esta_corriendo:
		return
	esta_corriendo = false
	$TimerConsumo.stop()
	_espera_recarga = tiempo_espera_recarga
	_tiempo_acumulado = 0.0


# --- GRINDEO ---
func empezar_grindeo():
	esta_grindeando = true
	pde_acumulador = _respaldo_pde_acumulador
	grindeo_pde()


func grindeo_pde():
	if not esta_grindeando:
		return
	if pde_acumulador > 0:
		_cambiar_pde(pde_acumulador * multiplicador_base_grindeo)
		pde_acumulador = 0


func terminar_grindeo():
	esta_grindeando = false
	pde_acumulador = 0
