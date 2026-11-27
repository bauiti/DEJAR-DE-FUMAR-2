extends ESCInventoryContainer
# Reparte los ítems del inventario en los lugares (slots) de INVENTARIO_Nuevo.
# Los slots son los Container hijos de este nodo (slot1..slot4), ubicados sobre
# los 4 huecos grises de la imagen. El tamaño de cada ítem lo fija Escoria con
# Project Settings > escoria/ui/inventory_item_size (230x230).
# Si hubiera más ítems que lugares, el sobrante queda guardado (oculto) y entra
# apenas se libera un lugar.

signal item_presionado(global_id: String)

@onready var _desborde: Control = $desborde


func _get_slots() -> Array:
	var slots := []
	for hijo in get_children():
		if hijo is Container:
			slots.append(hijo)
	return slots


func _boton_en(slot: Node) -> ESCInventoryButton:
	for c in slot.get_children():
		if c is ESCInventoryButton and not c.is_queued_for_deletion():
			return c
	return null


func get_buttons() -> Array:
	var botones := []
	for slot in _get_slots():
		var b := _boton_en(slot)
		if b:
			botones.append(b)
	return botones


func add_item(inventory_item: ESCInventoryItem) -> ESCInventoryButton:
	var button := ESCInventoryButton.new(inventory_item)
	button.inventory_item_focused.connect(_on_inventory_item_focused)
	button.inventory_item_unfocused.connect(_on_inventory_item_unfocused)
	button.ignore_texture_size = true
	button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	button.focus_mode = Control.FOCUS_NONE
	button.button_down.connect(func(): item_presionado.emit(button.global_id))

	for slot in _get_slots():
		if _boton_en(slot) == null:
			slot.add_child(button)
			return button

	escoria.logger.warn(self, "Inventario lleno: '%s' queda guardado hasta que haya lugar." % button.global_id)
	_desborde.add_child(button)
	return button


func remove_item(inventory_item: ESCInventoryItem) -> void:
	var button := get_inventory_button(inventory_item)
	if button:
		button.get_parent().remove_child(button)
		button.queue_free()
	_reacomodar()


func get_inventory_button(inventory_item: ESCInventoryItem) -> ESCInventoryButton:
	for contenedor in _get_slots() + [_desborde]:
		for c in contenedor.get_children():
			if c is ESCInventoryButton and c.global_id == inventory_item.global_id:
				return c
	return null


# Corre los ítems hacia la izquierda para que no queden huecos y mete los que
# estaban esperando en el desborde.
func _reacomodar() -> void:
	var botones := get_buttons()
	for c in _desborde.get_children():
		if c is ESCInventoryButton:
			botones.append(c)
	var slots := _get_slots()
	for i in botones.size():
		var b: ESCInventoryButton = botones[i]
		var destino: Node = slots[i] if i < slots.size() else _desborde
		if b.get_parent() != destino:
			b.get_parent().remove_child(b)
			destino.add_child(b)
