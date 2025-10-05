extends Sprite2D

func start_fade():
	modulate.a = 1.0
	var tween = self.create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.8)
	tween.tween_callback(self.queue_free)
