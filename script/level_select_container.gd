extends Panel

@onready var btn_toh = $LevelSelectContainer/Tower_of_hanoi
@onready var btn_bst = $LevelSelectContainer/Binary_search_tree
@onready var btn_bt =  $LevelSelectContainer/BinaryTree
@onready var btn_csp = $LevelSelectContainer/CarStackParking
@onready var btn_cqp = $LevelSelectContainer/CarQueueParking

# The Exit button handles Quitting the game directly
@onready var exit_button = $Exitbutton 

func _ready():
	# --- CONNECT GAME BUTTONS ---
	if btn_toh: btn_toh.pressed.connect(_on_toh_pressed)
	if btn_bst: btn_bst.pressed.connect(_on_bst_pressed)
	if btn_bt:  btn_bt.pressed.connect(_on_bt_pressed)
	if btn_csp: btn_csp.pressed.connect(_on_csp_pressed)
	if btn_cqp: btn_cqp.pressed.connect(_on_cqp_pressed)

	# --- CONNECT EXIT BUTTON ---
	if exit_button: exit_button.pressed.connect(_on_exit_pressed)

# ====================================================
# GAME SCENE LOADING
# ====================================================

func _on_csp_pressed():
	get_tree().change_scene_to_file("res://scenes/car_stack_parking.tscn")

func _on_cqp_pressed():
	# Make sure you have the Queue version scene made!
	get_tree().change_scene_to_file("res://scenes/car_queue_parking.tscn")

func _on_toh_pressed():
	get_tree().change_scene_to_file("res://scenes/tower_of_hanoi.tscn")

func _on_bst_pressed():
	get_tree().change_scene_to_file("res://scenes/binary_search_tree.tscn")
	
func _on_bt_pressed():
	get_tree().change_scene_to_file("res://scenes/binary_tree.tscn")

# ====================================================
# QUIT GAME
# ====================================================

func _on_exit_pressed():
	get_tree().change_scene_to_file('res://scenes/main_menu.tscn')
