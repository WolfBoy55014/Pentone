extends Node2D

@onready var sample_hz = $AudioStreamPlayer.stream.mix_rate
var frequency = 440.0 # The frequency of the sound wave.
var amplitude = 0.0
var phase = 0.0
var playback: AudioStreamPlayback = null

var mouse_pressure
var mouse_x
var mouse_y


# Called when the node enters the scene tree for the first time.
func _ready():
	$AudioStreamPlayer.stream.mix_rate = sample_hz
	$AudioStreamPlayer.play()
	playback = $AudioStreamPlayer.get_stream_playback()
	fill_buffer()


# Called every frame. 'delta' is the elapsed time since the previous frame.
@warning_ignore("unused_parameter")
func _process(delta):
	fill_buffer()


func _input(event):
	if event is InputEventMouseMotion:
		if event.pressure >= 0.2:
			update_tone(event)
	if event.is_action_pressed("ui_cancel"):
		get_tree().quit()

func update_tone(event):
	mouse_pressure = event.pressure
	mouse_x = event.position.x
	mouse_y = event.position.y
	
	frequency = remap(mouse_x, 0, get_viewport().size.x, 10, 1000)
	amplitude = remap(mouse_y, get_viewport().size.y, 0, 0.0, 1.0)

func fill_buffer():
	var increment = frequency / sample_hz

	var to_fill = playback.get_frames_available()
	while to_fill > 0:
		playback.push_frame(Vector2.ONE * (amplitude * sin(phase * TAU))) # Audio frames are stereo.
		phase = fmod(phase + increment, 1.0)
		to_fill -= 1
