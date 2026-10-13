extends Area3D

var material_bandera: StandardMaterial3D
var activado: bool = false

func _ready():
	# 0. Agregamos esta bandera al grupo "checkpoints" automáticamente por código
	add_to_group("checkpoints")
	
	# 1. Generar el modelo 3D del poste
	var poste = MeshInstance3D.new()
	var mesh_poste = CylinderMesh.new()
	mesh_poste.top_radius = 0.05
	mesh_poste.bottom_radius = 0.05
	mesh_poste.height = 2.0
	poste.mesh = mesh_poste
	poste.position = Vector3(0, 1, 0)
	
	var material_poste = StandardMaterial3D.new()
	material_poste.albedo_color = Color(0.4, 0.2, 0.0)
	poste.set_surface_override_material(0, material_poste)
	add_child(poste)

	# 2. Generar el modelo 3D de la tela de la bandera
	var tela = MeshInstance3D.new()
	var mesh_tela = BoxMesh.new()
	mesh_tela.size = Vector3(0.8, 0.5, 0.05)
	tela.mesh = mesh_tela
	tela.position = Vector3(0.45, 1.7, 0)
	
	material_bandera = StandardMaterial3D.new()
	material_bandera.albedo_color = Color.RED # Inicia en rojo
	tela.set_surface_override_material(0, material_bandera)
	add_child(tela)

	# 3. Generar el área de colisión (Hitbox)
	var colision = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(3.0, 2.0, 3.0)
	colision.shape = shape
	colision.position = Vector3(0, 1, 0)
	add_child(colision)
	
	# 4. Conectar la señal de colisión
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	# Si es el jugador y esta bandera NO es la que ya está activa actualmente
	if body.is_in_group("Player") and not activado:
		EmisorDeSonidos.emitir_sonido.emit()
		# 1. Mandamos la orden a TODAS las banderas del nivel de ponerse en rojo
		get_tree().call_group("checkpoints", "desactivar_bandera")
		
		# 2. Activamos únicamente esta bandera y la ponemos en verde
		activado = true
		material_bandera.albedo_color = Color.GREEN
		
		# 3. Guardamos esta nueva posición en el jugador
		body.ultimo_checkpoint = global_position
		print("Nuevo checkpoint activo en: ", global_position)

# Esta función será llamada en todas las banderas al mismo tiempo gracias a call_group
func desactivar_bandera():
	activado = false
	if material_bandera:
		material_bandera.albedo_color = Color.RED
