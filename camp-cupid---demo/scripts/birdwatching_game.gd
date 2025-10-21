extends Node2D

@onready var birds = $Birds.get_children()
@onready var identify_button = $Identify
@onready var score_label = $ScoreLabel
@onready var timer_label = $TimerLabel

signal end_game(score)
var target = Sprite2D.new()

var birds_left = 6
var flip_var = 1
var found_bird : Node2D = null

var time := 0.0
var amplitude := 250.0
var speed := 1.2
var time_left := 90.0
var new_button_pos := Vector2.ZERO
var moving := false
var fly_away := false
var end_state := false

var bird_names := [
	"Rosate Spoonbill",
	"Lowlands Sparrow",
	"Ornate Fireback",
	"Small Spectral Hawk",
	"Yellow Wormgulper",
	"Tall Shortbeak"
]
var names_index = 0

func _ready():
	set_process(false)
	identify_button.hide()
	identify_button.pivot_offset = identify_button.size / 2
	
	for bird in birds:
		bird.hide()

		bird.spotted.connect(on_bird_found)
		bird.shot.connect(on_bird_shot)

func _process(delta):
	if fly_away:
		found_bird.position.y -= 25
		found_bird.position.x += 20 * flip_var
	
	# end_state: killed bird falls and other birds scatter
	if end_state and is_instance_valid(found_bird):
		var sprite = found_bird.get_node_or_null("Sprite2D")
		if sprite:
			sprite.flip_v = true
		found_bird.position.y += 30 * delta * 60
		for bird in birds:
			if is_instance_valid(bird) and bird != found_bird:
				bird.show()
				bird.modulate = Color(1, 1, 1, 1)
				bird.position.y -= 25 * delta * 60
				bird.position.x += 20 * flip_var * delta * 60
	
	# moving identify button (only while moving)
	if moving:
		time += delta * speed
		var offset_x = sin(time) * amplitude
		var offset_y = cos(time * 2.0) * 60.0 * flip_var
		identify_button.position = new_button_pos + Vector2(offset_x, offset_y)

	# timer
	time_left -= delta
	if time_left <= 0:
		timer_label.text = "Time's up!"
		emit_signal("end_game", (70-(birds_left*10)))
	else:
		timer_label.text = "Time Left: %d" % ceil(time_left)

func on_bird_found(bird):
	if moving or end_state:
		return

	found_bird = bird

	for b in birds:
		if b != found_bird and is_instance_valid(b):
			b.hide()
	spawn_button()

func spawn_button():
	if not is_instance_valid(found_bird):
		return
	new_button_pos = found_bird.position + Vector2(-225, 50)
	identify_button.position = new_button_pos
	identify_button.text = bird_names[names_index]
	names_index = min(names_index + 1, bird_names.size()) # avoid overflow
	identify_button.show()
	moving = true
	set_process(true)

func on_bird_shot(bird):
	if end_state:
		return

	found_bird = bird
	end_state = true
	moving = false
	identify_button.hide()

	await get_tree().create_timer(1.5).timeout
	emit_signal("end_game", -50+(birds_left*10))
	queue_free()

func _on_identify_pressed():
	if not is_instance_valid(found_bird):
		return

	birds_left -= 1
	speed *= 1.2
	flip_var *= -1
	score_label.text = "Birds left: %d" % birds_left
	
	identify_button.hide()
	fly_away = true
	if birds.has(found_bird):
		birds.erase(found_bird)
	

	await get_tree().create_timer(0.8).timeout

	fly_away = false
	moving = false

	if is_instance_valid(found_bird):
		found_bird.hide()

	_reset_after_round()

	# if done, exit
	if birds_left <= 0:
		print("All birds found!")
		emit_signal("end_game", 75)
		get_tree().change_scene_to_file("res://scenes/main.tscn")

func _reset_after_round():
	moving = false
	fly_away = false
	end_state = false
	found_bird = null

	for b in birds:
		if is_instance_valid(b):
			b.show()
			b.modulate = Color(0,0,0, 0.35)
	identify_button.hide()

	set_process(false)

func _on_button_pressed():
	set_process(true)
	$TutorialMessage.hide()
	for bird in birds:
		bird.show()
		bird.modulate = Color(0,0,0,0.35)
