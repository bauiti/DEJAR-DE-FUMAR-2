extends Sprite2D
# Muestra una imagen sobre el personaje cuando se usa :look.
# Uso: agregar como hijo de un personaje, nombre del nodo: "LookFX".
# En el Inspector: asignar solo la Texture.

@export var offset_pos: Vector2 = Vector2(0, -150)  # offset respecto al personaje
@export var escala: Vector2 = Vector2.ONE
@export var duracion: float = 3.5                   # segundos visible
@export var fade_out: float = 1.5         # segundos de desvanecido al final

var _tween: Tween


func _ready() -> void:
	top_level = true          # no hereda escala/posición del padre
	z_as_relative = false
	z_index = 4000
	visible = false


# Función que llama el script ESC.
func play_look(_args = null) -> void:
	if texture == null:
		print("LookFX: FALTA LA TEXTURA en ", get_path())
		return

	if _tween:
		_tween.kill()

	var padre := get_parent() as Node2D
	global_position = padre.global_position + offset_pos
	scale = escala
	modulate.a = 1.0
	visible = true

	_tween = create_tween()
	_tween.tween_interval(max(duracion - fade_out, 0.0))
	_tween.tween_property(self, "modulate:a", 0.0, fade_out)
	_tween.finished.connect(func(): visible = false)
