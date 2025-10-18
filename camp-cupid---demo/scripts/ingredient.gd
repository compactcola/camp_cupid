extends Area2D

signal collected(ingredient_type : String)

@onready var sprite := $Sprite2D
@onready var difficulty = Globals.smores_difficulty[Globals.smores_difficulty_index]

@export var ingredient_type := "graham"

var velocity := Vector2.ZERO
var angular_velocity := 0.0

var SCREEN_WIDTH
var SCREEN_HEIGHT

var textures := {
	"graham": preload("res://assets/sprites/cracker.png"),
	"chocolate": preload("res://assets/sprites/chocolate.png"),
	"marshmallow": preload("res:///assets/sprites/marshmallow.png")
}

func _ready():
	hide() #### frame bs to properly get viewport size
	await get_tree().process_frame  # wait one frame so viewport exists
	var vp := get_viewport()
	if not vp:
		push_warning("Viewport not ready; using fallback screen size")
		vp = get_tree().root
	var vp_size := vp.get_visible_rect().size
	SCREEN_WIDTH = vp_size.x
	SCREEN_HEIGHT = vp_size.y
	show()

	angular_velocity = randf_range(-3.0, 3.0) *difficulty
	sprite.texture = textures[ingredient_type]
	
	var pos_x = randf_range(100, SCREEN_WIDTH-100)
	position = Vector2(pos_x, SCREEN_HEIGHT + 50)
	
	var dir = 1 if pos_x < (SCREEN_WIDTH / 2) else -1
		
	var x_impulse = randf_range(300, 500)
	var y_impulse = -randf_range(1200, 1500)*difficulty
	velocity = (Vector2(dir*x_impulse, y_impulse))
	
func _process(delta):
	position += velocity * delta
	velocity.y += (gravity*difficulty) * delta  # gravity pull
	rotation += angular_velocity * delta

	if position.y > SCREEN_HEIGHT + 100:
		queue_free()

func _input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed:
		emit_signal("collected", ingredient_type)
		queue_free()
