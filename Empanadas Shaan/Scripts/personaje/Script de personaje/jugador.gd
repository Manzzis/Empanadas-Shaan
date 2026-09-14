class_name Jugador extends CharacterBody3D
#SCRIPT DEL PERSONAJE PRINCIPAL


#Estados del jugador
var estados : Estados_jugador_resource = Estados_jugador_resource.new()


#Estadísticas del jugador
@export var velocidad : float = 100.0
@export var aceleracion : float = 30
@export var friccion : float = 5.0

func _physics_process(delta: float) -> void:
	move_and_slide()
