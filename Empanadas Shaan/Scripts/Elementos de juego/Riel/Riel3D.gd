extends Path3D
class_name Riel3D

@export var margen: float = 1.0
@export var detalle_curva: float = 0.5
@export var desplazamiento_y: float = -0.1  # Ajuste fino para subir o bajar la colisión

@onready var path_follow: PathFollow3D = $PathFollow3D
@onready var area_deteccion: Area3D = $Area3D
@onready var csg: CSGPolygon3D = $CSGPolygon3D

func _ready() -> void:
	_generar_colisiones()
	
	if area_deteccion:
		area_deteccion.body_entered.connect(_on_body_entered)
		area_deteccion.body_exited.connect(_on_body_exited)

func _generar_colisiones() -> void:
	if not curve or not area_deteccion or not csg:
		return

	# Limpiamos colisiones anteriores
	for hijo in area_deteccion.get_children():
		hijo.queue_free()

	var poly := csg.polygon
	if poly.size() == 0:
		return
		
	var min_p : Vector2 = poly[0]
	var max_p : Vector2 = poly[0]
	for p in poly:
		min_p = min_p.min(p)
		max_p = max_p.max(p)
		
	var ancho := (max_p.x - min_p.x) + margen
	var alto_real := (max_p.y - min_p.y) + margen
	var centro_perfil := (min_p + max_p) / 2.0

	# Obtenemos los puntos locales que componen la curva
	var puntos := curve.tessellate(5, detalle_curva)

	for i in puntos.size() - 1:
		var a := puntos[i]
		var b := puntos[i + 1]
		var largo := a.distance_to(b)
		
		if largo < 0.01:
			continue

		var forma := BoxShape3D.new()
		forma.size = Vector3(ancho, alto_real, largo)

		var cs := CollisionShape3D.new()
		cs.shape = forma
		area_deteccion.add_child(cs)

		# 1. Calculamos el progreso (offset) en la curva justo en la mitad de este segmento
		var pos_intermedia_segmento := (a + b) / 2.0
		var progreso_intermedio := curve.get_closest_offset(pos_intermedia_segmento)
		
		# 2. --- SOLUCIÓN DE ORIENTACIÓN LOCAL EN GODOT 4 ---
		# Extraemos la transformación local exacta (posición y rotación) de la curva en ese progreso.
		# Esto coincide al 100% con cómo el CSGPolygon3D calcula su forma.
		var transform_curva_local := curve.sample_baked_with_rotation(progreso_intermedio, true)
		var base_exacta := transform_curva_local.basis

		# 3. Aplicamos el desplazamiento del perfil usando la rotación interna del riel
		var centro_y_ajustado = centro_perfil.y + desplazamiento_y
		var offset_perfil := base_exacta * Vector3(centro_perfil.x, centro_y_ajustado, 0.0)
		
		# La posición final es el centro del segmento en la curva más el desfase de la forma del riel
		var pos_final_local := transform_curva_local.origin + offset_perfil

		# Asignamos la transformación combinada completamente en espacio local
		cs.transform = Transform3D(base_exacta, pos_final_local)

	# Notificamos al servidor de físicas para que active los colisionadores inmediatamente
	PhysicsServer3D.set_active(true)

func _on_body_entered(body: Node3D) -> void:
	if body is Jugador:
		body.riel_actual = self

func _on_body_exited(body: Node3D) -> void:
	if body is Jugador and body.riel_actual == self:
		body.riel_actual = null

func get_closest_progress(player_global_pos: Vector3) -> float:
	var local_pos = to_local(player_global_pos)
	return curve.get_closest_offset(local_pos)
