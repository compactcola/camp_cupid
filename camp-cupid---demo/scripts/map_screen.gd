extends Control

@onready var character_choice_container = $CharacterChoice
var buttons =[]
var game_choice : String
var character_choice : String

var options = [
	{"Text": "Aubrey              ", "Value": "Aubrey"},
	{"Text": "Ethan              ", "Value": "Ethan"},
	{"Text": "Harper               ", "Value": "Harper"}
]

func _ready():
	character_choice_container.hide()
	
	for i in $CharacterChoice.get_children():
		if i is Button:
			buttons.append(i)
	
	for i in range(buttons.size()):
		var btn = buttons[i]
		var opt = options[i]
		
		btn.text = opt["Text"]
		
		if Globals.is_alive.get(opt["Value"], true) == false: ### speaker is dead
			btn.modulate = Color(0.4,0.4,0.4,1)
			continue
		btn.pressed.connect(_on_button_pressed.bind(opt["Value"]))

func _on_button_pressed(value):
	character_choice = value
	finalize_choice(game_choice, character_choice)

func _on_bird_game_pressed() -> void:
	game_choice = "birdwatching_game.tscn"
	character_choice_container.show()
	$BirdGame.hide()
	$FishGame.hide()
	
func _on_fish_game_pressed() -> void:
	game_choice = "fishing_game.tscn"
	character_choice_container.show()
	$BirdGame.hide()
	$FishGame.hide()
	
func finalize_choice(game_choice, character_choice):
	Globals.current_character = character_choice
	Globals.current_game = game_choice
	
	Globals.scene_index += 1
	await TransitionManager.transition_to_scene("res://scenes/%s" % game_choice)
	#get_tree().change_scene_to_file("res://scenes/%s" % game_choice)
	#### advance scene index?
