extends ESCInventory
# Inventario nuevo (INVENTARIO_Nuevo.png, 4 lugares).
#  - Cerrado: solo asoma la pestaña (la "joroba" con flechas) abajo a la izquierda.
#  - Se abre al pasar el mouse por la pestaña y se cierra al sacar el mouse
#    hacia arriba (fuera de la barra).
#  - Arrastrar un ítem y soltarlo sobre otro ítem del inventario, o sobre algo
#    de la sala (personaje, objeto), equivale a "usar X con Y": dispara el
#    evento ":use X" del script .esc correspondiente.
#    También funciona a la vieja usanza: click en el ítem y después click en el destino.

# Medidas en coordenadas del panel (la imagen se dibuja a 1920x1080).
const BORDE_BARRA := 333.0                    # y donde empieza la barra del inventario
const PESTANA := Rect2(30, 165, 310, 185)     # zona de la joroba con flechas
const ASOMA_CERRADO := 345.0                  # cuánto del panel se ve cerrado
const UMBRAL_ARRASTRE := 14.0                 # px antes de considerar que es un arrastre

var inventory_visible: bool = false

var _tween: Tween
var _arrastre_id: String = ""
var _arrastre_desde: Vector2
var _arrastrando: bool = false

@onready var inventory_scene: Control = $panel
@onready var _bloqueo: Control = $panel/bloqueo
@onready var _slots = $panel/slot_manager


func _ready() -> void:
	super._ready()
	inventory_scene.position.y = _y_cerrado()
	$panel/pestana.mouse_entered.connect(show_inventory)
	_slots.item_presionado.connect(_on_item_presionado)


func _y_cerrado() -> float:
	return get_viewport_rect().size.y - ASOMA_CERRADO


func _y_abierto() -> float:
	return get_viewport_rect().size.y - inventory_scene.size.y


func show_inventory() -> void:
	if inventory_visible:
		return
	inventory_visible = true
	_bloqueo.mouse_filter = Control.MOUSE_FILTER_STOP
	_mover(_y_abierto(), 0.35)


func hide_inventory() -> void:
	if not inventory_visible:
		return
	inventory_visible = false
	_bloqueo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_mover(_y_cerrado(), 0.45)


func _mover(y: float, duracion: float) -> void:
	if _tween:
		_tween.kill()
	_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_tween.tween_property(inventory_scene, "position:y", y, duracion)


# --- Abrir / cerrar según la posición del mouse --------------------------------

func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return

	if event is InputEventMouseMotion:
		var mouse := get_viewport().get_mouse_position()
		var local := mouse - inventory_scene.global_position
		var sobre_pestana := PESTANA.has_point(local)
		if inventory_visible:
			if local.y < BORDE_BARRA and not sobre_pestana:
				hide_inventory()
		elif sobre_pestana:
			# Mientras se arrastra, Godot no manda mouse_entered a otros nodos.
			show_inventory()
		if _arrastre_id != "" and not _arrastrando \
				and mouse.distance_to(_arrastre_desde) > UMBRAL_ARRASTRE:
			_arrastrando = true

	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT \
			and not event.pressed and _arrastre_id != "":
		var soltado := _arrastre_id
		var era_arrastre := _arrastrando
		_arrastre_id = ""
		_arrastrando = false
		if era_arrastre:
			_soltar(soltado, get_viewport().get_mouse_position())


# --- Arrastrar y soltar ----------------------------------------------------------

func _on_item_presionado(global_id: String) -> void:
	_arrastre_id = global_id
	_arrastre_desde = get_viewport().get_mouse_position()
	_arrastrando = false


func _soltar(herramienta: String, pos_pantalla: Vector2) -> void:
	if escoria.current_state != escoria.GameState.DEFAULT \
			or escoria.inputs_manager.input_mode != ESCInputsManager.INPUT_ALL \
			or not escoria.inventory_manager.inventory_has(herramienta) \
			or escoria.object_manager.get_object(herramienta) == null:
		_cancelar()
		return

	var mundo := get_viewport().get_canvas_transform().affine_inverse() * pos_pantalla
	var objetivo := _item_de_inventario_en(pos_pantalla)
	var en_sala := false
	if objetivo == "":
		objetivo = _item_de_sala_en(mundo)
		en_sala = true

	if objetivo == "" or objetivo == herramienta:
		_cancelar()
		return

	var am = escoria.action_manager
	# Al apretar el ítem Escoria ya lo tomó como herramienta de "usar";
	# si por algún motivo no (otro verbo elegido), lo fuerzo.
	if am.current_tool == null or am.current_tool.global_id != herramienta:
		am.clear_current_action()
		am.set_current_action("use")
		am.do(am.ACTION.ITEM_LEFT_CLICK, [herramienta, _evento(pos_pantalla)])

	# Solo saco el ícono del ítem del cursor: cambiar de verbo acá borraría la
	# herramienta antes de usarla. Escoria vuelve a "caminar" al terminar la acción.
	_limpiar_cursor(false)
	if en_sala:
		hide_inventory()
	am.do(am.ACTION.ITEM_LEFT_CLICK, [objetivo, _evento(mundo)], true)


func _item_de_inventario_en(pos_pantalla: Vector2) -> String:
	if not inventory_visible:
		return ""
	for boton in _slots.get_buttons():
		if boton.get_global_rect().has_point(pos_pantalla):
			return boton.global_id
	return ""


func _item_de_sala_en(pos_mundo: Vector2) -> String:
	if inventory_visible and get_viewport().get_mouse_position().y \
			>= inventory_scene.global_position.y + BORDE_BARRA:
		return ""   # se soltó sobre la barra del inventario, no sobre la sala
	var consulta := PhysicsPointQueryParameters2D.new()
	consulta.position = pos_mundo
	consulta.collide_with_areas = true
	consulta.collide_with_bodies = false
	var golpes := get_viewport().world_2d.direct_space_state.intersect_point(consulta, 32)

	var jugador = escoria.main.current_scene.player if escoria.main.current_scene else null
	var mejor: ESCItem = null
	for golpe in golpes:
		var nodo = golpe.collider
		if not (nodo is ESCItem) or nodo == jugador or not nodo.is_visible_in_tree():
			continue
		if not escoria.object_manager.has(nodo.global_id):
			continue
		var obj = escoria.object_manager.get_object(nodo.global_id)
		if obj == null or not obj.active or not obj.interactive:
			continue
		if mejor == null or nodo.z_index > mejor.z_index \
				or (nodo.z_index == mejor.z_index and nodo.global_position.y > mejor.global_position.y):
			mejor = nodo
	return mejor.global_id if mejor else ""


func _evento(pos: Vector2) -> InputEventMouseButton:
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.pressed = true
	ev.position = pos
	ev.global_position = pos
	return ev


func _cancelar() -> void:
	escoria.action_manager.clear_current_action()
	_limpiar_cursor(true)


func _limpiar_cursor(volver_a_caminar: bool) -> void:
	var verbos = escoria.game_scene.get_node_or_null("mouse_layer/verbs_menu")
	if verbos:
		verbos.clear_tool_texture()
		if volver_a_caminar:
			verbos.set_by_name("walk")
