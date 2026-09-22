class_name Base_de_estados extends Node
#	CLASE ABSTRACTA, NO TOCAR

#referencia al nodo que controla
var nodo_controlador : Node

var mi_maquina_de_estados : Maquina_de_estados


#métodos que todos los estados comparten
#pueden servir para algo especial que ocurra cuando un estado inicia o finaliza
func iniciar():
	pass

func finalizar():
	pass

func on_process(_delta: float) -> void:
	pass

func on_physics_process(_delta: float) -> void:
	pass

func on_input(_event: InputEvent) -> void:
	pass

func on_unhandled_input(_event: InputEvent) -> void:
	pass

func on_unhandled_key_input(_event: InputEvent) -> void:
	pass
