extends AudioStreamPlayer3D

@export var jugador : Jugador
@export var caminar : AudioStream
@export var salto : AudioStream

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	EVENT_BUS_JUGADOR.sonido_estado.connect(gestionar_sonido)

func gestionar_sonido(estado : String):
	match estado:
		jugador.estados.Caminar:
			set_stream(caminar)
			play()
		jugador.estados.Saltar:
			set_stream(salto)
			play()
