class_name Puntos_de_estilo extends Node

@export var jugador : Jugador
var costo_dash : int = 4
@export var maquina_de_estados_del_jugador : Maquina_de_estados

func _ready():
	#conectamos el componente a la señal del EVENT_BUS_JUGADOR
	EVENT_BUS_JUGADOR.aumentar_pde_del_jugador.connect(aumentar_pde)
	EVENT_BUS_JUGADOR.reducir_pde_del_jugador.connect(reducir_pde)
	EVENT_BUS_JUGADOR.usar_dash.connect(calcular_pde)

func aumentar_pde():
	if jugador.PDE < 10:
		jugador.PDE = jugador.PDE + 1
		EVENT_BUS_JUGADOR.pde_actualizado.emit(jugador.PDE)

func reducir_pde():
	if jugador.PDE > 0:
		jugador.PDE = 0
		EVENT_BUS_JUGADOR.pde_actualizado.emit(jugador.PDE)

func calcular_pde():
	if jugador.PDE >= 4:
		jugador.PDE = jugador.PDE - costo_dash
		maquina_de_estados_del_jugador.cambiar_a(jugador.estados.Dashear)
		EVENT_BUS_JUGADOR.pde_actualizado.emit(jugador.PDE)
