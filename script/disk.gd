extends Node2D

@export var size_index: int = 1
@onready var rect = $ColorRect

func _ready():
	rect.size.x = 50 + size_index * 30
	rect.size.y = 20
	rect.color = Color.from_hsv(float(size_index) * 0.15, 0.8, 0.9)
