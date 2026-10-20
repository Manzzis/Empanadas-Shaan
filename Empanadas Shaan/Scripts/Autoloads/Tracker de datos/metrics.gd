extends Node
## Autoload "Metrics" (Project Settings > Globals > Autoload).
## Escribe un evento JSON por línea en user://metricas/sesion_<fecha>.jsonl

var nivel_actual := "sin_nivel"
var checkpoint_idx := 0

var _t0_usec := Time.get_ticks_usec()
var _t_nivel_usec := Time.get_ticks_usec()
var _buffer: Array[String] = []
var _file: FileAccess
var _vol_visto: Array[float] = []
var _vol_confirmado: Array[float] = []


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute("user://metricas")
	var stamp := Time.get_datetime_string_from_system().replace(":", "-")
	_file = FileAccess.open("user://metricas/sesion_%s.jsonl" % stamp, FileAccess.WRITE)
	print("Métricas en: ", ProjectSettings.globalize_path("user://metricas"))
	_crear_timer(5.0, flush)
	_crear_timer(0.5, _revisar_audio)
	for i in AudioServer.bus_count:
		var v := _pct_bus(i)
		_vol_visto.append(v)
		_vol_confirmado.append(v)
	log_event("sesion_inicio", {"volumen_inicial": _vol_confirmado})


func _crear_timer(seg: float, cb: Callable) -> void:
	var t := Timer.new()
	t.wait_time = seg
	t.timeout.connect(cb)
	add_child(t)
	t.start()


# ---------- API pública ----------

static func v3(v: Vector3) -> Array:
	return [snappedf(v.x, 0.01), snappedf(v.y, 0.01), snappedf(v.z, 0.01)]


func t_nivel() -> float:
	return (Time.get_ticks_usec() - _t_nivel_usec) / 1000000.0


func log_event(evento: String, data: Dictionary = {}) -> void:
	_buffer.append(JSON.stringify({
		"t_usec": Time.get_ticks_usec() - _t0_usec,
		"frame": Engine.get_physics_frames(),
		"nivel": nivel_actual,
		"t_nivel_s": snappedf(t_nivel(), 0.001),
		"event": evento,
		"data": data,
	}))


func nivel_inicio(id: String) -> void:
	nivel_actual = id
	checkpoint_idx = 0
	_t_nivel_usec = Time.get_ticks_usec()
	log_event("nivel_inicio")


func nivel_fin() -> void:
	log_event("nivel_fin", {"tiempo_s": snappedf(t_nivel(), 0.001)})


func checkpoint() -> void:
	checkpoint_idx += 1
	log_event("checkpoint", {"idx": checkpoint_idx})


# ---------- Audio: detecta cambios de volumen automáticamente ----------

func _pct_bus(i: int) -> float:
	if AudioServer.is_bus_mute(i):
		return 0.0
	return snappedf(db_to_linear(AudioServer.get_bus_volume_db(i)) * 100.0, 0.1)


func _revisar_audio() -> void:
	# Se registra el cambio cuando el valor se estabiliza (evita un evento por cada
	# tick mientras se arrastra un slider).
	for i in mini(AudioServer.bus_count, _vol_visto.size()):
		var v := _pct_bus(i)
		if is_equal_approx(v, _vol_visto[i]) and absf(v - _vol_confirmado[i]) >= 0.5:
			log_event("volumen", {
				"bus": AudioServer.get_bus_name(i),
				"desde": _vol_confirmado[i],
				"hasta": v,
			})
			_vol_confirmado[i] = v
		_vol_visto[i] = v


# ---------- Disco ----------

func flush() -> void:
	if _file == null or _buffer.is_empty():
		return
	for linea in _buffer:
		_file.store_line(linea)
	_file.flush()
	_buffer.clear()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		flush()


func _exit_tree() -> void:
	flush()
