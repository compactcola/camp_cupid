extends Node2D

@onready var character = %Character
@onready var dui = %DialogueUI

var dialog_index : int = 0
var dialog_lines = []
var body_expression : String = "Default"
var head_expression : String = "Default"

var current_charater : String
var current_bg

var dialog_paused: bool = false

var sfx_player : AudioStreamPlayer

func _ready():
	$UI/Button.hide()
	
	character.character_shot.connect(relationship_gain)
	
	sfx_player = AudioStreamPlayer.new()
	add_child(sfx_player)
	
	var file = FileAccess.open("res://dialogue/dialogue.json", FileAccess.READ)
	if file:
		var parsed = JSON.parse_string(file.get_as_text())
		if typeof(parsed) == TYPE_DICTIONARY:
			dialog_lines = parsed[Globals.scenes[Globals.scene_index]] ### HERE'S WHERE I ACCESS THE SCENE INDEX!!!!!
		
	dialog_index = -1
	character.change_character("Empty", body_expression, head_expression)
	process_current_line()



### getting fancy with backgrounds
var backgrounds := {
	"bunks": preload("res://assets/backgrounds/bunks.jpg"),
	"camp_day": preload("res://assets/backgrounds/camp3.webp"),
	"camp_evening": preload("res://assets/backgrounds/camp2.jpg")
}	
func change_background(id : String) -> void:
	if id in backgrounds:
		$Background/image.texture = backgrounds[id]
		current_bg = backgrounds[id]
		
		if current_bg !=  backgrounds["bunks"]:
			var birds_ambience = load("res://audio/bird_ambience.wav")
			sfx_player.stream = birds_ambience
			sfx_player.play()
		else:
			sfx_player.stop()
			
	else:
		return



@warning_ignore("unused_parameter")
func _process(delta) -> void:
	if Input.is_action_just_pressed("Space"):
		if active_typing_timer and is_instance_valid(active_typing_timer):
			active_typing_timer.stop()
			active_typing_timer.queue_free()
			active_typing_timer = null
		process_current_line() 

func parse_line(line: String):
	var line_info = line.split(":")
	assert(len(line_info) >= 2)
	return {
		"speaker": line_info[0],
		"dialog": line_info[1]
	}

func parse_placeholders(text: String) -> String:
	var result = text
	result = result.replace("{player}", Globals.player_name)
	return result

func process_current_line():
	if dialog_index < len(dialog_lines) - 1:
		dialog_index += 1
		advance_to_next_line()

func advance_to_next_line():
	while dialog_index < len(dialog_lines):
		if dialog_paused:
			return
		var line = dialog_lines[dialog_index]
		if typeof(line) == TYPE_DICTIONARY:
			if line.has("type") and line["type"] == "CHOICE":
				show_choices(line["options"])
				return
		
		var line_info = parse_line(line)
		var speaker : String  = line_info["speaker"]
		var text : String = parse_placeholders(line_info["dialog"])
		
		# handle non-dialogue (command) lines
		if speaker in ["FACE", "BODY", "POINTS", "POP_IN", "POP_OUT", "BACKGROUND", "SCENE", "EMPTY"]:
			await process_special_line(speaker, text)
			dialog_index += 1
			continue

		# otherwise display dialogue
		process_line(speaker, text)
		return

# handles commands like FACE, BODY, SCENE, etc.
func process_special_line(speaker: String, text: String) -> void:
	match speaker:
		"FACE":
			head_expression = text
		"BODY":
			body_expression = text
		"POINTS":
			var info = text.split(",")
			if len(info) >= 2:
				relationship_gain(info[0], float(info[1]))
		"POP_IN":
			character.change_character(text, body_expression, head_expression)
			await character.pop_in()
		"POP_OUT":
			await character.pop_out()
		"BACKGROUND":
			change_background(text)
		"SCENE":
			if (text == "name_select"):
				dialog_paused = true
				run_name_selection()
				return
			elif (text == "smores_game"):
				run_smores_game()
				return
			elif (text == "end_day"):
				end_day()
				return
			elif (text == "main_screen"):
				get_tree().change_scene_to_file("res://scenes/map_screen.tscn")
				return
			else:
				get_tree().change_scene_to_file("res://scenes/%s.tscn" % text)
				Globals.scene_index += 1
				return
		"EMPTY":
			character.change_character("EMPTY", "Default", "Default")
		_:
			pass

# handles actual dialogue display
func process_line(speaker: String, text: String) -> void:
	if (speaker == "Player"):
		speaker = Globals.player_name
	else:
		character.hop()
		Globals.current_character = speaker
		
	if (speaker == "Danny"):
		dui.speaker.text = "Counselor Dan"
	else:
		dui.speaker.text = speaker
	
	dui.dialog.text = text
	dui.dialog.visible_characters = 0
	type_text(text.length())
	character.change_character(speaker, body_expression, head_expression)

##### typewriter and auto-text effect
var typing_speed_max : float = 0.03
var typing_speed_min : float = 0.025
var read_delay : float = 0.9
var active_typing_timer: Timer = null

func type_text(line_length : int) -> void:
	if active_typing_timer and is_instance_valid(active_typing_timer):
		active_typing_timer.stop()
		active_typing_timer.queue_free()
		
	var timer = Timer.new()
	timer.wait_time = 0.05
	timer.one_shot = false
	add_child(timer)
	timer.start()
	
	active_typing_timer = timer
	timer.timeout.connect(Callable(self, "_on_type_timeout").bind(timer, line_length))
	
func _on_type_timeout(timer : Timer, line_length : int) -> void:
	if not is_instance_valid(timer) or dui.dialog == null:
		return
		
	if dui.dialog.visible_characters < line_length:
		var next_char = dui.dialog.text[dui.dialog.visible_characters]
		var delay =  randf_range(typing_speed_max, typing_speed_min)
		
		if next_char in [".", ",", "!", "?", ";", ":", ")"]:
			delay += 0.2
		elif next_char == "." and dui.dialog.text.substr(dui.dialog.visible_characters, 3) == "...":
			delay += 0.4
		elif next_char == "-":
			delay = 0
		
		timer.wait_time = delay
		dui.dialog.visible_characters +=1
	else:
		timer.stop()
		timer.queue_free()
		await _continue_after_delay()

func _continue_after_delay() -> void:
	await get_tree().create_timer(read_delay).timeout
	process_current_line()
	
##### choices!
func show_choices(options : Array) -> void:
	var container = $UI/DialogueUI/ChoiceContainer
	container.visible = true
	
	for child in container.get_children():
		child.queue_free()
	
	for option in options:
		var button := Button.new()
		button.text = option["text"]
		button.action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
		button.custom_minimum_size = Vector2(600, 200)
		button.theme = load("res://resources/themes/button.tres")
		button.pressed.connect(func():
			on_choice_selected(option["next"])
			container.visible = false
		)
		container.add_child(button)

###### relationship functions!
func relationship_gain(character : String, points : float):
	var old_value = Globals.relationships[character]
	var delta = points - old_value
	Globals.add_relationship(character, points)
	$UI/RelationshipUI.show_relationship_change(old_value, points, delta)

func on_choice_selected(next_branch : String):
	var file = FileAccess.open("res://dialogue/dialogue.json", FileAccess.READ)
	if file:
		var parsed = JSON.parse_string(file.get_as_text())
		if typeof(parsed) == TYPE_DICTIONARY and parsed.has(next_branch):
			dialog_lines = parsed[next_branch]
			dialog_index = -1
	process_current_line()
	
############### name selection logic!
func run_name_selection():
	character.change_character("EMPTY", "Default", "Default")
	var name_selection = preload("res://scenes/name_selection.tscn").instantiate()
	name_selection.name_chosen.connect(name_chosen)
	var parent_ui = $UI
	dui.hide()
	parent_ui.add_child(name_selection)
	
func name_chosen(_name : String) -> void:
	dialog_paused = false
	dui.show()
	dialog_index -= 1 ###show current line hopefully
	process_current_line()

func run_smores_game():
	get_tree().change_scene_to_file("res://scenes/smores_game.tscn")

func run_fishing_game():
	character.change_character("EMPTY", "Default", "Default")
	var fishing_game = preload("res://scenes/fishing_game.tscn").instantiate()
	fishing_game.end_game.connect(end_game)
	var parent_ui = $UI
	dui.hide()
	parent_ui.add_child(fishing_game)
	
func run_birdwatching_game():
	character.change_character("EMPTY", "Default", "Default")
	var bird_game = preload("res://scenes/birdwatching_game.tscn").instantiate()
	bird_game.end_game.connect(end_game)
	var parent_ui = $UI
	dui.hide()
	parent_ui.add_child(bird_game)
	
func end_day():
	print("Ending day ", Globals.current_day)
	Globals.current_day += 1
	Globals.scene_index += 1
	load_next_day_dialogue()

func load_next_day_dialogue():
	var file = FileAccess.open("res://dialogue/dialogue.json", FileAccess.READ)
	if file:
		var parsed = JSON.parse_string(file.get_as_text())
		if typeof(parsed) == TYPE_DICTIONARY:
			var next_scene = Globals.scene_index
			if parsed.has(next_scene):
				dialog_lines = parsed[next_scene]
				dialog_index = -1
				process_current_line()
			else:
				print("No dialogue found for ", next_scene)

func end_game(score : int):
	dui.show()
	relationship_gain("Aubrey",score)
	process_current_line()
	
## useless ass button position randomizer
func randomize_botton_pos() -> void:
	var viewport_size = get_viewport_rect().size
	var button_size = $UI/Button.size
	
	var new_x = randi() % int(viewport_size.x - button_size.x)
	var new_y = randi() % int((viewport_size.y -230)- button_size.y)
	
	$UI/Button.position.x = new_x
	$UI/Button.position.y = new_y
