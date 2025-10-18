extends Node2D

@onready var body_sprite = $Body
@onready var head_sprite = $Head

const approved_names = [
	"Aubrey",
	"Ethan",
	"Harper",
	"Danny"
]

const CHARACTER_FRAMES = {
	"Aubrey":preload("res://resources/aubrey.tres"),
	"Harper":preload("res://resources/harper.tres"),
	"Ethan":preload("res://resources/ethan.tres"),
	"Danny":preload("res://resources/danny.tres"),
	"EMPTY":preload("res://resources/empty.tres")
}

const HEAD_FRAMES = {
	"Aubrey":preload("res://resources/aubrey_head.tres"),
	"Harper":preload("res://resources/harper_head.tres"),
	"Ethan":preload("res://resources/ethan_head.tres"),
	"Danny":preload("res://resources/empty.tres"),
	"EMPTY":preload("res://resources/empty.tres")
}

const FACE_OFFSETS = {
	"Harper": Vector2(0,-455.0), ## baseline lol
	"Aubrey": Vector2(0, -468.0),
	"Ethan": Vector2(0, -486.0)
}

const CHARACTER_HITBOXES = {
	"Aubrey": [
		Vector2(163.0, -135.0), 
		Vector2(86.0, -19.0), 
		Vector2(129.0, 444.0), 
		Vector2(-80.0, 495.0), 
		Vector2(-125.0, 20.0), 
		Vector2(-162.0, -133.0), 
		Vector2(-78.0, -313.0), 
		Vector2(-46.0, -432.0), 
		Vector2(12.0, -481.0), 
		Vector2(74.0, -427.0)
	],
	"Ethan": [
		Vector2(129.0, -159.0), 
		Vector2(75.0, 296.0), 
		Vector2(-100.0, 264.0), 
		Vector2(-75.0, -35.0), 
		Vector2(-162.0, -133.0), 
		Vector2(-114.0, -325.0), 
		Vector2(-45.0, -361.0), 
		Vector2(-63.0, -440.0), 
		Vector2(-6.0, -517.0), 
		Vector2(55.0, -429.0), 
		Vector2(38.0, -349.0), 
		Vector2(92.0, -324.0)
	],
	"Harper": [
		Vector2(21.0, -456.0), 
		Vector2(76.0, -423.0), 
		Vector2(100.0, -291.0), 
		Vector2(117.0, -262.0), 
		Vector2(120.0, -148.0), 
		Vector2(162.0, 24.0), 
		Vector2(140.0, 56.0), 
		Vector2(115.0, 33.0), 
		Vector2(123.0, -10.0), 
		Vector2(73.0, -208.0), 
		Vector2(31.0, -137.0), 
		Vector2(140.0, 265.0),
		Vector2(179.0, 524.0), 
		Vector2(-139.0, 520.0), 
		Vector2(-95.0, 239.0), 
		Vector2(-132.0, -59.0), 
		Vector2(-122.0, -192.0),
		Vector2(-38.0, -298.0), 
		Vector2(-51.0, -417.0)
	],
	"Danny": [
		Vector2(-35, -170),
		Vector2(35, -170),
		Vector2(65, 80),
		Vector2(-65, 80)
	]
}

func _ready():
	pass


@warning_ignore("shadowed_variable_base_class")
func validate_name(name : String):
	#check for player dialog
	if (name == Globals.player_name):
		return "Player"
	
	#make sure name is valid
	var name_index = approved_names.find(name)
	if (name_index == -1):
		return "EMPTY"
	else:
		return approved_names[name_index]

func change_character(character_name : String, body_expression : String, head_expression : String):
	character_name = validate_name(character_name)
	if (character_name == "Player"):
		return
		
	body_sprite.sprite_frames = CHARACTER_FRAMES[character_name]
	head_sprite.sprite_frames = HEAD_FRAMES[character_name]
	
	if character_name in FACE_OFFSETS:
		head_sprite.position = FACE_OFFSETS[character_name]
	
	if character_name in CHARACTER_HITBOXES:
		$Area2D/CollisionPolygon2D.polygon = CHARACTER_HITBOXES[character_name]
	else:
		$Area2D/CollisionPolygon2D.polygon = []
		
	body_sprite.play(body_expression)
	head_sprite.play(head_expression)
	
var hop_duration : float
var hop_distance : float

func hop():
	self.position = Vector2(0,-35)
	var tween = get_tree().create_tween()
	var start_y = position.y
	hop_distance = randf_range(-25, -10)
	hop_duration = randf_range(0.1, 0.3)
	
	tween.tween_property(self, "position:y", start_y + hop_distance, hop_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position:y", start_y, hop_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

###### character animations!
func pop_in():
	var rest_pos = position
	position = rest_pos + Vector2(0,500)
	
	var tween = create_tween()
	tween.set_parallel(true)
	
	var up_pos = rest_pos - Vector2(0, 40)
	tween.tween_property(self, "position", up_pos, 0.75).set_ease(Tween.EASE_OUT)
	tween.chain().tween_property(self, "position", rest_pos, 0.15).set_ease(Tween.EASE_IN_OUT)
	
	await tween.finished

func pop_out():
	var final_pos = position + Vector2(0,2000)
	
	var tween = create_tween()
	tween.set_parallel(true)
	
	tween.tween_property(self, "position", final_pos, 0.5).set_ease(Tween.EASE_OUT)
	
	await tween.finished

### hitbox functionality - doesn't do anything rn
#### use for future relationship harm, hurt sprite, death, etc
func _on_area_2d_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		print("Character clicked!")
