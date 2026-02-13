extends Control

@export var value: int
@export var radius: int = 50

func _ready():
	size = Vector2(radius * 2, radius * 2)
	set_anchors_and_offsets_preset(PRESET_CENTER)
	queue_redraw()

func _draw():
	# Draw circle
	draw_circle(size / 2, radius, Color(1.0, 0.55, 0.1))

	# Auto text size
	var font_size := int(radius * 0.8)

	var font := get_theme_default_font()

	# Measure text using font_size (Godot 4 style)
	var text := str(value)
	var text_size: Vector2 = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)

	# Center it
	var pos: Vector2 = (size - text_size) / 2 + Vector2(0, text_size.y * 0.7)

	# Draw text using the selected size
	draw_string(
		font,
		pos,
		text,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		font_size,
		Color.BLACK
	)
