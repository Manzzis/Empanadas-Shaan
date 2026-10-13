extends CanvasLayer

@onready var GLOBAL_BUS_ID = AudioServer.get_bus_index("Master")
@onready var sonido_global_control: HSlider = %sonido_global_control_deslizante

@onready var MUSIC_BUS_ID = AudioServer.get_bus_index("MUSIC")
@onready var music_control: HSlider = %music_control_deslizante

@onready var SFX_BUS_ID = AudioServer.get_bus_index("SFX")
@onready var sfx_control: HSlider = %SFX_control_deslizante

@onready var menu: Control = $menu

func _ready() -> void:
	_aplicar_volumen(GLOBAL_BUS_ID, sonido_global_control.value)
	_aplicar_volumen(MUSIC_BUS_ID, music_control.value)
	_aplicar_volumen(SFX_BUS_ID, sfx_control.value)

func _aplicar_volumen(bus_id: int, valor: float) -> void:
	AudioServer.set_bus_volume_db(bus_id, linear_to_db(valor))
	AudioServer.set_bus_mute(bus_id, valor < 0.05)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("menu"):
		menu.visible = !menu.visible

func _on_sonido_global_control_deslizante_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(GLOBAL_BUS_ID, linear_to_db(value))
	AudioServer.set_bus_mute(GLOBAL_BUS_ID, value < 0.05)


func _on_music_control_deslizante_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(MUSIC_BUS_ID, linear_to_db(value))
	AudioServer.set_bus_mute(MUSIC_BUS_ID, value < 0.05)


func _on_sfx_control_deslizante_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(SFX_BUS_ID, linear_to_db(value))
	AudioServer.set_bus_mute(SFX_BUS_ID, value < 0.05)
