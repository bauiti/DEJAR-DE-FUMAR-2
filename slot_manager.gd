extends ESCInventoryContainer

func _get_slots() -> Array:
	var slots = []
	for hijo in get_parent().get_children():
		if hijo is MarginContainer:
			slots.append(hijo)
	return slots
	
	

# 1.0 = tamaño del slot, 1.15 = 15% más grande, 1.3 = 30% más grande


# 1.0 = tamaño del slot, 2.0 = el doble, 3.0 = el triple
const ESCALA_ITEM := 3.0



func add_item(inventory_item: ESCInventoryItem) -> ESCInventoryButton:
	var button = ESCInventoryButton.new(inventory_item)
	button.inventory_item_focused.connect(_on_inventory_item_focused)
	button.inventory_item_unfocused.connect(_on_inventory_item_unfocused)

	button.ignore_texture_size = true
	button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.size_flags_vertical = Control.SIZE_SHRINK_CENTER

	for slot in _get_slots():
		if slot.get_child_count() == 0:
			# Base: tamaño del slot (o su mínimo si el layout aún no se calculó)
			var tam_slot: Vector2 = slot.size
			if tam_slot == Vector2.ZERO:
				tam_slot = slot.custom_minimum_size
			if tam_slot == Vector2.ZERO:
				tam_slot = Vector2(240, 240)  # valor de respaldo, ajustalo

			button.custom_minimum_size = tam_slot

			# Agrando visualmente desde el centro, sin deformar el layout del slot
			button.resized.connect(func(): button.pivot_offset = button.size / 2.0)
			button.scale = Vector2.ONE * ESCALA_ITEM

			slot.clip_contents = false  # que el excedente no se corte
			slot.add_child(button)

			# Aseguro el pivot centrado una vez que el botón ya tiene su tamaño
			button.pivot_offset = tam_slot / 2.0
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
