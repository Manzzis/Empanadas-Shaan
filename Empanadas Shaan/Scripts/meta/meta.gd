extends Area3D

@onready var menu_victoria = $Menu_Victoria
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	menu_victoria.hide()


func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("Player"):
		menu_victoria.show()
		Metrics.al_terminar_nivel()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
