extends Area3D

var material_bandera: StandardMaterial3D
var activado: bool = false

func _ready():
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

	var tela = MeshInstance3D.new()
	var mesh_tela = BoxMesh.new()
	mesh_tela.size = Vector3(0.8, 0.5, 0.05)
	tela.mesh = mesh_tela
	tela.position = Vector3(0.45, 1.7, 0) 
	
	material_bandera = StandardMaterial3D.new()
	material_bandera.albedo_color = Color.RED 
	tela.set_surface_override_material(0, material_bandera)
	add_child(tela)

	var colision = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = Vector3(3.0, 2.0, 3.0) 
	colision.shape = shape
	colision.position = Vector3(0, 1, 0)
	add_child(colision)
	
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.is_in_group("Player") and not activado:
		activado = true
		material_bandera.albedo_color = Color.GREEN 
		
		body.ultimo_checkpoint = global_position
