extends AnimatableBody3D
class_name PlataformaNube
@onready var deteccion_area = $Area_nube
@onready var animacion_nube = $AnimationNube

func _ready() -> void:
	pass


func _on_area_nube_body_entered(body: Node3D) -> void:
	if body is Jugador:
		animacion_nube.play("moviendo")
