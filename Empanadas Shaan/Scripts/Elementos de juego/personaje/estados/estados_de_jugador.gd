class_name Estados_de_jugador extends Base_de_estados
#Agarramos la clase abstracta de "Base de estados" y la personalizamos para jugador
#Esta es la clase padre de todos los estados del jugador

#esta var se usa en iniciar
var jugador : Jugador

signal mas_puntos_de_estilo
signal menos_puntos_de_estilo

func _ready():
	#conectamos la señal puntos_de_estilo al autoload para avisarle cada vez que queramos
	#que este autoload gestione los puntos de estilo del jugador
	
	#le decimos directamente que active su metodo gestionar_pde
	mas_puntos_de_estilo.connect(EVENT_BUS_JUGADOR.aumentar_pde)
	menos_puntos_de_estilo.connect(EVENT_BUS_JUGADOR.reducir_pde)

func iniciar():
	jugador = nodo_controlador
	#ahora el nodo controlador ya no es tan misterioso para los estados del jugador,
	#simplemente es el jugador, porque están personalizados, ya que heredan de esta clase

func finalizar():
	pass
