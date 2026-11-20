extends ESCInventoryContainer

func _get_slots() -> Array:
	var slots = []
	for hijo in get_parent().get_children():
		if hijo is MarginContainer:
			slots.append(hijo)
	return slots

func add_item(inventory_item: ESCInventoryItem) -> ESCInventoryButton:
	var button = ESCInventoryButton.new(inventory_item)
	button.inventory_item_focused.connect(_on_inventory_item_focused)
	button.inventory_item_unfocused.connect(_on_inventory_item_unfocused)

	
	button.ignore_texture_size = true
	button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	button.custom_minimum_size = Vector2(64, 64) # ajustá al tamaño de tus slots
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.size_flags_vertical = Control.SIZE_EXPAND_FILL

	for slot in _get_slots():
		if slot.get_child_count() == 0:
			slot.add_child(button)
			return button
	escoria.logger.error(self, "Inventario lleno")
	return null

func remove_item(inventory_item: ESCInventoryItem):
	var button = get_inventory_button(inventory_item)
	if button:
		button.get_parent().remove_child(button)
		button.queue_free()

func get_inventory_button(inventory_item: ESCInventoryItem) -> ESCInventoryButton:
	for slot in _get_slots():
		for c in slot.get_children():
			if c is ESCInventoryButton and c.global_id == inventory_item.global_id:
				return c
	return null
