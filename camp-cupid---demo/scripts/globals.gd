extends Node

var relationships = {
	"Aubrey": 0,
	"Harper": 0,
	"Ethan": 0
}
var player_name : String = "Default"
var fx_layer : CanvasLayer

func _ready():
	fx_layer = CanvasLayer.new()
	fx_layer.layer = 100
	get_tree().current_scene.add_child(fx_layer)

# mouse arrow effect
var ClickEffect = preload("res://scenes/arrow_impact.tscn")
func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var effect = ClickEffect.instantiate()
		fx_layer.add_child(effect)
		effect.global_position = event.position
		effect.start_fade()

func add_relationship(character_name : String, amount : int):
	if character_name in relationships:
		relationships[character_name] += amount
