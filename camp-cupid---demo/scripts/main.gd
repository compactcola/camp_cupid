extends Node2D

@onready var character = %Character
@onready var dui = %DialogueUI

var dialog_index : int = 0
var dialog_lines = []

var target = Sprite2D.new()

func _ready():
	$UI/Button.hide()
	
	## target reticule
	target.texture = load("res://assets/target.png")
	target.scale = Vector2(0.2, 0.2)
	get_tree().current_scene.add_child(target)
	
	var file = FileAccess.open("res://dialogue/dialogue.json", FileAccess.READ)
	if file:
		var parsed = JSON.parse_string(file.get_as_text())
		if typeof(parsed) == TYPE_DICTIONARY:
			dialog_lines = parsed[Globals.scenes[Globals.scene_index]]
		
	dialog_index = -1
	character.change_character("Empty")
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
	else:
		return

func _process(_delta) -> void:
	target.position = Globals.pos
	
## button to advance dialogue
#func _on_button_pressed() -> void:
	#process_current_line()
	##randomize_botton_pos()
	
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
	if(line_info["speaker"] == "BACKGROUND"):
		change_background(line_info["dialog"])
		process_current_line() ## auto advance so you don't have to click next again
		return
		
	 ## change scene
	if (line_info["speaker"] == "SCENE"):
		if (line_info["dialog"] == "name_select"):
			run_name_selection()
			character.change_character("EMPTY")
			return
		else:
			get_tree().change_scene_to_file("res://scenes/%s.tscn" % line_info["dialog"])
	
	## clear current character on screen
	if (line_info["speaker"] == "EMPTY"):
		character.change_character("EMPTY")
		process_current_line()
		return
	
	if (line_info["speaker"] == "Danny"):
		dui.speaker.text = "Counselor Dan"
	else:
		dui.speaker.text = line_info["speaker"]
	
	dui.dialog.text = line_info["dialog"]
	dui.dialog.visible_characters = 0
	type_text(line_info["dialog"].length()) ## call typewriter effect function
	character.change_character(line_info["speaker"])

##### typewriter and auto-text effect
var typing_speed_max : float = 0.05
var typing_speed_min : float = 0.03
var read_delay : float = 0.8

func type_text(line_length : int) -> void:
	var timer = Timer.new()
	timer.wait_time = 0.05
	timer.one_shot = false
	add_child(timer)
	timer.start()
	
	timer.timeout.connect(Callable(self, "_on_type_timeout").bind(timer, line_length))
	
func _on_type_timeout(timer : Timer, line_length : int) -> void:
	if dui.dialog.visible_characters < line_length:
		var next_char = dui.dialog.text[dui.dialog.visible_characters]
		var delay =  randf_range(typing_speed_max, typing_speed_min)
		
		if next_char in [".", ",", "!", "?", ";", ":"]:
			delay += 0.2
		elif next_char == "." and dui.dialog.text.substr(dui.dialog.visible_characters, 3) == "...":
			delay += 0.4  # slightly longer pause for ellipses
		
		timer.wait_time = delay
		dui.dialog.visible_characters +=1
	else:
		timer.stop()
		timer.queue_free()
		await _continue_after_delay()

func _continue_after_delay() -> void:
	await get_tree().create_timer(read_delay).timeout
	process_current_line()


############### name selection logic!
func run_name_selection():
	var name_selection = preload("res://scenes/name_selection.tscn").instantiate()
	name_selection.name_chosen.connect(name_chosen)
	var parent_ui = $UI
	dui.hide()
	parent_ui.add_child(name_selection)

func name_chosen(_name : String) -> void:
	dui.show()
	process_current_line()

## useless ass button position randomizer
func randomize_botton_pos() -> void:
	var viewport_size = get_viewport_rect().size
	var button_size = $UI/Button.size
	
	var new_x = randi() % int(viewport_size.x - button_size.x)
	var new_y = randi() % int((viewport_size.y -230)- button_size.y)
	
	$UI/Button.position.x = new_x
	$UI/Button.position.y = new_y
	
