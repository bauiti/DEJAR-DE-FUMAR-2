# A simple dialog chooser that shows selectable lines of text
# Supports timeout and avatar display
extends ESCDialogOptionsChooser

@onready var _vbox: VBoxContainer = $MarginContainer/MarginContainer/PanelContainer/MarginContainer/VBoxContainer
@onready var _texto: RichTextLabel = $MarginContainer/MarginContainer/PanelContainer/MarginContainer/Texto

var fuente: Font = load("res://assets_making - pepo/FUENTES/Tahoma-4styles-Font/Tahoma Regular font.ttf")
var _audio_hover: AudioStream = preload()

const ZONAS = {
	"default": {"color": Color(0.1, 0.1, 0.1, 0.5), "avatar": ""},
	"plaza1": {"color": Color(0.0, 0.809, 0.0, 0.8), "avatar": "nenechoriPlaza"},
	"plaza2": {"color": Color(0.0, 0.809, 0.0, 0.8), "avatar": "pibesPlaza"},
	"escuela1": {"color": Color(0.959, 0.317, 0.0, 0.8), "avatar": "kiosqueraEscuela"},
	"escuela2": {"color": Color(0.959, 0.317, 0.0, 0.8), "avatar": "profeEscuela"},
	"bar1": {"color":Color(0.0, 0.0, 1.0, 0.8), "avatar": "bartenderBar"},
	"bar2": {"color":Color(0.0, 0.0, 1.0, 0.8), "avatar": "chicaBar"},
	"casa1": {"color": Color(1.0, 0.0, 1.0, 0.8), "avatar": "papaCasa"},
	"casa2": {"color":Color(1.0, 0.0, 1.0, 0.8), "avatar": "mamaCasa"},
}

var plaza1 = Color(0.0, 0.809, 0.0, 0.8) # (Color, RGB)
var escuela1 = Color(0.959, 0.317, 0.0, 0.8) # (Color, RGB)
var bar1 = Color(0.0, 0.0, 1.0, 0.8) # (Color, RGB)
var casa = Color(1.0, 0.0, 1.0, 0.8) # (Color, RGB)


var room_id = escoria.main.current_scene.global_id	
var zona = ZONAS.get(room_id, ZONAS["default"])

@export var color_normal = Color(1, 1, 1, 1)
@export var color_hover = Color(1, 1, 0, 1)

var _tween_panel: Tween

var color_zona = [plaza1, escuela1, bar1, casa]

var _terminado: bool = false

var _no_more_options: bool = false

var _ya_animado := false


# Hide the chooser at the start just to be safe
signal say_finished
signal say_visible



var _tween: Tween

var _tween_Verde = create_tween()


# Process the timeout display
func _process(_delta: float) -> void:
	if $MarginContainer.visible and self.dialog and self.dialog.timeout > 0:
		$TimerProgress.value = (
			self.dialog.timeout - $Timer.time_left
		) / self.dialog.timeout * 100


# Show the chooser
func show_chooser():
	if _tween:
		_tween.kill()
	_texto.hide()
	_vbox.show()	
	var vbox = $MarginContainer/MarginContainer/PanelContainer/MarginContainer/VBoxContainer
	var elContainer = $MarginContainer/PanelContainer
	
	if not _ya_animado:
		_ya_animado = true
		_animar_panel()

	for option_node in vbox.get_children():
		vbox.remove_child(option_node)
		
		

	

	
	print("ROOM ACTUAL: ", room_id)


	var estilo_panel = StyleBoxFlat.new()
	estilo_panel.bg_color = zona["color"]
	elContainer.add_theme_stylebox_override("panel", estilo_panel)

	for option in self.dialog.options:
		print("CHOOSER EJECUTADO")
		print("ROOM ACTUAL: '", room_id, "'")
		print("DIALOG AVATAR: '", self.dialog.avatar, "'")
		if option.is_valid():
			var option_node = Button.new()
			option_node.text = (option as ESCDialogOption).option
			option_node.flat = false
			option_node.alignment = HORIZONTAL_ALIGNMENT_CENTER
			option_node.size_flags_horizontal = Control.SIZE_FILL
			option_node.add_theme_color_override("font_color", Color(1, 1, 1, 1))
			option_node.add_theme_color_override("font_color_hover", Color(1, 1, 0, 1))
			option_node.add_theme_font_override("font", fuente)
			option_node.add_theme_font_size_override("font_size", 25)

			var box = StyleBoxFlat.new()
			box.bg_color = Color(0.1, 0.1, 0.1, 0.8)
			box.set_border_width_all(2)
			box.border_color = Color(1, 1, 1, 1)
			box.set_corner_radius_all(6)
			box.set_content_margin_all(8)

			var box_hover = box.duplicate()
			box_hover.bg_color = Color(0.25, 0.25, 0.25, 0.9)

			option_node.add_theme_stylebox_override("normal", box)
			option_node.add_theme_stylebox_override("hover", box_hover)
			option_node.add_theme_stylebox_override("pressed", box_hover)

			vbox.add_child(option_node)
			option_node.pressed.connect(_on_answer_selected.bind(option))

	if vbox.get_child_count() == 0:
		_no_more_options = true
		$Timer.start(0.05)
		return

	var ruta = escoria.avatares.get(zona["avatar"], "")
	var rutaM = escoria.avatares.get("mikeD")
	
	if ruta != "":
		var avatar_nodo = load(ruta).instantiate()
		var avatar_nodo2 = load("res://addons/escoria-dialog-simple/avatar_path/mikeD.tscn").instantiate()
		$AvatarContainer2.add_child(avatar_nodo2)
		$AvatarContainer.add_child(avatar_nodo)
		$MarginContainer.show()

	if self.dialog.timeout > 0 and self.dialog.get_timeout_option():
		$Timer.start(self.dialog.timeout)
	else:
		$TimerProgress.value = 0

# Hide the chooser
func hide_chooser():
	$MarginContainer.hide()


# An option was choosen, emit the option
#
# #### Parameters
# - option: Option that was chosen
func _option_chosen(option: ESCDialogOption):
	$TimerProgress.value = 0
	option_chosen.emit(option)


# An option was chosen directly from the list
#
# #### Parameters
# - option: Option that was chosen
func _on_answer_selected(option: ESCDialogOption):
	_option_chosen(option)


# The timeout came and a option was selected
func _on_Timer_timeout() -> void:
	var option_chosen = null if _no_more_options else self.dialog.get_timeout_option()
	_no_more_options = false
	_option_chosen(option_chosen)


# Remove the avatar
func _remove_avatar():
	for contenedor in [$AvatarContainer, $AvatarContainer2]:
		for hijo in contenedor.get_children():
			contenedor.remove_child(hijo)
			hijo.queue_free()
			
func say(_global_id: String, text: String) -> void:
	_terminado = false
	_vbox.hide()
	_texto.show()
	_texto.text = tr(text)
	_texto.visible_ratio = 0.0
	_color_texto(_global_id)


	var ms_por_letra: float = ProjectSettings.get_setting(
		SimpleDialogSettings.TEXT_TIME_PER_LETTER_MS
	)
	_animar_texto(ms_por_letra / 1000.0 * text.length())
	



func _on_texto_completo() -> void:
	if _terminado:
		return
	_terminado = true
	say_visible.emit()
	var wpm: int = ProjectSettings.get_setting(SimpleDialogSettings.READING_SPEED_IN_WPM)
	var palabras := _texto.get_parsed_text().split(" ", false).size()
	await get_tree().create_timer(palabras / float(wpm) * 60.0).timeout
	say_finished.emit()
	
func _animar_texto(duracion: float) -> void:
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(_texto, "visible_ratio", 2.0, duracion)
	_tween.finished.connect(_on_texto_completo)
	
func speedup() -> void:
	if _terminado or _texto.visible_ratio >= 1.0:
		return
	var ms_rapido: float = ProjectSettings.get_setting(
		SimpleDialogSettings.TEXT_TIME_PER_LETTER_MS_FAST
	)
	_animar_texto(ms_rapido / 1000.0 * _texto.get_total_character_count())
	
func finish() -> void:
	if _terminado:
		return
	_animar_texto(0.0)
	

	


func _animar_panel(duracion: float = 0.7) -> void:
	var panel: Control = $MarginContainer
	await get_tree().process_frame  # espera a que el layout calcule el size
	panel.pivot_offset = panel.size / 2.0
	panel.scale = Vector2(1, 1)
	panel.modulate.a = 0.0

	if _tween_panel:
		_tween_panel.kill()
	_tween_panel = create_tween().set_parallel(true)
	_tween_panel.set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN)
	_tween_panel.tween_property(panel, "scale", Vector2.ONE, duracion)
	_tween_panel.tween_property(panel, "modulate:a", 1.0, duracion)
	
func _color_texto(_global_id: String):
	
	var Texto_afuera = $MarginContainer/MarginContainer/PanelContainer/MarginContainer/Texto
	if _global_id == "mike":
		print("color: ", _global_id)
		Texto_afuera.add_theme_color_override("default_color", Color (1,1,1))
	else:
		print("color: ", _global_id)
		Texto_afuera.add_theme_color_override("default_color", zona["color"])
	
	
		
	
