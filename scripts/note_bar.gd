extends Node2D

var x
var note_name :String

func _ready():
	global_position.x = x
	$Label.text = note_name
	
	if note_name.contains("C"):
		set_color('d08770')
	elif note_name.contains("#"):
		set_color('81a1c1')

func set_color(color :Color):
	$Line2D.default_color = color
