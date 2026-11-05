extends Control

# Costos de las mejoras (puedes cambiarlos)
var costo_velocidad : int = 25
var costo_pde : int = 30

@onready var texto_monedas = $Panel/VBoxContainer/TextoMonedas
@onready var boton_vel = $Panel/VBoxContainer/BotonVelocidad
@onready var boton_pde = $Panel/VBoxContainer/BotonPDE
@onready var boton_cerrar = $Panel/BotonCerrar


func _ready() -> void:
	boton_vel.pressed.connect(_on_comprar_velocidad)
	boton_pde.pressed.connect(_on_comprar_pde)
	boton_cerrar.pressed.connect(_on_cerrar_tienda)
	visibility_changed.connect(_on_visibility_changed)
	
	actualizar_ui()

# Esta función revisa el dinero y apaga los botones si no te alcanza o si ya lo compraste
func actualizar_ui() -> void:
	texto_monedas.text = "Tus Monedas: " + str(GlobalVar.monedas)
	# Lógica Botón Velocidad
	if GlobalVar.velocidad_mejorada:
		boton_vel.text = "Velocidad: AL MÁXIMO"
		boton_vel.disabled = true
	elif GlobalVar.monedas < costo_velocidad:
		boton_vel.disabled = true
	else:
		boton_vel.disabled = false
	
	if GlobalVar.pde_mejorados:
		boton_pde.text = "Límite PDE: AL MÁXIMO"
		boton_pde.disabled = true
	elif GlobalVar.monedas < costo_pde:
		boton_pde.disabled = true
	else:
		boton_pde.disabled = false


func _on_comprar_velocidad() -> void:
	# Usamos la función de GlobalVar
	var compra_exitosa = GlobalVar.comprar_mejora_velocidad(costo_velocidad)
	if compra_exitosa:
		
		var jugador = get_tree().get_first_node_in_group("Player")
		if jugador:
			jugador.velocidad = GlobalVar.velocidad_rapida 
			
		actualizar_ui()


func _on_comprar_pde() -> void:
	# Usamote
	var compra_exitosa = GlobalVar.comprar_mejora_pde(costo_pde)
	
	if compra_exitosa:
		actualizar_ui()
	
	var jugador = get_tree().get_first_node_in_group("Player")
	if jugador:
		EVENT_BUS_JUGADOR.pde_actualizado.emit(jugador.PDE)


func _on_cerrar_tienda() -> void:
	hide()
	get_tree().paused = false 
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _on_visibility_changed() -> void:
	if visible:
		actualizar_ui() 
		


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and visible:
		_on_cerrar_tienda()
		get_viewport().set_input_as_handled()
