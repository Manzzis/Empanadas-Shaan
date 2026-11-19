extends Node
#Esta escena autoload crea la señal de los sonidos del entorno
#Luego, al ser emitida esta señal, la escucha y ejecuta el sonido que debe reproducir
#Además, reproduce la musiquita del juego
@onready var voz_waliam: AudioStreamPlayer = $Voz_waliam
@onready var voz_dios: AudioStreamPlayer = $Voz_dios



@onready var musica: AudioStreamPlayer = $Musica

@onready var moneda: AudioStreamPlayer = $Moneda
@onready var acelerador: AudioStreamPlayer = $Acelerador
@onready var checkpoint: AudioStreamPlayer = $Checkpoint
@onready var rampa: AudioStreamPlayer = $Rampa

@export_group("Tramo checkpoint")
@export var checkpoint_inicio : float = 3.05
@export var checkpoint_fin : float = 5.40

var timer_checkpoint : SceneTreeTimer

var voz_actual : AudioStreamPlayer = null

#Señal emitida para que los objetos del entorno emitan su sonido
#Se usa por: Moneda, Acelerador, Checkpoint y Rampa
#########################################
signal emitir_sonido(grupo : StringName)
#########################################

func _ready() -> void:
	emitir_sonido.connect(reproducir_sonido)
	musica.finished.connect(musica.play)

func reproducir_sonido(grupo : StringName):
	match grupo:
		"Monedas":
			moneda.play()
		"Acelerador":
			acelerador.play()
		"Checkpoint":
			reproducir_checkpoint()
		"Rampa":
			rampa.play()


func reproducir_checkpoint() -> void:
	checkpoint.play(checkpoint_inicio)
	var timer := get_tree().create_timer(checkpoint_fin - checkpoint_inicio)
	timer_checkpoint = timer
	await timer.timeout
	# Solo corta si no se reactivó el checkpoint mientras esperaba
	if timer == timer_checkpoint:
		checkpoint.stop()

func iniciar_voz(personaje : String) -> void:
	detener_voz()
	match personaje:
		"Waliam":
			voz_actual = voz_waliam
		"Dios", "???":
			voz_actual = voz_dios
		_:
			voz_actual = null  # narración, sin voz
	if voz_actual:
		voz_actual.play()

func detener_voz() -> void:
	if voz_actual:
		voz_actual.stop()
