extends Node2D

@onready var body_sprite = $Visuals/Body
@onready var head_sprite = $Visuals/Head

signal character_shot(name : String, points_loss : float)

var is_talking := false
var times_shot = {
	"Aubrey":0,
	"Ethan":0,
	"Harper":0,
	"Danny":0
}
var is_alive = {
	"Aubrey": true,
	"Ethan": true,
	"Harper": true
}

signal interrupt_dialog(name : String)

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
		Vector2(169, -78),
		Vector2(-5, -397),
		Vector2(-191, -64),
		Vector2(-162, 498),
		Vector2(176,499)
	]
}

var current_char : String

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
	
	if Globals.is_alive.get(character_name, true) == false: ### speaker is dead
		body_sprite.sprite_frames = CHARACTER_FRAMES["EMPTY"]
		head_sprite.sprite_frames = HEAD_FRAMES["EMPTY"]
		current_char = character_name
		return
	else:
		body_sprite.sprite_frames = CHARACTER_FRAMES[character_name]
		head_sprite.sprite_frames = HEAD_FRAMES[character_name]
	current_char = character_name
	
	if character_name in FACE_OFFSETS:
		head_sprite.position = FACE_OFFSETS[character_name]
	
	if character_name in CHARACTER_HITBOXES:
		$Area2D/CollisionPolygon2D.polygon = CHARACTER_HITBOXES[character_name]
	else:
		$Area2D/CollisionPolygon2D.polygon = []
		
	if character_name == "Danny":
		body_sprite.position.y =- 200
		body_sprite.play(head_expression)
		head_sprite.sprite_frames = HEAD_FRAMES["EMPTY"]
		
	else:
		body_sprite.position.y = 0
		
		### wierd aubrey edge case
		if character_name == "Aubrey" and body_expression == "alt":
			body_sprite.flip_h = true
		else:
			body_sprite.flip_h = false
			
		body_sprite.play(body_expression)
		head_sprite.play(head_expression)
	
var hop_duration : float
var hop_distance : float

func hop():
	if !is_instance_valid(self) or get_tree() == null or !is_inside_tree():
		return
			
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

func show_hit_reaction():
	if "hit" in body_sprite.sprite_frames.get_animation_names():
		body_sprite.play("hit")
	else:
		var flash = create_tween()
		flash.tween_property(self, "modulate", Color(1,0.4,0.4), 0.1)
		flash.tween_property(self, "modulate", Color(1,1,1), 0.3)
		if current_char != "Danny":
			head_sprite.play("angry")
		else:
			body_sprite.play("angry")
	
func show_death_animation():
	body_sprite.sprite_frames = CHARACTER_FRAMES["EMPTY"]
	head_sprite.play("death")
	head_sprite.position.y += 200
	var tween = create_tween()

	var start_pos = position
	var hit_offset = Vector2(-250, -170)  # tweak for stronger/weaker effect
	tween.tween_property(self, "position", start_pos + hit_offset, 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	tween.tween_interval(0.2)
	
	tween.tween_property(self, "position", start_pos + Vector2(-250, 1100), 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)

	await tween.finished
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.8)

	tween.tween_callback(Callable(self, "queue_free"))
	await tween.finished

### hitbox functionality - doesn't do anything rn
#### use for future relationship harm, hurt sprite, death, etc
func _on_area_2d_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if current_char == "EMPTY":
		return

	if not Globals.is_alive.get(current_char, true):
		return  # already dead

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		Globals.times_shot[current_char] = Globals.times_shot.get(current_char, 0) + 1

		if current_char == "Danny" and Globals.times_shot[current_char] > 2:
			return  # Ignore further shots after 2

		emit_signal("interrupt_dialog", current_char)
		if Globals.times_shot[current_char] <= 2:
			emit_signal("character_shot", current_char, (-20 * Globals.times_shot[current_char]))
			show_hit_reaction()

		elif Globals.times_shot[current_char] >= 3:
			Globals.is_alive[current_char] = false
			show_death_animation()
			emit_signal("character_shot", current_char, -100)
