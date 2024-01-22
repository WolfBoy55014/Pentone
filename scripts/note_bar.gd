extends Node2D

var x
var note_name :String

func _ready():
	global_position.x = x
	$Label.text = note_name
	
	if note_name.contains("#"):
		set_color('81a1c140')
		set_width(3)
	elif note_name.contains("C"):
		set_color('d08770')
		set_width(6)
	else:
		set_color('ffffff89')
		set_width(4.5)

func set_color(color :Color):
	$Line2D.default_color = color
	
func set_width(width :float):
	$Line2D.width = width
