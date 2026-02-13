extends Node2D

@onready var pegs = [$rod1, $rod2, $rod3]
@onready var button = $Button
@onready var label = $Control/Label
@onready var target_input = $TargetPeg
@onready var disk_input = $DiskCount
@onready var bg_music = $hanoi_music

var disks = []
var num_disks = 3
var move_count = 0

# Track where the stack is currently sitting (starts at 0 -> Rod 1)
var current_source_peg = 0 

# Gets the base y of rod 
var base_y = 0 
var disk_height = 30 

func _ready():
	button.pressed.connect(_on_solve_pressed)
	# new y for the rods spawn
	base_y = $rod1.global_position.y + 180
	
	setup_disks(num_disks, current_source_peg)
	label.text = "Ready! Choose Rods and Disk Count"
	bg_music.play()
	bg_music.connect("finished", Callable(self, "_on_bg_music_finished"))

func setup_disks(n, start_peg_index):
	var disk_scene = preload("res://scenes/disk.tscn")
	var start_peg = pegs[start_peg_index]

	for i in range(n):
		var disk = disk_scene.instantiate()
		disk.size_index = i + 1

		var disk_width = 50 + disk.size_index * 30
		var disk_x = start_peg.global_position.x - disk_width / 2
		
		# Stacking logic: Base - (stack_height)
		var disk_y = base_y - (n - 1 - i) * disk_height

		disk.position = Vector2(disk_x, disk_y)
		
		# Z-Index Fix: Smaller disks (top) get higher Z-Index
		disk.z_index = 10 + (n - i)
		
		add_child(disk)
		disks.append(disk)

func reset_disks():
	for d in disks:
		d.queue_free()
	disks.clear()

func _on_solve_pressed():
	# --- BUTTON LOCK ---
	button.disabled = true 
	
	num_disks = int(disk_input.value)
	var target_peg_index = target_input.get_selected_id()
	
	# Safety check to ensure target is valid
	if target_peg_index == -1: target_peg_index = 2 
	target_peg_index = clamp(target_peg_index, 0, 2)

	# --- FIXED LOGIC CHECK ---
	# We now check against 'current_source_peg', not hardcoded 0.
	if target_peg_index == current_source_peg:
		label.text = "Disks are already at Rod %d!" % (current_source_peg + 1)
		button.disabled = false 
		return

	# Reset and spawn disks at the CURRENT location (e.g., Rod 3)
	reset_disks()
	setup_disks(num_disks, current_source_peg)

	move_count = 0
	label.text = "Solving %d disks: Rod %d -> Rod %d" % [num_disks, current_source_peg + 1, target_peg_index + 1]

	var auxiliary = get_auxiliary_peg(current_source_peg, target_peg_index)
	
	# Run the solver
	await hanoi(num_disks, current_source_peg, target_peg_index, auxiliary)

	# --- FIX IS HERE ---
	# Added " % [move_count]" so the number actually displays
	label.text = "Solved in %d moves!" % [move_count]
	
	# Update the current location to the new target
	current_source_peg = target_peg_index
	
	# Re-enable button
	button.disabled = false 

func get_auxiliary_peg(a, b):
	for i in range(3):
		if i != a and i != b:
			return i
	return 0

func hanoi(n, source, target, auxiliary):
	if n == 1:
		await move_disk(source, target)
	else:
		await hanoi(n - 1, source, auxiliary, target)
		await move_disk(source, target)
		await hanoi(n - 1, auxiliary, target, source)

func move_disk(from_idx, to_idx):
	var disk_to_move = get_top_disk(from_idx)
	if disk_to_move:
		move_count += 1

		var disk_width = 50 + disk_to_move.size_index * 30
		var peg_x = pegs[to_idx].global_position.x
		var new_x = peg_x - disk_width / 2
		
		# Calculate new Y
		var new_y = base_y - count_disks(to_idx) * disk_height

		var tween = get_tree().create_tween()
		tween.tween_property(disk_to_move, "position", Vector2(new_x, new_y), 0.4)
		await tween.finished
		
		# Update Z-index so it sits correctly on the new stack
		disk_to_move.z_index = 10 + (10 - count_disks(to_idx)) 

		label.text = "Move %d: %d -> %d" % [move_count, from_idx + 1, to_idx + 1]
		await get_tree().create_timer(0.1).timeout

func get_top_disk(peg_index):
	var peg_x = pegs[peg_index].global_position.x
	var peg_disks = disks.filter(func(d):
		var disk_center_x = d.position.x + (50 + d.size_index * 30) / 2
		return abs(disk_center_x - peg_x) < 20 
	)
	if peg_disks.size() == 0:
		return null
		
	peg_disks.sort_custom(Callable(self, "_sort_by_y"))
	return peg_disks[0] 

func _sort_by_y(a, b):
	return a.position.y < b.position.y

func count_disks(peg_index):
	var peg_x = pegs[peg_index].global_position.x
	var peg_disks = disks.filter(func(d):
		var disk_center_x = d.position.x + (50 + d.size_index * 30) / 2
		return abs(disk_center_x - peg_x) < 20
	)
	return peg_disks.size()
	
func _on_bg_music_finished():
	bg_music.play()
