class_name PlayerCamera
extends RefCounted

var player: CharacterBody3D
var state: PlayerState
var camera_pivot: Node3D
var camera_bob: Node3D
var camera: Camera3D

var bob_amount := 0.0
var bob_frequency := 0.0
var sway_amount := 0.0
var landing_bob := 0.0
var camera_smooth := 0.0
var slide_tilt := 0.0
var speed_shake_amount := 0.0
var idle_bob_amount := 0.0
var idle_bob_speed := 0.0
var wall_run_tilt := 0.0
var tilt_amount := 0.0
var long_jump_camera_tilt := 0.0
var long_jump_fov_boost := 0.0
var fov_default := 90.0
var fov_speed := 108.0
var speed_reference := 50.0
var walk_speed := 12.0
var stand_camera_height := 1.55
var slide_camera_height := 0.6
var crouch_camera_height := 0.9
var crouch_tilt := 0.08

var _base_camera_pos := Vector3.ZERO
var _base_camera_rot := Vector3.ZERO
var _current_bob_offset := Vector3.ZERO
var _current_sway_rot := Vector3.ZERO
var _bob_time := 0.0
var _idle_time := 0.0
var _tilt_accum := 0.0
var _current_fov := 90.0
var _move_speed_smooth := 0.0
var _step_timer := 0.0
var _recoil_pitch := 0.0
var _look_ahead_offset := Vector3.ZERO
var look_ahead_amount := 0.04
var look_ahead_speed_threshold := 25.0
const LANDING_BOB_FALL_SCALE := 8.0
const RECOIL_DECAY := 8.0

func _init(p: CharacterBody3D, s: PlayerState) -> void:
	player = p
	state = s
	camera_pivot = p.get_node_or_null(PlayerNodes.CAMERA_PIVOT)
	camera_bob = p.get_node_or_null(PlayerNodes.CAMERA_BOB)
	camera = p.get_node_or_null(PlayerNodes.CAMERA_3D)

func setup_params(params: PlayerCameraParams) -> void:
	bob_amount = params.bob_amount
	bob_frequency = params.bob_frequency
	sway_amount = params.sway_amount
	landing_bob = params.landing_bob
	camera_smooth = params.camera_smooth
	slide_tilt = params.slide_tilt
	speed_shake_amount = params.speed_shake_amount
	idle_bob_amount = params.idle_bob_amount
	idle_bob_speed = params.idle_bob_speed
	wall_run_tilt = params.wall_run_tilt
	tilt_amount = params.tilt_amount
	long_jump_camera_tilt = params.long_jump_camera_tilt
	long_jump_fov_boost = params.long_jump_fov_boost
	fov_default = params.fov_default
	fov_speed = params.fov_speed
	speed_reference = params.speed_reference
	walk_speed = params.walk_speed
	stand_camera_height = params.stand_camera_height
	slide_camera_height = params.slide_camera_height
	crouch_camera_height = params.crouch_camera_height
	crouch_tilt = params.crouch_tilt
	look_ahead_amount = params.look_ahead_amount
	look_ahead_speed_threshold = params.look_ahead_speed_threshold

func init_camera() -> void:
	if camera_bob:
		_base_camera_pos = camera_bob.position
		_base_camera_rot = camera_bob.rotation
	if camera:
		_current_fov = fov_default
		camera.fov = _current_fov

func _get_horizontal_velocity() -> Vector2:
	return Vector2(player.velocity.x, player.velocity.z)

func _is_on_ramp_floor(floor_normal: Vector3) -> bool:
	return floor_normal.y < 0.99

func update(delta: float, on_footstep: Callable) -> void:
	if not camera_pivot or not camera_bob or not camera:
		return

	var horizontal_velocity := _get_horizontal_velocity()
	var speed := horizontal_velocity.length()
	var on_floor := player.is_on_floor()
	var is_on_ramp := on_floor and _is_on_ramp_floor(player.get_floor_normal())
	var grounded := on_floor or state.grounded_frames > 0
	var speed_threshold := 0.3 if is_on_ramp else 0.5
	var is_moving := (speed > speed_threshold and grounded and not state.is_sliding) or (state.is_on_wall and speed > speed_threshold)

	if is_moving:
		state.move_speed_smooth = lerpf(state.move_speed_smooth, speed, 1.0 - exp(-12.0 * delta))
		_bob_time += delta * bob_frequency * (speed / walk_speed)
		if on_footstep.is_valid():
			on_footstep.call(delta, speed)
	else:
		state.move_speed_smooth = lerpf(state.move_speed_smooth, 0.0, 1.0 - exp(-8.0 * delta))
		_step_timer = 0.0

	var target_bob := Vector3.ZERO
	var target_sway := Vector3.ZERO

	if not is_moving and grounded and not state.is_sliding:
		_idle_time += delta * idle_bob_speed
		target_bob.y = sin(_idle_time) * idle_bob_amount
		target_bob.x = cos(_idle_time * 0.7) * idle_bob_amount * 0.6

	if is_moving:
		target_bob.y = sin(_bob_time) * bob_amount
		target_bob.x = cos(_bob_time * 0.5) * bob_amount * 0.5
		var move_dir := horizontal_velocity.normalized()
		target_sway.z = -move_dir.x * sway_amount
		target_sway.x = move_dir.y * sway_amount * 0.3

	if state.landing_bob_timer > 0:
		var t := 1.0 - state.landing_bob_timer / 0.25
		var fall_scale := clampf(state.landing_fall_speed / LANDING_BOB_FALL_SCALE, 0.5, 2.5)
		target_bob.y -= sin(t * PI) * landing_bob * fall_scale
		state.landing_bob_timer -= delta

	_tilt_accum -= state.mouse_turn_accum * tilt_amount
	_tilt_accum = clampf(_tilt_accum, -0.12, 0.12)
	_tilt_accum = lerpf(_tilt_accum, 0.0, 1.0 - exp(-5.0 * delta))
	target_sway.y = _tilt_accum

	_recoil_pitch += state.camera_recoil_pitch
	state.camera_recoil_pitch = 0.0
	_recoil_pitch = lerpf(_recoil_pitch, 0.0, 1.0 - exp(-RECOIL_DECAY * delta))
	target_sway.x -= _recoil_pitch

	if state.is_sliding:
		target_sway.x += slide_tilt
	elif state.is_crouching:
		target_sway.x += crouch_tilt

	if state.is_on_wall:
		var wall_roll: float
		if abs(state.wall_normal.x) >= 0.1:
			wall_roll = float(-sign(state.wall_normal.x)) * wall_run_tilt
		else:
			wall_roll = float(sign(state.wall_normal.z)) * wall_run_tilt
		target_sway.z += wall_roll

	if state.long_jump_camera_timer > 0:
		var t := state.long_jump_camera_timer / 0.8
		target_sway.x += long_jump_camera_tilt * t

	var smooth := 1.0 - exp(-camera_smooth * delta)
	_current_bob_offset = _current_bob_offset.lerp(target_bob, smooth)
	_current_sway_rot = _current_sway_rot.lerp(target_sway, smooth)

	var speed_shake := Vector3.ZERO
	if speed > speed_reference * 0.6:
		var shake_range := maxf(speed_reference * 0.4, 0.1)
		var shake_t := clampf((speed - speed_reference * 0.6) / shake_range, 0.0, 1.0)
		var t := Time.get_ticks_msec() * 0.01
		speed_shake = Vector3(sin(t * 12.3) * 0.5 + sin(t * 7.1) * 0.5, cos(t * 9.7) * 0.5 + cos(t * 11.2) * 0.5, 0) * speed_shake_amount * shake_t

	var look_ahead := Vector3.ZERO
	if speed > look_ahead_speed_threshold and horizontal_velocity.length_squared() > 0.01:
		var world_vel := Vector3(horizontal_velocity.x, 0.0, horizontal_velocity.y)
		var local_vel := player.global_transform.basis.inverse() * world_vel
		local_vel.y = 0.0
		if local_vel.length_squared() > 0.01:
			var look_t := clampf((speed - look_ahead_speed_threshold) / 30.0, 0.0, 1.0)
			look_ahead = local_vel.normalized() * look_ahead_amount * look_t
	_look_ahead_offset = lerp(_look_ahead_offset, look_ahead, 1.0 - exp(-6.0 * delta))

	camera_bob.position = _base_camera_pos + _current_bob_offset + speed_shake + _look_ahead_offset
	camera_bob.rotation = _base_camera_rot + _current_sway_rot

	var target_height: float
	if state.is_sliding:
		target_height = slide_camera_height
	elif state.is_crouching:
		target_height = crouch_camera_height
	else:
		target_height = stand_camera_height
	var height_smooth := 1.0 - exp(-8.0 * delta)
	camera_pivot.position.y = lerpf(camera_pivot.position.y, target_height, height_smooth)

	fov_default = clampf(SettingsManager.get_fov_default(), 1.0, 179.0)
	fov_speed = clampf(SettingsManager.get_fov_speed(), 1.0, 179.0)
	var speed_t := clampf(speed / maxf(speed_reference, 0.1), 0.0, 1.0)
	var target_fov := fov_default
	if state.is_sliding:
		target_fov = lerpf(fov_default, fov_speed, speed_t)
	elif on_floor and is_moving:
		target_fov = lerpf(fov_default, fov_speed, speed_t)
	elif state.is_on_wall:
		target_fov = lerpf(fov_default, fov_speed, clampf(speed_t, 0.0, 0.7))
	elif not on_floor and speed > walk_speed:
		var fov_range := maxf(speed_reference - walk_speed, 0.1)
		target_fov = lerpf(fov_default, fov_speed, clampf((speed - walk_speed) / fov_range, 0.0, 0.8))
	if state.long_jump_camera_timer > 0:
		var t := state.long_jump_camera_timer / 0.8
		target_fov += long_jump_fov_boost * t
	var fall_fov := 0.0
	if not on_floor and player.velocity.y < -15.0:
		fall_fov = clampf((-player.velocity.y - 15.0) / 25.0, 0.0, 1.0) * 6.0
	target_fov += fall_fov
	_current_fov = lerpf(_current_fov, target_fov, 1.0 - exp(-10.0 * delta))
	camera.fov = clampf(_current_fov, 1.0, 179.0)
