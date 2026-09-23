extends Control

@onready var progress_bar: ProgressBar = $ProgressBar
@onready var label: Label = $Label

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	EVENT_BUS_JUGADOR.pde_actualizado.connect(actualizar_barra)
	progress_bar.max_value = 10


# Called every frame. 'delta' is the elapsed time since the previous frame.
func actualizar_barra(valor: int) -> void:
	progress_bar.value = valor
	label.text = str(valor)
