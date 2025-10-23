extends Control

@onready var logo = $"CampCupid-logo"
@onready var tween := create_tween()

func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _ready() -> void:
	idle_wobble()

func idle_wobble() -> void:
	# Reset tween if it’s running
	if tween and tween.is_running():
		tween.kill()
	
	# Create a repeating wobble pattern
	tween = create_tween()
	tween.set_loops()  # infinite loop

	tween.tween_property(logo, "rotation_degrees", 5, 2.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_interval(0.5)
	tween.tween_property(logo, "rotation_degrees", -7, 2.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_interval(0.5)
