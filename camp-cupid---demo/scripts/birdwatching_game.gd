extends Node2D

@onready var birds = $Birds.get_children()
@onready var identify_button = $Identify
@onready var score_label = $ScoreLabel
@onready var timer_label = $TimerLabel

var birds_left = 6
var flip_var = 1
var found_bird = null

var time := 0.0
var amplitude := 250.0   #sine wave height
var speed := 1.2         #sine wave speed
var time_left := 90.0
var new_button_pos := Vector2.ZERO
var moving := false
var fly_away := false

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
	identify_button.hide()
	identify_button.pivot_offset = identify_button.size / 2
	
	for bird in birds:
		bird.hide()
		
	set_process(false)

func _process(delta):
	if !moving:
		fly_away = false
		for bird in birds:
			bird.modulate = Color(0,0,0,0.35)
			bird.show()
			bird.spotted.connect(on_bird_found)
			
	if fly_away:
		found_bird.position.y -= 25
		found_bird.position.x += 20 * flip_var
	
	time += delta * speed

	var offset_x = sin(time) * amplitude
	identify_button.position.x = new_button_pos.x + offset_x

	var offset_y = cos(time * 2.0) * 60.0 * flip_var
	identify_button.position.y = new_button_pos.y + offset_y
	
	time_left -= delta
	##### end game!
	if time_left <= 0:
		timer_label.text = "Time's up!"
		print("Time's up!")
		Globals.scene_index += 1
		get_tree().change_scene_to_file("res://scenes/main.tscn")
	else:
		timer_label.text = "Time Left: %d" % ceil(time_left)

func on_bird_found(bird):
	if moving:
		return
		
	found_bird = bird
	for i in birds:
		if i != found_bird:
			i.hide()
	spawn_button()

func spawn_button():
	new_button_pos.x = found_bird.position.x -225
	new_button_pos.y = found_bird.position.y + 50
	identify_button.position = new_button_pos
	
	identify_button.show()
	identify_button.text = bird_names[names_index]
	names_index+=1
	
	time = 0.0
	moving = true
	set_process(true)
	

func _on_identify_pressed() -> void:
	birds_left -= 1
	speed = speed * 1.2
	flip_var *= -1
	score_label.text = "Birds left: %d" %birds_left
	
	identify_button.hide()
	fly_away = true
	
	await get_tree().create_timer(1.0).timeout
	
	moving = false
	found_bird.hide()
	birds.erase(found_bird)
	

func _on_button_pressed() -> void:
	set_process(true)
	$TutorialMessage.hide()
