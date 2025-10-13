extends Node2D

var score := 0

var target = Sprite2D.new()

func _on_ball_popped():
	score += 1
	$Label.text = "Apples Shot: %d" % score

func _ready():
	target.texture = load("res://assets/target.png")
	target.scale = Vector2(0.2, 0.2)
	get_tree().current_scene.add_child(target)

func _process(delta: float) -> void:
	target.position = Globals.pos
