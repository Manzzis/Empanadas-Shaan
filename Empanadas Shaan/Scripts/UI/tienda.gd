extends Control

# Costos de las mejoras (puedes cambiarlos)
var costo_velocidad : int = 50
var costo_pde : int = 30

@onready var texto_monedas = $Panel/VBoxContainer/TextoMonedas
@onready var boton_vel = $Panel/VBoxContainer/BotonVelocidad
@onready var boton_pde = $Panel/VBoxContainer/BotonPDE
@onready var boton_cerrar = $Panel/VBoxContainer/BotonCerrar

func _ready() -> void:
	boton_vel.pressed.connect(_on_comprar_velocidad)
	boton_pde.pressed.connect(_on_comprar_pde)
	boton_cerrar.pressed.connect(_on_cerrar_tienda)
	
	actualizar_ui()

# Esta función revisa el dinero y apaga los botones si no te alcanza o si ya lo compraste
func actualizar_ui() -> void:
	texto_monedas.text = "Tus Monedas: " + str(GlobalVar.monedas) # <-- CORREGIDO
	
	# Lógica Botón Velocidad
	if GlobalVar.velocidad_mejorada: # <-- CORREGIDO
		boton_vel.text = "Velocidad: AL MÁXIMO"
		boton_vel.disabled = true
	elif GlobalVar.monedas < costo_velocidad:
		boton_vel.disabled = true
	else:
		boton_vel.disabled = false
		
	# Lógica Botón PDE
	if GlobalVar.pde_mejorados: # <-- CORREGIDO
		boton_pde.text = "Límite PDE: AL MÁXIMO"
		boton_pde.disabled = true
	elif GlobalVar.monedas < costo_pde:
		boton_pde.disabled = true
	else:
		boton_pde.disabled = false


func _on_comprar_velocidad() -> void:
	# Usamos la función de GlobalVar que hace toda la matemática por nosotros
	var compra_exitosa = GlobalVar.comprar_mejora_velocidad(costo_velocidad)
	
	if compra_exitosa:
		# Buscar al jugador en la escena para darle la velocidad INMEDIATAMENTE
		var jugador = get_tree().get_first_node_in_group("Player")
		if jugador:
			jugador.velocidad = GlobalVar.velocidad_rapida 
			
		actualizar_ui()


func _on_comprar_pde() -> void:
	# Usamos la función de GlobalVar que descuenta el dinero y sube el límite
	var compra_exitosa = GlobalVar.comprar_mejora_pde(costo_pde)
	
	if compra_exitosa:
		actualizar_ui()


func _on_cerrar_tienda() -> void:
	# Oculta la tienda y devuelve el control al juego
	hide()
	get_tree().paused = false # Si pausas el juego al abrir la tienda
