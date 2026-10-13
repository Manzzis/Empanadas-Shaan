extends Node
#Esta escena autoload crea la señal de los sonidos del entorno
#Luego, al ser emitida esta señal, la escucha y ejecuta el sonido que debe reproducir

@onready var moneda: AudioStreamPlayer = $Moneda
@onready var acelerador: AudioStreamPlayer = $Acelerador
@onready var checkpoint: AudioStreamPlayer = $Checkpoint
@onready var rampa: AudioStreamPlayer = $Rampa

#Señal emitida para que los objetos del entorno emitan su sonido
#Se usa por: Moneda, Acelerador, Checkpoint y Rampa
#########################################
signal emitir_sonido(grupo : StringName)
#########################################

func _ready() -> void:
	emitir_sonido.connect(reproducir_sonido)

func reproducir_sonido(grupo : StringName):
	match grupo:
		"Monedas":
			moneda.play()
		"Acelerador":
			acelerador.play()
		"Checkpoint":
			checkpoint.play()
		"Rampa":
			rampa.play()
