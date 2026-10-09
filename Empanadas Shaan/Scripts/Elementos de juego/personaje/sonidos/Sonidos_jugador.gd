extends Node

@export var jugador : Jugador

@export var s_caminar : AudioStreamPlayer
@export var s_saltar : AudioStreamPlayer
@export var s_grindear : AudioStreamPlayer

func _ready() -> void:
	EVENT_BUS_JUGADOR.sonido_estado.connect(gestionar_sonido)
	

func gestionar_sonido(estado : String):
	match estado:
		jugador.estados.Caminar:
			s_caminar.play()
		jugador.estados.Saltar:
			s_saltar.play()
		jugador.estados.Grindear:
			s_grindear.play()
