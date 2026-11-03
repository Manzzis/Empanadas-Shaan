extends Node3D

# Lo que tarda cada trail en desaparecer
@export var trail_duration: float = 0.7

# Que tan grueso es el trail
@export var trail_width: float = 0.045

# La velocidad que es necesaria para que se genere el trail
@export var min_speed: float = 0.5

# La distancia entre punto y punto dentro del trail (el trail esta hecho de puntos)
@export var min_point_distance: float = 0.06

# La altura del trail
@export var vertical_offset: float = 0.5

# Las referencias al personaje y a los puntos del trail
var player: CharacterBody3D
var trail_points: Array[Dictionary] = []

# las variables de los visuales para el trail
var trail_mesh: MeshInstance3D
var trail_material: StandardMaterial3D


func _ready() -> void:
	player = get_parent() as CharacterBody3D

# Crea una malla, la pone como trail y desactiva la sombra de la misma.
	trail_mesh = MeshInstance3D.new()
	add_child(trail_mesh)
	trail_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

# Modificaciones basicas del material
	trail_material = StandardMaterial3D.new()
	
	# Color
	trail_material.albedo_color = Color.WHITE
	# Evita que el escenario toque el color del trail
	trail_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	# Transparencia para los extremos de los puntos
	trail_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	# Habilita que cada vertice tenga su propio color
	trail_material.vertex_color_use_as_albedo = true
	# Permite que veamos el trail de todos lados
	trail_material.cull_mode = BaseMaterial3D.CULL_DISABLED


# Si el personaje desaparece, el efecto termina
func _process(delta: float) -> void:
	if player == null:
		return

	var velocity := Vector2(
		player.velocity.x,
		player.velocity.z
	)

	# Añadir puntos solo cuando el personaje se mueve y mover el trail acorde al personaje
	if velocity.length() > min_speed:
		var new_position := player.global_position
		new_position.y += vertical_offset
	
	# El sistema de trails: chequea si el trail tiene puntos, si no los tiene los crea y si los tiene, toma el ultimo y crea otro a partir de este.
		if trail_points.is_empty():
			_add_point(new_position)
		else:
			var last_position: Vector3 = trail_points[-1]["position"]

			if last_position.distance_to(new_position) >= min_point_distance:
				_add_point(new_position)

	# "Envejece" los puntos; agrega una vida util a cada punto, borra los viejos, agrega uno nuevo y repite este proceso.
	for i in range(trail_points.size()):
		trail_points[i]["age"] += delta

	while not trail_points.is_empty():
		if trail_points[0]["age"] >= trail_duration:
			trail_points.pop_front()
		else:
			break

	# Updatea constantemente el trail visualmente, para que tire facha.
	_update_trail()

# Sistema de puntos del trail; agrega un punto 3D con una posicion y una edad
func _add_point(pos: Vector3) -> void:
	trail_points.append({
		"position": pos,
		"age": 0.0
	})

# Actualiza el trail para que no se sature; si tiene menos de 2 puntos se elimina.
func _update_trail() -> void:
	if trail_points.size() < 2:
		trail_mesh.mesh = null
		return

# Busca la camara 3D activa en la escena, si no la encuentra para la funcion.
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return

# Crea una herramienta para construir geometria con codigo, le dice que vamos a usar triangulos y que vamos a usar el material que creamos antes (el coso WHITE).
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface.set_material(trail_material)

# Logica interna de como funciona el trail; crea vertices en los puntos y los une, tambien los hace transparentes mientras mas viejos sean.
	for i in range(trail_points.size() - 1):

		var point_a: Vector3 = to_local(trail_points[i]["position"])
		var point_b: Vector3 = to_local(trail_points[i + 1]["position"])

		var direction := (point_b - point_a).normalized()

		var midpoint := (point_a + point_b) * 0.5
		var camera_direction := to_local(camera.global_position) - midpoint

		var side := direction.cross(camera_direction).normalized()

		if side.length() < 0.01:
			side = direction.cross(Vector3.UP).normalized()

		side *= trail_width * 0.5

		var left_a := point_a - side
		var right_a := point_a + side
		var left_b := point_b - side
		var right_b := point_b + side

		var alpha_a := 1.0 - float(trail_points[i]["age"]) / trail_duration
		var alpha_b := 1.0 - float(trail_points[i + 1]["age"]) / trail_duration

		_add_vertex(surface, left_a, alpha_a)
		_add_vertex(surface, right_a, alpha_a)
		_add_vertex(surface, left_b, alpha_b)

		_add_vertex(surface, left_b, alpha_b)
		_add_vertex(surface, right_a, alpha_a)
		_add_vertex(surface, right_b, alpha_b)
# Manda todo lo que hizo el "for" anterior y lo manda al personaje.
	trail_mesh.mesh = surface.commit()

# Crea una funcioon que recibe una superficie, una posicion y un valor de transparecia.
func _add_vertex(surface: SurfaceTool, pos: Vector3, alpha: float) -> void:
	surface.set_color(Color(1.0, 1.0, 1.0, clampf(alpha, 0.0, 1.0)))
	surface.add_vertex(pos)
