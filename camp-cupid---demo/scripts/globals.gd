extends Node

var relationships = {
	"Aubrey": 0,
	"Harper": 0,
	"Ethan": 0
}
var player_name : String = "Me"
var fx_layer : CanvasLayer

### Serial Imput (so help me god)
var serial : GdSerial
var last_click := false

func _ready():
	serial = GdSerial.new()
	var ports = serial.list_ports()
	print("Ports avalible: ", ports)
	
	if ports.size() > 0:
		serial.set_port(ports[0]) #first open port (maybe use COM3 in future)
		serial.set_baud_rate(9600)
		
		if serial.open():
			print("serial opened! ", ports[0])
		else:
			print("did not open, but found serials I guess")
	else:
		print("didn't find shit")
	
	create_fx_layer() #not serial obviously

var line : String ## serial data line for parsing

func _process(delta):
	if serial and serial.is_open():
		line = serial.readline()
		if line != "":
			_parse_line(line)

func _parse_line(line : String):
	var parts = line.strip_edges().split(" ")
	var pos = Vector2.ZERO
	var click = false ## can change to an int or add int later for fire strength
	
	for part in parts:
		if part.begins_with("X:"):
			pos.x = int(part.substr(2))
		if part.begins_with("Y:"):
			pos.y = int(part.substr(2))
		elif part.begins_with("CLICK:"):
			click = int(part.substr(6)) == 1
	
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
		
		#make sure correct scene is loaded
		if fx_layer and is_instance_valid(fx_layer):
			fx_layer.add_child(effect)
		else:
			create_fx_layer()
		
		#create and start fade
		effect.global_position = event.position
		effect.start_fade()

func add_relationship(character_name : String, amount : int):
	if character_name in relationships:
		relationships[character_name] += amount
