extends Node

signal level_completed(time: float, is_new_record: bool)

const DEFAULT_LEVEL_PATH := "res://scenes/main.tscn"
const START_SCORE := 100

var score := 100

var LEVEL_LIST: Array[Dictionary] = [
	{"path": "res://scenes/tutorial.tscn", "name": "Tutorial"},
	{"path": "res://scenes/main.tscn", "name": "Parkour"}
]

var LEVELS: PackedStringArray:
	get:
		var arr: PackedStringArray = []
		for d in LEVEL_LIST:
			arr.append(d["path"])
		return arr

var current_time := 0.0
var is_level_complete := false
var best_time := 0.0
var best_score := 0
const BEST_TIMES_PATH := "user://best_times.json"
const BEST_SCORES_PATH := "user://best_scores.json"
const NO_SCORE_RECORD := -2147483648

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	if not is_level_complete:
		current_time += delta

func reset_for_level() -> void:
	current_time = 0.0
	is_level_complete = false
	score = START_SCORE
	best_time = _load_best_time()
	best_score = _load_best_score()

func deduct_score(cost: int) -> void:
	score -= cost

func complete_level() -> void:
	if is_level_complete:
		return
	is_level_complete = true
	var time := current_time
	var is_new := best_time <= 0.0 or time < best_time
	if is_new:
		best_time = time
		_save_best_time()
	var is_new_score := best_score <= NO_SCORE_RECORD or score > best_score
	if is_new_score:
		best_score = score
		_save_best_score()
	var cur: Node = get_tree().current_scene
	var level_path: String = cur.scene_file_path if cur and cur.scene_file_path else DEFAULT_LEVEL_PATH
	RecordsManager.stop_and_save_record(time, level_path)
	level_completed.emit(time, is_new)

func get_time_formatted() -> String:
	return format_time(current_time)

func format_time(t: float) -> String:
	var mins := int(t / 60)
	var secs := int(fmod(t, 60))
	var cs := int(fmod(t * 100, 100))
	return "%02d:%02d.%02d" % [mins, secs, cs]

func get_next_level_path() -> String:
	var cur: Node = get_tree().current_scene
	if not cur or not cur.scene_file_path:
		return ""
	var current_path := cur.scene_file_path
	var idx := LEVELS.find(current_path)
	if idx < 0 or idx >= LEVELS.size() - 1:
		return ""
	return LEVELS[idx + 1]

func has_next_level() -> bool:
	return get_next_level_path() != ""

func get_best_time_for_level(level_path: String) -> float:
	if not FileAccess.file_exists(BEST_TIMES_PATH):
		return 0.0
	var file := FileAccess.open(BEST_TIMES_PATH, FileAccess.READ)
	if not file:
		return 0.0
	var text := file.get_as_text()
	file.close()
	var data: Variant = JSON.parse_string(text)
	if data == null or not data is Dictionary:
		return 0.0
	var scene: String = level_path.get_file().get_basename()
	return float((data as Dictionary).get(scene, 0.0))

func get_best_score_for_level(level_path: String) -> int:
	if not FileAccess.file_exists(BEST_SCORES_PATH):
		return NO_SCORE_RECORD
	var file := FileAccess.open(BEST_SCORES_PATH, FileAccess.READ)
	if not file:
		return NO_SCORE_RECORD
	var text := file.get_as_text()
	file.close()
	var data: Variant = JSON.parse_string(text)
	if data == null or not data is Dictionary:
		return NO_SCORE_RECORD
	var scene: String = level_path.get_file().get_basename()
	return int((data as Dictionary).get(scene, NO_SCORE_RECORD))

func _load_best_score() -> int:
	var cur: Node = get_tree().current_scene
	if not cur or not cur.scene_file_path:
		return NO_SCORE_RECORD
	return get_best_score_for_level(cur.scene_file_path)

func _save_best_score() -> void:
	var data: Dictionary = {}
	if FileAccess.file_exists(BEST_SCORES_PATH):
		var file_read := FileAccess.open(BEST_SCORES_PATH, FileAccess.READ)
		if file_read:
			var parsed: Variant = JSON.parse_string(file_read.get_as_text())
			file_read.close()
			if parsed is Dictionary:
				data = parsed as Dictionary
	var cur: Node = get_tree().current_scene
	if not cur or not cur.scene_file_path:
		return
	var scene: String = cur.scene_file_path.get_file().get_basename()
	data[scene] = best_score
	var file_write := FileAccess.open(BEST_SCORES_PATH, FileAccess.WRITE)
	if file_write:
		file_write.store_string(JSON.stringify(data))
		file_write.close()

func _load_best_time() -> float:
	var cur: Node = get_tree().current_scene
	if not cur or not cur.scene_file_path:
		return 0.0
	return get_best_time_for_level(cur.scene_file_path)

func _save_best_time() -> void:
	var data: Dictionary = {}
	if FileAccess.file_exists(BEST_TIMES_PATH):
		var file_read := FileAccess.open(BEST_TIMES_PATH, FileAccess.READ)
		if file_read:
			var parsed: Variant = JSON.parse_string(file_read.get_as_text())
			file_read.close()
			if parsed is Dictionary:
				data = parsed as Dictionary
	var cur: Node = get_tree().current_scene
	if not cur or not cur.scene_file_path:
		return
	var scene: String = cur.scene_file_path.get_file().get_basename()
	data[scene] = best_time
	var file_write := FileAccess.open(BEST_TIMES_PATH, FileAccess.WRITE)
	if file_write:
		file_write.store_string(JSON.stringify(data))
		file_write.close()
