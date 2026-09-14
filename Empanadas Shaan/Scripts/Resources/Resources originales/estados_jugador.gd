class_name Estados_jugador_resource extends Resource
#	este resource tiene la única funcion de hacer que
#	los estados del jugador tengan una referencia limpia al jugador,
#	ya que pueden referenciar al siguiente estado con ayuda del motor,
#	en lugar de depender que por ejemplo escribamos "Caminar" en lugar
#	de "Caninar"

const Idle : String = "Idle"
const Caminar : String = "Caminar"
const Correr : String = "Correr"
const Saltar : String = "Saltar"
const Gridear : String = "Gridear"
const Caer : String = "Caer"
const Aterrizar : String = "Aterrizar"
const Morir : String = "Morir"
