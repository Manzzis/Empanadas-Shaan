class_name Puntos_de_estilo extends Node

@export var jugador : Jugador

var costo_dash : int = 4
@export var maquina_de_estados_del_jugador : Maquina_de_estados
@export_category("Configuración de PDE")
@export var segundos_por_pde_normal: float = 1.0  
@export var segundos_por_pde_grindeo: float = 0.2 
@export var multiplicador_base_grindeo: int = 2   
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
		

@export var tiempo_espera_recarga: float = 1.0 

func iniciar_regeneracion_pde(intervalo: float):
	if esta_corriendo:
		return
		
	$TimerRegeneracion.wait_time = intervalo
	$TimerRegeneracion.start()

func _on_timer_regeneracion_timeout():
	if esta_corriendo or jugador.PDE >= GlobalVar.pde_max:
		$TimerRegeneracion.stop()
		return
		
	jugador.PDE = min(jugador.PDE + 1, GlobalVar.pde_max)
	EVENT_BUS_JUGADOR.pde_actualizado.emit(jugador.PDE)
	
	if jugador.PDE >= GlobalVar.pde_max:
		$TimerRegeneracion.stop()




func empezar_correr():
	if esta_corriendo or jugador.PDE <= 0:
		return
		
	esta_corriendo = true
	
	
	$TimerRegeneracion.stop()
	
	
	$TimerConsumo.wait_time = segundos_por_gasto_correr
	$TimerConsumo.start()


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
	
	
	$TimerConsumo.stop()
	
	
	await get_tree().create_timer(tiempo_espera_recarga).timeout
	
	
	if not esta_corriendo:
		iniciar_regeneracion_pde(segundos_por_pde_grindeo)


# --- 3. GRINDEO ---
func empezar_grindeo():
	esta_grindeando = true
	multiplicador_base_grindeo = 2
	
	
	pde_acumulador = _respaldo_pde_acumulador
	
	grindeo_pde()


func grindeo_pde():
	if not esta_grindeando:
		return

	if pde_acumulador > 0:
		var aumento_inicial = pde_acumulador * multiplicador_base_grindeo
		jugador.PDE = min(jugador.PDE + aumento_inicial, GlobalVar.pde_max)
		EVENT_BUS_JUGADOR.pde_actualizado.emit(jugador.PDE)
		
		
		
		pde_acumulador = 0


func terminar_grindeo():
	esta_grindeando = false
	pde_acumulador = 0
