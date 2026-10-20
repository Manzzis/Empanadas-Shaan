class_name MetricsTracker extends Node
## Hijo directo del nodo Jugador. Observa al personaje cada frame de física y
## manda eventos al autoload Metrics. No modifica el comportamiento del jugador.

@export var accion_salto: StringName = &"Saltar"
@export var accion_girar_der: StringName = &"Girar_der"
@export var accion_girar_izq: StringName = &"Girar_izq"

@export_group("Umbrales")
@export var intervalo_muestra := 0.2          ## segundos entre muestras del mapa de calor
@export var umbral_quieto := 0.2              ## m/s: por debajo se considera quieto
@export var quieto_min_s := 0.25              ## ignora pausas más cortas que esto
@export var borde_umbral_m := 0.5             ## despegar a menos de esto del borde = salto "al borde"
@export var ventana_salto_tardio_s := 0.35    ## salto pedido hasta X s después de dejar el piso
@export var caida_fuerte_vy := -8.0           ## velocidad vertical (m/s) que cuenta como caída fuerte
@export var recuperacion_pct := 0.9           ## % de la velocidad previa para dar por recuperado
@export var recuperacion_timeout_s := 5.0
@export var acomodo_min_grados := 5.0         ## giro mínimo parado para contar como "acomodarse"

var j: Jugador
var _t := 0.0
var _t_muestra := 0.0
var _was_floor := true
var _prev_vy := 0.0
var _rapidez_prev := 0.0
var _piso_actual: Object = null
var _pos_piso := Vector3.ZERO
var _t_input_salto := -99.0

# quieto
var _quieto_t := 0.0
var _ultimo_quieto_dur := 0.0
var _ultimo_quieto_fin := -99.0

# acomodo
var _acomodo_rad := 0.0
var _acomodo_t := 0.0
var _rot_prev := 0.0

# pared
var _en_pared := false
var _pared_t := 0.0
var _pared_gap := 0.0
var _pared_v := 0.0

# saltos
var _en_salto := false
var _salto := {}
var _t_dejo_piso := -99.0
var _salio_sin_saltar := false
var _salto_tardio := false
var _v_al_dejar_piso := 0.0

# recuperación tras caída
var _recup_activa := false
var _recup_t0 := 0.0
var _recup_objetivo := 0.0


func _ready() -> void:
	j = get_parent() as Jugador
	if j == null:
		push_error("MetricsTracker debe ser hijo directo del Jugador")
		set_physics_process(false)
		return
	process_physics_priority = 100  # corre DESPUÉS de move_and_slide del jugador
	_rot_prev = j.rotation.y


func _physics_process(delta: float) -> void:
	_t += delta
	if Input.is_action_just_pressed(accion_salto):
		_t_input_salto = _t

	var on_floor := j.is_on_floor()
	var rapidez := Vector2(j.velocity.x, j.velocity.z).length()
	var piso: Object = _collider_piso() if on_floor else null

	_muestrear(delta, rapidez, on_floor)
	_medir_quieto(delta, rapidez, on_floor)
	_medir_acomodo(delta, rapidez, on_floor)
	_medir_pared(delta)
	_medir_aire(on_floor, piso, rapidez)
	_medir_recuperacion(rapidez)

	if on_floor:
		if piso != null:
			_piso_actual = piso
		_pos_piso = j.global_position
	_was_floor = on_floor
	_prev_vy = j.velocity.y
	_rapidez_prev = rapidez


# ---------- API pública: llamala donde reaparece el jugador ----------

func registrar_muerte(causa: String = "caida") -> void:
	if _salto_tardio and causa == "caida":
		causa = "salto_tardio"
	if _en_salto:
		_cerrar_salto(null, true)
	Metrics.log_event("muerte", {
		"causa": causa,
		"checkpoint_idx": Metrics.checkpoint_idx,
		"pos": Metrics.v3(j.global_position),
	})
	_reset()


func _reset() -> void:
	_quieto_t = 0.0
	_acomodo_rad = 0.0
	_acomodo_t = 0.0
	_en_pared = false
	_en_salto = false
	_salto_tardio = false
	_salio_sin_saltar = false
	_recup_activa = false
	_was_floor = true
	_prev_vy = 0.0


# ---------- Mapa de calor + velocidad ----------

func _muestrear(delta: float, rapidez: float, on_floor: bool) -> void:
	_t_muestra += delta
	if _t_muestra < intervalo_muestra:
		return
	_t_muestra -= intervalo_muestra
	Metrics.log_event("muestra", {
		"p": Metrics.v3(j.global_position),
		"v": snappedf(rapidez, 0.01),
		"suelo": on_floor,
	})


# ---------- Tiempo quieto ----------

func _medir_quieto(delta: float, rapidez: float, on_floor: bool) -> void:
	if on_floor and rapidez < umbral_quieto:
		_quieto_t += delta
	elif _quieto_t > 0.0:
		_cerrar_quieto()


func _cerrar_quieto() -> void:
	if _quieto_t >= quieto_min_s:
		Metrics.log_event("quieto", {
			"dur": snappedf(_quieto_t, 0.001),
			"pos": Metrics.v3(j.global_position),
		})
		_ultimo_quieto_dur = _quieto_t
		_ultimo_quieto_fin = _t
	_quieto_t = 0.0


# ---------- Acomodarse antes de moverse ----------

func _medir_acomodo(delta: float, rapidez: float, on_floor: bool) -> void:
	var giro := Input.get_axis(accion_girar_der, accion_girar_izq)
	var parado := on_floor and rapidez < umbral_quieto
	if parado:
		if giro != 0.0:
			_acomodo_rad += absf(angle_difference(_rot_prev, j.rotation.y))
			_acomodo_t += delta
	else:
		if rad_to_deg(_acomodo_rad) >= acomodo_min_grados:
			Metrics.log_event("acomodo", {
				"giro_deg": snappedf(rad_to_deg(_acomodo_rad), 0.1),
				"dur_s": snappedf(_acomodo_t, 0.001),
			})
		_acomodo_rad = 0.0
		_acomodo_t = 0.0
	_rot_prev = j.rotation.y


# ---------- Contacto con paredes ----------

func _medir_pared(delta: float) -> void:
	if j.is_on_wall():
		_pared_gap = 0.0
		if not _en_pared:
			_en_pared = true
			_pared_t = 0.0
			_pared_v = _rapidez_prev
		_pared_t += delta
	elif _en_pared:
		_pared_gap += delta
		if _pared_gap > 0.1:  # histéresis: evita cortar el contacto por un frame
			_en_pared = false
			Metrics.log_event("pared", {
				"dur": snappedf(_pared_t, 0.001),
				"v_impacto": snappedf(_pared_v, 0.01),
				"pos": Metrics.v3(j.global_position),
			})


# ---------- Saltos, salto tardío y aterrizajes ----------

func _medir_aire(on_floor: bool, piso: Object, rapidez: float) -> void:
	if _was_floor and not on_floor:
		_v_al_dejar_piso = rapidez
		var voluntario := j.velocity.y > 1.0 and (_t - _t_input_salto) < 0.25
		if voluntario:
			_iniciar_salto()
		else:
			_t_dejo_piso = _t
			_salio_sin_saltar = true

	# Salió de la plataforma caminando y apretó salto DESPUÉS de dejar el piso.
	if not on_floor and _salio_sin_saltar and not _salto_tardio \
			and _t_input_salto >= _t_dejo_piso \
			and (_t_input_salto - _t_dejo_piso) <= ventana_salto_tardio_s:
		_salto_tardio = true

	if not _was_floor and on_floor:
		_aterrizar(piso, rapidez)


func _iniciar_salto() -> void:
	var s := _mejor_shape(_piso_actual, _pos_piso)
	var dist_borde: float = s.get("d", -1.0)
	var pre := _ultimo_quieto_dur if (_t - _ultimo_quieto_fin) <= 0.4 else 0.0
	_en_salto = true
	_salto = {
		"origen": _id_plataforma(_piso_actual),
		"pos": _pos_piso,
		"t": _t,
		"dist_borde_origen": snappedf(dist_borde, 0.01),
		"borde_origen": dist_borde >= 0.0 and dist_borde < borde_umbral_m,
		"pre_quieto_s": snappedf(pre, 0.001),
	}


func _aterrizar(piso: Object, rapidez: float) -> void:
	if _en_salto:
		_cerrar_salto(piso, false)
	_salio_sin_saltar = false
	_salto_tardio = false
	if _prev_vy < caida_fuerte_vy:
		Metrics.log_event("caida", {"vy": snappedf(_prev_vy, 0.1), "v_antes": snappedf(_v_al_dejar_piso, 0.01)})
		if _v_al_dejar_piso > 2.0:
			_recup_activa = true
			_recup_t0 = _t
			_recup_objetivo = _v_al_dejar_piso


func _cerrar_salto(piso: Object, fallo: bool) -> void:
	var pos0: Vector3 = _salto["pos"]
	var destino := ""
	var resultado := "fallo"
	var corto := -1.0  # distancia desde donde aterrizó al borde cercano (por donde llegó)
	var largo := -1.0  # distancia al borde lejano (cuánto le faltó para pasarse)
	if not fallo:
		destino = _id_plataforma(piso)
		resultado = "acierto" if destino != _salto["origen"] else "mismo_sitio"
		var dir := j.global_position - pos0
		dir.y = 0.0
		var s := _mejor_shape(piso, j.global_position)
		if not s.is_empty() and dir.length() > 0.2:
			var inv: Transform3D = s["inv"]
			var ldir: Vector3 = inv.basis * dir
			ldir.y = 0.0
			ldir = ldir.normalized()
			corto = _dist_hasta_borde(s, -ldir)
			largo = _dist_hasta_borde(s, ldir)
			if not is_finite(corto) or not is_finite(largo):
				corto = -1.0
				largo = -1.0
	var total := corto + largo
	Metrics.log_event("salto", {
		"origen": _salto["origen"],
		"destino": destino,
		"resultado": resultado,
		"borde_origen": _salto["borde_origen"],
		"dist_borde_origen": _salto["dist_borde_origen"],
		"pre_quieto_s": _salto["pre_quieto_s"],
		"aire_s": snappedf(_t - _salto["t"], 0.001),
		"borde_cercano_m": snappedf(corto, 0.01),
		"borde_lejano_m": snappedf(largo, 0.01),
		# 0 = rozó el borde por donde llegó, 100 = aterrizó casi pasándose
		"aterrizaje_pct": snappedf(100.0 * corto / total, 0.1) if corto >= 0.0 and total > 0.0 else -1.0,
		"pos_despegue": Metrics.v3(pos0),
		"pos_aterrizaje": Metrics.v3(j.global_position),
	})
	_en_salto = false


# ---------- Recuperación de velocidad tras caer ----------

func _medir_recuperacion(rapidez: float) -> void:
	if not _recup_activa:
		return
	var dt := _t - _recup_t0
	if rapidez >= _recup_objetivo * recuperacion_pct:
		Metrics.log_event("recuperacion", {"t": snappedf(dt, 0.001), "ok": true, "v_objetivo": snappedf(_recup_objetivo, 0.01)})
		_recup_activa = false
	elif dt > recuperacion_timeout_s:
		Metrics.log_event("recuperacion", {"t": snappedf(dt, 0.001), "ok": false, "v_objetivo": snappedf(_recup_objetivo, 0.01)})
		_recup_activa = false


# ---------- Utilidades de plataformas ----------
# Cada plataforma debe ser un cuerpo (StaticBody3D, etc.) con CollisionShape3D
# como hijo directo. Su id es el meta "id_plataforma" o, si no existe, su nombre.

func _collider_piso() -> Object:
	var n := j.get_floor_normal()
	for i in j.get_slide_collision_count():
		var c := j.get_slide_collision(i)
		if c.get_normal().dot(n) > 0.98:
			return c.get_collider()
	return null


func _id_plataforma(col: Object) -> String:
	if col == null:
		return "?"
	if col.has_meta("id_plataforma"):
		return str(col.get_meta("id_plataforma"))
	return str(col.name) if col is Node else "?"


## Devuelve el CollisionShape3D del cuerpo "bajo" pos, con la posición en su espacio local.
## d = distancia (m) de pos al borde más cercano del rectángulo XZ del shape.
func _mejor_shape(col: Object, pos: Vector3) -> Dictionary:
	var mejor := {}
	var mejor_d := -INF
	if col == null or not (col is Node):
		return mejor
	for hijo in col.get_children():
		if hijo is CollisionShape3D and hijo.shape != null:
			var aabb: AABB = hijo.shape.get_debug_mesh().get_aabb()
			var inv: Transform3D = hijo.global_transform.affine_inverse()
			var lp: Vector3 = inv * pos
			var c := aabb.get_center()
			var h := aabb.size * 0.5
			var d := minf(h.x - absf(lp.x - c.x), h.z - absf(lp.z - c.z))
			if d > mejor_d:
				mejor_d = d
				mejor = {"inv": inv, "lp": lp, "c": c, "h": h, "d": d}
	return mejor


func _dist_hasta_borde(s: Dictionary, dir: Vector3) -> float:
	var lp: Vector3 = s["lp"]
	var c: Vector3 = s["c"]
	var h: Vector3 = s["h"]
	var t := INF
	for eje in [0, 2]:
		if absf(dir[eje]) > 0.00001:
			var limite: float = c[eje] + h[eje] * signf(dir[eje])
			t = minf(t, (limite - lp[eje]) / dir[eje])
	return t
