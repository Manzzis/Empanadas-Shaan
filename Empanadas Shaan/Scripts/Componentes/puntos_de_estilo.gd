class_name Puntos_de_estilo extends Node

@export var jugador : Jugador

var costo_dash : int = 4
@export var maquina_de_estados_del_jugador : Maquina_de_estados
@export_category("Configuración de PDE")
@export var segundos_por_pde_normal: float = 1.0  # Tiempo normal entre cada PDE
@export var segundos_por_pde_grindeo: float = 0.2 # Tiempo rápido al grindear
@export var multiplicador_base_grindeo: int = 2   # Cuánto multiplica el acumulador al entrar
@export var pde_acumulador: int = 1
var corrutina_activa: bool = false
var esta_grindeando: bool = false
var esta_corriendo: bool = false
@export var segundos_por_gasto_correr: float = 0.5 
var _respaldo_pde_acumulador: float = 0.0
func _ready():
	_respaldo_pde_acumulador = pde_acumulador
	iniciar_regeneracion_pde(segundos_por_pde_normal)
	EVENT_BUS_JUGADOR.usar_dash.connect(calcular_pde)
	EVENT_BUS_JUGADOR.aumentar_pde_del_jugador_grindeo.connect(empezar_grindeo)
	EVENT_BUS_JUGADOR.terminar_grindeo.connect(terminar_grindeo)
	EVENT_BUS_JUGADOR.disminuir_pde_del_jugador.connect(empezar_correr)
	EVENT_BUS_JUGADOR.terminar_correr.connect(terminar_correr)




func calcular_pde():
	if jugador.PDE >= 4:
		jugador.PDE = jugador.PDE - costo_dash
		maquina_de_estados_del_jugador.cambiar_a(jugador.estados.Dashear)
		EVENT_BUS_JUGADOR.pde_actualizado.emit(jugador.PDE)
		

# Función progresiva general que ahora usa las variables exportadas
@export var tiempo_espera_recarga: float = 1.0 # Segundos que espera antes de empezar a recargar tras gastar

func iniciar_regeneracion_pde(intervalo: float):
	# Si ya está corriendo, no activamos la regeneración pasiva
	if esta_corriendo:
		return
		
	# Configuramos el tiempo del timer y lo encendemos
	$TimerRegeneracion.wait_time = intervalo
	$TimerRegeneracion.start()

# Conecta la señal 'timeout' de $TimerRegeneracion a esta función:
func _on_timer_regeneracion_timeout():
	if esta_corriendo or jugador.PDE >= GlobalVar.pde_max:
		$TimerRegeneracion.stop()
		return
		
	jugador.PDE = min(jugador.PDE + 1, GlobalVar.pde_max)
	EVENT_BUS_JUGADOR.pde_actualizado.emit(jugador.PDE)
	
	# Si llegó al máximo, detenemos el timer
	if jugador.PDE >= GlobalVar.pde_max:
		$TimerRegeneracion.stop()


# --- 2. CONSUMO AL CORRER (Usando Timer) ---

func empezar_correr():
	if esta_corriendo or jugador.PDE <= 0:
		return
		
	esta_corriendo = true
	
	# MATAMOS la regeneración pasiva al instante (sin esperas ni solapamientos)
	$TimerRegeneracion.stop()
	
	# Arrancamos el timer de consumo de correr
	$TimerConsumo.wait_time = segundos_por_gasto_correr
	$TimerConsumo.start()

# Conecta la señal 'timeout' de $TimerConsumo a esta función:
func _on_timer_consumo_timeout():
	if not esta_corriendo:
		$TimerConsumo.stop()
		return
		
	jugador.PDE = max(jugador.PDE - 1, 0)
	EVENT_BUS_JUGADOR.pde_actualizado.emit(jugador.PDE)
	
	if jugador.PDE <= 0:
		terminar_correr()


func terminar_correr():
	if not esta_corriendo:
		return
		
	esta_corriendo = false
	
	# Apagamos el consumo de correr de inmediato
	$TimerConsumo.stop()
	
	# Esperamos el tiempo de retraso antes de volver a regenerar, y luego arrancamos
	await get_tree().create_timer(tiempo_espera_recarga).timeout
	
	# Verificamos que no haya vuelto a correr durante el retraso
	if not esta_corriendo:
		iniciar_regeneracion_pde(segundos_por_pde_grindeo)


# --- 3. GRINDEO ---
func empezar_grindeo():
	esta_grindeando = true
	multiplicador_base_grindeo = 2
	
	# 2. RESTAURAMOS EL VALOR INICIAL: 
	# Cada vez que empieza a grindear, recupera el valor exacto del inspector
	pde_acumulador = _respaldo_pde_acumulador
	
	grindeo_pde()


func grindeo_pde():
	if not esta_grindeando:
		return

	if pde_acumulador > 0:
		var aumento_inicial = pde_acumulador * multiplicador_base_grindeo
		jugador.PDE = min(jugador.PDE + aumento_inicial, GlobalVar.pde_max)
		EVENT_BUS_JUGADOR.pde_actualizado.emit(jugador.PDE)
		
		# 3. VACIADO: Una vez aplicado el aumento, lo ponemos en 0 
		# para que no siga sumando en bucle
		pde_acumulador = 0


func terminar_grindeo():
	esta_grindeando = false
	pde_acumulador = 0
