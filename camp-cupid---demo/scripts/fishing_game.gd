extends Node2D

@onready var fish_spawner = $FishSpawner
@onready var score_label = $ScoreLabel
@onready var timer_label = $"TimerLabel"

var time_left := 45.0
var score := 0
var fish_scene := preload("res://scenes/fish.tscn")

var VIEWPORT_HEIGHT = Globals.SCREEN_HEIGHT
var VIEWPORT_WIDTH = Globals.SCREEN_WIDTH

var fish_list: Array = []      # Track all active fish
var water_disturbed := false   # Flag for whether player has clicked yet
var bg_sfx_player

func _ready():
	set_process(false)
	
	bg_sfx_player = AudioStreamPlayer.new()
	add_child(bg_sfx_player)
	bg_sfx_player.volume_db = +10
	bg_sfx_player.stream = preload("res://audio/water_ambience.wav")
	bg_sfx_player.play()
	
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
	if not water_disturbed:
		return
	var fish = fish_scene.instantiate()
	fish.position = Vector2(randf_range(50, VIEWPORT_WIDTH - 50), randf_range(180, VIEWPORT_HEIGHT - 50))
	fish_spawner.add_child(fish)
	fish_list.append(fish)
	
	fish.appear()
	fish.start_swimming()
	fish.caught.connect(_on_fish_caught.bind(fish))
	fade_out_fish_later(fish)
	
	# schedule next spawn
	var delay = randf_range(0.8, 7.0)
	await get_tree().create_timer(delay).timeout
	spawn_fish_loop()


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
	water_disturbed = false   # stops spawn loop
	set_process(false)
	for fish in fish_list:
		if is_instance_valid(fish):
			fish.queue_free()
	fish_list.clear()
	
	Globals.game_score = score
	Globals.minigame_flag = true
	water_disturbed = false   # stop the spawning loop
	await TransitionManager.transition_to_scene("res://scenes/main.tscn")
	queue_free()

func spawn_fish_shadows():
	for i in range(3): # a few subtle “shadow” fish roaming around
		var shadow = fish_scene.instantiate()
		shadow.position = Vector2(randf_range(50, VIEWPORT_WIDTH - 50), randf_range(180, VIEWPORT_HEIGHT - 50))
		fish_spawner.add_child(shadow)
		shadow.make_shadow()  # makes it semi-transparent and swims around subtly
