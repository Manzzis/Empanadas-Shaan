extends Area3D

@export var local_direction: Vector3 = Vector3(1,0,0)

func _ready():
	pass

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		body.call_deferred("rail_nearby", self)

func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		body.call_deferred("rail_left", self)

func get_rail_direction() -> Vector3:
	# En Godot 4 se usa el operador * en lugar de xform
	return (global_transform.basis * local_direction).normalized()
