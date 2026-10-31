extends Node

func _input(event):
	if event is InputEventMouseButton and event.pressed:
		print("--- CLICK ---")
		print("pos: ", event.position)
		print("GUI hovered: ", get_viewport().gui_get_hovered_control())

func _unhandled_input(event):
	if event is InputEventMouseButton and event.pressed:
		print("llegó a unhandled (nadie lo consumió)")

func _ready():
	await get_tree().create_timer(2.0).timeout
	var bg = get_tree().root.find_child("escbackground", true, false)
	if bg:
		print("BG rect: ", bg.get_global_rect(), " filter: ", bg.mouse_filter, " visible: ", bg.is_visible_in_tree())
	else:
		print("no encontré escbackground")
