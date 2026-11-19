extends Node

@export var jugador : Jugador

@export var s_caminar : AudioStreamPlayer
@export var s_saltar : AudioStreamPlayer
@export var s_grindear : AudioStreamPlayer
var grindeando = false
@export var s_dashear : AudioStreamPlayer
@export var s_pared : AudioStreamPlayer
@export var s_caida : AudioStreamPlayer

@export_group("Fade caminar")
@export var volumen_max_db : float = -15.0
@export var volumen_min_db : float = -40.0
@export var duracion_fade_in : float = 0.3
@export var duracion_fade_out : float = 0.5

@export_group("Loop caminar")
@export var caminar_loop_inicio : float = 1.0
@export var caminar_loop_fin : float = 6.60

@export_group("Loop grindear")
@export var grindear_loop_inicio : float = 1.0
@export var grindear_loop_fin : float = 1.50

@export_group("Tramo saltar")
@export var saltar_inicio : float = 1.5
@export var saltar_fin : float = 3.0

@export_group("Tramo pared")
@export var pared_inicio : float = 2.0
@export var pared_fin : float = 3.45

@export_group("Tramo caida")
@export var caida_inicio : float = 3.48
@export var caida_fin : float = 3.91

var estado_actual : String = ""
var caminar_activo : bool = false
var tween_caminar : Tween
var timer_saltar : SceneTreeTimer
var timer_pared : SceneTreeTimer
var timer_caida : SceneTreeTimer


func _ready() -> void:
	EVENT_BUS_JUGADOR.sonido_estado.connect(gestionar_sonido)
	s_caminar.volume_db = volumen_min_db


func _physics_process(_delta: float) -> void:
	var debe_sonar = debe_sonar_caminar()
	if debe_sonar != caminar_activo:
		caminar_activo = debe_sonar
		if caminar_activo:
			fade_in_caminar()
		else:
			fade_out_caminar()

	# Loop de caminar entre inicio y fin
	if s_caminar.playing and s_caminar.get_playback_position() >= caminar_loop_fin:
		s_caminar.seek(caminar_loop_inicio)

	# Loop de grindear entre inicio y fin
	if grindeando and s_grindear.playing and s_grindear.get_playback_position() >= grindear_loop_fin:
		s_grindear.seek(grindear_loop_inicio)


func debe_sonar_caminar() -> bool:
	if estado_actual == jugador.estados.Caminar:
		return true
	if estado_actual == jugador.estados.Idle:
		var vel_horizontal = Vector2(jugador.velocity.x, jugador.velocity.z).length()
		return vel_horizontal > 0.1
	return false


func fade_in_caminar() -> void:
	if tween_caminar:
		tween_caminar.kill()
	if not s_caminar.playing:
		s_caminar.play(caminar_loop_inicio)
	tween_caminar = create_tween()
	tween_caminar.tween_property(s_caminar, "volume_db", volumen_max_db, duracion_fade_in)


func fade_out_caminar() -> void:
	if tween_caminar:
		tween_caminar.kill()
	tween_caminar = create_tween()
	tween_caminar.tween_property(s_caminar, "volume_db", volumen_min_db, duracion_fade_out)
	tween_caminar.tween_callback(s_caminar.stop)


func reproducir_saltar() -> void:
	s_saltar.play(saltar_inicio)
	var timer := get_tree().create_timer(saltar_fin - saltar_inicio)
	timer_saltar = timer
	await timer.timeout
	if timer == timer_saltar:
		s_saltar.stop()


func reproducir_pared() -> void:
	s_pared.play(pared_inicio)
	var timer := get_tree().create_timer(pared_fin - pared_inicio)
	timer_pared = timer
	await timer.timeout
	if timer == timer_pared:
		s_pared.stop()


func reproducir_caida() -> void:
	s_caida.play(caida_inicio)
	var timer := get_tree().create_timer(caida_fin - caida_inicio)
	timer_caida = timer
	await timer.timeout
	# Solo corta si no se reinició el sonido mientras esperaba
	if timer == timer_caida:
		s_caida.stop()


func gestionar_sonido(estado : String):
	var estado_anterior : String = estado_actual
	var cambio_de_estado : bool = estado != estado_anterior
	estado_actual = estado

	if estado != jugador.estados.Grindear:
		grindeando = false
		s_grindear.stop()

	if estado != jugador.estados.Pared:
		timer_pared = null
		s_pared.stop()

	if cambio_de_estado:
		# Al entrar a Grindear o Pared
		var entra_a_superficie : bool = estado == jugador.estados.Grindear or estado == jugador.estados.Pared
		# Al tocar el piso después de estar cayendo
		var aterriza : bool = estado_anterior == jugador.estados.Caer \
				and estado != jugador.estados.Saltar \
				and jugador.is_on_floor()

		if entra_a_superficie or aterriza:
			reproducir_caida()

	match estado:
		jugador.estados.Saltar:
			reproducir_saltar()
		jugador.estados.Pared:
			reproducir_pared()
		jugador.estados.Grindear:
			grindeando = true
			if not s_grindear.playing:
				s_grindear.play(grindear_loop_inicio)
		jugador.estados.Dashear:
			s_dashear.play()


# Respaldo: si el audio llegara a terminar solo, reinicia en el inicio del loop
func _on_s_grindear_finished() -> void:
	if grindeando:
		s_grindear.play(grindear_loop_inicio)
