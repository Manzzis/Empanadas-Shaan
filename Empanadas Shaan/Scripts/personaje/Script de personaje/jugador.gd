class_name Jugador extends CharacterBody3D
#script del personaje principal

#estados del jugador
var estados : Estados_jugador_resource = Estados_jugador_resource.new()

var gravedad : float = ProjectSettings.get_setting("physics/3d/default_gravity")

#estadísticas del jugador
@export var velocidad : float = 10.0
@export var aceleracion : float = 12.0
@export var friccion : float = 6.0
@export var velocidad_giro : float = 3.0


var direccion_delantera : bool = false

func _physics_process(delta: float) -> void:
	move_and_slide()
	handle_gravity(delta)
	girar(delta)


func girar(delta: float) -> void:
	var direccion_giro := Input.get_axis("Girar_der", "Girar_izq")
	if direccion_giro == 0:
		return
	rotation.y += direccion_giro * velocidad_giro * delta

func handle_gravity(delta):
	velocity.y -= gravedad * delta
