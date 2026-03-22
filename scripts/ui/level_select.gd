class_name LevelSelect
extends Control

const MAIN_MENU := "res://scenes/ui/main_menu.tscn"

@onready var levels_grid := $CenterContainer/Panel/Margin/VBox/LevelsGrid
@onready var back_btn := $CenterContainer/Panel/Margin/VBox/BackBtn

var _btn_style: StyleBoxFlat

func _ready() -> void:
	back_btn.pressed.connect(_on_back)
	_btn_style = _create_level_btn_style()
	_populate_levels()

func _create_level_btn_style() -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.2, 0.3, 0.45, 1)
	s.border_width_left = 1
	s.border_width_top = 1
	s.border_width_right = 1
	s.border_width_bottom = 1
	s.border_color = Color(0.35, 0.5, 0.7, 0.8)
	s.set_corner_radius_all(8)
	return s

func _populate_levels() -> void:
	for c in levels_grid.get_children():
		c.queue_free()
	var list: Array = LevelState.LEVEL_LIST
	var n := list.size()
	var cols := 2
	var rows := (n + 1) / 2 if n > 0 else 0

	for row in range(rows):
		for col in range(cols):
			var idx := col * rows + row
			if idx >= n:
				levels_grid.add_child(Control.new())
				continue
			var d: Dictionary = list[idx]
			var path: String = d["path"]
			var name: String = d["name"]
			var best: float = LevelState.get_best_time_for_level(path)
			var best_sc: int = LevelState.get_best_score_for_level(path)
			var time_str: String = LevelState.format_time(best) if best > 0 else "—"
			var score_str: String = str(best_sc) if best_sc > LevelState.NO_SCORE_RECORD else "—"
			var btn := Button.new()
			btn.custom_minimum_size = Vector2(260, 44)
			btn.text = "%s  •  %s  •  %s" % [name, time_str, score_str]
			btn.pressed.connect(_on_level_pressed.bind(path))
			btn.add_theme_font_size_override("font_size", 16)
			btn.add_theme_stylebox_override("normal", _btn_style)
			btn.add_theme_stylebox_override("hover", _btn_style)
			btn.add_theme_stylebox_override("pressed", _btn_style)
			btn.add_theme_color_override("font_color", Color(0.85, 0.9, 1.0, 1))
			levels_grid.add_child(btn)
	if levels_grid.get_child_count() > 0:
		var first_btn := levels_grid.get_child(0)
		if first_btn is Button:
			first_btn.grab_focus()
		else:
			back_btn.grab_focus()
	else:
		back_btn.grab_focus()

func _on_level_pressed(level_path: String) -> void:
	get_tree().change_scene_to_file(level_path)

func _on_back() -> void:
	get_tree().change_scene_to_file(MAIN_MENU)
