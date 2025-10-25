extends Node2D

@onready var fish_spawner = $FishSpawner
@onready var score_label = $ScoreLabel
@onready var timer_label = $"TimerLabel"

var time_left := 45.0
var score := 0
var fish_scene := preload("res://scenes/fish.tscn")

const VIEWPORT_HEIGHT = Globals.SCREEN_HEIGHT
const VIEWPORT_WIDTH = Globals.SCREEN_WIDTH

var fish_list: Array = []      # Track all active fish
var water_disturbed := false   # Flag for whether player has clicked yet

func _ready():
	set_process(false)
	
	# Create idle shadows moving around even before water is disturbed
	spawn_fish_shadows()

func _input(event):
	if event is InputEventMouseButton and event.pressed:
		if not water_disturbed:
			water_disturbed = true
			spawn_fish_loop()   # Start spawning real fish
		else:
			water_disturbed = true

func _process(delta: float) -> void:
	time_left -= delta
	if time_left <= 0:
		timer_label.text = "Time's up!"
		end_game()
	else:
		timer_label.text = "Time Left: %d" % ceil(time_left)

func spawn_fish_loop():
	while water_disturbed:
		await get_tree().create_timer(randf_range(0.8, 3.0)).timeout
		var fish = fish_scene.instantiate()
		fish.position = Vector2(randf_range(50, VIEWPORT_WIDTH - 50), randf_range(180, VIEWPORT_HEIGHT - 50))
		fish_spawner.add_child(fish)
		fish_list.append(fish)

		# Custom fade-in & swim behavior (implemented in fish script)
		fish.appear()
		fish.start_swimming()

		# Connect signals
		fish.caught.connect(_on_fish_caught.bind(fish))

		fade_out_fish_later(fish)

func fade_out_fish_later(fish):
	await get_tree().create_timer(randf_range(2.0, 4.0)).timeout
	if is_instance_valid(fish):
		fish.fade_out()
		fish_list.erase(fish)

func _on_fish_caught(caught_fish):
	score += 5
	score_label.text = "Score: %d" % score

	for f in fish_list:
		if f != caught_fish and is_instance_valid(f):
			f.scatter()

	caught_fish.queue_free()
	fish_list.erase(caught_fish)

func _on_button_pressed() -> void:
	set_process(true)
	$TutorialMessage.hide()
	water_disturbed = false  # reset until first click

func end_game():
	Globals.game_score = score
	Globals.minigame_flag = true
	await TransitionManager.transition_to_scene("res://scenes/main.tscn")
	#get_tree().change_scene_to_file("res://scenes/main.tscn")

func spawn_fish_shadows():
	for i in range(3): # a few subtle “shadow” fish roaming around
		var shadow = fish_scene.instantiate()
		shadow.position = Vector2(randf_range(50, VIEWPORT_WIDTH - 50), randf_range(180, VIEWPORT_HEIGHT - 50))
		fish_spawner.add_child(shadow)
		shadow.make_shadow()  # makes it semi-transparent and swims around subtly
