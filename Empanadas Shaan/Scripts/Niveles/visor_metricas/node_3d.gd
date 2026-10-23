@tool
extends Node3D
## Visor de métricas. Colocalo en el origen (0,0,0) de tu nivel.
## Pulsá "Cargar datos" en el Inspector: dibuja los puntos guardados por las
## partidas (user://metricas/*.jsonl) directamente en el escenario del editor.
##
## Los nodos que crea no se guardan en la escena: son solo para mirar.

const COLORES := {
	"muestra": Color.RED,
	"salto": Color.WHITE,
	"aterrizaje": Color.GREEN,
	"recuperacion": Color.ORANGE,
	"quieto": Color.GRAY,
	"pared": Color.CYAN,
	"acomodo": Color.PURPLE,
	"duda": Color.MAGENTA,
}
const COLOR_MUERTE_TRAS_SALTO := Color.BLUE
const COLOR_MUERTE_SIN_SALTO := Color.YELLOW

## Vacío = usa el nombre de la escena donde está este nodo.
## Si el nivel se llama distinto al ejecutar el juego, escribilo acá.
@export var nivel := ""
## Qué tipos de evento dibujar. Podés agregar: "quieto", "pared", "acomodo", "duda".
@export var mostrar: Array[String] = ["muestra", "salto", "aterrizaje", "muerte", "recuperacion"]
@export var radio := 0.3
@warning_ignore("unused_private_class_variable")
@export_tool_button("Cargar datos") var _boton_cargar := cargar
@warning_ignore("unused_private_class_variable")
@export_tool_button("Limpiar") var _boton_limpiar := limpiar


func limpiar() -> void:
	for hijo in get_children():
		hijo.queue_free()


func cargar() -> void:
	limpiar()
	var nivel_buscado := nivel
	if nivel_buscado == "" and owner != null:
		nivel_buscado = owner.name

	var puntos := {}                  # color -> lista de posiciones
	var lineas: Array[Vector3] = []   # de a pares: aterrizaje, salto

	for evento in _leer_eventos():
		if nivel_buscado != "" and evento.get("nivel", "") != nivel_buscado:
			continue
		var tipo: String = evento.get("tipo", "")
		var datos: Dictionary = evento.get("datos", {})
		if not tipo in mostrar or not datos.has("pos"):
			continue

		var posicion := _a_vector(datos["pos"])
		var color := _color_de(tipo, datos)
		if not puntos.has(color):
			puntos[color] = []
		puntos[color].append(posicion)

		if tipo == "aterrizaje" and datos.has("desde"):
			lineas.append(posicion)
			lineas.append(_a_vector(datos["desde"]))

	_dibujar_puntos(puntos)
	_dibujar_lineas(lineas)
	@warning_ignore("integer_division")
	print("Visor: %d colores, %d líneas (nivel '%s')" % [puntos.size(), lineas.size() / 2, nivel_buscado])


## Lee todos los archivos .jsonl de la carpeta y devuelve la lista de eventos.
func _leer_eventos() -> Array[Dictionary]:
	var eventos: Array[Dictionary] = []
	var ruta := "res://metricas"
	
	if not DirAccess.dir_exists_absolute(ruta):
		print("Visor: La carpeta 'res://metricas' no existe.")
		return eventos

	for nombre in DirAccess.get_files_at(ruta):
		if not nombre.ends_with(".jsonl"):
			continue
			
		var archivo := FileAccess.open(ruta + "/" + nombre, FileAccess.READ)
		if archivo:
			while not archivo.eof_reached():
				var linea = archivo.get_line().strip_edges()
				if linea == "":
					continue
					
				var evento = JSON.parse_string(linea)
				if evento is Dictionary:
					eventos.append(evento)
			archivo.close()
			
	return eventos


func _color_de(tipo: String, datos: Dictionary) -> Color:
	if tipo == "muerte":
		if datos.get("tras_salto", false):
			return COLOR_MUERTE_TRAS_SALTO
		return COLOR_MUERTE_SIN_SALTO
	return COLORES.get(tipo, Color.GRAY)


func _a_vector(lista: Array) -> Vector3:
	return Vector3(lista[0], lista[1], lista[2])


## Un MultiMesh dibuja muchísimas esferas iguales en una sola pasada (es rápido).
## Se crea uno por color.
func _dibujar_puntos(puntos: Dictionary) -> void:
	for color in puntos:
		var lista: Array = puntos[color]

		var material := StandardMaterial3D.new()
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED  # sin sombras
		material.albedo_color = color

		var esfera := SphereMesh.new()
		esfera.radius = radio
		esfera.height = radio * 2.0
		esfera.material = material

		var multi := MultiMesh.new()
		multi.transform_format = MultiMesh.TRANSFORM_3D
		multi.mesh = esfera
		multi.instance_count = lista.size()
		for i in lista.size():
			multi.set_instance_transform(i, Transform3D(Basis(), lista[i]))

		var nodo := MultiMeshInstance3D.new()
		nodo.multimesh = multi
		add_child(nodo)


## Líneas blancas entre cada aterrizaje y su salto.
func _dibujar_lineas(lineas: Array[Vector3]) -> void:
	if lineas.is_empty():
		return
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color.WHITE

	var malla := ImmediateMesh.new()
	malla.surface_begin(Mesh.PRIMITIVE_LINES, material)
	for punto in lineas:
		malla.surface_add_vertex(punto)
	malla.surface_end()

	var nodo := MeshInstance3D.new()
	nodo.mesh = malla
	add_child(nodo)
