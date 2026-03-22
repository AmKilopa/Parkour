class_name PlayerAudio
extends RefCounted

var player: CharacterBody3D
var state: PlayerState
var footstep_player: AudioStreamPlayer
var land_player: AudioStreamPlayer
var wind_player: AudioStreamPlayer

var step_length: float
var land_volume_db_offset: float
var walk_sound: AudioStream
var land_sound: AudioStream
var wind_sound: AudioStream
var walk_speed: float

var _wind_was_playing := false
var _wind_fade_timer := 0.0
var _land_cooldown := 0.0

func _init(p: CharacterBody3D, s: PlayerState) -> void:
	player = p
	state = s
	footstep_player = p.get_node_or_null(PlayerNodes.FOOTSTEP_PLAYER)
	land_player = p.get_node_or_null(PlayerNodes.LAND_PLAYER)
	wind_player = p.get_node_or_null(PlayerNodes.WIND_PLAYER)

func setup_params(params: PlayerAudioParams) -> void:
	step_length = params.step_length
	land_volume_db_offset = params.land_volume_db_offset
	walk_sound = params.walk_sound
	land_sound = params.land_sound
	wind_sound = params.wind_sound
	walk_speed = params.walk_speed

func play_land(fall_speed_override: float = -1.0) -> void:
	var fall_speed := fall_speed_override if fall_speed_override >= 0.0 else -state.prev_velocity_y
	if not land_sound or not land_player:
		return
	if _land_cooldown > 0.0:
		return
	_land_cooldown = 0.25
	land_player.stream = land_sound
	var fall_boost := clampf(fall_speed / 15.0, 0.0, 1.0) * 4.0
	land_player.volume_db = SettingsManager.get_sfx_volume_db() + land_volume_db_offset + fall_boost
	land_player.pitch_scale = randf_range(0.9, 1.1)
	land_player.play()

func update_footsteps(delta: float, speed: float) -> void:
	if state.is_sliding:
		state.step_timer = 0.0
		return
	var is_on_ramp := player.is_on_floor() and player.get_floor_normal().y < 0.99
	if is_on_ramp:
		state.step_timer = 0.0
		return
	var is_running: bool = speed > walk_speed * 1.2
	var interval := clampf(step_length / maxf(speed, 4.0), 0.28, 0.55)
	state.step_timer += delta
	if footstep_player and footstep_player.playing:
		return
	if state.step_timer >= interval:
		state.step_timer = 0.0
		if walk_sound and footstep_player:
			footstep_player.stream = walk_sound
			footstep_player.volume_db = SettingsManager.get_sfx_volume_db() - 12.0
			footstep_player.pitch_scale = randf_range(1.12, 1.28) if is_running else randf_range(0.92, 1.08)
			footstep_player.play()

func update_wind(delta: float) -> void:
	if _land_cooldown > 0.0:
		_land_cooldown -= delta
	var on_floor := player.is_on_floor()
	var horizontal_speed := Vector2(player.velocity.x, player.velocity.z).length()
	var fall_speed := -player.velocity.y
	var from_slide := state.is_sliding and horizontal_speed > 5.0
	var in_air_long_enough := state.air_time > 0.03
	var from_fall := fall_speed > 4.0 and not state.is_on_wall and in_air_long_enough
	var from_air_speed := not on_floor and horizontal_speed > 8.0 and in_air_long_enough and not state.is_on_wall
	var should_play := from_slide or from_fall or from_air_speed
	if should_play and wind_sound and wind_player:
		_wind_fade_timer = 0.0
		if not wind_player.playing:
			wind_player.stream = wind_sound
			wind_player.play()
		var t: float
		if from_slide or from_air_speed:
			t = clampf((horizontal_speed - 5.0) / 25.0, 0.0, 1.0)
		else:
			t = clampf((fall_speed - 4.0) / 20.0, 0.0, 1.0)
		wind_player.volume_db = SettingsManager.get_sfx_volume_db() + lerpf(-18.0, -6.0, t)
		wind_player.pitch_scale = lerpf(0.85, 1.15, t)
		_wind_was_playing = true
	elif wind_player and wind_player.playing and _wind_was_playing:
		_wind_fade_timer += delta
		var fade_dur := 0.12
		if _wind_fade_timer >= fade_dur:
			_stop_wind()
		else:
			wind_player.volume_db = lerpf(wind_player.volume_db, -40.0, delta / fade_dur * 4.0)
	else:
		_wind_fade_timer = 0.0
		if not wind_player or not wind_player.playing:
			_wind_was_playing = false

func _stop_wind() -> void:
	if _wind_was_playing and wind_player and wind_player.playing:
		wind_player.stop()
	_wind_was_playing = false
