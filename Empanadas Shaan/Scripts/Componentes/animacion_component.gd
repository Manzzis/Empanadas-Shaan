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
		
	match nombre_estado:
		"Idle", "Caminar":
			playback.travel("Movimiento")
			
		"Saltar", "Caer":
			playback.travel("Saltar")
			
		"Grindear", "Dashear":
			playback.travel("Grindeo")
			
		"Pared":
			# Leemos el cálculo exacto de la pared (+1 izq, -1 der)
			var lado = jugador.get_meta("ultimo_lado_muro", 1.0)
			
			if lado > 0:
				playback.travel("Pared_Izq")
			else:
				playback.travel("Pared_Der")
