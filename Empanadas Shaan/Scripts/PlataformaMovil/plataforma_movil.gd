extends AnimatableBody3D

@export var velocidad: float = 2.0
@export var distancia: float = 5.0
# Usa (1,0,0) para X, (0,1,0) para Y, o (0,0,1) para Z
@export var direccion: Vector3 = Vector3(1, 0, 0) 
@export var tamano: Vector3 = Vector3(2, 0.5, 2)

var posicion_inicial: Vector3
var tiempo: float = 0.0

func _ready():
	posicion_inicial = global_position
	
	# Aseguramos que la dirección sea un vector de longitud 1
	direccion = direccion.normalized()
	
	# Ajustamos el tamaño visual y de colisión al valor configurado
	$Malla.scale = tamano
	$Colision.scale = tamano

func _physics_process(delta):
	tiempo += delta * velocidad
	
	# Calculamos la posición entre punto A y B usando la función seno.
	# (sin() va de -1 a 1. Al sumarle 1 y dividir por 2, va de 0 a 1)
	var progreso = (sin(tiempo) + 1.0) / 2.0
	
	# Movemos la plataforma desde su origen hasta la distancia máxima
	global_position = posicion_inicial + (direccion * (progreso * distancia))
