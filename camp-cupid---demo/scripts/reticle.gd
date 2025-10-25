extends CanvasLayer

@onready var sprite := $Sprite2D

func _ready():
	set_process(true)
	sprite.visible = true
	sprite.modulate = Color(1,0.1,0.2,1)
	process_mode = Node.PROCESS_MODE_ALWAYS  # Keeps running even when scene paused

func _physics_process(delta: float) -> void:
	var target = Globals.pos
	sprite.position = sprite.position.lerp(target, delta * 10.0)
