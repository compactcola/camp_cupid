extends Node2D

@onready var character = %Character
@onready var dui = %DialogueUI

var dialog_index : int = 0
var typing_speed : float = 0.02
var dialog_lines = []

func _ready():
	var file = FileAccess.open("res://dialogue/dialogue.json", FileAccess.READ)
	if file:
		var parsed = JSON.parse_string(file.get_as_text())
		if typeof(parsed) == TYPE_DICTIONARY:
			dialog_lines = parsed["conversation"]
		
	dialog_index = -1
	character.change_character("Empty")
	process_current_line()
	
## button to advance dialogue
func _on_button_pressed() -> void:
	process_current_line()
	#randomize_botton_pos()
	
func parse_line(line: String):
	var line_info = line.split(":")
	assert(len(line_info) >= 2)
	return {
		"speaker": line_info[0],
		"dialog": line_info[1]
	}
	
func process_current_line():
	if dialog_index < len(dialog_lines) -1:
		dialog_index += 1
	
	var line = dialog_lines[dialog_index]
	var line_info = parse_line(line)
	
	## add custom player name
	if (line_info["speaker"] == "Player"):
		line_info["speaker"] = Globals.player_name
	
	## change background
	if(line_info["speaker"] == "Background"):
		change_background(line_info["dialog"])
		process_current_line() ## auto advance so you don't have to click next again
		return
	 ## change scene
	if (line_info["speaker"] == "Scene"):
		get_tree().change_scene_to_file("res://scenes/ball_game.tscn")
		
	if(line_info["speaker"] == "NameSelect"):
		run_name_selection()
		character.change_character("Empty")
		return
	
	if (line_info["speaker"] == "Danny"):
		dui.speaker.text = "Counselor Dan"
	else:
		dui.speaker.text = line_info["speaker"]
	
	dui.dialog.text = line_info["dialog"]
	dui.dialog.visible_characters = 0
	type_text(line_info["dialog"].length()) ## call typewriter effect function
	character.change_character(line_info["speaker"])

func type_text(line_length : int) -> void:
	var timer = Timer.new()
	timer.wait_time = typing_speed
	timer.one_shot = false
	add_child(timer)
	timer.start()
	
	$UI/Button.hide()
	
	timer.timeout.connect(func():
		if dui.dialog.visible_characters < line_length:
			dui.dialog.visible_characters +=1
		else:
			timer.queue_free()
			randomize_botton_pos()
			$UI/Button.show()
	)

## name selection logic!
func run_name_selection():
	var name_selection = preload("res://scenes/name_selection.tscn").instantiate()
	name_selection.name_chosen.connect(name_chosen)
	var parent_ui = $UI
	dui.hide()
	$UI/Button.hide() ## probably will cause an error at some point
	parent_ui.add_child(name_selection)

func name_chosen(_name : String) -> void:
	dui.show()
	$UI/Button.show()
	process_current_line()

# getting fancy with backgrounds
var backgrounds := {
	"bunks": preload("res://assets/backgrounds/bunks.jpg"),
	"camp_day": preload("res://assets/backgrounds/camp3.webp"),
	"camp_evening": preload("res://assets/backgrounds/camp2.jpg")
}	
func change_background(id : String) -> void:
	if id in backgrounds:
		$Background/image.texture = backgrounds[id]
	else:
		return

## useless ass button position randomizer
func randomize_botton_pos() -> void:
	var viewport_size = get_viewport_rect().size
	var button_size = $UI/Button.size
	
	var new_x = randi() % int(viewport_size.x - button_size.x)
	var new_y = randi() % int((viewport_size.y -230)- button_size.y)
	
	$UI/Button.position.x = new_x
	$UI/Button.position.y = new_y
	
