class_name Puntos_de_estilo extends Node

@export var jugador : Jugador

func _ready():
	#conectamos el componente a la señal del global
	EVENT_BUS_JUGADOR.aumentar_pde_del_jugador.connect(aumentar_pde)
	EVENT_BUS_JUGADOR.reducir_pde_del_jugador.connect(reducir_pde)

func aumentar_pde():
	if jugador.PDE < 10:
		jugador.PDE = jugador.PDE + 1
		print(jugador.PDE)

func reducir_pde():
	if jugador.PDE > 0:
		jugador.PDE = 0
		print(jugador.PDE)
