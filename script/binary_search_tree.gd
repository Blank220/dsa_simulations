extends Node2D

@onready var tree_root = $BSTvisuals
@onready var input_value = $InputValue
@onready var insert_button = $InsertButton
@onready var reset_button = $ResetButton
@onready var random_button = $RandomButton
@onready var num_nodes_spinbox = $NumberNodes
@onready var inorder_label = $InorderLabel
@onready var numbers_gen = $numbers

var NodeScene := preload("res://scenes/treenode.tscn")

# --------------------
# BST Data structure
# --------------------
class TreeNodeData:
	extends Object
	var value: int
	var left = null
	var right = null
	var visual = null

var root: TreeNodeData = null

# --------------------
# Layout Settings (Tweak these to change look)
# --------------------
var node_spacing_x = 60   # Horizontal gap between "lanes"
var node_spacing_y = 100  # Vertical gap between levels
var layout_index = 0      # Internal counter used for positioning

# --------------------
# Ready
# --------------------
func _ready():
	insert_button.pressed.connect(_on_insert_pressed)
	reset_button.pressed.connect(_on_reset_pressed)
	random_button.pressed.connect(_on_random_pressed)

# --------------------
# Manual insertion
# --------------------
func _on_insert_pressed():
	var v = input_value.text.to_int()
	if input_value.text.strip_edges() == "" or (v == 0 and input_value.text != "0"):
		return
	insert_value(v)
	input_value.clear()

# --------------------
# Insert value into BST
# --------------------
func insert_value(value: int):
	# 1. Logic Insertion (Create the data)
	if root == null:
		# We give it a temporary position (0,0), the layout function will fix it later
		root = create_node(value, Vector2.ZERO)
	else:
		_insert_recursive(root, value, 0)
	
	# 2. Visual Update (Recalculate ALL positions to prevent overlap)
	recalculate_positions()
	update_inorder()

# --------------------
# Recursive insert (Logic Only)
# --------------------
# We removed "horizontal" and "spacing" arguments because we don't calculate position here anymore.
func _insert_recursive(node: TreeNodeData, value: int, depth: int):
	if value <= node.value:
		if node.left == null:
			node.left = create_node(value, Vector2.ZERO) # Temp position
		else:
			_insert_recursive(node.left, value, depth + 1)
	else:
		if node.right == null:
			node.right = create_node(value, Vector2.ZERO) # Temp position
		else:
			_insert_recursive(node.right, value, depth + 1)

# --------------------
# RECALCULATE POSITIONS (The New "Lanes" Algorithm)
# --------------------
func recalculate_positions():
	if root == null: return

	# 1. Reset the counter
	layout_index = 0

	# 2. Find Screen Center
	var screen_center_x = get_viewport_rect().size.x / 2
	
	# 3. Calculate Offset based on LEFT children only
	# We need to know how many nodes come BEFORE the root (the left side)
	var left_nodes_count = count_nodes(root.left)
	
	# If there are 5 nodes on the left, the root will be at index 5.
	# So we start drawing back by 5 spaces.
	var start_x = screen_center_x - (left_nodes_count * node_spacing_x)

	# 4. Apply positions In-Order
	_apply_position_inorder(root, 0, start_x)
	
	# 5. Force redraw
	queue_redraw()

func _apply_position_inorder(node: TreeNodeData, depth: int, start_x: float):
	if node == null: return

	# A. Process Left Subtree First
	_apply_position_inorder(node.left, depth + 1, start_x)

	# B. Position Current Node
	var new_x = start_x + (layout_index * node_spacing_x)
	
	# --- CHANGE IS HERE ---
	# Adjust -150 to whatever height you prefer
	var new_y = -300 + (depth * node_spacing_y) 
	node.visual.position = Vector2(new_x, new_y)
	layout_index += 1
	
	# C. Process Right Subtree
	_apply_position_inorder(node.right, depth + 1, start_x)

func count_nodes(node: TreeNodeData) -> int:
	if node == null: return 0
	return 1 + count_nodes(node.left) + count_nodes(node.right)

# --------------------
# Create visual node
# --------------------
func create_node(value: int, pos: Vector2) -> TreeNodeData:
	var node_visual = NodeScene.instantiate()
	node_visual.value = value
	tree_root.add_child(node_visual)
	node_visual.position = pos

	var data = TreeNodeData.new()
	data.value = value
	data.visual = node_visual
	return data

# --------------------
# Reset tree
# --------------------
func _on_reset_pressed():
	for c in tree_root.get_children():
		c.queue_free()
	root = null
	inorder_label.text = ""
	numbers_gen.text = ""
	queue_redraw()

# --------------------
# Random BST generator
# --------------------
func _on_random_pressed():
	_on_reset_pressed()

	var num_nodes = int(num_nodes_spinbox.value)
	var numbers: Array[int] = []

	# Generate unique random numbers
	while numbers.size() < num_nodes:
		var n = randi() % 100 + 1
		if not n in numbers:
			numbers.append(n)

	# Insert all numbers (Logic Only)
	for n in numbers:
		if root == null:
			root = create_node(n, Vector2.ZERO)
		else:
			_insert_recursive(root, n, 0)
	
	# Calculate Visuals ONCE at the end (Much faster and cleaner)
	recalculate_positions()
	update_inorder()

	var str_list = numbers.map(func(x): return str(x))
	numbers_gen.text = "Random numbers: " + ", ".join(str_list)

# --------------------
# Draw lines
# --------------------
func _draw():
	if root != null:
		_draw_lines(root)

func _draw_lines(node: TreeNodeData):
	if node.left != null:
		# Adjust line start/end to be centered on the node
		draw_line(node.visual.position, node.left.visual.position, Color.WHITE, 2)
		_draw_lines(node.left)
	if node.right != null:
		draw_line(node.visual.position, node.right.visual.position, Color.WHITE, 2)
		_draw_lines(node.right)

func _process(delta):
	queue_redraw()

# --------------------
# Inorder traversal (Text)
# --------------------
func update_inorder():
	if root == null:
		inorder_label.text = ""
		return
	var arr = []
	_inorder(root, arr)
	inorder_label.text = "Inorder: " + ", ".join(arr)

func _inorder(node: TreeNodeData, arr: Array):
	if node == null: return
	_inorder(node.left, arr)
	arr.append(str(node.value))
	_inorder(node.right, arr)
