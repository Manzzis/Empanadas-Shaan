class_name Jugador extends CharacterBody3D
#script del personaje principal

#estados del jugador
var estados : Estados_jugador_resource = Estados_jugador_resource.new()
@onready var camera_component := $CameraComponent

var gravedad : float = ProjectSettings.get_setting("physics/3d/default_gravity")
var ultimo_checkpoint: Vector3
#estadísticas del jugador
@export var velocidad : float = 10.0
@export var aceleracion : float = 12.0
@export var friccion : float = 4.0
@export var friccion_lateral : float = friccion * 2

@export var velocidad_giro : float = 2.5
@export var aceleracion_giro : float = 5.0
@export var friccion_giro : float = 6.0

var riel_actual : Riel3D = null
@export var fuerza_salto : float = 6.0
var direccion_delantera : bool = false

var rampa_actual : Rampa = null
@export var fuerza_deslizamiento : float = 15.0

var grindeando = false

@export var PDE : int #(Abreviación de Puntos de Estilo)
@export var fuerza_dash : float = 25.0

func _ready() -> void:
	ultimo_checkpoint = global_position
	camera_component.set_target(self)

func _physics_process(delta: float) -> void:	
	handle_gravity(delta)
	handle_deslizamiento(delta)
	move_and_slide()
	girar(delta)


func girar(delta: float) -> void:
	var direccion_giro : float = Input.get_axis("Girar_der", "Girar_izq")
	if direccion_giro == 0:
		return
	
	var vel_horizontal := Vector3(velocity.x, 0, velocity.z)
	var rapidez := vel_horizontal.length()
	
	# CASO A: Giro sobre su eje si está casi detenido
	if rapidez < 0.2:
		rotation.y += direccion_giro * velocidad_giro * delta
		
	# CASO B: Ajuste de trayectoria en movimiento
	else:
		var direccion_movimiento_anterior := vel_horizontal.normalized()
		
		rotation.y += direccion_giro * velocidad_giro * delta
		
		var frente := get_adelante()
		var va_hacia_adelante := velocity.dot(frente) >= 0.0
		var dir_factor := 1.0 if va_hacia_adelante else -1.0
		
		var nueva_direccion_movimiento = direccion_movimiento_anterior.move_toward(
			frente * dir_factor, 
			aceleracion_giro * delta
		)
		
		var nueva_velocidad = nueva_direccion_movimiento.normalized() * rapidez
		
		velocity.x = nueva_velocidad.x
		velocity.z = nueva_velocidad.z


func handle_gravity(delta):
	velocity.y -= gravedad * delta


func get_adelante() -> Vector3:
	return -global_transform.basis.z


func handle_deslizamiento(delta):
	if rampa_actual == null or not is_on_floor():
		return
	
	var normal = get_floor_normal()
	var direccion_deslizamiento = (Vector3.DOWN - normal * Vector3.DOWN.dot(normal))
	
	# ¿Está subiendo? Si la velocidad va contra la dirección de deslizamiento, no lo tocamos
	if velocity.dot(-direccion_deslizamiento) > 0.1:
		return
	
	velocity += direccion_deslizamiento * fuerza_deslizamiento * delta
