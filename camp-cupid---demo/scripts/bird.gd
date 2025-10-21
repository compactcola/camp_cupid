extends Area2D

signal spotted(bird)
signal shot(bird)

func _on_mouse_entered() -> void:
	emit_signal("spotted", self)
	self.modulate = Color(1,1,1,1)
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(2.0,2.0), 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2(1.8,1.8), 0.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	

func _on_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed:
		emit_signal("shot", self)
