extends Control

@export var car_id: String

@onready var sprite: Sprite2D = $Sprite2D
@onready var label: Label = $Label

func _ready():
	size = Vector2(120, 30)

	# Label setup
	label.text = car_id
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.size = Vector2(size.x, 20)
	label.position = Vector2(0, size.y + 5)

	# ENTERING → FACE DOWN
	face_down()

# =========================
# FACE BASED ON MOVEMENT
# =========================
func face_direction(from: Vector2, to: Vector2) -> void:
	var dir := to - from

	if abs(dir.y) >= abs(dir.x):
		if dir.y > 0:
			face_down()
		else:
			face_up()
	else:
		sprite.rotation = deg_to_rad(90 if dir.x > 0 else -90)

# =========================
# ORIENTATIONS
# =========================
func face_up() -> void:
	sprite.rotation = deg_to_rad(0)

func face_down() -> void:
	sprite.rotation = deg_to_rad(180)
