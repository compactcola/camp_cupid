extends Node2D

var collected_items: Array = []
var score := 0
var target = Sprite2D.new()
var second_cracker : bool = false

@onready var ui_marshmallow = $Marshmallow
@onready var ui_chocolate = $Chocolate
@onready var ui_cracker_1 = $Cracker
@onready var ui_cracker_2 = $Cracker2

var time_left := 60.0
@onready var timer_label := $"Timer Label"

func _ready():
	ui_marshmallow.hide()
	ui_chocolate.hide()
	ui_cracker_1.hide()
	ui_cracker_2.hide()
	
	target.texture = load("res://assets/target.png")
	target.scale = Vector2(0.2, 0.2)
	get_tree().current_scene.add_child(target)
	
func _process(delta: float) -> void:
	target.position = Globals.pos
		
	time_left -= delta
	if time_left <= 0:
		print("Time's up!")
		Globals.smores_difficulty_index += 1
		get_tree().change_scene_to_file("res://scenes/main.tscn")
	else:
		timer_label.text = "Time: %d" % ceil(time_left)

func _on_ingredient_collected(ingredient_type: String):
	collected_items.append(ingredient_type)
	
	if ingredient_type == "graham":
		if collected_items.count("graham") >= 2:
			second_cracker = true

	if (ingredient_type == "marshmallow"):
		ui_marshmallow.show()
	elif (ingredient_type == "chocolate"):
		ui_chocolate.show()
	elif (ingredient_type == "graham" and !second_cracker):
		ui_cracker_1.show()
	elif (ingredient_type == "graham" and second_cracker):
		ui_cracker_2.show()
	
	check_for_smore()

func check_for_smore():
	var required = ["graham", "chocolate", "marshmallow"]
	if !second_cracker: return
	for item in required:
		if item not in collected_items:
			return

	score += 1
	collected_items.clear()
	second_cracker = false
	
	ui_marshmallow.hide()
	ui_chocolate.hide()
	ui_cracker_1.hide()
	ui_cracker_2.hide()
	
	$"Score Label".text = "Smores: %d" % score
