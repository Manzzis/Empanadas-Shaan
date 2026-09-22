class_name Estados_de_jugador extends Base_de_estados
#Agarramos la clase abstracta de "Base de estados" y la personalizamos para jugador
#Esta es la clase padre de todos los estados del jugador

#esta var se usa en iniciar
var jugador : Jugador


func iniciar():
	jugador = nodo_controlador
	#ahora el nodo controlador ya no es tan misterioso para los estados del jugador,
	#simplemente es el jugador, porque están personalizados, ya que heredan de esta clase

func finalizar():
	pass
