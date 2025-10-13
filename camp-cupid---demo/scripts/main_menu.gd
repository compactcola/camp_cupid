extends Control

var target = Sprite2D.new()

func _ready() -> void:
	target.texture = load("res://assets/target.png")
	target.scale = Vector2(0.2, 0.2)
	get_tree().current_scene.add_child(target)
	
func _process(delta: float) -> void:
	target.position = Globals.pos

func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main.tscn")
