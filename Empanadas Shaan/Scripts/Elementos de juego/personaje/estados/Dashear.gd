extends Estados_de_jugador
# Lógica del estado DASHEAR del jugador

@export var duracion_dash: float = 0.25  # Duración en segundos del dash
var vector_dash: Vector3 = Vector3.ZERO

func iniciar() -> void:
	jugador = nodo_controlador
	
	# 1. Calculamos la dirección y la aplanamos en Y para que no vuele si mira hacia arriba/abajo
	var direccion_dash = jugador.get_adelante()
	direccion_dash.y = 0
	direccion_dash = direccion_dash.normalized()
	
	# 2. Guardamos el vector de velocidad constante
	vector_dash = direccion_dash * jugador.fuerza_dash
	
	# Aplicamos la velocidad inicial e ignoramos la gravedad en el eje Y (estilo Hollow Knight)
	jugador.velocity.x = vector_dash.x
	jugador.velocity.z = vector_dash.z
	jugador.velocity.y = 0 
	
	# 3. Creamos el Timer usando la sintaxis moderna de Callables en Godot 4
	var timer = jugador.get_tree().create_timer(duracion_dash)
	timer.timeout.connect(_on_dash_terminado)

func on_physics_process(_delta: float) -> void:
	# 4. Forzamos a que la velocidad se mantenga idéntica CADA FRAME.
	# Esto evita que la fricción u otras fuerzas frenen al jugador a mitad del dash.
	jugador.velocity.x = vector_dash.x
	jugador.velocity.z = vector_dash.z
	jugador.velocity.y = 0 # Mantiene al jugador suspendido horizontalmente en el aire
	
	# Si tu máquina de estados no llama automáticamente al movimiento, hazlo aquí:
	# jugador.move_and_slide()

func _on_dash_terminado() -> void:
	# 5. Freno en seco absoluto
	jugador.velocity.x = jugador.velocity.x / 4
	jugador.velocity.z = jugador.velocity.z / 4
	if jugador.is_on_floor():
		mi_maquina_de_estados.cambiar_a(jugador.estados.Idle)
	else:
		mi_maquina_de_estados.cambiar_a(jugador.estados.Caer)
