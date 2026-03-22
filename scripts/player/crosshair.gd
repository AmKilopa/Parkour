class_name Crosshair
extends Control

func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

@export var color := Color(1.0, 1.0, 1.0, 0.95)
@export var outline_color := Color(0.0, 0.0, 0.0, 0.8)
@export var line_length := 6
@export var gap := 4
@export var thickness := 2.0
@export var dot_size := 0.0

func _draw() -> void:
	var cx := size.x / 2.0
	var cy := size.y / 2.0
	var o := 1.0

	var _draw_line := func(from: Vector2, to: Vector2) -> void:

		draw_line(from + Vector2(-o, 0), to + Vector2(-o, 0), outline_color)
		draw_line(from + Vector2(o, 0), to + Vector2(o, 0), outline_color)
		draw_line(from + Vector2(0, -o), to + Vector2(0, -o), outline_color)
		draw_line(from + Vector2(0, o), to + Vector2(0, o), outline_color)
		draw_line(from, to, color)

	if line_length > gap / 2.0:
		_draw_line.call(Vector2(cx, cy - line_length), Vector2(cx, cy - gap / 2.0))

	_draw_line.call(Vector2(cx, cy + gap / 2.0), Vector2(cx, cy + line_length))

	_draw_line.call(Vector2(cx - line_length, cy), Vector2(cx - gap / 2.0, cy))

	_draw_line.call(Vector2(cx + gap / 2.0, cy), Vector2(cx + line_length, cy))

	if dot_size > 0:
		var r := dot_size / 2.0
		draw_rect(Rect2(cx - r - 1, cy - r - 1, dot_size + 2, dot_size + 2), outline_color)
		draw_rect(Rect2(cx - r, cy - r, dot_size, dot_size), color)
