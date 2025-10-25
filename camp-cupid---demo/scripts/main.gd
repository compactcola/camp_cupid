extends Node2D

@onready var character = %Character
@onready var dui = %DialogueUI

var dialog_index : int = 0
var dialog_lines = []

var flavor_lines = {
	"Aubrey": ["Ow! Watch it!", "Hey! That hurt!", "Careful!"],
	"Ethan": ["Hey! what the hell?", "Ow! Watch it!", "Jeez, watch it!"],
	"Harper": ["Yeesh!", "Ow, rude!", "Could you not?"],
	"Danny": ["Good luck- I'm immortal!", "Your pathetic arrows do nothing!", "Barely even a scratch!", "Nice try."]
}

var body_expression : String = "Default"
var head_expression : String = "Default"

var current_charater : String
var current_bg

var dialog_paused: bool = false
var sfx_player : AudioStreamPlayer
var bg_sfx_player : AudioStreamPlayer
@onready var type_sound = preload("res://audio/text_blip.wav")

# typewriter
var typing_speed_max : float = 0.03
var typing_speed_min : float = 0.025
var normal_read_delay : float = 0.9
var flavor_read_delay : float = 2.0

var active_typing_timer: Timer = null

var sfx_levels = {
	"Aubrey":1.2,
	"Ethan":0.8,
	"Harper":1.1,
	"Danny":0.7
}

var interrupting_flavor_line : String = ""
var interrupting_speaker : String = ""
var is_interrupting_dialog : bool = false
var reveal_timer: Timer = null

func _ready():
	$UI/Button.hide()
	
	if Globals.minigame_flag == true: ### post-minigame relationship handler (maybe call function isntead?)
		print("works")
		relationship_gain(Globals.current_character, Globals.game_score)
		Globals.minigame_flag = false
	
	character.character_shot.connect(relationship_gain)
	character.interrupt_dialog.connect(on_character_interrupt_dialogue)
	#character.resume_dialog.connect(on_character_resume_dialogue)
	
	sfx_player = AudioStreamPlayer.new()
	bg_sfx_player = AudioStreamPlayer.new()
	add_child(sfx_player)
	add_child(bg_sfx_player)
	sfx_player.volume_db = -15
	bg_sfx_player.volume_db = 20
	
	var file = FileAccess.open("res://dialogue/dialogue.json", FileAccess.READ)
	if file:
		var parsed = JSON.parse_string(file.get_as_text())
		if typeof(parsed) == TYPE_DICTIONARY:
			if Globals.scene_index >= Globals.scenes.size():
				Globals.scene_index = Globals.scenes.size() - 1
			if parsed.has(Globals.scenes[Globals.scene_index]):
				dialog_lines = parsed[Globals.scenes[Globals.scene_index]]
			else:
				dialog_lines = []
	else:
		dialog_lines = []

	# reset safely
	dialog_index = -1
	dialog_paused = false
	is_interrupting_dialog = false
	character.change_character("Empty", body_expression, head_expression)

	if not dialog_lines.is_empty():
		process_current_line()
	else:
		print("No dialogue found for scene index ", Globals.scene_index)


### backgrounds
var backgrounds := {
	"bunks": preload("res://assets/backgrounds/bunks.png"),
	"camp_day": preload("res://assets/backgrounds/camp_outside.png"),
	"camp_evening": preload("res://assets/backgrounds/camp_outside-night.png")
}	
func change_background(id : String) -> void:
	if id in backgrounds:
		$Background/image.texture = backgrounds[id]
		current_bg = backgrounds[id]
		
		if current_bg !=  backgrounds["bunks"]:
			var birds_ambience = load("res://audio/bird_ambience.wav")
			bg_sfx_player.stream = birds_ambience
			bg_sfx_player.play()
		else:
			bg_sfx_player.stop()
	else:
		return

@warning_ignore("unused_parameter")
func _process(delta) -> void:
	if Input.is_action_just_pressed("Space") and not dialog_paused:
		_skip_dialog()


func _skip_dialog() -> void:
	if not dui.dialog or not dui.dialog.text:
		return

	if active_typing_timer and is_instance_valid(active_typing_timer):
		# stop the typewriter
		active_typing_timer.stop()
		active_typing_timer.queue_free()
		active_typing_timer = null

		# reveal the full text
		dui.dialog.visible_characters = dui.dialog.text.length()

		# cancel any previously scheduled reveal timer
		if reveal_timer and is_instance_valid(reveal_timer):
			reveal_timer.stop()
			reveal_timer.queue_free()
			reveal_timer = null

		reveal_timer = Timer.new()
		reveal_timer.one_shot = true
		reveal_timer.wait_time = normal_read_delay
		add_child(reveal_timer)
		reveal_timer.start()
		reveal_timer.timeout.connect(Callable(self, "_on_reveal_timeout"))

	else:
		if reveal_timer and is_instance_valid(reveal_timer):
			reveal_timer.stop()
			reveal_timer.queue_free()
			reveal_timer = null
		process_current_line()

func _on_reveal_timeout() -> void:
	if reveal_timer and is_instance_valid(reveal_timer):
		reveal_timer.queue_free()
		reveal_timer = null
	process_current_line()

func parse_line(line: String):
	var line_info = line.split(":")
	assert(len(line_info) >= 2)
	return {"speaker": line_info[0], "dialog": line_info[1]}

func parse_placeholders(text: String) -> String:
	return text.replace("{player}", Globals.player_name)

func process_current_line():
	if not Globals.is_dialogue_active:
		return
		
	if dialog_lines.is_empty():
		print("Warning: No dialog lines loaded.")
		return

	# Ensure index never exceeds bounds
	if dialog_index >= dialog_lines.size() - 1:
		print("End of dialogue reached safely.")
		dialog_index = dialog_lines.size() - 1
		return

	# Increment safely
	dialog_index += 1

	# Guard against async overlap
	if dialog_index < 0 or dialog_index >= dialog_lines.size():
		print("Index out of range — aborting advance")
		return

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
		
		if speaker in ["FACE", "BODY", "POINTS", "POP_IN", "POP_OUT", "BACKGROUND", "SCENE", "EMPTY"]:
			await process_special_line(speaker, text)
			dialog_index += 1
			continue
		if Globals.is_alive.get(speaker, true) == false: ### speaker is dead
			text = "..."

		current_charater = speaker
		process_line(speaker, text)
		return

# commands
func process_special_line(speaker: String, text: String) -> void:
	match speaker:
		"FACE":
			head_expression = text
		"BODY":
			body_expression = text
		"POINTS":
			var info = text.split(",")
			if len(info) >= 2:
				if Globals.is_alive.get(info[0], true) == false: ### speaker is dead
					return
				relationship_gain(info[0], float(info[1]))
		"POP_IN":
			character.change_character(text, body_expression, head_expression)
			await character.pop_in()
		"POP_OUT":
			await character.pop_out()
		"BACKGROUND":
			change_background(text)
		"SCENE":
			if text == "name_select":
				dialog_paused = true
				run_name_selection()
				return
			elif text == "smores_game":
				run_smores_game()
				return
			elif text == "end_day":
				end_day()
				return
			elif text == "map_screen":
				await TransitionManager.transition_to_scene("res://scenes/map_screen.tscn")
				#get_tree().change_scene_to_file("res://scenes/map_screen.tscn")
				return
			else:
				get_tree().change_scene_to_file("res://scenes/%s.tscn" % text)
				Globals.scene_index += 1
				return
		"EMPTY":
			character.change_character("EMPTY", "Default", "Default")
		_:
			pass

# dialogue
func process_line(speaker: String, text: String) -> void:
	if speaker == "Player":
		speaker = Globals.player_name
	else:
		character.hop()
		Globals.current_character = speaker
		
	dui.speaker.text = "Counselor Dan" if speaker == "Danny" else speaker
	dui.dialog.text = text
	dui.dialog.visible_characters = 0

	# regular typewriter call with optional completion callback
	type_text(text.length())
	character.change_character(speaker, body_expression, head_expression)

####  typewriter effect stuff!
var pitch = 1.0
func type_text(line_length: int, custom_read_delay: float = -1) -> void:
	if reveal_timer and is_instance_valid(reveal_timer):
		reveal_timer.stop()
		reveal_timer.queue_free()
		reveal_timer = null

	if active_typing_timer and is_instance_valid(active_typing_timer):
		active_typing_timer.stop()
		active_typing_timer.queue_free()

	var timer = Timer.new()
	timer.wait_time = 0.05
	timer.one_shot = false
	add_child(timer)
	timer.start()
	
	pitch = 1.0
	if current_charater in sfx_levels:
		pitch = sfx_levels[current_charater]

	active_typing_timer = timer
	timer.timeout.connect(Callable(self, "_on_type_timeout").bind(timer, line_length, custom_read_delay))

func _on_type_timeout(timer: Timer, line_length: int, custom_read_delay: float) -> void:
	if not is_instance_valid(timer) or dui.dialog == null:
		return

	if dui.dialog.visible_characters < line_length:
		var next_char = dui.dialog.text[dui.dialog.visible_characters]
		
		var delay = randf_range(typing_speed_min, typing_speed_max)
		if next_char in [".", ",", "!", "?", ";", ":", ")"]:
			delay += 0.2
		elif next_char == "." and dui.dialog.text.substr(dui.dialog.visible_characters, 3) == "...":
			delay += 0.4
		elif next_char == "-":
			delay = 0
		timer.wait_time = delay
		
		### very bad text sound effect (it's delayed sometimes?)
		if next_char != " " and next_char != "\n": 
			sfx_player.pitch_scale = randf_range(1.7, 1.9) * pitch
			sfx_player.stream = type_sound
			sfx_player.play()
			
		dui.dialog.visible_characters += 1
	else:
		timer.stop()
		timer.queue_free()
		await _continue_after_delay(custom_read_delay)

func _continue_after_delay(custom_read_delay: float = -1) -> void:
	var delay = custom_read_delay if custom_read_delay > 0 else normal_read_delay
	await get_tree().create_timer(delay).timeout

	# If a reveal timer exists for some reason, clear it to avoid duplicate calls
	if reveal_timer and is_instance_valid(reveal_timer):
		reveal_timer.stop()
		reveal_timer.queue_free()
		reveal_timer = null

	if custom_read_delay > 0 and is_interrupting_dialog:
		is_interrupting_dialog = false
		dialog_paused = false

		var bridge_line = "Anyways..."
		if Globals.is_alive.get(current_charater, true) == false: ### speaker is dead
			bridge_line = "..."
			
		dui.speaker.text = interrupting_speaker
		dui.dialog.text = bridge_line
		dui.dialog.visible_characters = 0

		# Type this short line with normal speed and delay
		type_text(bridge_line.length(), normal_read_delay)
		return  # prevent jumping ahead too early

	if custom_read_delay > 0 and is_interrupting_dialog:
		is_interrupting_dialog = false
		dialog_paused = false

	if dialog_index < dialog_lines.size() - 1:
		process_current_line()
	else:
		print("End of dialogue reached — halting further progression.")

##### choices
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

func on_choice_selected(next_branch : String):
	var file = FileAccess.open("res://dialogue/dialogue.json", FileAccess.READ)
	if file:
		var parsed = JSON.parse_string(file.get_as_text())
		if typeof(parsed) == TYPE_DICTIONARY and parsed.has(next_branch):
			dialog_lines = parsed[next_branch]
			dialog_index = -1
	process_current_line()

###### relationship functions
func relationship_gain(_character : String, points : float):
	if _character == "Danny" or _character == "EMPTY":
		return
	var old_value = Globals.relationships[_character]
	var new_value = clamp(points, 0, 100)  # ensure points is within 0–100
	Globals.add_relationship(_character, new_value)
	$UI/RelationshipUI.show_relationship_change(old_value, new_value)

# handling interruptions (NOT FLEXIBLE RIGHT NOW)
func on_character_interrupt_dialogue(char_name: String) -> void:
	if flavor_lines.has(char_name) and not is_interrupting_dialog:
		is_interrupting_dialog = true
		dialog_paused = true

		# Stop current typing
		if active_typing_timer and is_instance_valid(active_typing_timer):
			active_typing_timer.stop()
			active_typing_timer.queue_free()
			active_typing_timer = null

		interrupting_speaker = char_name
		interrupting_flavor_line = flavor_lines[char_name].pick_random()

		dui.speaker.text = interrupting_speaker
		dui.dialog.text = interrupting_flavor_line
		dui.dialog.visible_characters = 0

		# Use typewriter for flavor line with long read delay
		type_text(interrupting_flavor_line.length(), flavor_read_delay)

func on_character_resume_dialogue():
	dialog_paused = false
	is_interrupting_dialog = false

############### name selection logic!
func run_name_selection():
	dialog_paused = true
	character.change_character("EMPTY", "Default", "Default")
	var name_selection = preload("res://scenes/name_selection.tscn").instantiate()
	name_selection.name_chosen.connect(name_chosen)
	var parent_ui = $UI
	dui.hide()
	parent_ui.add_child(name_selection)
	
func name_chosen(_name : String) -> void:
	dialog_paused = false
	dui.show()
	dialog_index -= 1
	process_current_line()

func run_smores_game():
	dialog_paused = true
	await TransitionManager.transition_to_scene("res://scenes/smores_game.tscn")
	#get_tree().change_scene_to_file("res://scenes/smores_game.tscn")

func end_game():
	dui.show()
	dialog_paused = false
	relationship_gain(Globals.current_character, Globals.game_score)
	dialog_index = -1
	process_current_line()
	
#func run_fishing_game():
	#character.change_character("EMPTY", "Default", "Default")
	#var fishing_game = preload("res://scenes/fishing_game.tscn").instantiate()
	#fishing_game.end_game.connect(end_game)
	#var parent_ui = $UI
	#dui.hide()
	#parent_ui.add_child(fishing_game)
	#
#func run_birdwatching_game():
	#character.change_character("EMPTY", "Default", "Default")
	#var bird_game = preload("res://scenes/birdwatching_game.tscn").instantiate()
	#bird_game.end_game.connect(end_game)
	#var parent_ui = $UI
	#dui.hide()
	#parent_ui.add_child(bird_game)
	
func end_day():
	Globals.scene_index += 1
	if Globals.scene_index >= Globals.scenes.size():
		print("No more scenes left!")
		return

	Globals.current_day = Globals.scenes[Globals.scene_index]
	load_next_day_dialogue()

func load_next_day_dialogue():
	var file = FileAccess.open("res://dialogue/dialogue.json", FileAccess.READ)
	if file:
		var parsed = JSON.parse_string(file.get_as_text())
		if typeof(parsed) == TYPE_DICTIONARY:
			var next_scene = Globals.current_day
			if parsed.has(next_scene):
				dialog_lines = parsed[next_scene]
				dialog_index = -1
				process_current_line()
			else:
				print("No dialogue found for scene: ", next_scene)
	
## useless ass button positsion randomizer
func randomize_botton_pos() -> void:
	var viewport_size = get_viewport_rect().size
	var button_size = $UI/Button.size
	
	var new_x = randi() % int(viewport_size.x - button_size.x)
	var new_y = randi() % int((viewport_size.y -230)- button_size.y)
	
	$UI/Button.position.x = new_x
	$UI/Button.position.y = new_y
