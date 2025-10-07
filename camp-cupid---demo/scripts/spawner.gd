extends Node2D

var ball_scene = preload("res://scenes/ball.tscn")

const SCREEN_WIDTH = 1920
const SCREEN_HEIGHT = 1080

@export var spawn_interval := 1.5

func _ready():
	_spawn_ball()
	spawn_timer()

func spawn_timer():
	await get_tree().create_timer(spawn_interval).timeout
	_spawn_ball()
	spawn_timer()
	
func _spawn_ball():
	var ball = ball_scene.instantiate()
	add_child(ball)

	ball.position = Vector2(randf_range(50, SCREEN_WIDTH - 50), SCREEN_HEIGHT - 50)

	var x_impulse = randf_range(-500, 500) 
	var y_impulse = -randf_range(600, 900)  
	ball.apply_impulse(Vector2(x_impulse, y_impulse))
	
	ball.popped.connect(get_parent()._on_ball_popped)
