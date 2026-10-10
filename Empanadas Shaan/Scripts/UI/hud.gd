extends CanvasLayer

@onready var GLOBAL_BUS_ID = AudioServer.get_bus_index("Master")
@onready var MUSIC_BUS_ID = AudioServer.get_bus_index("MUSIC")
@onready var SFX_BUS_ID = AudioServer.get_bus_index("SFX")
@onready var menu: Control = $menu

func _ready() -> void:
	pass # Replace with function body.


func _process(delta: float) -> void:
	pass

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
