class_name Jugador extends CharacterBody3D
#script del personaje principal

#estados del jugador
var estados : Estados_jugador_resource = Estados_jugador_resource.new()

#estadísticas del jugador
@export var velocidad : float = 100.0
@export var aceleracion : float = 30.0
@export var friccion : float = 5.0

# Velocidad de giro
@export var velocidad_giro : float = 3.0


var direccion_delantera : bool = false


func _physics_process(delta: float) -> void:
	move_and_slide()
	girar(delta)


func girar(delta: float) -> void:
	var direccion_giro := Input.get_axis("Girar_der", "Girar_izq")
	
	if direccion_giro == 0:
		return
	
	rotation.y += direccion_giro * velocidad_giro * delta
