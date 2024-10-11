extends Node2D

#region Variables
var thread1
var stopping

@onready var sample_hz = $AudioStreamPlayer.stream.mix_rate # Retrieve sample rate from AudioStreamPlayer node
@onready var note_bar = preload("res://scenes/note_bar.tscn")
@onready var notes_csv = preload("res://note_freq_440_432.csv")

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
	get_tree().root.connect("size_changed", _window_resize) # run function _window_resize() when the window is resized

	$AudioStreamPlayer.play() # Start playing the stream
	playback = $AudioStreamPlayer.get_stream_playback() # Get its contents (empty)

	populate_note_bars() # initial creation of note bars

	#region Making and starting sound generation thread
	thread1 = Thread.new()
	thread1.start(_thread1)
	#endregion

func _input(event):
	if event is InputEventMouseMotion:
		update_tone(event) # Update the generated tone
	if event.is_action_pressed("ui_cancel"):
		get_tree().quit() # Stop game

func _window_resize():
	remove_note_bars()
	populate_note_bars()

func update_tone(event):
	
	# Get mouse info
	mouse_pressure = event.pressure
	mouse_x = event.position.x
	mouse_y = event.position.y

	mouse_pressed = ceili(mouse_pressure) # If pressure > 0, then 1

	# Remap mouse x to virtual string length
	string_length = x_2_string_length(mouse_x)
	#  IMPORTANT: string length of 100 = A2, 21.0225 = C5. These values should not be changed without
	#  first checking the Mersenne curve (see equation below).

	# string_length integrated into Mersenne's Law for realistic frequency spacing
	frequency = string_length_2_frequency(string_length)

	# Remap the mouse y to 0 and max volume
	amplitude = remap(mouse_y, 0, get_viewport().size.y, 1, 0) * mouse_pressed

func populate_note_bars():
	for note in notes_csv.records:
		var bar = note_bar.instantiate()
		bar.x = string_length_2_x(frequency_2_string_length(note[1]))
		bar.note_name = note[0]
		add_child(bar)

func remove_note_bars():
	var children = self.get_children()
	for c in children:
		if c is Node2D:
			self.remove_child(c)
			c.queue_free()

#region Conversion Functions

func string_length_2_frequency(string_length):
	return 27.5 * (800 / (2 * string_length))

func frequency_2_string_length(frequency):
	return ((27.5 / frequency) * 800) / 2

func x_2_string_length(x):
	return remap(x, 0, get_viewport().size.x, 100, 21.0225)

func string_length_2_x(string_length):
	return remap(string_length, 100, 21.0225, 0, get_viewport().size.x)
#endregion

#region Thread1
func _thread1():
	# Stop if the game is trying to stop
	while !stopping:
		fill_buffer(amplitude, frequency)

func fill_buffer(amplitude, frequency):
	if amplitude == 0:
		return
	
	var increment = frequency / sample_hz

	var to_fill = playback.get_frames_available() # Check how many samples of the buffer are empty
	while to_fill > 0: # If there are samples empty, fill them

		# This generates a sine wave
		playback.push_frame(Vector2.ONE * (amplitude * sin(phase * TAU))) # Audio frames are stereo.
		phase = fmod(phase + increment, 1.0)

		to_fill -= 1
#endregion

func _exit_tree():
	# Wait for thread1 before quiting
	stopping = true
	thread1.wait_to_finish()
