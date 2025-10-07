extends Control

@onready var name_box : LineEdit = $CanvasLayer/VBoxContainer/LineEdit
@onready var keyboard : VBoxContainer = $CanvasLayer/VBoxContainer/VBoxContainer

signal name_chosen(name : String)

func _ready():
	for i in keyboard.get_children():
		if i is Button:
			i.pressed.connect(Callable(self, "_on_key_button_pressed").bind(i))
		else:
			for j in i.get_children():
				if j is Button:
					j.pressed.connect(Callable(self, "_on_key_button_pressed").bind(j))
			
func _on_key_button_pressed(btn : Button):
	var key : String = btn.text
	
	match key:
		"OK":
			_submit_name(name_box.text)
		_:
			if name_box.text.length() > 0:
				name_box.text += key.to_lower()
			else:
				name_box.text += key

func _submit_name(entered_name : String):
	if entered_name.strip_edges() == "":
		entered_name = "Camper"
	Globals.player_name = entered_name
		
	emit_signal("name_chosen", entered_name)
	queue_free()
	##print("Player name set to: %s" % Globals.player_name)
	
