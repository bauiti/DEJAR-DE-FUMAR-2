# A simple dialog chooser that shows selectable lines of text
# Supports timeout and avatar display
extends ESCDialogOptionsChooser


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


@export var color_normal = Color(1, 1, 1, 1)
@export var color_hover = Color(1, 1, 0, 1)

var color_zona = [plaza1, escuela1, bar1, casa]

var _no_more_options: bool = false


# Hide the chooser at the start just to be safe
func _ready() -> void:
	hide_chooser()
	process_mode = PROCESS_MODE_PAUSABLE
	


# Process the timeout display
func _process(_delta: float) -> void:
	if $MarginContainer.visible and self.dialog and self.dialog.timeout > 0:
		$TimerProgress.value = (
			self.dialog.timeout - $Timer.time_left
		) / self.dialog.timeout * 100


# Show the chooser
func show_chooser():
	var vbox = $MarginContainer/MarginContainer/PanelContainer/MarginContainer/VBoxContainer
	var elContainer = $MarginContainer/PanelContainer

	for option_node in vbox.get_children():
		vbox.remove_child(option_node)

	_remove_avatar()

	var room_id = escoria.main.current_scene.global_id
	print("ROOM ACTUAL: ", room_id)
	var zona = ZONAS.get(room_id, ZONAS["default"])

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
			option_node.alignment = HORIZONTAL_ALIGNMENT_LEFT
			option_node.size_flags_horizontal = Control.SIZE_FILL
			option_node.add_theme_color_override("font_color", Color(1, 1, 1, 1))
			option_node.add_theme_color_override("font_color_hover", Color(1, 1, 0, 1))

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
	print("AVATAR CLAVE: '", zona["avatar"], "'")
	print("AVATAR RUTA: '", ruta, "'")
	if ruta != "":
		var avatar_nodo = load(ruta).instantiate()
		$AvatarContainer.add_child(avatar_nodo)
		print("AVATAR HIJOS: ", $AvatarContainer.get_child_count())
		print("AVATAR POS: ", $AvatarContainer.global_position, " VISIBLE: ", $AvatarContainer.visible)
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
	_remove_avatar()
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
	if $AvatarContainer.get_child_count() > 0:
		$AvatarContainer.remove_child($AvatarContainer.get_child(0))
