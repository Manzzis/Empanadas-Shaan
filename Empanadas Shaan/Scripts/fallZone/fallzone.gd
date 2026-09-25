extends Area3D



func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("Player"):
		body.global_position = body.ultimo_checkpoint
		body.velocity = Vector3.ZERO
	pass # Replace with function body.
