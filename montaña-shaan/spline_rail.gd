extends Path3D

@onready var path_follow: PathFollow3D = $PathFollow3D
var grind_direction := 1.0 # 1.0 para adelante, -1.0 para atrás

# Esta función calcula en qué parte exacta de la línea cayó el jugador
func get_closest_progress(player_global_pos: Vector3) -> float:
	var local_pos = to_local(player_global_pos)
	return curve.get_closest_offset(local_pos)
