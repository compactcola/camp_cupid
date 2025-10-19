extends Control

@onready var bar = $RelationshipBar
@onready var hearts = $Hearts.get_children()
@onready var tween : Tween
@onready var heart_full = load("res://assets/sprites/heart-full.png")
@onready var heart_empty = load("res://assets/sprites/heart-empty.png")

var visible_time := 1.6
var bar_speed := 1
var decreasing = false
var heart_thresholds = [33, 67, 100]
var triggered = []

func show_relationship_change(old_value : float, new_value: float, delta: float):
	visible = true
	modulate.a = 1.0
	
	decreasing = new_value < old_value
	 
	if tween:
		tween.kill()
	
	tween = create_tween()
	bar.value = old_value
	tween.tween_property(bar, "value", new_value, bar_speed).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	set_process(true)
	
	tween.parallel().tween_property(self, "scale", Vector2(1.1, 1.1), 0.1).set_trans(Tween.TRANS_SINE)
	tween.tween_property(self, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_SINE)
	
	# Optional: animate label pulse
	tween.tween_interval(visible_time)
	tween.tween_property(self, "modulate:a", 0.0, 0.4)
	tween.tween_callback(Callable(self, "_on_hide"))

func _process(delta: float) -> void:
	if !tween:
		return
	
	for i in range(heart_thresholds.size()):
		var threshold = heart_thresholds[i]
		
		if bar.value >= threshold and !triggered.has(i):
			triggered.append(i)
			bar_speed = bar_speed*1.2
			spawn_heart(i, decreasing)
		elif bar.value < threshold and triggered.has(i):
			triggered.erase(i)
			bar_speed = bar_speed*0.9
			spawn_heart(i, decreasing)
			
	if !tween.is_running():
		set_process(false)
		
func spawn_heart(i : int, decreasing : bool):
	if i >= hearts.size():
		return
	
	var heart = hearts[i]
	heart.texture = heart_full if !decreasing else heart_empty
	heart.z_index = 16 if !decreasing else 14
	var heart_size = heart.scale
	
	var pop = create_tween()
	pop.tween_property(heart, "scale", heart_size*1.1, 0.1)
	pop.tween_property(heart, "scale", heart_size, 0.1)

func _on_hide():
	visible = false
