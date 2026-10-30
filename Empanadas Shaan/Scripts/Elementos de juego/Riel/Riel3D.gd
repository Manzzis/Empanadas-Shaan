extends Path3D
class_name Riel3D

@export var margen: float = 1.0
@export var detalle_curva: float = 0.5

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

	for hijo in area_deteccion.get_children():
		hijo.queue_free()

	var poly := csg.polygon
	var min_p := poly[0]
	var max_p := poly[0]
	for p in poly:
		min_p = min_p.min(p)
		max_p = max_p.max(p)
	var ancho := (max_p.x - min_p.x) + margen
	var alto := (max_p.y - min_p.y) + margen
	var centro_perfil := (min_p + max_p) / 2.0

	var puntos := curve.tessellate(5, detalle_curva)

	for i in puntos.size() - 1:
		var a := puntos[i]
		var b := puntos[i + 1]
		var largo := a.distance_to(b)
		if largo < 0.01:
			continue

		var forma := BoxShape3D.new()
		forma.size = Vector3(ancho, alto, largo)

		var cs := CollisionShape3D.new()
		cs.shape = forma
		area_deteccion.add_child(cs)

		var dir := (b - a).normalized()
		var up := Vector3.UP if abs(dir.dot(Vector3.UP)) < 0.99 else Vector3.FORWARD
		var base := Basis.looking_at(dir, up)
		var pos := (a + b) / 2.0 + base * Vector3(centro_perfil.x, centro_perfil.y, 0.0)
		cs.transform = Transform3D(base, pos)

func _on_body_entered(body: Node3D) -> void:
	if body is Jugador:
		body.riel_actual = self

func _on_body_exited(body: Node3D) -> void:
	if body is Jugador and body.riel_actual == self:
		body.riel_actual = null

func get_closest_progress(player_global_pos: Vector3) -> float:
	var local_pos = to_local(player_global_pos)
	return curve.get_closest_offset(local_pos)
