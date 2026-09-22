extends Path3D
class_name Riel3D

@onready var path_follow: PathFollow3D = $PathFollow3D
@onready var area_deteccion: Area3D = $Area3D

func _ready() -> void:
	if area_deteccion:
		area_deteccion.body_entered.connect(_on_body_entered)
		area_deteccion.body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node3D) -> void:
	if body is Jugador:
		body.riel_actual = self

func _on_body_exited(body: Node3D) -> void:
	if body is Jugador and body.riel_actual == self:
		body.riel_actual = null

func get_closest_progress(player_global_pos: Vector3) -> float:
	var local_pos = to_local(player_global_pos)
	return curve.get_closest_offset(local_pos)
