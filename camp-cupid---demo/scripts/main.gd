extends Node2D

@onready var character = %Character
@onready var dui = %DialogueUI

var dialog_index : int = 0
var dialog_lines = []

func _ready():
	var file = FileAccess.open("res://dialogue/dialogue.json", FileAccess.READ)
	if file:
		var parsed = JSON.parse_string(file.get_as_text())
		if typeof(parsed) == TYPE_DICTIONARY:
			dialog_lines = parsed["conversation"]
		
	dialog_index = -1
	process_current_line()
	
# button to advance dialogue
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
	
	dui.speaker.text = line_info["speaker"]
	dui.dialog.text = line_info["dialog"]
	character.change_character(line_info["speaker"])
	
func randomize_botton_pos() -> void:
	var viewport_size = get_viewport_rect().size
	var button_size = $UI/Button.size
	
	var new_x = randi() % int(viewport_size.x - button_size.x)
	var new_y = randi() % int((viewport_size.y -230)- button_size.y)
	
	$UI/Button.position.x = new_x
	$UI/Button.position.y = new_y
	
