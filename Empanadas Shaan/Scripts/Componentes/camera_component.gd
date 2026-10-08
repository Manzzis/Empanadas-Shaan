extends Node3D
class_name CameraComponent

@export var nodo_visual_jugador: Node3D
@export_category("Configuración de Cámara")
@export var mouse_sensitivity: float = 0.003
@export var velocidad_centrado: float = 5.0 

@export_category("Referencias")

@onready var pcam: PhantomCamera3D = $PhantomCamera3D

var jugador: CharacterBody3D = null
var auto_alinear_espalda: bool = false
var estado_actual_nombre: String = ""

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	# Nos conectamos al Autoload de Eventos
	EVENT_BUS_JUGADOR.estado_jugador_cambiado.connect(_on_estado_jugador_cambiado)

func set_target(target: CharacterBody3D) -> void:
	jugador = target
	
	# La PhantomCamera sigue la posición del nodo raíz (el CharacterBody3D)
	pcam.follow_target = jugador
	
	# Fallback de seguridad: si olvidaste asignar la malla en el inspector, 
	# intentará buscar un nodo llamado "Malla" dentro del jugador.
	if not nodo_visual_jugador:
		nodo_visual_jugador = jugador.get_node_or_null("Malla")

func _on_estado_jugador_cambiado(nombre_estado: String) -> void:
	estado_actual_nombre = nombre_estado
	# La cámara solo fuerza la rotación hacia la espalda si el jugador está caminando
	auto_alinear_espalda = (nombre_estado == "Caminar")

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		var rot: Vector3 = pcam.get_third_person_rotation()
		
		# Movimiento libre de cámara con el mouse
		rot.y -= event.relative.x * mouse_sensitivity
		
		# Límite de vista hacia arriba y hacia abajo (Pitch)
		rot.x -= event.relative.y * mouse_sensitivity
		rot.x = clamp(rot.x, deg_to_rad(-70.0), deg_to_rad(75.0))
		
		pcam.set_third_person_rotation(rot)

func _process(delta: float) -> void:
	# Verificamos tener tanto el jugador como su malla visual antes de calcular
	if not jugador or not nodo_visual_jugador:
		return

	if auto_alinear_espalda:
		var rot: Vector3 = pcam.get_third_person_rotation()
		
		# Ahora tomamos la rotación Y del NODO VISUAL, no del jugador raíz
		var angulo_espalda: float = nodo_visual_jugador.global_rotation.y + PI
		
		# Suavizamos la rotación de la cámara hacia la espalda de la malla
		rot.y = lerp_angle(rot.y, angulo_espalda, velocidad_centrado * delta)
		
		pcam.set_third_person_rotation(rot)
