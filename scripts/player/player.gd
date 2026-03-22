extends CharacterBody3D

signal velocity_changed(vel: Vector3)
signal mouse_turn_changed(turn: float)

@export_group("Движение")
@export var walk_speed := 12.0
@export var speed_reference := 50.0
@export var air_acceleration := 180.0
@export var air_drag := 3.0
@export var air_control := 12.0
@export var ground_friction := 8.0
@export var jump_velocity := 3.6
@export var coyote_time := 0.18
@export var jump_buffer_time := 0.2

@export_group("Камера")
@export var bob_amount := 0.035
@export var bob_frequency := 7.0
@export var sway_amount := 0.045
@export var landing_bob := 0.03
@export var camera_smooth := 12.0
@export var fov_default := 90.0
@export var fov_speed := 108.0
@export var tilt_amount := 0.06
@export var slide_tilt := 0.35
@export var speed_shake_amount := 0.008
@export var idle_bob_amount := 0.035
@export var idle_bob_speed := 2.5
@export var recoil_pitch_amount := 0.12
@export var look_ahead_amount := 0.04
@export var look_ahead_speed_threshold := 25.0

@export_group("Слайд")
@export var slide_friction_slow := 25.0
@export var slide_friction_fast := 4.0
@export var slide_fast_threshold := 14.0
@export var slide_accel := 2.0
@export var slide_min_speed := 0.3
@export var slide_max_distance_stand := 3.5
@export var slide_max_time_stand := 1.2
@export var slide_landing_boost := 1.35
@export var slide_steer := 8.0
@export var slide_end_cooldown := 1.0
@export var slope_accel_stand := 3.0
@export var slope_accel_slide := 22.0
@export var ramp_launch_base := 6.0
@export var ramp_launch_speed_factor := 0.28
@export var ramp_launch_max_vy := 22.0
@export var ramp_launch_min_speed := 8.0
@export var slide_ramp_landing_boost := 1.25
@export var ramp_climb_speed := 5.0
@export var void_y := -20.0

@export_group("Long Jump")
@export var long_jump_prep_window := 0.25
@export var long_jump_horizontal := 22.0
@export var long_jump_vertical := 4.5
@export var long_jump_camera_tilt := 0.25
@export var long_jump_fov_boost := 15.0

@export_group("Ledge Grab")
@export var ledge_grab_reach := 1.2
@export var ledge_hang_max_time := 1.5
@export var mantle_velocity := 3.8
@export var mantle_windup_time := 0.35

@export_group("Присед")
@export var crouch_walk_speed_multiplier := 0.5
@export var crouch_capsule_height := 0.9
@export var crouch_camera_height := 0.9
@export var crouch_tilt := 0.08

@export_group("Wall Run")
@export var wall_run_min_speed := 1.5
@export var wall_run_gravity := 4.5
@export var wall_run_tilt := 0.25
@export var wall_jump_velocity := 11.5

@export_group("Дробовик")
@export var start_with_shotgun := true
@export var shotgun_recoil_force := 6.0
@export var shotgun_cooldown := 1.0

@export_group("Звук")
@export var step_length := 4.0
@export var land_volume_db_offset := -10.0
@export var walk_sound: AudioStream = preload("res://assets/sounds/walk.mp3")
@export var land_sound: AudioStream = preload("res://assets/sounds/land.mp3")
@export var wind_sound: AudioStream = preload("res://assets/sounds/wind.wav")

var _stand_camera_height := 1.55
var _slide_camera_height := 0.6

var _state: PlayerState
var _movement: PlayerMovement
var _camera: PlayerCamera
var _audio: PlayerAudio
var _ui: PlayerUI
var _shotgun: PlayerShotgun

@onready var body_mesh: MeshInstance3D = $MeshInstance3D
@onready var _collision_shape: CollisionShape3D = $CollisionShape3D
@onready var _shotgun_node: Node3D = get_node_or_null(PlayerNodes.SHOTGUN)
@onready var _crosshair: Control = $SpeedUI/Crosshair
@onready var _camera_pivot: Node3D = $CameraPivot
@onready var _restart_btn: Button = $SpeedUI/LevelCompletePanel/MarginContainer/VBox/ButtonsRow/RestartBtn
@onready var _next_btn: Button = $SpeedUI/LevelCompletePanel/MarginContainer/VBox/ButtonsRow/NextBtn

func get_state() -> PlayerState:
	return _state

const _STAND_CAPSULE_HEIGHT := 1.75

func _create_movement_params() -> PlayerMovementParams:
	var p := PlayerMovementParams.new()
	p.walk_speed = walk_speed
	p.speed_reference = speed_reference
	p.air_acceleration = air_acceleration
	p.air_drag = air_drag
	p.air_control = air_control
	p.ground_friction = ground_friction
	p.jump_velocity = jump_velocity
	p.coyote_time = coyote_time
	p.jump_buffer_time = jump_buffer_time
	p.slide_friction_slow = slide_friction_slow
	p.slide_friction_fast = slide_friction_fast
	p.slide_fast_threshold = slide_fast_threshold
	p.slide_accel = slide_accel
	p.slide_min_speed = slide_min_speed
	p.slide_max_distance_stand = slide_max_distance_stand
	p.slide_max_time_stand = slide_max_time_stand
	p.slide_landing_boost = slide_landing_boost
	p.slide_steer = slide_steer
	p.slide_end_cooldown = slide_end_cooldown
	p.slide_ramp_landing_boost = slide_ramp_landing_boost
	p.slope_accel_stand = slope_accel_stand
	p.slope_accel_slide = slope_accel_slide
	p.ramp_launch_base = ramp_launch_base
	p.ramp_launch_speed_factor = ramp_launch_speed_factor
	p.ramp_launch_max_vy = ramp_launch_max_vy
	p.ramp_launch_min_speed = ramp_launch_min_speed
	p.ramp_climb_speed = ramp_climb_speed
	p.wall_run_min_speed = wall_run_min_speed
	p.wall_run_gravity = wall_run_gravity
	p.wall_jump_velocity = wall_jump_velocity
	p.void_y = void_y
	p.long_jump_prep_window = long_jump_prep_window
	p.long_jump_horizontal = long_jump_horizontal
	p.long_jump_vertical = long_jump_vertical
	p.ledge_grab_reach = ledge_grab_reach
	p.ledge_hang_max_time = ledge_hang_max_time
	p.mantle_velocity = mantle_velocity
	p.mantle_windup_time = mantle_windup_time
	p.crouch_walk_speed_multiplier = crouch_walk_speed_multiplier
	p.crouch_capsule_height = crouch_capsule_height
	return p

func _create_camera_params() -> PlayerCameraParams:
	var p := PlayerCameraParams.new()
	p.bob_amount = bob_amount
	p.bob_frequency = bob_frequency
	p.sway_amount = sway_amount
	p.landing_bob = landing_bob
	p.camera_smooth = camera_smooth
	p.slide_tilt = slide_tilt
	p.speed_shake_amount = speed_shake_amount
	p.idle_bob_amount = idle_bob_amount
	p.idle_bob_speed = idle_bob_speed
	p.wall_run_tilt = wall_run_tilt
	p.tilt_amount = tilt_amount
	p.long_jump_camera_tilt = long_jump_camera_tilt
	p.long_jump_fov_boost = long_jump_fov_boost
	p.fov_default = clampf(SettingsManager.get_fov_default(), 1.0, 179.0)
	p.fov_speed = clampf(SettingsManager.get_fov_speed(), 1.0, 179.0)
	p.speed_reference = speed_reference
	p.walk_speed = walk_speed
	p.stand_camera_height = _stand_camera_height
	p.slide_camera_height = _slide_camera_height
	p.crouch_camera_height = crouch_camera_height
	p.crouch_tilt = crouch_tilt
	p.look_ahead_amount = look_ahead_amount
	p.look_ahead_speed_threshold = look_ahead_speed_threshold
	return p

func _create_audio_params() -> PlayerAudioParams:
	var p := PlayerAudioParams.new()
	p.step_length = step_length
	p.land_volume_db_offset = land_volume_db_offset
	p.walk_sound = walk_sound
	p.land_sound = land_sound
	p.wind_sound = wind_sound
	p.walk_speed = walk_speed
	return p

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	body_mesh.visible = false
	if _collision_shape and _collision_shape.shape:
		_collision_shape.shape = _collision_shape.shape.duplicate()

	_state = PlayerState.new()

	var spawn_node := get_tree().get_first_node_in_group("spawn_point")
	if spawn_node and spawn_node is Node3D:
		_state.spawn_position = spawn_node.global_position
	else:
		_state.spawn_position = global_position
	global_position = _state.spawn_position

	_audio = PlayerAudio.new(self, _state)
	_audio.setup_params(_create_audio_params())

	_movement = PlayerMovement.new(self, _state)
	_movement.setup_params(_create_movement_params())
	_movement.on_landed = _audio_land
	_movement.on_init_land = _audio_init_land
	_movement.on_respawn = _audio_respawn
	_movement.on_die = _on_die

	_camera = PlayerCamera.new(self, _state)
	_camera.setup_params(_create_camera_params())
	_camera.init_camera()

	_ui = PlayerUI.new(self, _state)
	_shotgun = PlayerShotgun.new(self, _state)
	_shotgun.recoil_force = shotgun_recoil_force
	_shotgun.cooldown_time = shotgun_cooldown

	_state.has_shotgun = start_with_shotgun
	_update_shotgun_visibility()

	LevelState.level_completed.connect(_on_level_completed)
	_restart_btn.pressed.connect(_on_level_complete_restart)
	_next_btn.pressed.connect(_on_level_complete_next)

func _audio_land(fall_speed: float) -> void:
	_audio.play_land(fall_speed)

func _audio_init_land(fall_speed: float) -> void:
	_audio.play_land(fall_speed)

func _audio_respawn() -> void:
	_audio.play_land(25.0)

func _on_die() -> void:
	get_tree().paused = true
	RecordsManager.discard_recording()
	var layer := CanvasLayer.new()
	layer.layer = 100
	add_child(layer)
	var label := Label.new()
	label.text = "Упал"
	label.add_theme_font_size_override("font_size", 56)
	label.add_theme_color_override("font_color", Color(0.1, 0.1, 0.1))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.set_anchors_preset(Control.PRESET_CENTER)
	label.offset_left = -120
	label.offset_top = -28
	label.offset_right = 120
	label.offset_bottom = 28
	layer.add_child(label)
	_audio.play_land(18.0)
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_interval(0.7)
	tween.tween_callback(func() -> void:
		get_tree().paused = false
		get_tree().reload_current_scene()
	)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var sens := SettingsManager.get_mouse_sensitivity()
		_state.mouse_turn_accum += event.relative.x
		rotate_y(-event.relative.x * sens)
		_camera_pivot.rotate_x(-event.relative.y * sens)
		_camera_pivot.rotation.x = clampf(_camera_pivot.rotation.x, -1.5, 1.5)
	if event.is_action_released("slide"):
		_state.slide_requires_release = false
	if event is InputEventMouseButton and event.pressed and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta: float) -> void:
	var mouse_turn := _state.mouse_turn_accum
	_shotgun.process(delta)
	if _shotgun.fired_this_frame:
		_state.camera_recoil_pitch += recoil_pitch_amount
	_movement.process(delta)

	var low_profile: bool = _state and (_state.is_crouching or _state.is_sliding)
	if _collision_shape and _collision_shape.shape is CapsuleShape3D:
		var cap: CapsuleShape3D = _collision_shape.shape as CapsuleShape3D
		cap.height = crouch_capsule_height if low_profile else _STAND_CAPSULE_HEIGHT
		_collision_shape.position.y = cap.height * 0.5
	if body_mesh and body_mesh.mesh is CapsuleMesh:
		var mesh: CapsuleMesh = body_mesh.mesh as CapsuleMesh
		mesh.height = crouch_capsule_height if low_profile else _STAND_CAPSULE_HEIGHT
		body_mesh.position.y = mesh.height * 0.5

	velocity_changed.emit(velocity)
	mouse_turn_changed.emit(mouse_turn)

	var speed := Vector2(velocity.x, velocity.z).length()
	var on_floor := is_on_floor()
	var is_on_ramp := on_floor and get_floor_normal().y < 0.99
	var floor_surface := "воздух"
	if on_floor:
		floor_surface = "рампа" if is_on_ramp else "земля"

	_ui.update_hud(speed)
	_ui.update_state(speed, on_floor, is_on_ramp, floor_surface)

	_audio.update_wind(delta)
	_camera.update(delta, func(d: float, spd: float): _audio.update_footsteps(d, spd))

	var cam_pitch: float = _camera_pivot.rotation.x
	var fired: bool = _shotgun.fired_this_frame if _shotgun else false
	var sliding: bool = _state.is_sliding if _state else false
	var ledge_hanging: bool = _state.is_ledge_hanging if _state else false
	var on_wall: bool = _state.is_on_wall if _state else false
	var wall_normal: Vector3 = _state.wall_normal if _state else Vector3.ZERO
	var crouching: bool = _state.is_crouching if _state else false
	var capsule_center := global_position + Vector3(0, (_STAND_CAPSULE_HEIGHT if not low_profile else crouch_capsule_height) * 0.5, 0)
	RecordsManager.record_frame(capsule_center, rotation.y, cam_pitch, LevelState.current_time, delta, fired, sliding, crouching, ledge_hanging, on_wall, wall_normal, _state.has_shotgun)

func give_shotgun() -> void:
	_state.has_shotgun = true
	_update_shotgun_visibility()

func _update_shotgun_visibility() -> void:
	if _shotgun_node:
		_shotgun_node.visible = _state.has_shotgun
	if _crosshair:
		_crosshair.visible = true

func _on_level_completed(time: float, _is_new_record: bool) -> void:
	_ui.show_level_complete(time)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _on_level_complete_restart() -> void:
	get_tree().reload_current_scene()

func _on_level_complete_next() -> void:
	var next := LevelState.get_next_level_path()
	if next != "":
		get_tree().change_scene_to_file(next)
