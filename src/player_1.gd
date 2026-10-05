extends CharacterBody2D

var Pos : Vector2

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("click"):
		Pos = get_global_mouse_position()
		
func _physics_process(_delta: float) -> void:
	var vel = Pos - self.global_position
	velocity = vel
	move_and_slide()
		
		
