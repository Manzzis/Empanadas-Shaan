extends AudioStreamPlayer3D

@export var jugador : Jugador

@export var s_caminata : AudioStream
@export var s_salto : AudioStream


func _ready() -> void:
	EVENT_BUS_JUGADOR.sonido_estado.connect(gestionar_sonido)

func gestionar_sonido(estado : String):
	match estado:
		jugador.estados.Caminar:
			set_stream(s_caminata)
			play()
		jugador.estados.Saltar:
			set_stream(s_salto)
			play()
