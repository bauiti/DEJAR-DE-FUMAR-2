extends Node

func _input(event):
	if event is InputEventMouseButton and event.pressed:
		print("--- CLICK ---")
		print("pos: ", event.position)
		print("GUI hovered: ", get_viewport().gui_get_hovered_control())

func _unhandled_input(event):
	if event is InputEventMouseButton and event.pressed:
		print("llegó a unhandled (nadie lo consumió)")
