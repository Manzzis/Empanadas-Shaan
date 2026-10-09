extends AudioStreamPlayer

@export var jugador : Jugador

@export var s_caminar : AudioStream
@export var s_saltar : AudioStream
@export var s_grindear : AudioStream

func _ready() -> void:
	EVENT_BUS_JUGADOR.sonido_estado.connect(gestionar_sonido)
	

func gestionar_sonido(estado : String):
	match estado:
		jugador.estados.Caminar:
			set_stream(s_caminar)
			play()
		jugador.estados.Saltar:
			set_stream(s_saltar)
			play()
		jugador.estados.Grindear:
			set_stream(s_grindear)
			play()
