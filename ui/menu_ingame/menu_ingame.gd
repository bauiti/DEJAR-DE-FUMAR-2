extends Control
# Menú in-game (fondo: menu_inGame_fondo.png) que entra deslizándose desde la
# derecha. Lo abre el botón MENÚ o la tecla Esc (game.gd -> pause_game()).
# Reemplaza al pause_menu de Escoria: mantiene los mismos métodos que usa
# game.gd (reset, set_save_enabled, show/hide).

const DURACION := 0.45
const OSCURECER := 0.45   # cuánto se oscurece la sala detrás del menú

@onready var _panel: Control = $panel
@onready var _oscuro: ColorRect = $oscuro
@onready var _guardar: Button = $panel/guardar

var _tween: Tween
var _cerrando := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visibility_changed.connect(_on_visibility_changed)
	hide()


func _on_visibility_changed() -> void:
	if not visible:
		return
	_cerrando = false
	reset()
	_panel.position.x = size.x
	_oscuro.color.a = 0.0
	_animar(0.0, OSCURECER, Tween.EASE_OUT)


func _animar(x_destino: float, oscuridad: float, curva: Tween.EaseType) -> Tween:
	if _tween:
		_tween.kill()
	_tween = create_tween().set_parallel(true)
	_tween.set_trans(Tween.TRANS_CUBIC).set_ease(curva)
	_tween.tween_property(_panel, "position:x", x_destino, DURACION)
	_tween.tween_property(_oscuro, "color:a", oscuridad, DURACION)
	return _tween


func _cerrar() -> void:
	if _cerrando:
		return
	_cerrando = true
	reset()
	await _animar(size.x, 0.0, Tween.EASE_IN).finished
	escoria.main.current_scene.game.unpause_game()


func _unhandled_input(event: InputEvent) -> void:
	if not visible or _cerrando:
		return
	if event.is_action_pressed("ui_cancel"):
		if $save_game.visible or $options.visible:
			reset()
		else:
			_cerrar()
		get_viewport().set_input_as_handled()


func reset() -> void:
	$save_game.hide()
	$options.hide()
	_panel.show()


func set_save_enabled(p_enabled: bool) -> void:
	_guardar.disabled = not p_enabled


func _on_continuar_pressed() -> void:
	_cerrar()


func _on_guardar_pressed() -> void:
	_panel.hide()
	$save_game.refresh_savegames()
	$save_game.show()


func _on_opciones_pressed() -> void:
	_panel.hide()
	$options.show()


func _on_salir_pressed() -> void:
	escoria.quit()


func _on_submenu_back_pressed() -> void:
	reset()
