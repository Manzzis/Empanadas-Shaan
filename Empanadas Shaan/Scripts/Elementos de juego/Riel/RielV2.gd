extends Path3D
class_name RielMapa3D

@export_category("Detección del Riel")
@export var ancho_deteccion: float = 1.0
@export var alto_deteccion: float = 1.0
@export var detalle_curva: float = 0.5
@export var desplazamiento_y: float = 0.0 # Ajuste fino vertical si el Path queda un poco arriba o abajo

@onready var path_follow: PathFollow3D = $PathFollow3D
@onready var area_deteccion: Area3D = $Area3D

func _ready() -> void:
	add_to_group("RailPath")
	_generar_colisiones()
	
	if area_deteccion:
		area_deteccion.body_entered.connect(_on_body_entered)
		area_deteccion.body_exited.connect(_on_body_exited)

func _generar_colisiones() -> void:
	if not curve or not area_deteccion:
		return

	for hijo in area_deteccion.get_children():
		hijo.queue_free()

	var puntos := curve.tessellate(5, detalle_curva)

	for i in puntos.size() - 1:
		var a := puntos[i]
		var b := puntos[i + 1]
		var largo := a.distance_to(b)
		
		if largo < 0.01:
			continue

		var forma := BoxShape3D.new()
		forma.size = Vector3(ancho_deteccion, alto_deteccion, largo)

		var cs := CollisionShape3D.new()
		cs.shape = forma
		area_deteccion.add_child(cs)

		var pos_intermedia := (a + b) / 2.0
		var progreso := curve.get_closest_offset(pos_intermedia)
		var transform_curva := curve.sample_baked_with_rotation(progreso, true)
		
		var offset_vertical := transform_curva.basis.y * desplazamiento_y
		cs.transform = Transform3D(transform_curva.basis, transform_curva.origin + offset_vertical)

func _on_body_entered(body: Node3D) -> void:
	if body is Jugador:
		body.riel_actual = self

func _on_body_exited(body: Node3D) -> void:
	if body is Jugador and body.riel_actual == self:
		body.riel_actual = null

func get_closest_progress(player_global_pos: Vector3) -> float:
	var local_pos := to_local(player_global_pos)
	return curve.get_closest_offset(local_pos)
