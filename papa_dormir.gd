extends Sprite2D
# Hijo del papá en casa1 (nombre "Dormido", textura "padre dormido.png").
# Reemplaza la animación del papá por la imagen de él dormido.
# Desde ESC:
#     custom("papa_casa", "Dormido", "dormir")              -> con fundido
#     custom("papa_casa", "Dormido", "dormir_instantaneo")  -> al volver a entrar a la sala


func _ready() -> void:
	visible = false


func dormir(_args = null) -> void:
	var anim := _animacion()
	_copiar_transform(anim)
	modulate.a = 0.0
	visible = true
	var t := create_tween().set_parallel(true)
	t.tween_property(self, "modulate:a", 1.0, 0.8)
	if anim:
		t.tween_property(anim, "modulate:a", 0.0, 0.8)
		t.chain().tween_callback(_apagar_animacion.bind(anim))


func dormir_instantaneo(_args = null) -> void:
	var anim := _animacion()
	_copiar_transform(anim)
	modulate.a = 1.0
	visible = true
	if anim:
		_apagar_animacion(anim)


func _animacion() -> AnimatedSprite2D:
	# El sprite animado del papá es un hijo interno de su escena.
	for hijo in get_parent().get_children(true):
		if hijo is AnimatedSprite2D:
			return hijo
	return null


func _copiar_transform(anim: AnimatedSprite2D) -> void:
	# "padre dormido.png" tiene el mismo tamaño que los frames de la animación,
	# así que con la misma posición/escala queda en el mismo lugar.
	if anim == null:
		return
	position = anim.position
	scale = anim.scale
	offset = anim.offset
	centered = anim.centered
	flip_h = anim.flip_h


func _apagar_animacion(anim: AnimatedSprite2D) -> void:
	anim.stop()
	anim.visible = false
	anim.modulate.a = 1.0
