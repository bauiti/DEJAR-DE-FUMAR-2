extends Node
# Animación de "drop" para ítems de la sala: el ítem cae desde `origen`
# (desplazamiento relativo a su lugar en la escena) hasta el piso.
#
# Uso: agregar como hijo de un ESCItem con nombre "DropFX".
# La posición del ítem en la escena es donde queda en el PISO, y ahí debe estar
# su punto de interacción (dentro del área caminable). Los Marker2D
# (ESCLocation / ESCInteractionLocation) no se mueven, solo lo visual y la colisión.
#
# Desde un script ESC:
#     set_active("cigarro", true)
#     custom("cigarro", "DropFX", "dropear")      -> cae con rebote
#     custom("vape3000", "DropFX", "en_origen")   -> queda arriba (ej: en la esfera)
#     custom("vape3000", "DropFX", "en_destino")  -> queda en el piso (al re-entrar)

@export var origen: Vector2 = Vector2(0, -300)
@export var duracion: float = 0.9
@export var flotar_en_origen: bool = false   # balanceo suave mientras está en origen

var _visuales: Array = []   # pares [nodo, posición original]
var _tween: Tween


func _ready() -> void:
	for hijo in get_parent().get_children():
		if hijo == self or hijo is Marker2D:
			continue
		if hijo is Node2D:
			_visuales.append([hijo, hijo.position])


func en_origen(_args = null) -> void:
	_frenar()
	_poner(origen)
	if flotar_en_origen:
		_tween = create_tween().set_loops()
		_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		_tween.tween_method(_poner, origen, origen + Vector2(0, -12), 1.1)
		_tween.tween_method(_poner, origen + Vector2(0, -12), origen, 1.1)


func en_destino(_args = null) -> void:
	_frenar()
	_poner(Vector2.ZERO)


func dropear(_args = null) -> void:
	_frenar()
	_poner(origen)
	_tween = create_tween()
	_tween.tween_method(_paso, 0.0, 1.0, duracion)


# x avanza lineal, y cae con rebote: queda una parábola que pica en el piso.
func _paso(t: float) -> void:
	var x: float = lerp(origen.x, 0.0, t)
	var y: float = lerp(origen.y, 0.0, Tween.interpolate_value(
		0.0, 1.0, t, 1.0, Tween.TRANS_BOUNCE, Tween.EASE_OUT
	))
	_poner(Vector2(x, y))


func _poner(desplazamiento: Vector2) -> void:
	for par in _visuales:
		if is_instance_valid(par[0]):
			par[0].position = par[1] + desplazamiento


func _frenar() -> void:
	if _tween:
		_tween.kill()
		_tween = null
