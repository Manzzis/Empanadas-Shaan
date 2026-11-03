class_name Jugador extends CharacterBody3D
#script del personaje principal

#estados del jugador
var estados : Estados_jugador_resource = Estados_jugador_resource.new()
@onready var camera_component := $CameraComponent
@onready var particulas_salto: GPUParticles3D = $ParticulasSalto
@onready var particulas_aterrizaje: GPUParticles3D = $ParticulasAterrizaje
@onready var particulas_grind: GPUParticles3D = $ParticulasGrind

var gravedad : float = ProjectSettings.get_setting("physics/3d/default_gravity")
var ultimo_checkpoint: Vector3

#estadísticas del jugador
var velocidad : float # SIN @export para que lo controle la tienda
@export var aceleracion : float = 12.0
@export var friccion : float = 4.0
@export var friccion_lateral : float = friccion * 2

@export var velocidad_giro : float = 2.5
@export var aceleracion_giro : float = 5.0
@export var friccion_giro : float = 6.0

var riel_actual : Riel3D = null
@export var fuerza_salto : float = 6.0
@export var tiempo_max_salto : float 
var direccion_delantera : bool = false

# Coyote time: segundos de gracia para saltar tras dejar el suelo
@export var coyote_time : float = 0.15
var coyote_timer : float = 0.0

var rampa_actual : Rampa = null
@export var fuerza_deslizamiento : float = 15.0

var grindeando = false

var PDE : int = 0 #(Abreviación de Puntos de Estilo), empieza en 0 cada nivel
@export var fuerza_dash : float = 25.0

@onready var texto_monedas = $CanvasLayer/Label

func _ready() -> void:
	ultimo_checkpoint = global_position
	camera_component.set_target(self)
	
	if GlobalVar.velocidad_mejorada:
		velocidad = GlobalVar.velocidad_rapida # También aprovechamos para usar la variable del Autoload
	else:
		velocidad = GlobalVar.velocidad_normal
		
	if texto_monedas:
		texto_monedas.text = "Monedas: " + str(GlobalVar.monedas)


func _physics_process(delta: float) -> void:
	var estaba_en_suelo = is_on_floor()
	handle_gravity(delta)
	handle_deslizamiento(delta)

	# Sistema de particulas

	# El salto
	if Input.is_action_just_pressed("Salto") and (is_on_floor() or puede_saltar_coyote()):
		velocity.y = fuerza_salto
		particulas_salto.restart()
		particulas_salto.emitting = true

	move_and_slide()
	girar(delta)
	actualizar_coyote_time(delta)

	# El aterrizaje
	if not estaba_en_suelo and is_on_floor():
		emitir_particulas(particulas_aterrizaje)

	# El grinding
	grindeando = riel_actual != null
	particulas_grind.emitting = grindeando
	
func actualizar_coyote_time(delta: float) -> void:
	if is_on_floor():
		coyote_timer = coyote_time
	else:
		coyote_timer = max(coyote_timer - delta, 0.0)


func puede_saltar_coyote() -> bool:
	return coyote_timer > 0.0


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
	# Momento coyote: salimos del suelo pero aún estamos en la ventana de gracia.
	# Sin gravedad, el jugador "flota" a la altura de la plataforma.
	if not is_on_floor() and coyote_timer > 0.0:
		velocity.y = 0.0
		#print("LLEGO EL COYOTEEEEEEEEEEEEE")
		return
	
	velocity.y -= gravedad * delta


func get_adelante() -> Vector3:
	return global_transform.basis.z


func handle_deslizamiento(delta):
	if rampa_actual == null or not is_on_floor():
		return
	
	var normal = get_floor_normal()
	var direccion_deslizamiento = (Vector3.DOWN - normal * Vector3.DOWN.dot(normal))
	
	# ¿Está subiendo? Si la velocidad va contra la dirección de deslizamiento, no lo tocamos
	if velocity.dot(-direccion_deslizamiento) > 0.1:
		return
	
	velocity += direccion_deslizamiento * fuerza_deslizamiento * delta


func sumar_moneda():
	GlobalVar.monedas += 1
	if texto_monedas:
		texto_monedas.text = "Monedas: " + str(GlobalVar.monedas)
		
func emitir_particulas(particulas: GPUParticles3D) -> void:
	particulas.restart()
	particulas.emitting = true
