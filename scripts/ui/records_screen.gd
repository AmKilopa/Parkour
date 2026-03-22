class_name RecordsScreen
extends Control

const MAIN_MENU := "res://scenes/ui/main_menu.tscn"
const REPLAY_VIEWER := "res://scenes/ui/replay_viewer.tscn"
const LEVEL_PATH := LevelState.DEFAULT_LEVEL_PATH

@onready var records_list := $Margin/VBox/RecordsList
@onready var back_btn := $Margin/VBox/BackBtn
@onready var vbox := $Margin/VBox

var _clear_btn: Button

func _ready() -> void:
	back_btn.pressed.connect(_on_back)
	_clear_btn = Button.new()
	_clear_btn.text = "Очистить все рекорды"
	_clear_btn.pressed.connect(_on_clear_all)
	vbox.add_child(_clear_btn)
	vbox.move_child(_clear_btn, vbox.get_child_count() - 2)
	_populate_records()

func _update_clear_button() -> void:
	var records: Array = RecordsManager.get_records(LEVEL_PATH)
	_clear_btn.visible = not records.is_empty()

func _on_delete_record(index: int) -> void:
	RecordsManager.delete_record_at(LEVEL_PATH, index)
	_populate_records()
	_update_clear_button()

func _on_clear_all() -> void:
	RecordsManager.clear_all_records()
	_populate_records()
	_update_clear_button()

func _populate_records() -> void:
	for c in records_list.get_children():
		c.queue_free()
	var records: Array = RecordsManager.get_records(LEVEL_PATH)
	if records.is_empty():
		var lbl := Label.new()
		lbl.text = "Пока нет рекордов.\nПройдите уровень до финиша или нажмите Перезапуск в паузе."
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		records_list.add_child(lbl)
		_update_clear_button()
		return
	for i in records.size():
		var r: Dictionary = records[i]
		var row := HBoxContainer.new()
		row.custom_minimum_size.y = 36
		var time_lbl := Label.new()
		time_lbl.text = "%d. %s" % [i + 1, LevelState.format_time(r["time"])]
		time_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		time_lbl.add_theme_font_size_override("font_size", 18)
		var watch_btn := Button.new()
		watch_btn.text = "Смотреть"
		watch_btn.pressed.connect(_on_watch.bind(r))
		var del_btn := Button.new()
		del_btn.text = "Удалить"
		del_btn.pressed.connect(_on_delete_record.bind(i))
		row.add_child(time_lbl)
		row.add_child(watch_btn)
		row.add_child(del_btn)
		records_list.add_child(row)
	_update_clear_button()

func _on_watch(record: Dictionary) -> void:
	ReplayViewerData.record = record
	ReplayViewerData.level_path = LEVEL_PATH
	get_tree().change_scene_to_file(REPLAY_VIEWER)

func _on_back() -> void:
	get_tree().change_scene_to_file(MAIN_MENU)
