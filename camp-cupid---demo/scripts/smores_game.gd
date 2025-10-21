extends Node2D

var collected_items: Array = []
var score := 0
var target = Sprite2D.new()
var second_cracker : bool = false

signal game_finished(score: int)

@onready var ui_marshmallow = $Marshmallow
@onready var ui_chocolate = $Chocolate
@onready var ui_cracker_1 = $Cracker
@onready var ui_cracker_2 = $Cracker2

var time_left := 60.0
@onready var timer_label := $TimerLabel

func _ready():
	$FlyMessage.pivot_offset = $FlyMessage.size / 2
	ui_marshmallow.hide()
	ui_chocolate.hide()
	ui_cracker_1.hide()
	ui_cracker_2.hide()
	
	set_process(false)
	
func _process(delta: float) -> void:
	time_left -= delta
	##### end game!
	if time_left <= 0:
		print("Time's up!")
		Globals.smores_difficulty_index += 1
		emit_signal("game_finished", score)
		queue_free()
	else:
		timer_label.text = "Time: %d" % ceil(time_left)

func _on_ingredient_collected(ingredient_type: String):
	if ingredient_type != "fly":
		collected_items.append(ingredient_type)
	else:
		collected_items.clear()
		second_cracker = false
		
		ui_marshmallow.hide()
		ui_chocolate.hide()
		ui_cracker_1.hide()
		ui_cracker_2.hide()
		
		show_fly_message()
	
	if ingredient_type == "graham":
		if collected_items.count("graham") >= 2:
			second_cracker = true

	if (ingredient_type == "marshmallow"):
		ui_marshmallow.show()
	elif (ingredient_type == "chocolate"):
		ui_chocolate.show()
	elif (ingredient_type == "graham" and !second_cracker):
		ui_cracker_1.show()
	elif (ingredient_type == "graham" and second_cracker):
		ui_cracker_2.show()
	
	check_for_smore()

func check_for_smore():
	var required = ["graham", "chocolate", "marshmallow"]
	if !second_cracker: return
	for item in required:
		if item not in collected_items:
			return

	score += 1
	collected_items.clear()
	second_cracker = false
	
	ui_marshmallow.hide()
	ui_chocolate.hide()
	ui_cracker_1.hide()
	ui_cracker_2.hide()
	
	$ScoreLabel.text = "Smores: %d" % score
	
func show_fly_message():
	var msg = $FlyMessage
	msg.show()
	msg.modulate.a = 1.0
	msg.scale = Vector2.ONE * 0.8
	msg.pivot_offset = msg.size / 2
	
	# Kill previous tween if active
	if msg.has_meta("tween"):
		var old_tween = msg.get_meta("tween")
		if old_tween and old_tween.is_running():
			old_tween.kill()

	var tween = create_tween()
	msg.set_meta("tween", tween)
	
	# Pop in animation
	tween.tween_property(msg, "scale", Vector2.ONE * 1.2, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(msg, "scale", Vector2.ONE, 0.1).set_trans(Tween.TRANS_SINE)
	
	# Stay visible
	tween.tween_interval(1.2)  # duration you want it to remain visible
	
	# Fade + shrink (with optional float-up)
	tween.parallel().tween_property(msg, "modulate:a", 0.0, 0.8).set_trans(Tween.TRANS_SINE)
	tween.parallel().tween_property(msg, "scale", Vector2.ONE * 0.7, 0.8).set_trans(Tween.TRANS_CUBIC)
	tween.parallel().tween_property(msg, "position:y", msg.position.y - 30, 0.8)
	
	# Hide when done
	tween.tween_callback(Callable(msg, "hide"))

func _on_button_pressed() -> void:
	set_process(true)
	add_child(load("res://scenes/spawner.tscn").instantiate())
	$TutorialMessage.hide()
