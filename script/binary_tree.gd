extends Node2D

@onready var tree_area = $TreeArea
@onready var generate_button = $GenerateButton
@onready var traverse_button = $TraversalButton
@onready var random_button = $RandomButton      # <--- NEW: Reference to the new button
@onready var level_spinbox = $LevelSpinBox
@onready var complete_check = $CompleteCheck
@onready var inorder_label = $InorderLabel
@onready var preorder_label = $PreorderLabel
@onready var postorder_label = $PostorderLabel

var NodeScene := preload("res://scenes/treenode_bt.tscn")

class TreeNode:
	var left: TreeNode = null
	var right: TreeNode = null
	var visual: LineEdit = null

var root: TreeNode = null

func _ready():
	generate_button.pressed.connect(generate_tree)
	traverse_button.pressed.connect(show_traversals)
	random_button.pressed.connect(generate_random_populated_tree) # <--- NEW: Connect signal

# -----------------------------
# Random Generation (Structure + Data)
# -----------------------------
func generate_random_populated_tree(): # <--- NEW FUNCTION
	# 1. Randomize whether it is a complete tree or scattered
	complete_check.button_pressed = (randf() > 0.7) # 30% chance of being "complete", 70% random
	
	# 2. Build the physical nodes
	generate_tree()
	
	# 3. Fill the nodes with random numbers
	populate_data_recursive(root)
	
	# 4. Update the traversal labels immediately (optional)
	show_traversals()

func populate_data_recursive(node: TreeNode): # <--- NEW FUNCTION
	if node == null:
		return
	
	# Set text to a random number between 1 and 99
	node.visual.text = str(randi_range(1, 99))
	
	populate_data_recursive(node.left)
	populate_data_recursive(node.right)

# -----------------------------
# Generate tree (Structure Only)
# -----------------------------
func generate_tree():
	clear_tree()
	var levels := int(level_spinbox.value)
	var complete: bool = complete_check.button_pressed

	root = create_node(0, 0, levels)
	build_tree(root, 1, 0, levels, complete)
	queue_redraw()

# -----------------------------
# Build structure recursively
# -----------------------------
func build_tree(node: TreeNode, level: int, index: int, max_level: int, complete: bool):
	if level >= max_level:
		return

	# LEFT CHILD
	if complete or randi() % 2 == 0:
		var left_index = index * 2
		node.left = create_node(level, left_index, max_level)
		if node.left != null:
			build_tree(node.left, level + 1, left_index, max_level, complete)

	# RIGHT CHILD
	if complete or randi() % 2 == 0:
		var right_index = index * 2 + 1
		node.right = create_node(level, right_index, max_level)
		if node.right != null:
			build_tree(node.right, level + 1, right_index, max_level, complete)

# -----------------------------
# Create visual node
# -----------------------------
func create_node(level: int, index: int, max_level: int) -> TreeNode:
	var t := TreeNode.new()
	var edit: LineEdit = NodeScene.instantiate()

	var nodes_in_level = pow(2, level)
	if index >= nodes_in_level:
		return null

	# Dynamic spacing
	# This uses only 80% of the screen width for the tree
	var total_width = get_viewport_rect().size.x * 0.9
	var spacing = total_width / (nodes_in_level + 1)
	edit.position = Vector2(spacing * (index + 1), 120 + level * 100)

	tree_area.add_child(edit)
	t.visual = edit
	return t

# -----------------------------
# Traversals
# -----------------------------
func show_traversals():
	if root == null:
		return

	var inorder := []
	var preorder := []
	var postorder := []

	inorder_traversal(root, inorder)
	preorder_traversal(root, preorder)
	postorder_traversal(root, postorder)

	inorder_label.text = "LTR (Inorder): " + ", ".join(inorder)
	preorder_label.text = "TLR (Preorder): " + ", ".join(preorder)
	postorder_label.text = "LRT (Postorder): " + ", ".join(postorder)

func inorder_traversal(n: TreeNode, arr: Array):
	if n == null: return
	inorder_traversal(n.left, arr)
	# Only add if text is not empty
	if n.visual.text != "": arr.append(n.visual.text) 
	inorder_traversal(n.right, arr)

func preorder_traversal(n: TreeNode, arr: Array):
	if n == null: return
	if n.visual.text != "": arr.append(n.visual.text)
	preorder_traversal(n.left, arr)
	preorder_traversal(n.right, arr)

func postorder_traversal(n: TreeNode, arr: Array):
	if n == null: return
	postorder_traversal(n.left, arr)
	postorder_traversal(n.right, arr)
	if n.visual.text != "": arr.append(n.visual.text)

# -----------------------------
# Clear tree
# -----------------------------
func clear_tree():
	for c in tree_area.get_children():
		c.queue_free()
	root = null
	inorder_label.text = ""
	preorder_label.text = ""
	postorder_label.text = ""
	queue_redraw()

# -----------------------------
# Draw connecting lines
# -----------------------------
func _draw():
	if root != null:
		draw_lines(root)

func draw_lines(node: TreeNode):
	# OFFSET FIX: We must add tree_area.position because the nodes 
	# live inside tree_area, but we are drawing on the root node.
	var offset = tree_area.position 
	
	if node.left != null:
		var p1 = offset + node.visual.position + node.visual.size / 2
		var p2 = offset + node.left.visual.position + node.left.visual.size / 2
		draw_line(p1, p2, Color.DARK_BLUE, 2)
		draw_lines(node.left)
		
	if node.right != null:
		var p1 = offset + node.visual.position + node.visual.size / 2
		var p2 = offset + node.right.visual.position + node.right.visual.size / 2
		draw_line(p1, p2, Color.DARK_BLUE, 2)
		draw_lines(node.right)
		
		
func _process(delta):
	queue_redraw()
