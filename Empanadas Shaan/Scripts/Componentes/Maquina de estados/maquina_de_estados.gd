class_name Maquina_de_estados extends Node
#	esta maquina es un componente, por lo que cualquier nodo puede controlarla
#	Para eso, simplemente le colocaremos la escena dueña de este script como hija
#	del nodo objetivo. Además, crearemos una clase que sea hija de "Base de estados".
#	Esa clase creada será la clase padre de todos los estados que vaya a utilizar ese nodo.

#	referencia al nodo que controla, lo recibimos con inyección de dependencia
@export var nodo_controlador : Node

#	referencia directa al estado base que queremos de nuestro controlador,
#	también lo inyectamos
@export var estado_por_defecto : Base_de_estados

var estado_actual : Base_de_estados = null

func _ready() -> void:
	call_deferred("iniciar_estado_por_defecto")
	#		esto inicializa el estado base 1 frame después de inicializarse
	#	la máquina de estados, evitando posibles errores de instanciación
	
func iniciar_estado_por_defecto() -> void:
	estado_actual = estado_por_defecto
	iniciar_estado()

func iniciar_estado() -> void:
	#prints("maquina de estados", nodo_controlador.name, "iniciar estado", estado_actual.name)
	estado_actual.nodo_controlador = nodo_controlador
	#	el estado actual, como sabemos que hereda de "Base de estados",
	#	sabemos que tiene una var de "nodo controlador", por lo que le asignaremos
	#	como su nodo controlador, el propio nodo controlador de esta máquina
	#	de estados, por lo que, será el mismo controlador que inyectamos al inicio
	
	estado_actual.mi_maquina_de_estados = self
	#	le avisamos también al estado que su máquina es esta
	
	estado_actual.iniciar()

func cambiar_a(nuevo_estado: String) -> void:
	if estado_actual and estado_actual.has_method("finalizar"):
		estado_actual.finalizar()
	estado_actual = get_node(nuevo_estado)
	iniciar_estado()
	print("estoy en ", estado_actual)


#		Para evitar que los estados particulares estén CONSTANTEMENTE atentos
#	a lo que deben hacer, el único responsable de ejecutarlos, sin importar el nodo
#	controlador, es esta maquina de estados. De modo que, por ejemplo, NO se
#	reproducirán 2 _process, solo uno.
func _process(delta: float) -> void:
	if estado_actual and estado_actual.has_method("on_process"):
		estado_actual.on_process(delta)

func _physics_process(delta: float) -> void:
	if estado_actual and estado_actual.has_method("on_physics_process"):
		estado_actual.on_physics_process(delta)

func _input(event: InputEvent) -> void:
	if estado_actual and estado_actual.has_method("on_input"):
		estado_actual.on_input(event)

func _unhandled_input(event: InputEvent) -> void:
	if estado_actual and estado_actual.has_method("on_unhandled_input"):
		estado_actual.on_unhandled_input(event)

func _unhandled_key_input(event: InputEvent) -> void:
	if estado_actual and estado_actual.has_method("on_unhandled_key_input"):
		estado_actual.on_unhandled_key_input(event)
