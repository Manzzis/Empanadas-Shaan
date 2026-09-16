class_name Jugador extends CharacterBody3D
#script del personaje principal

#estados del jugador
var estados : Estados_jugador_resource = Estados_jugador_resource.new()

var gravedad : float = ProjectSettings.get_setting("physics/3d/default_gravity")

#estadísticas del jugador
@export var velocidad : float = 10.0
@export var aceleracion : float = 12.0
@export var friccion : float = 4.0
@export var friccion_lateral : float = friccion * 2

@export var velocidad_giro : float = 2.5
@export var aceleracion_giro : float = 5.0
@export var friccion_giro : float = 6.0

var direccion_delantera : bool = false

func _physics_process(delta: float) -> void:
	handle_gravity(delta)
	move_and_slide()
	girar(delta)


func girar(delta: float) -> void:
	var direccion_giro : float = Input.get_axis("Girar_der", "Girar_izq")
	if direccion_giro == 0:
		return
	
	# 1. Calculamos cuánta velocidad horizontal tiene actualmente
	var vel_horizontal := Vector3(velocity.x, 0, velocity.z)
	var rapidez := vel_horizontal.length()
	
	# 2. CASO A: El jugador está quieto (o casi quieto) -> Gira sobre su eje
	if rapidez < 0.2:
		rotation.y += direccion_giro * velocidad_giro * delta
		
	# 3. CASO B: El jugador se está desplazando -> Modifica la trayectoria
	else:
		# Guardamos la dirección anterior en la que se movía
		var direccion_movimiento_anterior := vel_horizontal.normalized()
		
		# Rotamos al personaje sobre su eje primero
		rotation.y += direccion_giro * velocidad_giro * delta
		
		# Calculamos hacia dónde apunta ahora su frente local (su nueva intención)
		var nuevo_frente := transform.basis.z.normalized()
		
		# Aquí está el truco: interpolamos (mezclamos) suavemente la dirección 
		# de movimiento vieja con la nueva orientación del cuerpo.
		# Aceleracion_giro controlará qué tan cerrado o abierto da las curvas.
		var nueva_direccion_movimiento = direccion_movimiento_anterior.move_toward(
			nuevo_frente * (1.0 if velocity.dot(transform.basis.z) > 0 else -1.0), 
			aceleracion_giro * delta
		)
		
		# Volvemos a aplicar la rapidez original al nuevo vector de dirección
		var nueva_velocidad = nueva_direccion_movimiento.normalized() * rapidez
		
		velocity.x = nueva_velocidad.x
		velocity.z = nueva_velocidad.z

func handle_gravity(delta):
	velocity.y -= gravedad * delta
