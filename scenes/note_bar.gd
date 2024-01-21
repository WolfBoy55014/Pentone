extends Node2D

var x
var note_name

func _ready():
	global_position.x = x
	$Label.text = note_name
