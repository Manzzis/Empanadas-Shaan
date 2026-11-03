extends Control

@onready var progress_bar: ProgressBar = $ProgressBar
@onready var label: Label = $Label


func _ready() -> void:
	EVENT_BUS_JUGADOR.pde_actualizado.connect(actualizar_barra)
	progress_bar.max_value = GlobalVar.pde_max


func actualizar_barra(valor: int) -> void:
	progress_bar.max_value = GlobalVar.pde_max
	progress_bar.value = valor
	label.text = str(valor)
