extends Button

@onready var exit_btn = $"."

func _ready():
	exit_btn.pressed.connect(_on_ext_presssed)
	
func _on_ext_presssed():
	get_tree().change_scene_to_file("res://scenes/level_select_container.tscn") 
