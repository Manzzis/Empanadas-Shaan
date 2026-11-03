extends Node
class_name AnimacionComponent

@export var animation_tree: AnimationTree
@export var jugador: CharacterBody3D

var playback: AnimationNodeStateMachinePlayback

func _ready() -> void:
	# Obtenemos el control interno del AnimationTree
	playback = animation_tree.get("parameters/playback")
	EVENT_BUS_JUGADOR.estado_jugador_cambiado.connect(_on_estado_cambiado)


func _process(delta: float) -> void:
	if not jugador or not animation_tree.active:
		return
	var vel_horizontal = Vector2(jugador.velocity.x, jugador.velocity.z)
	var rapidez = vel_horizontal.length()
	var valor_blend = clamp(rapidez / 15.0, 0.0, 1.0)
	
	# Enviamos la velocidad matemática al BlendSpace1D "Movimiento"
	animation_tree.set("parameters/Movimiento/blend_position", valor_blend)


func _on_estado_cambiado(nombre_estado: String) -> void:
	if not playback:
		return
		
	# playback.travel("NombreNodo") viaja suavemente entre los nodos del AnimationTree
	match nombre_estado:
		"Idle", "Caminar":
			# Todos estos estados usan la misma máquina de mezcla por velocidad
			playback.travel("Movimiento")
			
		"Saltar", "Caer":
			# Reemplaza "Saltar" por el nombre que le pusiste al nodo de salto en el panel
			playback.travel("Saltar")
			
		"Grindear", "Dashear":
			playback.travel("Grindeo")
