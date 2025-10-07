extends RigidBody2D

signal popped

func _ready():
	var x_impulse = randf_range(-200,200)
	var y_impulse = -randf_range(400, 600)
	apply_impulse(Vector2(x_impulse, y_impulse))

func _input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed:
		emit_signal("popped")
		print("it got hit")
		queue_free()
