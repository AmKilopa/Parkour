extends Node

const RECORDS_PATH := "user://records.json"
const MAX_RECORDS := 10
const RECORD_INTERVAL := 1.0 / 60.0

var _recording := false
var _frames: Array[Dictionary] = []
var _barrel_explosions: Array[Dictionary] = []
var _accum := 0.0

func start_recording() -> void:
	_recording = true
	_frames.clear()
	_barrel_explosions.clear()
	_accum = 0.0

func record_barrel_explosion(pos: Vector3, time: float) -> void:
	if not _recording:
		return
	_barrel_explosions.append({"x": pos.x, "y": pos.y, "z": pos.z, "t": time})

func record_frame(player_pos: Vector3, player_rot_y: float, camera_pitch: float, time: float, delta: float, fired: bool = false, sliding: bool = false, crouching: bool = false, ledge_hanging: bool = false, on_wall: bool = false, wall_normal: Vector3 = Vector3.ZERO, has_shotgun: bool = true) -> void:
	if not _recording:
		return
	_accum += delta
	if _accum >= RECORD_INTERVAL:
		_accum = 0.0
		var frame: Dictionary = {
			"t": time,
			"x": player_pos.x,
			"y": player_pos.y,
			"z": player_pos.z,
			"ry": player_rot_y,
			"cp": camera_pitch,
			"f": 1 if fired else 0,
			"s": 1 if sliding else 0,
			"c": 1 if crouching else 0,
			"l": 1 if ledge_hanging else 0,
			"w": 1 if on_wall else 0,
			"h": 1 if has_shotgun else 0
		}
		if on_wall and wall_normal.length() > 0.1:
			frame["wx"] = wall_normal.x
			frame["wz"] = wall_normal.z
		_frames.append(frame)

func discard_recording() -> void:
	_recording = false
	_frames.clear()
	_barrel_explosions.clear()
	_accum = 0.0

func stop_and_save_record(time: float, level_path: String) -> void:
	_recording = false
	if _frames.is_empty():
		return
	var record: Dictionary = {
		"level": level_path,
		"time": time,
		"frames": _frames,
		"v": 2
	}
	if _barrel_explosions.size() > 0:
		record["barrels"] = _barrel_explosions.duplicate()
	_add_record(record)
	_frames.clear()
	_barrel_explosions.clear()

func _add_record(record: Dictionary) -> void:
	var all := _load_records()
	var level: String = record["level"].get_file().get_basename()
	if not all.has(level):
		all[level] = []
	var list: Array = all[level]
	list.append(record)
	list.sort_custom(func(a, b): return a["time"] < b["time"])
	while list.size() > MAX_RECORDS:
		list.pop_back()
	all[level] = list
	_save_records(all)

func get_records(level_path: String) -> Array:
	var all := _load_records()
	var level: String = level_path.get_file().get_basename()
	if not all.has(level):
		return []
	return all[level]

func delete_record_at(level_path: String, index: int) -> void:
	var all := _load_records()
	var level: String = level_path.get_file().get_basename()
	if not all.has(level):
		return
	var list: Array = all[level]
	if index >= 0 and index < list.size():
		list.remove_at(index)
		all[level] = list
		_save_records(all)

func clear_all_records() -> void:
	_save_records({})

func _load_records() -> Dictionary:
	if not FileAccess.file_exists(RECORDS_PATH):
		return {}
	var file := FileAccess.open(RECORDS_PATH, FileAccess.READ)
	if not file:
		return {}
	var data: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	return data if data is Dictionary else {}

func _save_records(data: Dictionary) -> void:
	var file := FileAccess.open(RECORDS_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))
		file.close()
