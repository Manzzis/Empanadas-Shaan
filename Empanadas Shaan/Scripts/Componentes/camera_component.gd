extends Node3D
class_name CameraComponent

@export var nodo_visual_jugador: Node3D
@export_category("Configuración de Cámara")
@export var mouse_sensitivity: float = 0.003
# velocidad_centrado eliminada porque ya no centraremos la cámara automáticamente

@export_category("Referencias")
@onready var pcam: PhantomCamera3D = $PhantomCamera3D

var jugador: CharacterBody3D = null
var estado_actual_nombre: String = ""

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	EVENT_BUS_JUGADOR.estado_jugador_cambiado.connect(_on_estado_jugador_cambiado)

func set_target(target: CharacterBody3D) -> void:
	jugador = target
	
	# La PhantomCamera sigue la posición del nodo raíz, pero ya no su rotación
	pcam.follow_target = jugador
	
	if not nodo_visual_jugador:
		nodo_visual_jugador = jugador.get_node_or_null("Malla")

func _on_estado_jugador_cambiado(nombre_estado: String) -> void:
	estado_actual_nombre = nombre_estado

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		var rot: Vector3 = pcam.get_third_person_rotation()
		
		# Movimiento libre de cámara con el mouse
		rot.y -= event.relative.x * mouse_sensitivity
		
		# Límite de vista hacia arriba y hacia abajo (Pitch)
		rot.x -= event.relative.y * mouse_sensitivity
		rot.x = clamp(rot.x, deg_to_rad(-70.0), deg_to_rad(75.0))
		
		pcam.set_third_person_rotation(rot)
