extends Node2D

@onready var parking_area = $ParkingArea
@onready var enter_button = $EnterButton
@onready var exit_button = $ExitButton
@onready var input = $CarIDInput
@onready var log_label = $LogLabel

var CarScene := preload("res://scenes/car.tscn")

# =========================
# NEW CONSTANTS (LIMITS)
# =========================
const MAX_CAPACITY := 6   # Limit cars to 6
const MAX_LOGS := 5       # Limit logs to 5 lines

# =========================
# QUEUE DATA
# =========================
var parking_queue: Array[String] = []
var car_nodes: Dictionary = {}
var logs: Array[String] = []

var attendance: Dictionary = {}

# =========================
# GARAGE POSITIONS
# =========================
const PARK_X: float = 400
const TOP_Y: float = -400
const GAP: float = 140.0

# ENTRY / EXIT
const ENTRY_Y: float = 400
const EXIT_Y: float = -900

# =========================
# LOOP PATH
# =========================
const LOOP_LEFT_X: float = -300

# =========================
# READY
# =========================
func _ready():
	enter_button.pressed.connect(enter_car)
	exit_button.pressed.connect(exit_car)
	update_log()

# =========================
# HELPER: MANAGE LOGS
# =========================
func add_log_entry(message: String):
	logs.append(message)
	# If we exceed the limit, remove the oldest log (First In, First Out)
	if logs.size() > MAX_LOGS:
		logs.pop_front()
	update_log()


# =========================
# ENTER (Bottom-Left -> Right -> Up)
# =========================
func enter_car():
	# --- CHECK CAPACITY ---
	if parking_queue.size() >= MAX_CAPACITY:
		add_log_entry("REJECTED: Garage Full!")
		return

	var id: String = input.text.strip_edges()
	if id == "" or car_nodes.has(id):
		return

	if not attendance.has(id):
		attendance[id] = { "in": 0, "out": 0 }

	attendance[id]["in"] += 1

	var car: Control = CarScene.instantiate()
	car.car_id = id
	
	# --- STEP 1: Spawn on the LEFT (Bottom-Left) ---
	# Spawning at (-400, 500) facing Right
	car.position = Vector2(LOOP_LEFT_X, ENTRY_Y)
	car.rotation_degrees = -180 # Face Right
	
	parking_area.add_child(car)
	car_nodes[id] = car
	parking_queue.append(id)

	add_log_entry("ENTER %s" % id)
	input.clear()

	# --- STEP 2: Drive RIGHT (To the Lane) ---
	# Move to (350, 500)
	await move_car(car, PARK_X, ENTRY_Y)
	car.rotation_degrees = 0 

	# --- STEP 3: Drive UP (Into Spot) ---
	# Calculate target (e.g., -300, -160, etc.)
	# Since ENTRY_Y is 500 and Target is -300, this is moving UP.
	var new_index = parking_queue.size() - 1
	var target_y = TOP_Y + (new_index * GAP)
	
	await move_car(car, PARK_X, target_y)
	

# =========================
# EXIT
# =========================
func exit_car():
	var id: String = input.text.strip_edges()
	if id == "" or not parking_queue.has(id):
		return

	await simulate_queue_exit(id)
	input.clear()


# =========================
# CIRCULAR QUEUE (Updated for L-Reverse)
# =========================
func simulate_queue_exit(target_id: String) -> void:
	while parking_queue.front() != target_id:
		var blocker_id: String = parking_queue.pop_front()
		var blocker_car: Control = car_nodes[blocker_id]
		
		# 1. Blocker exits (Left -> Exit)
		await move_car(blocker_car, LOOP_LEFT_X, blocker_car.position.y)
		await move_car(blocker_car, LOOP_LEFT_X, EXIT_Y)
		
		# 2. SHIFT UP EXISTING CARS (Make room at bottom)
		await update_queue_positions()

		# 3. Blocker Re-enters (Teleport to Bottom-Left)
		attendance[blocker_id]["out"] += 1
		attendance[blocker_id]["in"] += 1
		
		blocker_car.position = Vector2(LOOP_LEFT_X, ENTRY_Y)
		blocker_car.rotation_degrees = 0 # Face Right
		
		parking_queue.append(blocker_id)
		
		# 4. Blocker drives the "L Reverse" Path
		# Drive RIGHT
		await move_car(blocker_car, PARK_X, ENTRY_Y)
		
		# Drive UP to the new last spot
		var new_index = parking_queue.size() - 1
		var target_y = TOP_Y + (new_index * GAP)
		await move_car(blocker_car, PARK_X, target_y)
		

	# --- TARGET EXITS ---
	var car: Control = car_nodes[target_id]
	attendance[target_id]["out"] += 1
	
	await move_car(car, LOOP_LEFT_X, car.position.y)
	await move_car(car, LOOP_LEFT_X, EXIT_Y)

	parking_queue.pop_front() 
	car.queue_free()
	car_nodes.erase(target_id)
	attendance.erase(target_id)
	
	add_log_entry("EXIT %s" % target_id)

	await update_queue_positions()


# =========================
# QUEUE POSITIONING
# =========================
func update_queue_positions() -> void:
	for i in range(parking_queue.size()):
		var id: String = parking_queue[i]
		var car: Control = car_nodes[id]

		var target_y: float = TOP_Y + i * GAP
		
		# Only move if not already there
		if car.position.y != target_y or car.position.x != PARK_X:
			await move_car(car, PARK_X, target_y)
			# ✅ FORCE FACE UP
			car.rotation_degrees = 0

# =========================
# MOVE CAR
# =========================
func move_car(car: Control, x: float, y: float) -> void:
	var from_pos := car.position
	var to_pos := Vector2(x, y)

	car.face_direction(from_pos, to_pos)

	var tween := create_tween()
	tween.tween_property(car, "position", to_pos, 0.4)
	await tween.finished

# =========================
# LOG DISPLAY
# =========================
func update_log():
	log_label.text = "QUEUE (FRONT → BACK)\n"
	log_label.text += str(parking_queue) + "\n\n"

	log_label.text += "ATTENDANCE (Current Cars Only)\n"
	for id in attendance.keys():
		log_label.text += "%s → IN:%d OUT:%d\n" % [
			id,
			attendance[id]["in"],
			attendance[id]["out"]
		]

	log_label.text += "\nLAST 5 ACTIONS:\n"
	for l in logs:
		log_label.text += l + "\n"
