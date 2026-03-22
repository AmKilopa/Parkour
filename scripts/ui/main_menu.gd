class_name MainMenu
extends Control

const LEVEL_SELECT := "res://scenes/ui/level_select.tscn"
const RECORDS_SCENE := "res://scenes/ui/records_screen.tscn"

@onready var play_btn := $CenterContainer/Panel/Margin/VBox/PlayBtn
@onready var records_btn := $CenterContainer/Panel/Margin/VBox/RecordsBtn
@onready var exit_btn := $CenterContainer/Panel/Margin/VBox/ExitBtn

func _ready() -> void:
	play_btn.pressed.connect(_on_play)
	if records_btn.visible:
		records_btn.pressed.connect(_on_records)
	exit_btn.pressed.connect(_on_exit)
	play_btn.grab_focus()

func _on_play() -> void:
	get_tree().change_scene_to_file(LEVEL_SELECT)

func _on_records() -> void:
	get_tree().change_scene_to_file(RECORDS_SCENE)

func _on_exit() -> void:
	get_tree().quit()
