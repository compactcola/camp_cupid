extends Sprite2D

var pos_x: float
var rotation_min: float
var rotation_max: float

func _ready():
	pos_x = get_viewport().get_mouse_position().x
	set_random_rotation()

func set_random_rotation():
	if pos_x < 960:
		rotation_min = -40.0
		rotation_max = -90.0
	else:
		rotation_min = -140.0
		rotation_max = -160.0

	rotation_degrees = randf_range(rotation_min, rotation_max)

func start_fade():
	set_random_rotation()

	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.8)
	tween.tween_callback(self.queue_free)
