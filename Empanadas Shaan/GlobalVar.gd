extends Node

# La única variable de dinero. ¡Bórrala del script del jugador!
var monedas : int = 0

# ### MEJORA: PUNTOS DE ESTILO ###
var pde_max : int = 10
var pde_mejorados : bool = false

# ### MEJORA: VELOCIDAD ###
var velocidad_mejorada : bool = false
var velocidad_normal : float = 10.0
var velocidad_rapida : float = 15.0 # La velocidad que tendrá tras comprar


## Función que llamará el botón de la tienda ##
func comprar_mejora_pde(costo: int) -> bool:
	if monedas >= costo and not pde_mejorados:
		monedas -= costo
		pde_mejorados = true
		pde_max = 15
		return true # Compra exitosa
	return false # No hay dinero o ya se compró

## Función que llamará el otro botón ##
func comprar_mejora_velocidad(costo: int) -> bool:
	if monedas >= costo and not velocidad_mejorada:
		monedas -= costo
		velocidad_mejorada = true
		return true
	return false
