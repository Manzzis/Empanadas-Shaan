extends Node3D
class_name CinematicaEmpanadas

signal linea_dialogo(hablante: String, texto: String)
signal cinematica_terminada

@export_category("Audio")
@export var reduccion_musica_db: float = -60.0   # cuánto baja (más negativo = más bajo)
@export var duracion_fade: float = 0.8

var _volumen_musica_original: float = 0.0

@export var rig: Node3D
@export var overlay: ColorRect
@export var camara_componente: CameraComponent

@export_category("Planos de Waliam")
@export var w_a: PhantomCamera3D
@export var w_b: PhantomCamera3D

@export_category("Planos del jugador")
@export var j1: PhantomCamera3D
@export var j2: PhantomCamera3D
@export var j3: PhantomCamera3D

var jugador: CharacterBody3D
var _prioridad: int = 10
var _siguiendo: bool = false
var _en_curso: bool = false

func _ready() -> void:
	rig.top_level = true   # el rig ignora el transform del padre
	overlay.modulate.a = 0.0

func _process(_delta: float) -> void:
	# El rig acompaña la posición del jugador, pero conserva su orientación
	if _siguiendo and is_instance_valid(jugador):
		rig.global_position = jugador.global_position

# ---------- utilidades ----------

func _bajar_musica() -> void:
	var bus := AudioServer.get_bus_index("MUSIC")
	_volumen_musica_original = AudioServer.get_bus_volume_db(bus)
	_fade_musica(bus, _volumen_musica_original, _volumen_musica_original + reduccion_musica_db)

func _restaurar_musica() -> void:
	var bus := AudioServer.get_bus_index("MUSIC")
	_fade_musica(bus, AudioServer.get_bus_volume_db(bus), _volumen_musica_original)

func _fade_musica(bus: int, desde: float, hasta: float) -> void:
	var t := create_tween()
	t.tween_method(func(v: float): AudioServer.set_bus_volume_db(bus, v), desde, hasta, duracion_fade)
	
func _anclar_rig() -> void:
	# Usa la orientación de la cámara de juego: "de espaldas" será
	# respecto a lo que el jugador veía justo antes
	var yaw: float = get_viewport().get_camera_3d().global_rotation.y
	rig.global_position = jugador.global_position
	rig.global_rotation = Vector3(0.0, yaw, 0.0)
	_siguiendo = true

func _cortar_a(pcam: PhantomCamera3D) -> void:
	_prioridad += 1
	pcam.priority = _prioridad   # al ser la más alta, la cámara salta a ella


func _devolver_camara() -> void:
	for p in [w_a, w_b, j1, j2, j3]:
		p.priority = 0
	_prioridad = 10   # la cámara principal (priority 1) vuelve a ser la más alta

func _parpadeo(al_cerrar: Callable, cerrar_primero: bool = true) -> void:
	if cerrar_primero:
		var t := create_tween()
		t.tween_property(overlay, "modulate:a", 1.0, 0.12)
		await t.finished
	al_cerrar.call()
	var t2 := create_tween()
	t2.tween_property(overlay, "modulate:a", 0.0, 0.12)
	await t2.finished

func _esperar(segundos: float) -> void:
	await get_tree().create_timer(segundos).timeout

func _bloquear_jugador(bloqueado: bool) -> void:
	if camara_componente == null:
		camara_componente = get_tree().get_first_node_in_group("camara_componente")
	if camara_componente:
		camara_componente.controles_activos = not bloqueado

# Se llama desde el archivo .dialogue
func plano(nombre: String) -> void:
	var mapa := {"w_a": w_a, "w_b": w_b, "j1": j1, "j2": j2, "j3": j3}
	if mapa.has(nombre):
		_cortar_a(mapa[nombre])

func iniciar(p_jugador: CharacterBody3D) -> void:
	if _en_curso: return
	_en_curso = true
	jugador = p_jugador
	_bajar_musica()          # <-- nuevo
	_bloquear_jugador(true)
	_anclar_rig()
	overlay.modulate.a = 1.0
	await _parpadeo(func(): _cortar_a(w_a), false)

func terminar() -> void:
	await _parpadeo(_devolver_camara)
	_restaurar_musica()      # <-- nuevo
	_siguiendo = false
	_bloquear_jugador(false)
	_en_curso = false
	cinematica_terminada.emit()
