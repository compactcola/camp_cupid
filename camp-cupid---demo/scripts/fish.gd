extends Area2D

signal caught

@export var visible_time := 2.0
var is_visible := false

@onready var sprite = $Sprite2D

func appear():
	sprite.modulate.a = 0
	create_tween().tween_property(sprite, "modulate:a", 1, 0.8)

func start_swimming():
	var tween = create_tween().set_loops()  # move back and forth
	var start_x = position.x
	var end_x = position.x + randf_range(-50, 50)
	tween.tween_property(self, "position:x", end_x, randf_range(2.0, 4.0))
	tween.tween_callback(func(): sprite.flip_h = !sprite.flip_h)

func fade_out():
	if !is_inside_tree(): return
	var t = create_tween()
	t.tween_property(sprite, "modulate:a", 0, 1.0)
	await t.finished
	queue_free()

func scatter():
	var t = create_tween()
	var random_offset = Vector2(randf_range(-200, 200), randf_range(-100, 100))
	t.tween_property(self, "position", position + random_offset, 0.5)

func make_shadow():
	modulate = Color(0, 0, 0, 0.3)  # darker and translucent
	start_swimming()

func _input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed:
		is_visible = false
		emit_signal("caught")
