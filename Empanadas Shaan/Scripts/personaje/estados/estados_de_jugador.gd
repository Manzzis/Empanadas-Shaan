class_name Estados_de_jugador extends Base_de_estados
#Agarramos la clase abstracta de "Base de estados" y la personalizamos para jugador
#Esta es la clase padre de todos los estados del jugador

#esta var se usa en iniciar
var jugador : Jugador

#Todos los estados usan la gravedad, entonces se los aplicamos directamente acá
var gravedad : float = ProjectSettings.get_setting("physics/3d/default_gravity")

func iniciar():
	jugador = nodo_controlador
	#ahora el nodo controlador ya no es tan misterioso para los estados del jugador,
	#simplemente es el jugador, porque están personalizados, ya que heredan de esta clase

func finalizar():
	pass

#acá aplicamos la gravedad, los demás estados simplemente deberán llamar al método
func handle_gravity(delta):
	nodo_controlador.velocity.y -= gravedad * delta
