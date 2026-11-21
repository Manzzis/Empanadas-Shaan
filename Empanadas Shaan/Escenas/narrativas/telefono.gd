extends Node3D

@export_category("Levitación")
@export var altura_levitacion: float = 0.15    # cuánto sube y baja (metros)
@export var duracion_levitacion: float = 1.6   # segundos por subida o bajada

@export_category("Escala")
@export var escala_minima: float = 0.9         # multiplicador respecto a la escala original
@export var escala_maxima: float = 1.15
@export var duracion_pulso: float = 1.2

@export_category("Giro")
@export var velocidad_giro: float = 45.0       # grados por segundo
@export var eje_giro: Vector3 = Vector3.UP

var _escala_base: Vector3
var _pos_base_y: float

func _ready() -> void:
	_escala_base = scale
	_pos_base_y = position.y
	_iniciar_levitacion()
	_iniciar_pulso()

func _process(delta: float) -> void:
	rotate(eje_giro.normalized(), deg_to_rad(velocidad_giro) * delta)

func _iniciar_levitacion() -> void:
	var t := create_tween().set_loops()
	t.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.tween_property(self, "position:y", _pos_base_y + altura_levitacion, duracion_levitacion)
	t.tween_property(self, "position:y", _pos_base_y - altura_levitacion, duracion_levitacion)

func _iniciar_pulso() -> void:
	var t := create_tween().set_loops()
	t.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.tween_property(self, "scale", _escala_base * escala_maxima, duracion_pulso)
	t.tween_property(self, "scale", _escala_base * escala_minima, duracion_pulso)
