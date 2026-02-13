extends Node2D

@export var rod_color: Color = Color(0.2, 0.2, 1.0)  # default blue

@onready var sprite = $ColorRect  # assuming your rod has a ColorRect child

func _ready():
	sprite.color = rod_color
