extends AnimatableBody3D

@export_category("Ruta de la Plataforma")
## Coordenadas locales (copiadas del Transform -> Position de la plataforma en el Inspector)
@export var puntos_ruta: Array[Vector3] = [Vector3.ZERO, Vector3(5, 0, 0)]
## Rapidez de movimiento en metros por segundo
@export var velocidad: float = 2.0
## Segundos que se detiene en cada punto antes de avanzar al siguiente
@export var tiempo_espera: float = 1.0
## Activo: vuelve directo del último punto al primero. Desactivado: regresa en reversa.
@export var recorrido_cerrado: bool = false


func _ready() -> void:
	if puntos_ruta.size() < 2 or velocidad <= 0.0:
		return
	
	# Usamos 'position' (local) para que coincida 100% con los números del Inspector
	position = puntos_ruta[0]
	
	iniciar_ruta()


func iniciar_ruta() -> void:
	var tween := create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	tween.set_loops()
	
	# 1. Recorrido de ida: desde el punto 1 hasta el último del array
	for i in range(1, puntos_ruta.size()):
		_agregar_tramo(tween, puntos_ruta[i - 1], puntos_ruta[i])
	
	# 2. Retorno al punto 0
	if recorrido_cerrado:
		_agregar_tramo(tween, puntos_ruta[-1], puntos_ruta[0])
	else:
		for i in range(puntos_ruta.size() - 2, -1, -1):
			_agregar_tramo(tween, puntos_ruta[i + 1], puntos_ruta[i])


func _agregar_tramo(tween: Tween, origen: Vector3, destino: Vector3) -> void:
	var distancia := origen.distance_to(destino)
	if distancia < 0.01:
		return
		
	var duracion := distancia / velocidad
	
	tween.tween_property(self, "position", destino, duracion)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN_OUT)
		
	if tiempo_espera > 0.0:
		tween.tween_interval(tiempo_espera)
