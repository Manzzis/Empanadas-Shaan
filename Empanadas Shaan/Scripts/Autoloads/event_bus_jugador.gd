extends Node
#Autoload que gestiona las señales referentes al jugador


################################################
#Señales desde los estados de Caminar, Saltar, Caer, Grindear y Idle
#para actualizar los PDE del jugador
################################################
signal aumentar_pde_del_jugador
signal reducir_pde_del_jugador
signal pde_actualizado(valor_pde : int)
################################################

################################################
#Señales desde los estados de Caminar, Saltar, Caer y Idle
#para gastar los PDE del jugador en utilizar el DASH
################################################
signal usar_dash

################################################


################################################
#Señal desde los estados hasta el componente de "sonidos del jugador"
################################################
signal sonido_estado(estado : String)
################################################

################################################
#Señales desde los estados de Caminar, Saltar, Caer y Idle
#para que la camara limite sus comportamientos
################################################

signal estado_jugador_cambiado(nuevo_estado : String)
