extends Node

var relationships = {
	"Aubrey": 0.0,
	"Harper": 0.0,
	"Ethan": 0.0
}

var is_alive = {
	"Aubrey": true,
	"Ethan": true,
	"Harper": true,
	"Danny": true
}

var times_shot = {
	"Aubrey": 0,
	"Ethan": 0,
	"Harper": 0,
	"Danny": 0
}

var scenes = [
	"intro", "night1",
	"day2", "night2",
	"day3", "night3",
	"prom"
]
var scene_index : int = 0 # works, but might need adjustment when going back to old scenes (campfire, map, etc)
var current_day

### minigame scene data
var current_game : String
var current_character : String
var game_score : float

var smores_difficulty_index : int = 0 # use for campfire game difficulty scaling
var smores_difficulty = {
	0: 1.0,
	1: 1.15,
	2: 1.4,
}
var smores_score = 0

var player_name : String = "Me"
var fx_layer : CanvasLayer

const SCREEN_WIDTH = 1920
const SCREEN_HEIGHT = 1080

## audio stuff!
var arrow_hit_sounds = [
	preload("res://audio/arrow_hit-1.wav"),
	preload("res://audio/arrow_hit-2.wav"),
	preload("res://audio/arrow_hit-3.wav"),
	preload("res://audio/arrow_hit-4.wav"),
	preload("res://audio/arrow_hit-5.wav")
]
var sfx_player : AudioStreamPlayer

### Serial Imput (so help me god)
var serial : GdSerial
var last_click := false
var target = Sprite2D.new()
var pos = Vector2.ZERO

var reticle_scene = preload("res://scenes/reticle.tscn")
var reticle_instance : CanvasLayer

func _ready():
	await get_tree().process_frame  # wait for root to exist
	if not reticle_instance:
		reticle_instance = reticle_scene.instantiate()
		get_tree().root.add_child(reticle_instance)
		reticle_instance.layer = 100
		reticle_instance.visible = true
	
	## audio
	sfx_player = AudioStreamPlayer.new()
	add_child(sfx_player)
	
	serial = GdSerial.new()
	var ports = serial.list_ports()
	print("Ports avalible: ", ports)
	
	if ports.size() > 0:
		serial.set_port("COM3") #first open port (maybe use COM3 in future)
		serial.set_baud_rate(9600)
		
		if serial.open():
			print("Serial opened! ", ports[0])
		else:
			print("Did not open, but found serials?")
	else:
		print("!! Didn't find any ports !!")
	
	create_fx_layer() #not serial obviously

var line : String ## serial data line for parsing

#func _on_scene_change():
	#my_current_scene = get_tree().current_scene

func play_arrow_hit():
	if arrow_hit_sounds.size() == 0:
		return
	var random_sound = arrow_hit_sounds.pick_random()
	sfx_player.stream = random_sound
	sfx_player.play()

func _process(delta):
	if serial and serial.is_open():
		line = serial.readline()
		if line != "":
			_parse_line(line)

func _parse_line(line : String):
	var parts = line.strip_edges().split(",")
	var click = false # can change to an int or add int later for fire strength
	
	pos.x = 2*int(parts[0])
	pos.y = SCREEN_HEIGHT - (int(parts[1])*2)
	
	click = bool(int(parts[-1]))
	
	# mouse input
	var motion := InputEventMouseMotion.new()
	motion.position = pos
	Input.parse_input_event(motion)
	
	# mouse click
	if click != last_click:
		var btn := InputEventMouseButton.new()
		btn.button_index = MOUSE_BUTTON_LEFT
		btn.pressed = click
		btn.position = pos
		Input.parse_input_event(btn)
		last_click = click
	
func create_fx_layer() -> void:
	fx_layer = CanvasLayer.new()
	fx_layer.layer = 100
	get_tree().current_scene.add_child(fx_layer)

# mouse arrow effect
var ClickEffect = preload("res://scenes/arrow_impact.tscn")
func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var effect = ClickEffect.instantiate()
		play_arrow_hit()
		
		#make sure correct scene is loaded
		if fx_layer and is_instance_valid(fx_layer):
			fx_layer.add_child(effect)
		else:
			create_fx_layer()
		
		#create and start fade
		effect.global_position = event.position
		effect.start_fade()

func add_relationship(character_name : String, amount : float):
	if character_name in relationships:
		relationships[character_name] += amount
		relationships[character_name] = clamp(relationships[character_name], 0,100)
		print(character_name, " gained ", amount)
		print(character_name, " current: ", relationships[character_name])
