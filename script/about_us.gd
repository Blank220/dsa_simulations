extends Panel

@onready var exitbutton: Button = $Exitbutton


func _ready() -> void:
	exitbutton.pressed.connect(backtomain)
	
func backtomain():
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
