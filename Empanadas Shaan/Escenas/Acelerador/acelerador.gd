extends Area3D

@onready var mi_animacion = $Animation
@export var fuerza_impulso := 20
@export var duracion_impulso := 0.3
var Vector_impulso := Vector3.ZERO
var direccion_impulso : Vector3
var actor : CharacterBody3D = null

var tiempo_restante := 0.0

func _ready() -> void:
	mi_animacion.play("Animation_arrow")
	set_physics_process(false)




func _on_body_entered(body: Node3D) -> void:
	if body is Jugador:
		actor = body
		tiempo_restante = duracion_impulso
		#igual que en dash, obtenemos el "adelante" del acelerador
		# (deberia ser el adelante de las flechas)
		
		var direccion_impulso = actor.global_transform.basis.z
		direccion_impulso.y = 0
		direccion_impulso = direccion_impulso.normalized()
		
		Vector_impulso = direccion_impulso * fuerza_impulso
		
		
		# este set physics procces es para que no se esten ejecutando en todo momento,
		# si ponemos 10 aceleradores, los 10 estarian funcionando al mismo tiempo
		# 60 veces por segundo, por eso apagamos y prendemos 
		
		set_physics_process(true)
		
	else:
		actor = null

func _physics_process(delta: float) -> void:
	tiempo_restante -= delta
	actor.velocity.x = Vector_impulso.x
	actor.velocity.z = Vector_impulso.z
	if tiempo_restante <= 0:
		actor = null
		set_physics_process(false)
	
	
