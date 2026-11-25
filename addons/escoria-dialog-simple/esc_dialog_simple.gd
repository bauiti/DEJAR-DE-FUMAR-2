## A simple dialog manager for Escoria
extends ESCDialogManager


## State machine that governs how the dialog manager behaves
var state_machine = preload("res://addons/escoria-dialog-simple/esc_dialog_simple_state_machine.gd").new()

# The currently running player
var _type_player: Node = null







var _preserved_type_player_type: String = ""

# Reference to the dialog player
var _dialog_player: Node = null

# Basic state tracking
var _is_saying: bool = false

# Whether to preserve the next dialog box used by `say`, or, if already
# preserving a dialog box, whether to continue using that dialog box
var _should_preserve_dialog_box: bool = false

func _on_chooser_say_finished() -> void:
	_programar_cierre()
	_on_say_finished()


func _programar_cierre() -> void:
	var dp := _dialog_player
	if not is_instance_valid(dp) or not dp.is_inside_tree():
		return
	var token := _leer_token()
	await dp.get_tree().create_timer(GRACIA_CIERRE).timeout

	if not is_instance_valid(dp):
		return
	if token != _leer_token():
		return

	_cerrar_chooser()


func _cerrar_chooser() -> void:
	print("CERRANDO chooser")
	var nodo := _get_chooser_activo()
	if is_instance_valid(_dialog_player) and _dialog_player.has_meta("chooser_activo"):
		_dialog_player.remove_meta("chooser_activo")
	if nodo:
		if nodo.get_parent():
			nodo.get_parent().remove_child(nodo)
		nodo.queue_free()
	_chooser = null

func _ready() -> void:
	add_child(state_machine)


# Check whether a specific type is supported by the
# dialog plugin
#
# #### Parameters
# - type: required type
# **Returns** Whether the type is supported or not
func has_type(type: String) -> bool:
	return true if type in ["floating", "avatar"] else false


# Check whether a specific chooser type is supported by the
# dialog plugin
#
# #### Parameters
# - type: required chooser type
# **Returns** Whether the type is supported or not
func has_chooser_type(type: String) -> bool:
	return true if type == "simple" else false


# Instructs the dialog manager to preserve the next dialog box used by a `say`
# command until a call to `disable_preserve_dialog_box` is made.
#
# This method should be idempotent, i.e. if called after the first time and
# prior to `disable_preserve_dialog_box` being called, the result should be the
# same.
func enable_preserve_dialog_box() -> void:
	_should_preserve_dialog_box = true


# Instructs the dialog manager to no longer preserve the currently-preserved
# dialog box or to not preserve the next dialog box used by a `say` command
# (this is the default state).
#
# This method should be idempotent, i.e. if called after the first time and
# prior to `enable_preserve_dialog_box` being called, the result should be the
# same.
func disable_preserve_dialog_box() -> void:
	_should_preserve_dialog_box = false

	if is_instance_valid(_dialog_player) and _dialog_player.get_children().has(_type_player):
		_dialog_player.remove_child(_type_player)
		_preserved_type_player_type = ""


# Output a text said by the item specified by the global id. Emit
# `say_finished` after finishing displaying the text.
#
# #### Parameters
# - dialog_player: Node of the dialog player in the UI
# - global_id: Global id of the item that is speaking
# - text: Text to say, optional prefixed by a translation key separated
#   by a ":"
# - type: Type of dialog box to use
# - *key*: Translation key
func say(dialog_player: Node, global_id: String, text: String, type: String, key: String):
	_dialog_player = dialog_player

	_initialize_say_states(global_id, text, type, key)

	if _should_preserve_dialog_box:
		# If the dialog box type doesn't match what's currently being reused (if anything),
		# we want to remove the old one (if it exists) and then initialize and add the new dialog
		# box type to the dialog player
		if type != _preserved_type_player_type:
			if is_instance_valid(_type_player) and _dialog_player.get_children().has(_type_player):
				_dialog_player.remove_child(_type_player)

			_init_type_player(type)

		_preserved_type_player_type = type
	else:
		_init_type_player(type)

	state_machine._change_state("say")


func do_say(global_id: String, text: String) -> void:
	var chooser := _get_chooser_activo()

	if chooser:
		_invalidar_cierre()

		if not chooser.say_finished.is_connected(_on_chooser_say_finished):
			chooser.say_finished.connect(_on_chooser_say_finished)
			chooser.say_visible.connect(_on_say_visible)

		chooser.say(global_id, text)
		return

	# Comportamiento de siempre: la Window de avatar.gd
	if not _dialog_player.get_children().has(_type_player):
		_dialog_player.add_child(_type_player)

	_type_player.say(global_id, text)


func _init_type_player(type: String) -> void:
	if type == "floating":
		_type_player = preload(\
			"res://addons/escoria-dialog-simple/types/floating.tscn"\
		).instantiate()
	else:
		_type_player = preload(\
			"res://addons/escoria-dialog-simple/types/avatar.tscn"\
		).instantiate()

	_type_player.say_finished.connect(_on_say_finished)
	_type_player.say_visible.connect(_on_say_visible)


func _initialize_say_states(global_id: String, text: String, type: String, key: String) -> void:
	state_machine.states_map["say"].initialize(self, global_id, text, type, key)
	state_machine.states_map["finish"].initialize(_dialog_player)
	state_machine.states_map["say_fast"].initialize(self)
	state_machine.states_map["say_finish"].initialize(self)
	state_machine.states_map["visible"].initialize(self)
	state_machine.states_map["interrupt"].initialize(self)


func _on_say_finished():
	if not _should_preserve_dialog_box and _dialog_player.get_children().has(_type_player):
		_dialog_player.remove_child(_type_player)

	_is_saying = false

	say_finished.emit()


func _on_say_visible():
	say_visible.emit()


# Present an option chooser to the player and sends the signal
# `option_chosen` with the chosen dialog option
#
# #### Parameters
# - dialog_player: Node of the dialog player in the UI
# - dialog: Information about the dialog to display
# - type: The dialog chooser type to use
func choose(dialog_player: Node, dialog: ESCDialog, type: String):
	_dialog_player = dialog_player

	state_machine.states_map["choices"].initialize(dialog_player, self, dialog, type)
	state_machine._change_state("choices")


func do_choose(dialog_player: Node, dialog: ESCDialog, type: String = "simple"):
	_dialog_player = dialog_player
	_invalidar_cierre()

	_chooser = _get_chooser_activo()  # reutiliza el de la vuelta anterior
	if not _chooser:
		_chooser = preload(\
			"res://addons/escoria-dialog-simple/chooser/simple.tscn"\
		).instantiate()
		dialog_player.add_child(_chooser)
		dialog_player.set_meta("chooser_activo", _chooser)

	_chooser.set_dialog(dialog)
	_chooser.show_chooser()

	var option = await _chooser.option_chosen

	_programar_cierre()
	option_chosen.emit(option)




# Trigger running the dialogue faster
func speedup():
	var chooser := _get_chooser_activo()
	if chooser:
		chooser.speedup()
		return
	if is_instance_valid(_type_player):
		_type_player.speedup()




# Trigger an instant finish of the current dialog
func finish():
	var chooser := _get_chooser_activo()
	if chooser:
		chooser.finish()
		return
	if is_instance_valid(_type_player):
		_type_player.finish()


# The say command has been interrupted, cancel the dialog display
func interrupt():
	if _dialog_player.get_children().has(_type_player):
		(
			escoria.object_manager.get_object(escoria.object_manager.SPEECH).node\
			 as ESCSpeechPlayer
		).set_state("off")

		if not _should_preserve_dialog_box and _dialog_player.get_children().has(_type_player):
			_dialog_player.remove_child(_type_player)

		say_finished.emit()


# To be called if voice audio has finished.
func voice_audio_finished():
	if is_instance_valid(_type_player):
		_type_player.voice_audio_finished()
		
func _leer_token() -> int:
	if is_instance_valid(_dialog_player) and _dialog_player.has_meta("token_cierre"):
		return _dialog_player.get_meta("token_cierre")
	return 0
		
func _invalidar_cierre() -> void:
	if is_instance_valid(_dialog_player):
		_dialog_player.set_meta("token_cierre", _leer_token() + 1)
		
func _get_chooser_activo() -> Node:
	if is_instance_valid(_dialog_player) and _dialog_player.has_meta("chooser_activo"):
		var nodo = _dialog_player.get_meta("chooser_activo")
		if is_instance_valid(nodo):
			return nodo
	return null


	
