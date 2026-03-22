class_name PauseMenu
extends CanvasLayer

signal closed

@onready var panel := $Panel
@onready var continue_btn := $Panel/Margin/VBox/ContinueBtn
@onready var sens_slider := $Panel/Margin/VBox/SensRow/SensSlider
@onready var sens_value := $Panel/Margin/VBox/SensRow/SensValue
@onready var invert_y_check := $Panel/Margin/VBox/InvertYCheck
@onready var fov_slider := $Panel/Margin/VBox/FovRow/FovSlider
@onready var fov_value := $Panel/Margin/VBox/FovRow/FovValue
@onready var volume_slider := $Panel/Margin/VBox/VolumeRow/VolumeSlider
@onready var volume_value := $Panel/Margin/VBox/VolumeRow/VolumeValue
@onready var ssao_check := $Panel/Margin/VBox/VideoGrid/SSAOCheck
@onready var ssil_check := $Panel/Margin/VBox/VideoGrid/SSILCheck
@onready var glow_check := $Panel/Margin/VBox/VideoGrid/GlowCheck
@onready var motion_blur_check := $Panel/Margin/VBox/VideoGrid/MotionBlurCheck
@onready var sdfgi_check := $Panel/Margin/VBox/VideoGrid/SDFGICheck
@onready var volumetric_fog_check := $Panel/Margin/VBox/VideoGrid/VolumetricFogCheck
@onready var speed_indicator_check := $Panel/Margin/VBox/SpeedIndicatorCheck
@onready var restart_btn := $Panel/Margin/VBox/RestartBtn
@onready var menu_btn := $Panel/Margin/VBox/MenuBtn
@onready var exit_btn := $Panel/Margin/VBox/ExitBtn

var _world_env: WorldEnvironment

func _ready() -> void:
	panel.visible = false
	_world_env = get_tree().get_first_node_in_group("world_environment") as WorldEnvironment
	sens_slider.value = SettingsManager.get_mouse_sensitivity() * 1000
	invert_y_check.button_pressed = SettingsManager.get_invert_y()
	fov_slider.value = SettingsManager.get_fov_default()
	volume_slider.value = SettingsManager.get_sfx_volume_db()
	ssao_check.button_pressed = SettingsManager.get_ssao_enabled()
	ssil_check.button_pressed = SettingsManager.get_ssil_enabled()
	glow_check.button_pressed = SettingsManager.get_glow_enabled()
	motion_blur_check.button_pressed = SettingsManager.get_motion_blur_enabled()
	sdfgi_check.button_pressed = SettingsManager.get_sdfgi_enabled()
	volumetric_fog_check.button_pressed = SettingsManager.get_volumetric_fog_enabled()
	speed_indicator_check.button_pressed = SettingsManager.get_show_speed_indicator()
	_apply_graphics()
	continue_btn.pressed.connect(_close)
	sens_slider.value_changed.connect(_on_sens_changed)
	invert_y_check.toggled.connect(_on_invert_y_toggled)
	fov_slider.value_changed.connect(_on_fov_changed)
	volume_slider.value_changed.connect(_on_volume_changed)
	_update_value_labels()
	ssao_check.toggled.connect(_on_ssao_toggled)
	ssil_check.toggled.connect(_on_ssil_toggled)
	glow_check.toggled.connect(_on_glow_toggled)
	motion_blur_check.toggled.connect(_on_motion_blur_toggled)
	sdfgi_check.toggled.connect(_on_sdfgi_toggled)
	volumetric_fog_check.toggled.connect(_on_volumetric_fog_toggled)
	speed_indicator_check.toggled.connect(_on_speed_indicator_toggled)
	restart_btn.pressed.connect(_on_restart)
	menu_btn.pressed.connect(_on_menu)
	exit_btn.pressed.connect(_on_exit)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("restart_level") and not panel.visible:
		var tc = get_parent().get_node_or_null("TutorialControls")
		if tc and tc.panel.visible:
			return
		_on_restart()
		return
	if event.is_action_pressed("ui_cancel"):
		if panel.visible:
			_close()
		else:
			_open()

func _open() -> void:
	panel.visible = true
	_get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	continue_btn.grab_focus()

func _close() -> void:
	panel.visible = false
	_get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	SettingsManager.save()
	closed.emit()

func _get_tree() -> SceneTree:
	return get_tree()

func _on_sens_changed(v: float) -> void:
	SettingsManager.set_mouse_sensitivity(v / 1000.0)
	_update_value_labels()

func _on_invert_y_toggled(v: bool) -> void:
	SettingsManager.set_invert_y(v)
	SettingsManager.save()

func _on_fov_changed(v: float) -> void:
	SettingsManager.set_fov_default(v)
	_update_value_labels()

func _on_volume_changed(v: float) -> void:
	SettingsManager.set_sfx_volume_db(v)
	_update_value_labels()

func _update_value_labels() -> void:
	if sens_value:
		sens_value.text = "%.3f" % SettingsManager.get_mouse_sensitivity()
	if fov_value:
		fov_value.text = "%d" % int(SettingsManager.get_fov_default())
	if volume_value:
		volume_value.text = "%d dB" % int(SettingsManager.get_sfx_volume_db())

func _on_ssao_toggled(v: bool) -> void:
	SettingsManager.set_ssao_enabled(v)
	_apply_graphics()
	SettingsManager.save()

func _on_ssil_toggled(v: bool) -> void:
	SettingsManager.set_ssil_enabled(v)
	_apply_graphics()
	SettingsManager.save()

func _on_glow_toggled(v: bool) -> void:
	SettingsManager.set_glow_enabled(v)
	_apply_graphics()
	SettingsManager.save()

func _on_motion_blur_toggled(v: bool) -> void:
	SettingsManager.set_motion_blur_enabled(v)
	SettingsManager.save()

func _on_sdfgi_toggled(v: bool) -> void:
	SettingsManager.set_sdfgi_enabled(v)
	_apply_graphics()
	SettingsManager.save()

func _on_volumetric_fog_toggled(v: bool) -> void:
	SettingsManager.set_volumetric_fog_enabled(v)
	_apply_graphics()
	SettingsManager.save()

func _on_speed_indicator_toggled(v: bool) -> void:
	SettingsManager.set_show_speed_indicator(v)
	SettingsManager.save()

func _apply_graphics() -> void:
	if _world_env and _world_env.environment:
		var env := _world_env.environment
		env.ssao_enabled = SettingsManager.get_ssao_enabled()
		env.ssil_enabled = SettingsManager.get_ssil_enabled()
		env.glow_enabled = SettingsManager.get_glow_enabled()
		env.sdfgi_enabled = SettingsManager.get_sdfgi_enabled()
		env.volumetric_fog_enabled = SettingsManager.get_volumetric_fog_enabled()

const MAIN_MENU_SCENE := "res://scenes/ui/main_menu.tscn"

func _on_restart() -> void:
	_get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	RecordsManager.discard_recording()
	_get_tree().reload_current_scene()

func _on_menu() -> void:
	_get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_get_tree().change_scene_to_file(MAIN_MENU_SCENE)

func _on_exit() -> void:
	_get_tree().quit()
