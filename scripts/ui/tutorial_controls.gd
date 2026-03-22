class_name TutorialControls
extends CanvasLayer

signal closed

@onready var panel := $Panel
@onready var start_btn := $Panel/Margin/VBox/StartBtn

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	panel.visible = true
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	start_btn.grab_focus()
	start_btn.pressed.connect(_close)

func _input(event: InputEvent) -> void:
	if panel.visible and event.is_action_pressed("restart_level"):
		get_tree().paused = false
		RecordsManager.discard_recording()
		get_tree().reload_current_scene()

func _close() -> void:
	panel.visible = false
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	closed.emit()
