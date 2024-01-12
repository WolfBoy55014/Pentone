extends Node2D

@onready var sample_hz = $AudioStreamPlayer.stream.mix_rate # Retrieve sample rate from AudioStreamPlayer node

# The frequency, amplitude, and phase of the sound wave
var frequency = 0.0
var amplitude = 0.0
var phase = 0.0

var string_length # Functions as 'string length' in frequency curve remap equation

# Contians the sound waves
var playback: AudioStreamPlayback = null

# Info about the mouse
var mouse_pressure
var mouse_x
var mouse_y


# Called when the node enters the scene tree for the first time.
func _ready():
	$AudioStreamPlayer.play() # Start playing the stream
	playback = $AudioStreamPlayer.get_stream_playback() # Get its contents (empty)
	fill_buffer()


# Called every frame. 'delta' is the elapsed time since the previous frame.
@warning_ignore("unused_parameter")
func _process(delta):
	fill_buffer() # Constantly fill the buffer


# Called for every input event. 'event' contains event data
func _input(event):
	if event is InputEventMouseMotion:
		update_tone(event) # Update the generated tone
	if event.is_action_pressed("ui_cancel"):
		get_tree().quit() # Stop game

func update_tone(event):
	# Get mouse info
	mouse_pressure = event.pressure
	mouse_x = event.position.x
	mouse_y = event.position.y
	
	var mouse_pressed = ceili(mouse_pressure) # If pressure > 0, then 1
	
	# Remap mouse x to virtual string length
	string_length = remap(mouse_x, 0, get_viewport().size.x, 100, 21.0225)
	#  IMPORTANT: string length of 100 = A2, 21.0225 = C5. These values should not be changed without
	#  first checking the Mersenne curve (see equation below).
	
	# string_length integrated into Mersenne's Law for realistic frequency spacing
	frequency = 27.5 * (800 / (2 * string_length))
	
	# Remap the mouse y to 0 and max volume
	amplitude = remap(mouse_y, 0, get_viewport().size.y, 5, 0) * mouse_pressed

func fill_buffer():
	var increment = frequency / sample_hz

	var to_fill = playback.get_frames_available() # Check how many samples of the buffer are empty
	while to_fill > 0: # If there are samples empty, fill them
		
		# This generates a sine wave
		playback.push_frame(Vector2.ONE * (amplitude * sin(phase * TAU))) # Audio frames are stereo.
		phase = fmod(phase + increment, 1.0)
		
		to_fill -= 1
