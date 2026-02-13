extends Node2D

@onready var parking_area = $ParkingArea
@onready var enter_button = $EnterButton
@onready var exit_button = $ExitButton
@onready var input = $CarIDInput
@onready var log_label = $LogLabel

var CarScene = preload("res://scenes/car.tscn")

# =========================
# SETTINGS
# =========================
const MAX_LOGS := 5 # <--- LIMIT: Only keep the last 5 logs
const MAX_CAPACITY := 6  # <--- NEW: Max cars allowed

# =========================
# STACK DATA
# =========================
var parking_stack: Array[String] = []
var car_nodes: Dictionary = {}
var logs: Array[String] = []

# car_id -> { in: int, out: int }
var attendance: Dictionary = {}

var is_moving = false

# =========================
# POSITIONS
# =========================
const PARK_X := 500
const BOTTOM_Y := 300

# MAIN GARAGE (VERTICAL)
const GAP := 140

# TEMP GARAGE (HORIZONTAL)
const TEMP_X := -450
const TEMP_Y := 320
const TEMP_GAP := 95

# ENTER / EXIT POINT
const ENTRY_Y := -900

# =========================
# READY
# =========================
func _ready():
	enter_button.pressed.connect(enter_car)
	exit_button.pressed.connect(exit_car)
	update_log()

# =========================
# HELPER: ADD LOG (LIMIT SIZE)
# =========================
func add_log_entry(message: String):
	logs.append(message)
	# If we have too many logs, remove the oldest one (First In, First Out)
	if logs.size() > MAX_LOGS:
		logs.pop_front()
	update_log()


# =========================
# ENTER CAR
# =========================
func enter_car():
	# --- CHECK: IS GARAGE FULL? ---
	if parking_stack.size() >= MAX_CAPACITY:
		add_log_entry("REJECTED: Garage Full! (%d/%d)" % [parking_stack.size(), MAX_CAPACITY])
		return
	# ------------------------------

	var id: String = input.text.strip_edges()
	if id == "" or car_nodes.has(id):
		return

	if not attendance.has(id):
		attendance[id] = { "in": 0, "out": 0 }

	attendance[id]["in"] += 1

	var car = CarScene.instantiate()
	car.car_id = id
	car.position = Vector2(PARK_X, ENTRY_Y)

	parking_area.add_child(car)
	car_nodes[id] = car
	parking_stack.append(id)

	# --- MOVE LOGIC ---
	var new_index = parking_stack.size() - 1
	var target_y = BOTTOM_Y - (new_index * GAP)
	
	await move_car(car, PARK_X, target_y)
	car.rotation_degrees = 180 
	# ------------------

	add_log_entry("ENTER %s (IN=%d OUT=%d)" % [
		id, attendance[id]["in"], attendance[id]["out"]
	])

	input.clear()

# =========================
# EXIT CAR
# =========================
func exit_car():
	if is_moving: return 
	var id: String = input.text.strip_edges()
	if id == "" or not parking_stack.has(id):
		return

	is_moving = true
	await simulate_exit(id)
	is_moving = false

	input.clear()


# =========================
# EXIT SIMULATION
# =========================
func simulate_exit(target_id: String) -> void:
	var temp_stack: Array[String] = []

	# 1. Move cars OUT to Temp Garage (SIDEWAYS EXIT)
	while parking_stack.back() != target_id:
		var top_id: String = parking_stack.pop_back()
		temp_stack.append(top_id)

		attendance[top_id]["out"] += 1
		var car = car_nodes[top_id]

		# Calculate where in the temp line this car goes
		var target_temp_x = TEMP_X + (temp_stack.size() - 1) * TEMP_GAP

		# Move LEFT from current spot to temp X
		await move_car(car, target_temp_x, car.position.y)
		
		# Adjust height to sit in the temp row
		await move_car(car, target_temp_x, TEMP_Y)
		
		car.face_up()

	# 2. Remove Target Car
	parking_stack.pop_back()
	attendance[target_id]["out"] += 1

	var target_car = car_nodes[target_id]
	
	# Target car drives out normally (Up to entry, then gone)
	await move_car(target_car, PARK_X, ENTRY_Y)
	target_car.queue_free()
	car_nodes.erase(target_id)

	add_log_entry("EXIT %s (IN=%d OUT=%d)" % [
		target_id,
		attendance[target_id]["in"],
		attendance[target_id]["out"]
	])
	
	# Remove from Attendance completely
	attendance.erase(target_id)

	# 3. Return temp cars (ALIGN HEIGHT FIRST)
	for i in range(temp_stack.size() - 1, -1, -1):
		var id: String = temp_stack[i]
		attendance[id]["in"] += 1
		parking_stack.append(id)

		var car = car_nodes[id]

		# Calculate exactly where this car needs to end up
		var new_index = parking_stack.size() - 1
		var target_y = BOTTOM_Y - (new_index * GAP)

		# --- STEP 1: Align Height ---
		# Move vertically (Up/Down) while still in the temp lane
		await move_car(car, car.position.x, target_y)
		
		# --- STEP 2: Drive In ---
		# Move horizontally (Right) into the parking slot
		await move_car(car, PARK_X, target_y)
		car.face_up()
		

	update_log()

# =========================
# STACK POSITIONING (UNUSED NOW)
# =========================
# We keep this just in case, but enter_car/exit_car now move cars individually!
func update_stack_positions() -> void:
	for i in range(parking_stack.size()):
		var id: String = parking_stack[i]
		var car = car_nodes[id]
		var target_y = BOTTOM_Y - i * GAP
		await move_car(car, PARK_X, target_y)
		car.rotation_degrees = 180

# =========================
# MOVE CAR
# =========================
func move_car(car: Control, x: float, y: float) -> void:
	var from_pos := car.position
	var to_pos := Vector2(x, y)

	car.face_direction(from_pos, to_pos)

	var tween = create_tween()
	tween.tween_property(car, "position", to_pos, 0.4)
	await tween.finished

# =========================
# LOG DISPLAY
# =========================
func update_log():
	log_label.text = "STACK (BOTTOM → TOP)\n"
	log_label.text += str(parking_stack) + "\n\n"

	log_label.text += "ATTENDANCE\n"
	for id in attendance.keys():
		log_label.text += "%s → IN:%d OUT:%d\n" % [
			id, attendance[id]["in"], attendance[id]["out"]
		]

	log_label.text += "\nLOGS (Last %d):\n" % MAX_LOGS
	for l in logs:
		log_label.text += l + "\n"
