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
		
		if Globals.is_alive.get(opt["Value"], true) == false:
			btn.modulate = Color(0.4,0.4,0.4,1)
			var tex_rect = btn.get_node("TextureRect")
			if tex_rect and tex_rect is TextureRect:
				var lower_name = opt["Value"].to_lower()
				tex_rect.texture = load("res://assets/characters/%s/%sHead_dead.png" % [lower_name, lower_name])
			
			continue
		btn.pressed.connect(_on_button_pressed.bind(opt["Value"]))

	$BirdGame.mouse_entered.connect(_on_hover_entered.bind($BirdGame))
	$BirdGame.mouse_exited.connect(_on_hover_exited.bind($BirdGame))
	$FishGame.mouse_entered.connect(_on_hover_entered.bind($FishGame))
	$FishGame.mouse_exited.connect(_on_hover_exited.bind($FishGame))

func _on_hover_entered(btn: Button) -> void:
	var tween = create_tween()
	tween.tween_property(btn, "scale", Vector2(1.1, 1.1), 0.15).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _on_hover_exited(btn: Button) -> void:
	var tween = create_tween()
	tween.tween_property(btn, "scale", Vector2(1, 1), 0.15).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

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
	Globals.minigame_flag = true
	await TransitionManager.transition_to_scene("res://scenes/%s" % game_choice)
