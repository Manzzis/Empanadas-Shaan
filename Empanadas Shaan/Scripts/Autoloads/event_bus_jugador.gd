extends Node
#Autoload que gestiona las señales referentes al jugador


signal aumentar_pde_del_jugador
func aumentar_pde():
	aumentar_pde_del_jugador.emit()

signal reducir_pde_del_jugador
func reducir_pde():
	reducir_pde_del_jugador.emit()
