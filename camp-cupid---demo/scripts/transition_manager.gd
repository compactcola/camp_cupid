extends CanvasLayer

@onready var fade_rect : ColorRect

func _ready():
	fade_rect = $Black
	fade_rect.visible = true
	fade_rect.modulate.a = 0.0  # start transparent
	
	if Globals.is_dialogue_active == true:
		Globals.is_dialogue_active = false
	elif Globals.is_dialogue_active == false:
		Globals.is_dialogue_active = true

# Fade the screen to black
func fade_to_black(duration: float = 1.0):
	fade_rect.visible = true
	var tween = create_tween()
	tween.tween_property(fade_rect, "modulate:a", 1.0, duration)
	await tween.finished

# Fade from black to clear
func fade_from_black(duration: float = 1.0):
	fade_rect.visible = true
	fade_rect.modulate.a = 1.0
	var tween = create_tween()
	tween.tween_property(fade_rect, "modulate:a", 0.0, duration)
	await tween.finished
	fade_rect.visible = false

# Combine fade + scene change
func transition_to_scene(scene_path: String, fade_time: float = 0.5):
	await fade_to_black(fade_time)
	get_tree().change_scene_to_file(scene_path)
	await get_tree().process_frame
	await fade_from_black(fade_time)
