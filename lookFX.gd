extends Sprite2D
# Banner en pantalla (ej: "Esto es una demo") que se dispara desde un script ESC:
#     custom("<global_id del personaje>", "LookFX", "play_look")
# Uso: agregar como hijo de un personaje, con nombre "LookFX", y asignar la Texture.
# La imagen se ajusta al tamaño de la pantalla (sin deformarse), centrada,
# sin importar dónde esté parado el personaje ni la cámara.

@export var duracion: float = 3.5          # segundos totales en pantalla
@export var fade_in: float = 0.25          # segundos de aparición
@export var fade_out: float = 1.0          # segundos de desvanecido al final
@export_range(0.1, 1.0) var ocupar_pantalla: float = 0.95  # porción de la pantalla

# Ya no se usan (antes el banner se dibujaba sobre el personaje). Se dejan para
# que las escenas que los tenían seteados sigan cargando sin avisos.
@export var offset_pos: Vector2 = Vector2(0, -150)
@export var escala: Vector2 = Vector2.ONE

var _capa: CanvasLayer
var _imagen: TextureRect
var _tween: Tween


func _ready() -> void:
	# El sprite del mundo nunca se dibuja: el banner va en una capa de pantalla.
	visible = false
	tree_exiting.connect(_liberar_capa)


# Función que llama el script ESC.
func play_look(_args = null) -> void:
	if texture == null:
		push_warning("LookFX: falta la textura en %s" % get_path())
		return

	_crear_capa()

	var pantalla: Vector2 = get_viewport().get_visible_rect().size
	var tam: Vector2 = pantalla * ocupar_pantalla
	_imagen.texture = texture
	_imagen.size = tam
	_imagen.position = (pantalla - tam) / 2.0
	_imagen.modulate.a = 0.0
	_capa.visible = true

	if _tween:
		_tween.kill()
	_tween = _imagen.create_tween()
	_tween.tween_property(_imagen, "modulate:a", 1.0, fade_in)
	_tween.tween_interval(max(duracion - fade_in - fade_out, 0.0))
	_tween.tween_property(_imagen, "modulate:a", 0.0, fade_out)
	_tween.finished.connect(func(): _capa.visible = false)


func _crear_capa() -> void:
	if is_instance_valid(_capa):
		return
	_capa = CanvasLayer.new()
	_capa.layer = 50
	_imagen = TextureRect.new()
	_imagen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_imagen.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_imagen.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_capa.add_child(_imagen)
	# Se cuelga de la raíz para no heredar la visibilidad/posición del personaje;
	# se libera cuando el personaje sale de la escena (cambio de sala).
	get_tree().root.add_child(_capa)


func _liberar_capa() -> void:
	if is_instance_valid(_capa):
		_capa.queue_free()
