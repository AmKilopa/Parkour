extends Node3D

@export_multiline var text := "Подсказка"
@export var font_size := 48
@export var pixel_size := 0.04

@onready var label: Label3D = $Label3D

func _ready() -> void:
	if label:
		label.text = text
		label.font_size = font_size
		label.pixel_size = pixel_size
