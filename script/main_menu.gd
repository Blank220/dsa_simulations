extends Node2D

# Only keep buttons that actually exist in the Main Menu scene
@onready var play_button = $VBoxContainer2/Playbutton  
@onready var exit_button = $VBoxContainer2/Exitbutton
@onready var about_usbutton: Button = $VBoxContainer2/AboutUsbutton

func _ready():
	play_button.pressed.connect(_on_play_pressed)
	exit_button.pressed.connect(_on_exit_pressed)
	about_usbutton.pressed.connect(_on_aboutus_pressed)

func _on_play_pressed():
	# This switches the screen to your NEW scene
	get_tree().change_scene_to_file("res://scenes/level_select_container.tscn")

func _on_exit_pressed():
	get_tree().quit()
	
func _on_aboutus_pressed():
	get_tree().change_scene_to_file("res://scenes/About_us.tscn")
