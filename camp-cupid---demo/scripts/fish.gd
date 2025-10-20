extends Area2D

signal caught

@export var visible_time := 2.0
var is_visible := false

func appear():
	is_visible = true
	
	## fade in animation
	var tween = create_tween()
	self.modulate.a = 0.0
	tween.tween_property(self, "modulate:a", 1.0, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	await get_tree().create_timer(visible_time).timeout
	if is_visible:
		dive()
		
func dive():
	is_visible = false
	
	var tween = create_tween()
	self.modulate.a = 1 
	tween.tween_property(self, "modulate:a", 0.0, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	await tween.finished
	queue_free()

func _input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed:
		is_visible = false
		emit_signal("caught")
