extends Area2D

@onready var sprite = $"../Visuals"

func _ready():
	connect("mouse_entered", _on_mouse_entered)
	connect("mouse_exited", _on_mouse_exited)

func _on_mouse_entered():
	var tween = create_tween()
	tween.tween_property(sprite, "scale", Vector2(1.01, 1.01), 0.2)

func _on_mouse_exited():
	var tween = create_tween()
	tween.tween_property(sprite, "scale", Vector2(1, 1), 0.2)
