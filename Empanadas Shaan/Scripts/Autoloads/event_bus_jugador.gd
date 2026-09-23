extends Node
#Autoload que gestiona las señales referentes al jugador



################################################
#Señales desde los estados de Caminar, Saltar, Caer, Grindear y Idle
#para actualizar los PDE del jugador
################################################
signal aumentar_pde_del_jugador
signal reducir_pde_del_jugador
signal pde_actualizado(valor_pde : int)
