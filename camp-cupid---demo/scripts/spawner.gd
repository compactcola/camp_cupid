extends Node2D

@export var IngredientScene : PackedScene
@export var ingredient_types := ["graham", "chocolate", "marshmallow"]

var spawn_interval : float = 1*Globals.smores_difficulty[Globals.smores_difficulty_index]

const SCREEN_WIDTH = 1920
const SCREEN_HEIGHT = 1080

func _ready():
	spawn_loop()
	IngredientScene = load("res://scenes/ingredient.tscn")

func spawn_loop():
	while true:
		await get_tree().create_timer(spawn_interval).timeout
		spawn_ingredient()

func spawn_ingredient():
	if IngredientScene == null:
		push_error("IngredientScene not assigned")
		return

	var ingredient = IngredientScene.instantiate()
	ingredient.ingredient_type = ingredient_types.pick_random()
	add_child(ingredient)

	ingredient.position = Vector2(randf_range(50, SCREEN_WIDTH - 50), SCREEN_HEIGHT - 50)
	ingredient.collected.connect(get_parent()._on_ingredient_collected)
