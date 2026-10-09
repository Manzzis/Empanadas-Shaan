extends Node

@export var jugador : Jugador

@export var s_caminar : AudioStreamPlayer
@export var s_saltar : AudioStreamPlayer
@export var s_grindear : AudioStreamPlayer
var grindeando = false
@export var s_dashear: AudioStreamPlayer

func _ready() -> void:
	EVENT_BUS_JUGADOR.sonido_estado.connect(gestionar_sonido)
	

func gestionar_sonido(estado : String):
	match estado:
		jugador.estados.Caminar:
			s_caminar.play()
			grindeando = false
		jugador.estados.Saltar:
			s_saltar.play()
			grindeando = false
		jugador.estados.Grindear:
			grindeando = true
			s_grindear.play()
		jugador.estados.Dashear:
			s_dashear.play()
			grindeando = false


func _on_s_grindear_finished() -> void:
	if grindeando:
		s_grindear.play()
