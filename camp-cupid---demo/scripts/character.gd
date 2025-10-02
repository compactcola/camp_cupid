extends Node2D

@onready var animated_sprite = $AnimatedSprite2D

const approved_names = [
	"Aubrey",
	"Ethan",
	"Harper"
]

const CHARACTER_FRAMES = {
	"Aubrey":preload("res://resources/aubrey.tres"),
	"Harper":preload("res://resources/harper.tres"),
	"Ethan":preload("res://resources/ethan.tres"),
	"Empty":preload("res://resources/empty.tres")
}

func _ready():
	pass

func validate_name(name : String):
	var name_index = approved_names.find(name)
	if (name_index == -1):
		return "Empty"
	else:
		return approved_names[name_index]

func change_character(character_name : String):
	character_name = validate_name(character_name)
	animated_sprite.sprite_frames = CHARACTER_FRAMES[character_name]
	animated_sprite.play("default")
