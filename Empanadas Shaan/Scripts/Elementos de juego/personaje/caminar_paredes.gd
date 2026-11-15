class_name CaminarParedesComponent extends Node

@export var jugador : Jugador

@export_group("Detección")
@export var distancia_rayo: float = 1.4
@export var altura_rayo: float = 0.5

@export_group("Deslizamiento")
@export var factor_gravedad_pared: float = 0.12
## Si está activo, el choque en ángulo se convierte en deslizamiento a la misma rapidez
@export var conservar_rapidez: bool = false

@export_group("Wall jump")
@export var impulso_adelante: float = 4.0   # BOOST: empujón a lo largo de la pared
@export var impulso_salida: float = 6.0     # JUMP_OUT: separación de la pared
@export var impulso_arriba: float = 8.0     # JUMP_UP: velocidad vertical fija
@export var cooldown: float = 0.3           # tiempo sin poder reenganchar tras saltar

@export_group("Giro del cuerpo")
## Cuánto se aleja el frente del muro, medido desde "paralelo a la pared"
@export_range(0.0, 90.0) var giro_alejado_grados : float = 35.0
@export var velocidad_giro_pared : float = 10.0

@export_group("Agarre")
## Segundos desde que te pegás en los que no hace falta mantener el giro
@export var gracia_entrada : float = 0.1
## Segundos sin poder volver a engancharte después de soltarte por no girar
@export var cooldown_soltar : float = 0.3

var _bloqueo: float = 0.0


func _physics_process(delta: float) -> void:
	_bloqueo = max(_bloqueo - delta, 0.0)


## ¿Debería el jugador engancharse a una pared ahora? Devuelve el hit o {}.
func detectar_entrada() -> Dictionary:
	if _bloqueo > 0.0 or jugador.is_on_floor():
		return {}
	return buscar_muro()


## Devuelve el hit del muro (con "normal", "position", "collider") o {}.
## dir_preferida: si se pasa, se prueba primero esa dirección (hacia el muro actual),
## porque al girar el cuerpo los rayos laterales ya no son perpendiculares al muro.
func buscar_muro(dir_preferida: Vector3 = Vector3.ZERO) -> Dictionary:
	var espacio := jugador.get_world_3d().direct_space_state
	var pos := jugador.global_position + Vector3.UP * altura_rayo
	var derecha := jugador.global_basis.x
	var lados: Array[Vector3] = [derecha, -derecha]
	if dir_preferida != Vector3.ZERO:
		lados.push_front(dir_preferida.normalized())

	for lado in lados:
		var query := PhysicsRayQueryParameters3D.create(
			pos, pos + lado * distancia_rayo,
			jugador.collision_mask, [jugador.get_rid()])
		var hit := espacio.intersect_ray(query)
		if hit and hit.collider.is_in_group("caminable"):
			return hit

	return {}


## lado: +1 = muro a la izquierda, -1 = muro a la derecha.
## Devuelve true si el input de giro empuja hacia el muro.
func mantiene_agarre(lado: float) -> bool:
	if lado == 0.0:
		return true
	var giro := Input.get_axis("Girar_der", "Girar_izq")   # +1 = izquierda
	return giro * lado > 0.0


## Te suelta del muro y bloquea reengancharte durante cooldown_soltar
func soltar_muro() -> void:
	_bloqueo = cooldown_soltar


## Elimina la velocidad contra el muro y reduce la gravedad
func deslizar_en_muro(muro: Dictionary, delta: float) -> void:
	var normal: Vector3 = muro.normal
	var contra_pared := jugador.velocity.dot(normal)

	if contra_pared < 0.0:
		var rapidez := jugador.velocity.length()
		jugador.velocity -= normal * contra_pared
		if conservar_rapidez and jugador.velocity.length() > 0.01:
			jugador.velocity = jugador.velocity.normalized() * rapidez

	jugador.velocity.y -= jugador.gravedad * factor_gravedad_pared * delta


## Gira el CUERPO (yaw) para que su frente quede levemente alejado del muro.
## Se llama cada frame desde el estado Pared. Al salir no se revierte,
## así el salto sale con el frente ya alineado.
func alinear_frente(muro: Dictionary, delta: float) -> void:
	var n: Vector3 = muro.normal
	var n_h := Vector3(n.x, 0.0, n.z)
	if n_h.length_squared() < 0.001:
		return
	n_h = n_h.normalized()

	# Dirección a lo largo de la pared
	var along := Vector3(jugador.velocity.x, 0.0, jugador.velocity.z).slide(n_h)
	if along.length_squared() < 0.25:
		along = jugador.get_adelante().slide(n_h)
	if along.length_squared() < 0.001:
		return
	along = along.normalized()

	var a := deg_to_rad(giro_alejado_grados)
	var frente := along * cos(a) + n_h * sin(a)

	# get_adelante() es basis.z, y rotation.y gira z hacia x: yaw = atan2(x, z)
	var yaw_objetivo := atan2(frente.x, frente.z)
	jugador.rotation.y = lerp_angle(
		jugador.rotation.y, yaw_objetivo, clampf(velocidad_giro_pared * delta, 0.0, 1.0))


## Salto desde la pared
func saltar_de_muro(muro: Dictionary) -> void:
	var normal: Vector3 = muro.normal
	var horizontal := Vector3(jugador.velocity.x, 0.0, jugador.velocity.z)
	var along := horizontal.slide(normal)

	jugador.velocity = along + along.normalized() * impulso_adelante
	jugador.velocity += normal * impulso_salida
	jugador.velocity.y = impulso_arriba

	_bloqueo = cooldown
