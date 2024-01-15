extends Node2D

#region Variables
var thread1
var stopping
var time_elapsed

@onready var sample_hz = $AudioStreamPlayer.stream.mix_rate # Retrieve sample rate from AudioStreamPlayer node

# Variables containing tone properties
var frequency = 0.0
var amplitude = 0.0
var phase = 0.0
var string_length # Functions as 'string length' in frequency curve remap equation

# Contians the sound waves
var playback: AudioStreamPlayback = null

# Variables containing mouse state
var mouse_pressure
var mouse_x
var mouse_y
var mouse_pressed
#endregion

# Called when the node enters the scene tree for the first time.
func _ready():
	$AudioStreamPlayer.play() # Start playing the stream
	playback = $AudioStreamPlayer.get_stream_playback() # Get its contents (empty)
	
	#region Making and starting sound generation thread
	thread1 = Thread.new()
	thread1.start(_thread1)
	#endregion

func _process(delta):
	$VBoxContainer/FPS.text = "SPuS: " + str(snapped(time_elapsed, 0.001))
	
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
	
	mouse_pressed = ceili(mouse_pressure) # If pressure > 0, then 1
	
	# Remap mouse x to virtual string length
	string_length = remap(mouse_x, 0, get_viewport().size.x, 100, 21.0225)
	#  IMPORTANT: string length of 100 = A2, 21.0225 = C5. These values should not be changed without
	#  first checking the Mersenne curve (see equation below).
	
	# string_length integrated into Mersenne's Law for realistic frequency spacing
	frequency = 27.5 * (800 / (2 * string_length))
	
	# Remap the mouse y to 0 and max volume
	amplitude = remap(mouse_y, 0, get_viewport().size.y, 5, 0) * mouse_pressed


#region Thread1
func _thread1():
	# Stop if the game is trying to stop
	while !stopping:
		fill_buffer(amplitude, frequency)
	
func fill_buffer(amplitude, frequency):
	var start_time = Time.get_ticks_usec()
	var increment = frequency / sample_hz
	
	var to_fill = playback.get_frames_available() # Check how many samples of the buffer are empty
	var filled = float(to_fill)
	while to_fill > 0: # If there are samples empty, fill them
		
		# This generates a sine wave
		playback.push_frame(Vector2.ONE * (amplitude * sin(phase * TAU))) # Audio frames are stereo.
		phase = fmod(phase + increment, 1.0)
		
		to_fill -= 1
	
	time_elapsed = ((Time.get_ticks_usec() - start_time) / filled) if filled > 0 else time_elapsed
#endregion

func _exit_tree():
	# Wait for thread1 before quiting
	stopping = true
	thread1.wait_to_finish()
