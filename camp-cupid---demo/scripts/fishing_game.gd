extends Node2D

@onready var fish_spawner = $FishSpawner
@onready var score_label = $ScoreLabel
@onready var timer_label := $"TimerLabel"

var target = Sprite2D.new()

var time_left := 60.0
var score := 0
var fish

const VIEWPORT_HEIGHT = Globals.SCREEN_HEIGHT
const VIEWPORT_WIDTH = Globals.SCREEN_WIDTH

func _ready():
	 ### target stuff might need to go into globals tbh
	target.texture = load("res://assets/target.png")
	target.scale = Vector2(0.2, 0.2)
	get_tree().current_scene.add_child(target)
	
	set_process(false)
	
func _physics_process(delta: float) -> void:
	target.position = Globals.pos
	
func _process(delta: float) -> void:
	time_left -= delta
	##### end game!
	if time_left <= 0:
		timer_label.text = "Time's up!"
		print("Time's up!")
		Globals.scene_index += 1
		Globals.smores_score = score
		get_tree().change_scene_to_file("res://scenes/main.tscn")
	else:
		timer_label.text = "Time Left: %d" % ceil(time_left)

func spawn_fish_loop():
	while true:
		await get_tree().create_timer(randf_range(0.2, 4.0)).timeout
		fish = preload("res://scenes/fish.tscn").instantiate()
		fish.position = Vector2(randf_range(50, VIEWPORT_WIDTH-50), randf_range(180,VIEWPORT_HEIGHT-50))
		fish_spawner.add_child(fish)
		fish.appear()
		fish.caught.connect(_on_fish_caught)
		
func _on_fish_caught():
	score += 10
	score_label.text = "Score: %d" % score
	### death animations
	fish.queue_free()


func _on_button_pressed() -> void:
	spawn_fish_loop()
	set_process(true)
	$TutorialMessage.hide()
