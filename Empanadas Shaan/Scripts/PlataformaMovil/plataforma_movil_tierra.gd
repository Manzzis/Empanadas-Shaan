extends AnimatableBody3D

@export_category("Ruta de la Plataforma")
@export var posicion_A: Vector3
@export var posicion_B: Vector3
@export var duracion_viaje: float = 2.0
@export var tiempo_espera: float = 1.0

@export_category("Visuales")
@export var tamano: Vector3 = Vector3(2, 0.5, 2)


func _ready() -> void:
	$Sphere.scale = tamano
	$Colision.scale = tamano
	
	global_position = posicion_A	
	iniciar_ruta()


func iniciar_ruta() -> void:
	var tween = create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	
	tween.set_loops()
	tween.tween_property(self, "global_position", posicion_B, duracion_viaje)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN_OUT)
		
	# Espera unos segundos en el Punto B
	tween.tween_interval(tiempo_espera)
	# aca se vuelve
	tween.tween_property(self, "global_position", posicion_A, duracion_viaje)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN_OUT)
	
	tween.tween_interval(tiempo_espera)
