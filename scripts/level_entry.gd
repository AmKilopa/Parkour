class_name LevelEntry
extends Node3D

func _ready() -> void:
	LevelState.reset_for_level()
	RecordsManager.start_recording()
