extends CharacterBody3D

@export_category("Movimiento")
@export var walk_speed := 5.0
@export var boost_speed := 15.0
@export var jump_velocity := 6.0
@export var mouse_sensitivity := 0.003

var grind_direction := 1.0 # 1.0 para adelante, -1.0 para atrás

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

# Variables del riel
var is_on_path := false
var current_rail_path: Path3D = null
var current_path_follow: PathFollow3D = null

@onready var camera: Camera3D = $Camera3D
@onready var mesh: MeshInstance3D = $MeshInstance3D

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event):
	# Alternar el control del mouse con ESC
	if event.is_action_pressed("ui_cancel"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	# Mover cámara
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		if not is_on_path:
			rotate_y(-event.relative.x * mouse_sensitivity)
			
		camera.rotate_x(-event.relative.y * mouse_sensitivity)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-80), deg_to_rad(80))

func _physics_process(delta):
	# ==========================================
	# MODO GRIND (Deslizándose por el riel)
	# ==========================================
	if is_on_path and current_path_follow:
		velocity = Vector3.ZERO
		
		# Multiplicamos la velocidad por 1 o -1 dependiendo de hacia dónde entramos
		current_path_follow.progress += boost_speed * grind_direction * delta
		
		# Clavamos al jugador en la posición
		global_position = current_path_follow.global_position
		
		# Rotamos al jugador. Si va hacia atrás, le sumamos 180° (PI en radianes) para que no vaya marcha atrás
		if grind_direction == 1.0:
			global_rotation.y = current_path_follow.global_rotation.y
		else:
			global_rotation.y = current_path_follow.global_rotation.y + PI
		
		mesh.rotation.z = lerp(mesh.rotation.z, deg_to_rad(20.0), delta * 10.0)
		
		# Salto para salir del riel
		if Input.is_action_just_pressed("ui_accept"):
			_detach_from_path()
			velocity.y = jump_velocity
			
		# Final del recorrido (Detecta ambos extremos del riel)
		elif (grind_direction == 1.0 and current_path_follow.progress_ratio >= 0.99) or \
			 (grind_direction == -1.0 and current_path_follow.progress_ratio <= 0.01):
			var exit_dir = -transform.basis.z
			_detach_from_path()
			velocity = exit_dir * boost_speed
			velocity.y = jump_velocity * 0.5
			
		move_and_slide()
		return

	# ==========================================
	# MODO NORMAL (Caminando o Acelerando)
	# ==========================================
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Salto normal
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = jump_velocity

	# Si mantiene presionado el Clic Izquierdo usa la velocidad rápida, si no, velocidad normal
	var current_speed = walk_speed
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		current_speed = boost_speed

	# Leer las teclas WASD o Flechas (configurado por defecto en Godot)
	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if direction:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0, walk_speed)
		velocity.z = move_toward(velocity.z, 0, walk_speed)

	mesh.rotation.z = lerp(mesh.rotation.z, 0.0, delta * 10.0)

	move_and_slide()

func _detach_from_path():
	is_on_path = false
	current_rail_path = null
	current_path_follow = null
	print("--> Desconectado del riel <--")

# --- CONEXIÓN DE LA SEÑAL (Inspector) ---
func _on_feet_detector_area_entered(area: Area3D) -> void:
	if area.is_in_group("RailPath") and velocity.y <= 0 and not is_on_path:
		var parent_path = area.get_parent()
		
		if parent_path is Path3D:
			current_rail_path = parent_path
			current_path_follow = current_rail_path.get_node_or_null("PathFollow3D")
			
			if current_path_follow:
				is_on_path = true
				
				# 1. Colocar al jugador en el punto de contacto
				var local_pos = current_rail_path.to_local(global_position)
				var entry_offset = current_rail_path.curve.get_closest_offset(local_pos)
				current_path_follow.progress = entry_offset
				
				# 2. MAGIA BIDIRECCIONAL: Obtener direcciones
				# El PathFollow mira hacia -Z. Comparamos eso con la mirada del jugador.
				var path_forward = -current_path_follow.global_transform.basis.z
				var player_forward = -transform.basis.z
				
				# Si el producto punto es mayor a 0, miran al mismo lado. Si no, están enfrentados.
				if player_forward.dot(path_forward) >= 0:
					grind_direction = 1.0
				else:
					grind_direction = -1.0
				
				print("--> GRIND ACTIVADO! Dirección: ", grind_direction, " <--")
