extends Node2D

var score := 0
func _on_ball_popped():
	score += 1
	$Label.text = "Apples Shot: %d" % score
