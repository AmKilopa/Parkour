class_name PlayerMovement
extends RefCounted

const SLOPE_FLAT_THRESHOLD := 0.99
const WALL_NORMAL_Y_THRESHOLD := 0.7
const GRAVITY := 9.8
const SLOPE_DOT_THRESHOLD := 0.25
const MIN_SLOPE_LENGTH := 0.05
const WALL_RAYCAST_DIST := 1.2
const WALL_RAYCAST_HEIGHT := 0.5
const GROUND_RAYCAST_DIST := 1.8
const COYOTE_RAYCAST_DIST := 0.4
const EDGE_RAYCAST_DIST := 1.2
const EDGE_DROP_MIN := 0.6
const LEDGE_CHEST_OFFSET := 1.0
const LEDGE_UP_CHECK := 0.6
const LEDGE_DOWN_CHECK := 1.0
const LEDGE_WALL_NORMAL_Y_MAX := 0.6
const LEDGE_TOP_NORMAL_Y_MIN := 0.85
const LEDGE_HANG_DROP := 0.25

var player: CharacterBody3D
var state: PlayerState
var on_landed: Callable
var on_init_land: Callable
var on_respawn: Callable
var on_die: Callable

var walk_speed: float
var speed_reference: float
var air_acceleration: float
var air_drag: float
var air_control: float
var ground_friction: float
var jump_velocity: float
var coyote_time: float
var jump_buffer_time: float
var slide_friction_slow: float
var slide_friction_fast: float
var slide_fast_threshold: float
var slide_accel: float
var slide_min_speed: float
var slide_max_distance_stand: float
var slide_max_time_stand: float
var slide_landing_boost: float
var slide_steer: float
var slide_end_cooldown: float
var slide_ramp_landing_boost: float
var slope_accel_stand: float
var slope_accel_slide: float
var ramp_launch_base: float
var ramp_launch_speed_factor: float
var ramp_launch_max_vy: float
var ramp_launch_min_speed: float
var ramp_climb_speed: float
var wall_run_min_speed: float
var wall_run_gravity: float
var wall_jump_velocity: float
var void_y: float
var long_jump_prep_window: float
var long_jump_horizontal: float
var long_jump_vertical: float
var ledge_grab_reach: float
var ledge_hang_max_time: float
var mantle_velocity: float
var mantle_windup_time: float
var crouch_walk_speed_multiplier: float
var crouch_capsule_height: float

func _init(p: CharacterBody3D, s: PlayerState) -> void:
	player = p
	state = s

func setup_params(params: PlayerMovementParams) -> void:
	walk_speed = params.walk_speed
	speed_reference = params.speed_reference
	air_acceleration = params.air_acceleration
	air_drag = params.air_drag
	air_control = params.air_control
	ground_friction = params.ground_friction
	jump_velocity = params.jump_velocity
	coyote_time = params.coyote_time
	jump_buffer_time = params.jump_buffer_time
	slide_friction_slow = params.slide_friction_slow
	slide_friction_fast = params.slide_friction_fast
	slide_fast_threshold = params.slide_fast_threshold
	slide_accel = params.slide_accel
	slide_min_speed = params.slide_min_speed
	slide_max_distance_stand = params.slide_max_distance_stand
	slide_max_time_stand = params.slide_max_time_stand
	slide_landing_boost = params.slide_landing_boost
	slide_steer = params.slide_steer
	slide_end_cooldown = params.slide_end_cooldown
	slide_ramp_landing_boost = params.slide_ramp_landing_boost
	slope_accel_stand = params.slope_accel_stand
	slope_accel_slide = params.slope_accel_slide
	ramp_launch_base = params.ramp_launch_base
	ramp_launch_speed_factor = params.ramp_launch_speed_factor
	ramp_launch_max_vy = params.ramp_launch_max_vy
	ramp_launch_min_speed = params.ramp_launch_min_speed
	ramp_climb_speed = params.ramp_climb_speed
	wall_run_min_speed = params.wall_run_min_speed
	wall_run_gravity = params.wall_run_gravity
	wall_jump_velocity = params.wall_jump_velocity
	void_y = params.void_y
	long_jump_prep_window = params.long_jump_prep_window
	long_jump_horizontal = params.long_jump_horizontal
	long_jump_vertical = params.long_jump_vertical
	ledge_grab_reach = params.ledge_grab_reach
	ledge_hang_max_time = params.ledge_hang_max_time
	mantle_velocity = params.mantle_velocity
	mantle_windup_time = params.mantle_windup_time
	crouch_walk_speed_multiplier = params.crouch_walk_speed_multiplier
	crouch_capsule_height = params.crouch_capsule_height

func _clamp_explosion_velocity() -> void:
	var hv := _get_horizontal_velocity()
	var speed_h := hv.length()
	if speed_h > 150.0:
		var scale_down := 150.0 / speed_h
		player.velocity.x *= scale_down
		player.velocity.z *= scale_down
	var vy := player.velocity.y
	if vy > 100.0:
		player.velocity.y = 100.0
	elif vy < -100.0:
		player.velocity.y = -100.0

func _get_forward_2d() -> Vector2:
	var fwd := -player.global_transform.basis.z
	return Vector2(fwd.x, fwd.z).normalized()

func _get_slope_down_2d(floor_normal: Vector3) -> Vector2:
	var slope_down := Vector3(0, -1, 0) - floor_normal * floor_normal.dot(Vector3(0, -1, 0))
	if slope_down.length() <= MIN_SLOPE_LENGTH:
		return _get_forward_2d()
	return Vector2(slope_down.x, slope_down.z).normalized()

func _get_horizontal_velocity() -> Vector2:
	return Vector2(player.velocity.x, player.velocity.z)

func _is_on_ramp_floor(floor_normal: Vector3) -> bool:
	return floor_normal.y < SLOPE_FLAT_THRESHOLD

func _is_at_edge() -> bool:
	var space_state := player.get_world_3d().direct_space_state
	if not space_state:
		return false
	var fwd := -player.global_transform.basis.z
	var fwd_h := Vector3(fwd.x, 0, fwd.z)
	if fwd_h.length() < 0.01:
		return false
	fwd_h = fwd_h.normalized()
	var origin := player.global_position + Vector3(0, 0.2, 0) + fwd_h * 0.4
	var query := PhysicsRayQueryParameters3D.create(origin, origin + Vector3.DOWN * 2.5)
	query.exclude = [player.get_rid()]
	var result := space_state.intersect_ray(query)
	if result.is_empty():
		return true
	var dist := origin.distance_to(result.position)
	return dist > EDGE_DROP_MIN

func _raycast_ground() -> Dictionary:
	var result := {"hit": false, "normal": Vector3.UP, "distance": INF, "is_ramp": false}
	var space_state := player.get_world_3d().direct_space_state
	if not space_state:
		return result
	var origin := player.global_position + Vector3.UP * 0.5
	var query := PhysicsRayQueryParameters3D.create(origin, origin + Vector3.DOWN * GROUND_RAYCAST_DIST)
	query.exclude = [player.get_rid()]
	var ray_result := space_state.intersect_ray(query)
	if ray_result.is_empty():
		return result
	result.hit = true
	result.normal = ray_result.normal
	result.distance = origin.distance_to(ray_result.position)
	var col = ray_result.collider
	result.is_ramp = col != null and col.is_in_group("ramp")
	return result

func _try_detect_ledge() -> Dictionary:
	var result := {"hit": false, "ledge_pos": Vector3.ZERO, "ledge_normal": Vector3.UP, "wall_normal": Vector3.ZERO}
	var space_state := player.get_world_3d().direct_space_state
	if not space_state:
		return result
	var fwd := -player.global_transform.basis.z
	var fwd_h := Vector3(fwd.x, 0, fwd.z)
	if fwd_h.length() < 0.01:
		return result
	fwd_h = fwd_h.normalized()
	var origin := player.global_position + Vector3(0, LEDGE_CHEST_OFFSET, 0)
	var query := PhysicsRayQueryParameters3D.create(origin, origin + fwd_h * ledge_grab_reach)
	query.exclude = [player.get_rid()]
	var wall_hit := space_state.intersect_ray(query)
	if wall_hit.is_empty():
		return result
	var wall_normal: Vector3 = wall_hit.normal
	if wall_normal.y > LEDGE_WALL_NORMAL_Y_MAX:
		return result
	var wall_pos: Vector3 = wall_hit.position
	var ledge_pos: Vector3
	var ledge_normal: Vector3 = Vector3.UP
	var check_origin := wall_pos + Vector3(0, LEDGE_UP_CHECK, 0)
	var check_end := check_origin + Vector3(0, -LEDGE_DOWN_CHECK - 0.5, 0)
	var query_down := PhysicsRayQueryParameters3D.create(check_origin, check_end)
	query_down.exclude = [player.get_rid()]
	var ledge_hit := space_state.intersect_ray(query_down)
	if not ledge_hit.is_empty():
		var ln: Vector3 = ledge_hit.normal
		if ln.y >= LEDGE_TOP_NORMAL_Y_MIN:
			ledge_pos = ledge_hit.position
			ledge_normal = ln
	if ledge_pos == Vector3.ZERO:
		var col = wall_hit.collider
		if col is Node3D:
			var shape_node: CollisionShape3D = col.get_node_or_null("CollisionShape3D")
			if shape_node and shape_node.shape is BoxShape3D:
				var box: BoxShape3D = shape_node.shape as BoxShape3D
				var half_h := box.size.y * 0.5
				var top_pt: Vector3 = (col as Node3D).global_transform * Vector3(0, half_h, 0)
				ledge_pos = Vector3(wall_pos.x, top_pt.y, wall_pos.z)
				ledge_normal = Vector3.UP
	var player_feet_y := player.global_position.y
	if ledge_pos == Vector3.ZERO or ledge_pos.y <= player_feet_y + 0.2:
		return result
	if ledge_pos.y > player_feet_y + 2.0:
		return result
	result.hit = true
	result.ledge_pos = ledge_pos
	result.ledge_normal = ledge_normal
	result.wall_normal = wall_normal
	return result

func _detect_wall_raycast() -> void:
	state.is_on_wall = false
	state.wall_normal = Vector3.ZERO
	var space_state := player.get_world_3d().direct_space_state
	if not space_state:
		return
	var origin := player.global_position + Vector3.UP * WALL_RAYCAST_HEIGHT
	var hv := _get_horizontal_velocity()
	var speed := hv.length()
	if speed < wall_run_min_speed:
		return
	var dir_2d: Vector2
	if speed > 0.5:
		dir_2d = hv.normalized()
	else:
		dir_2d = Vector2(-player.global_transform.basis.z.x, -player.global_transform.basis.z.z).normalized()
	var directions: Array[Vector3] = [
		Vector3(-dir_2d.y, 0, dir_2d.x),
		Vector3(dir_2d.y, 0, -dir_2d.x),
		Vector3(-dir_2d.y, 0, dir_2d.x) + Vector3(dir_2d.x, 0, dir_2d.y),
		Vector3(dir_2d.y, 0, -dir_2d.x) + Vector3(dir_2d.x, 0, dir_2d.y)
	]
	for d in directions:
		if d.length() < 0.1:
			continue
		d = d.normalized()
		var query := PhysicsRayQueryParameters3D.create(origin, origin + d * WALL_RAYCAST_DIST)
		query.exclude = [player.get_rid()]
		var result := space_state.intersect_ray(query)
		if result.is_empty():
			continue
		var n: Vector3 = result.normal
		if abs(n.y) >= WALL_NORMAL_Y_THRESHOLD:
			continue
		var collider = result.collider
		var cid: int = collider.get_instance_id() if collider else -1
		if cid == state.last_wall_jump_from:
			continue
		state.is_on_wall = true
		state.wall_normal = n
		state.wall_collider_id = cid
		state.wall_coyote_timer = 0.2
		return

const STAND_CAPSULE_HEIGHT := 1.75

func _can_stand_up() -> bool:
	var space_state := player.get_world_3d().direct_space_state
	if not space_state:
		return true
	var origin := player.global_position + Vector3(0, crouch_capsule_height, 0)
	var cast_dist := STAND_CAPSULE_HEIGHT - crouch_capsule_height
	var query := PhysicsRayQueryParameters3D.create(origin, origin + Vector3(0, cast_dist, 0))
	query.exclude = [player.get_rid()]
	return space_state.intersect_ray(query).is_empty()

func _start_slide(from_air: bool) -> void:
	state.is_sliding = true
	state.slide_from_air = from_air
	state.slide_grace = 0.06
	state.slide_distance = 0.0
	state.slide_time = 0.0

func process(delta: float) -> void:
	if state.is_dead:
		return
	if LevelState.is_level_complete:
		player.velocity = Vector3.ZERO
		return

	if state.ledge_grab_cooldown > 0:
		state.ledge_grab_cooldown -= delta

	if state.is_ledge_hanging:
		player.velocity = Vector3.ZERO
		state.ledge_hang_timer += delta

		if state.mantle_windup_timer > 0:
			state.mantle_windup_timer -= delta
			var windup_t := 1.0 - state.mantle_windup_timer / mantle_windup_time
			windup_t = windup_t * windup_t * (3.0 - 2.0 * windup_t)
			player.global_position = state.ledge_hang_pos.lerp(state.ledge_mantle_target, windup_t)
			if state.mantle_windup_timer <= 0:
				state.is_ledge_hanging = false
				state.ledge_hang_timer = 0.0
				var fwd := Vector3(-state.ledge_wall_normal.x, 0, -state.ledge_wall_normal.z)
				if fwd.length() < 0.1:
					fwd = -player.global_transform.basis.z
				fwd = fwd.normalized()
				var up_fwd := (Vector3(0, 2.2, 0) + fwd * 0.6).normalized()
				player.velocity = up_fwd * mantle_velocity
		elif Input.is_action_just_pressed("jump"):
			state.mantle_windup_timer = mantle_windup_time
		else:
			player.global_position = state.ledge_hang_pos
			if state.ledge_hang_timer >= ledge_hang_max_time:
				state.is_ledge_hanging = false
				state.ledge_hang_timer = 0.0
				state.ledge_grab_cooldown = 0.5
				player.velocity = Vector3.ZERO
		player.move_and_slide()
		state.mouse_turn_accum = 0.0
		return

	player.velocity += state.recoil_impulse
	state.recoil_impulse = Vector3.ZERO
	_clamp_explosion_velocity()
	var on_floor := player.is_on_floor()
	var is_on_ramp := on_floor and _is_on_ramp_floor(player.get_floor_normal())

	player.floor_constant_speed = is_on_ramp

	if state.slide_force_zero_next:
		player.velocity.x = 0
		player.velocity.z = 0
		state.slide_force_zero_next = false

	var just_landed := state.was_in_air and on_floor
	var just_left_floor := not state.was_in_air and not on_floor

	if is_on_ramp:
		state.slide_requires_release = false
		state.slide_air_grace = 0.0
	elif state.is_sliding:
		if just_left_floor:
			state.slide_air_grace = 0.2
		else:
			state.slide_air_grace -= delta

	if on_floor:
		state.is_ledge_hanging = false
		state.ledge_hang_timer = 0.0
		state.mantle_windup_timer = 0.0
		state.air_time = 0.0
		state.ramp_launch_applied = false
		state.long_jump_camera_timer = 0.0
		if is_on_ramp:
			state.ramp_contact_time += delta
			if state.ramp_contact_time > 0.5:
				state.ramp_landed_from_fall = false
		else:
			state.ramp_contact_time = 0.0
		state.coyote_timer = coyote_time
		state.is_on_wall = false
		state.last_wall_jump_from = -1
		state.wall_jump_grace = 0.0
		state.wall_coyote_timer = 0.0
		if state.prev_velocity_y < -3.0:
			state.landing_bob_timer = 0.25
			state.landing_fall_speed = -state.prev_velocity_y
		if just_landed:
			if is_on_ramp and state.prev_velocity_y < -4.0:
				state.ramp_landed_from_fall = true
			else:
				state.ramp_landed_from_fall = false
			state.landing_speed = _get_horizontal_velocity().length()
			state.landing_speed_timer = 0.4
			if not is_on_ramp and on_landed.is_valid():
				on_landed.call(-1.0)
		elif not state.has_played_initial_land:
			if not is_on_ramp and on_init_land.is_valid():
				on_init_land.call(5.0)
			state.has_played_initial_land = true
			if state.is_sliding and is_on_ramp and state.landing_speed > 3.0:
				var hv := _get_horizontal_velocity() * slide_ramp_landing_boost
				player.velocity.x = hv.x
				player.velocity.z = hv.y
		if just_landed and Input.is_action_pressed("slide") and (not state.slide_requires_release or is_on_ramp):
			_start_slide(true)
			var spd := _get_horizontal_velocity().length()
			var fwd2 := _get_forward_2d()
			var boost := slide_ramp_landing_boost if is_on_ramp else 1.0
			spd *= boost
			if fwd2.length_squared() > 0.01:
				player.velocity.x = fwd2.x * spd
				player.velocity.z = fwd2.y * spd
	else:
		state.coyote_timer -= delta
		if state.coyote_timer < coyote_time * 0.5:
			var ground := _raycast_ground()
			if ground.hit and ground.distance < COYOTE_RAYCAST_DIST:
				state.coyote_timer = coyote_time

	state.was_in_air = not on_floor
	state.prev_velocity_y = player.velocity.y
	if on_floor:
		state.grounded_frames = 3 if (on_floor and _is_on_ramp_floor(player.get_floor_normal())) else 2
	else:
		state.grounded_frames = maxi(0, state.grounded_frames - 1)

	if Input.is_action_just_pressed("jump"):
		state.jump_buffer_timer = jump_buffer_time
	state.jump_buffer_timer -= delta

	if Input.is_action_just_pressed("long_jump_prep"):
		state.long_jump_prep_timer = long_jump_prep_window
	if state.long_jump_prep_timer > 0:
		state.long_jump_prep_timer -= delta
	if state.long_jump_just_done > 0:
		state.long_jump_just_done -= delta
	if state.long_jump_camera_timer > 0:
		state.long_jump_camera_timer -= delta

	state.at_edge = on_floor and not is_on_ramp and _is_at_edge()

	if not on_floor:
		if state.wall_coyote_timer > 0:
			state.wall_coyote_timer -= delta
		if state.is_on_wall:
			player.velocity.y -= wall_run_gravity * delta
			var push := Vector3(state.wall_normal.x, 0, state.wall_normal.z)
			if push.length() > 0.1:
				push = push.normalized() * 2.0 * delta
				player.velocity.x -= push.x
				player.velocity.z -= push.z
		else:
			player.velocity.y -= GRAVITY * delta

		if not state.is_sliding and state.wall_jump_grace <= 0 and state.ledge_grab_cooldown <= 0:
			if player.velocity.y <= 2.0:
				var ledge := _try_detect_ledge()
				if ledge.hit and Input.is_action_pressed("long_jump_prep"):
					LevelState.deduct_score(4)
					state.is_ledge_hanging = true
					state.ledge_hang_timer = 0.0
					state.ledge_position = ledge.ledge_pos
					state.ledge_normal = ledge.ledge_normal
					state.ledge_wall_normal = ledge.wall_normal
					state.mantle_windup_timer = 0.0
					var wall_n: Vector3 = ledge.wall_normal
					var edge_off := Vector3(wall_n.x, 0, wall_n.z)
					if edge_off.length() > 0.1:
						edge_off = edge_off.normalized() * 0.25
					var grab_pos: Vector3 = ledge.ledge_pos + edge_off
					state.ledge_hang_pos = Vector3(grab_pos.x, ledge.ledge_pos.y - LEDGE_CHEST_OFFSET - 0.35 - LEDGE_HANG_DROP, grab_pos.z)
					state.ledge_initial_pos = state.ledge_hang_pos
					state.ledge_mantle_target = Vector3(grab_pos.x, ledge.ledge_pos.y, grab_pos.z)
					state.ledge_pullup_time = 0.0
					player.global_position = state.ledge_hang_pos
					player.velocity = Vector3.ZERO

	var input_dir := Vector2(
		float(Input.is_action_pressed("move_right")) - float(Input.is_action_pressed("move_left")),
		float(Input.is_action_pressed("move_back")) - float(Input.is_action_pressed("move_forward"))
	)
	if input_dir.length() > 1.0:
		input_dir = input_dir.normalized()
	var direction := Vector3.ZERO
	if input_dir.length_squared() > 0.01:
		direction = (player.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	var can_wall_jump := state.is_on_wall or state.wall_coyote_timer > 0
	var jump_requested := state.jump_buffer_timer > 0 or Input.is_action_just_pressed("jump") or Input.is_action_pressed("jump")
	var can_slide_jump := state.is_sliding and (on_floor or state.slide_air_grace > 0)
	var can_jump := jump_requested and (state.coyote_timer > 0 or can_wall_jump or can_slide_jump)
	var jump_allowed := (not is_on_ramp) or state.is_sliding or can_wall_jump

	if can_jump and jump_allowed:
		if can_wall_jump and state.wall_normal.length() > 0.1:
			LevelState.deduct_score(2)
			var camera: Camera3D = player.get_node_or_null("CameraPivot/CameraBob/Camera3D")
			var look_fwd := -camera.global_transform.basis.z if camera else -player.global_transform.basis.z
			var look_h := Vector3(look_fwd.x, 0, look_fwd.z)
			if look_h.length() < 0.01:
				look_h = Vector3(-player.transform.basis.z.x, 0, -player.transform.basis.z.z)
			look_h = look_h.normalized()
			var jump_dir := (look_h * 1.5 + Vector3(0, 0.85, 0)).normalized()
			player.velocity = jump_dir * wall_jump_velocity
			state.wall_jump_grace = 0.7
			state.wall_coyote_timer = 0.0
			state.last_wall_jump_from = state.wall_collider_id
		elif not is_on_ramp and state.long_jump_prep_timer > 0 and _is_at_edge():
			var fwd := -player.global_transform.basis.z
			var fwd_h := Vector3(fwd.x, 0, fwd.z)
			if fwd_h.length() < 0.01:
				fwd_h = Vector3(-player.transform.basis.z.x, 0, -player.transform.basis.z.z)
			fwd_h = fwd_h.normalized()
			player.velocity.x = fwd_h.x * long_jump_horizontal
			player.velocity.y = long_jump_vertical
			player.velocity.z = fwd_h.z * long_jump_horizontal
			state.long_jump_prep_timer = 0.0
			state.long_jump_just_done = 0.5
			state.long_jump_camera_timer = 0.8
			LevelState.deduct_score(2)
		elif state.is_sliding:

			var hv := _get_horizontal_velocity()
			var spd := hv.length()
			var slide_jump_boost := 1.15
			if spd > 0.5:
				var dir_2d: Vector2
				var fwd2 := _get_forward_2d()
				if fwd2.length_squared() > 0.01 and hv.normalized().dot(fwd2) > 0.3:
					dir_2d = fwd2.normalized()
				else:
					dir_2d = hv.normalized()
				var new_spd := minf(spd * slide_jump_boost, speed_reference * 0.85)
				player.velocity.x = dir_2d.x * new_spd
				player.velocity.z = dir_2d.y * new_spd
			player.velocity.y = jump_velocity
		else:
			LevelState.deduct_score(1)

			var hv := _get_horizontal_velocity()
			var spd := hv.length()
			if state.landing_speed_timer > 0 and state.landing_speed > walk_speed and direction.length_squared() > 0.01:
				var preserve_spd := maxf(spd, state.landing_speed * 0.92)
				preserve_spd = minf(preserve_spd, speed_reference * 0.9)
				var dir_2d := Vector2(direction.x, direction.z).normalized()
				if hv.length_squared() > 0.25 and hv.normalized().dot(dir_2d) > 0.5:
					player.velocity.x = dir_2d.x * preserve_spd
					player.velocity.z = dir_2d.y * preserve_spd
			player.velocity.y = jump_velocity
		state.jump_buffer_timer = 0
		state.coyote_timer = 0
		state.long_jump_prep_timer = 0.0
		state.is_sliding = false
		state.is_on_wall = false
		state.slide_cooldown = slide_end_cooldown
		if Input.is_action_pressed("slide"):
			state.slide_requires_release = true

	if on_floor and Input.is_action_pressed("slide") and not state.is_sliding and not just_landed and state.slide_cooldown <= 0 and (not state.slide_requires_release or is_on_ramp):
		var hv := _get_horizontal_velocity()
		var spd := hv.length()
		if state.landing_speed_timer > 0 and state.landing_speed > 5.0:
			_start_slide(false)
			var boost := maxf(spd, state.landing_speed * slide_landing_boost)
			if is_on_ramp:
				boost *= slide_ramp_landing_boost
			var fwd2 := _get_forward_2d()
			player.velocity.x = fwd2.x * boost
			player.velocity.z = fwd2.y * boost
			state.landing_speed_timer = 0.0
		elif spd >= slide_min_speed:
			var fwd2 := _get_forward_2d()
			var dot := hv.normalized().dot(fwd2) if spd > 0.5 else 1.0
			if dot > 0.3:
				_start_slide(false)
				player.velocity.x = fwd2.x * spd
				player.velocity.z = fwd2.y * spd
		else:
			var fn := player.get_floor_normal()
			var slide_dir := _get_slope_down_2d(fn) if _is_on_ramp_floor(fn) else _get_forward_2d()
			_start_slide(false)
			var start_spd := walk_speed * 0.35 if fn.y >= SLOPE_FLAT_THRESHOLD else maxf(5.0, spd * 0.8)
			player.velocity.x = slide_dir.x * start_spd
			player.velocity.z = slide_dir.y * start_spd

	if state.landing_speed_timer > 0:
		state.landing_speed_timer -= delta
	if state.slide_cooldown > 0:
		state.slide_cooldown -= delta

	if on_floor and not state.is_sliding:
		if Input.is_action_pressed("crouch"):
			state.is_crouching = true
		elif Input.is_action_just_released("crouch"):
			if _can_stand_up():
				state.is_crouching = false
	else:
		if not on_floor:
			state.is_crouching = false

	var horizontal_velocity := _get_horizontal_velocity()
	var current_speed := horizontal_velocity.length()

	var rolling_down := false
	var sliding_up_ramp := false
	if on_floor and is_on_ramp:
		var slope_2d := _get_slope_down_2d(player.get_floor_normal())
		var dot_slope := horizontal_velocity.normalized().dot(slope_2d) if current_speed > 0.5 else 1.0
		if dot_slope > SLOPE_DOT_THRESHOLD:
			rolling_down = true
		elif dot_slope < -SLOPE_DOT_THRESHOLD:
			sliding_up_ramp = true

	if state.is_sliding and on_floor:
		state.slide_distance += current_speed * delta
		state.slide_time += delta

	if state.is_sliding:
		var should_end := false
		var force_stop := false
		var released_c := false
		if not Input.is_action_pressed("slide"):
			should_end = true
			released_c = true
		elif on_floor and not is_on_ramp and state.slide_air_grace <= 0:
			if state.slide_grace <= 0 and current_speed < slide_min_speed:
				should_end = true
				force_stop = true
			elif not state.slide_from_air and not rolling_down:
				if state.slide_distance >= slide_max_distance_stand or state.slide_time >= slide_max_time_stand:
					should_end = true
					force_stop = true
		if should_end:
			state.is_sliding = false
			state.slide_from_air = false
			state.slide_distance = 0
			state.slide_time = 0
			state.slide_cooldown = slide_end_cooldown
			state.slide_air_grace = 0.0
			if not released_c and force_stop and on_floor and not is_on_ramp:
				state.slide_requires_release = true
			elif released_c:
				state.slide_requires_release = false
			if force_stop:
				player.velocity.x = 0
				player.velocity.z = 0
				state.slide_force_zero_next = true

	if on_floor:
		var floor_normal := player.get_floor_normal()
		if _is_on_ramp_floor(floor_normal):
			var slope_2d := _get_slope_down_2d(floor_normal)
			var vel_2d := horizontal_velocity
			var dot_slope := vel_2d.normalized().dot(slope_2d) if vel_2d.length() > 0.5 else 1.0
			if dot_slope > SLOPE_DOT_THRESHOLD:
				if not state.is_sliding:
					var spd := vel_2d.length()
					var speed_factor := 1.0 + clampf(spd / 15.0, 0.0, 2.0)
					var accel := slope_accel_stand * speed_factor
					player.velocity.x += slope_2d.x * accel * delta
					player.velocity.z += slope_2d.y * accel * delta
			elif dot_slope < -SLOPE_DOT_THRESHOLD:
				if direction.length_squared() > 0.01:
					var slope_up := -slope_2d
					var climb_dir := Vector2(direction.x, direction.z)
					if climb_dir.length_squared() > 0.01:
						climb_dir = climb_dir.normalized()
					else:
						climb_dir = slope_up
					var dot_up := climb_dir.dot(slope_up)
					if dot_up > 0.3:
						var target_spd := ramp_climb_speed
						player.velocity.x = move_toward(player.velocity.x, slope_up.x * target_spd, walk_speed * 10 * delta)
						player.velocity.z = move_toward(player.velocity.z, slope_up.y * target_spd, walk_speed * 10 * delta)
					else:
						var climb_friction: float = slope_accel_slide * 1.2 * delta
						player.velocity.x = move_toward(player.velocity.x, 0, climb_friction)
						player.velocity.z = move_toward(player.velocity.z, 0, climb_friction)
				else:
					var climb_friction: float = slope_accel_slide * 1.2 * delta
					player.velocity.x = move_toward(player.velocity.x, 0, climb_friction)
					player.velocity.z = move_toward(player.velocity.z, 0, climb_friction)
		if state.is_sliding:
			state.slide_grace -= delta
			var friction: float
			if not state.slide_from_air:
				friction = slide_friction_slow
			else:
				var speed_factor := clampf(current_speed / speed_reference, 0.0, 1.0)
				friction = lerpf(slide_friction_fast * 2.0, slide_friction_fast * 0.5, speed_factor)
			var is_fast_slide := current_speed >= slide_fast_threshold and state.slide_from_air and state.slide_grace <= 0
			if is_fast_slide and horizontal_velocity.length_squared() > 0.01:
				var slide_dir := horizontal_velocity.normalized()
				player.velocity.x += slide_dir.x * slide_accel * delta
				player.velocity.z += slide_dir.y * slide_accel * delta
			if abs(input_dir.x) > 0.1:
				var right := Vector3(player.global_transform.basis.x.x, 0, player.global_transform.basis.x.z).normalized()
				var right2 := Vector2(right.x, right.z)
				player.velocity.x += right2.x * input_dir.x * slide_steer * delta
				player.velocity.z += right2.y * input_dir.x * slide_steer * delta
			if state.slide_grace <= 0:
				var slide_speed := _get_horizontal_velocity().length()
				var new_speed: float
				if rolling_down:
					new_speed = slide_speed + slope_accel_slide * delta
				elif sliding_up_ramp:
					new_speed = slide_speed
				else:
					new_speed = maxf(0.0, slide_speed - friction * delta)
				if new_speed < slide_min_speed:
					player.velocity.x = 0
					player.velocity.z = 0
					state.slide_force_zero_next = true
					state.is_sliding = false
					state.slide_from_air = false
					state.slide_distance = 0
					state.slide_time = 0
					state.slide_cooldown = slide_end_cooldown
					if not is_on_ramp:
						state.slide_requires_release = true
				else:
					var vel_2d := _get_horizontal_velocity()
					var slide_dir: Vector2
					if vel_2d.length_squared() > 0.01:
						slide_dir = vel_2d.normalized()
					elif horizontal_velocity.length_squared() > 0.01:
						slide_dir = horizontal_velocity.normalized()
					else:
						slide_dir = _get_forward_2d()
					player.velocity.x = slide_dir.x * new_speed
					player.velocity.z = slide_dir.y * new_speed
			horizontal_velocity = _get_horizontal_velocity()
		elif direction.length_squared() > 0.01:
			var move_speed := walk_speed * crouch_walk_speed_multiplier if state.is_crouching else walk_speed
			player.velocity.x = move_toward(player.velocity.x, direction.x * move_speed, move_speed * 10 * delta)
			player.velocity.z = move_toward(player.velocity.z, direction.z * move_speed, move_speed * 10 * delta)
		elif not rolling_down:
			player.velocity.x = move_toward(player.velocity.x, 0, ground_friction)
			player.velocity.z = move_toward(player.velocity.z, 0, ground_friction)
	else:
		state.air_time += delta
		var spd := _get_horizontal_velocity().length()

		var from_ramp_exit: bool = state.was_on_ramp and state.ramp_contact_time >= 0.15 and not state.ramp_landed_from_fall
		if from_ramp_exit and not state.ramp_launch_applied and spd >= ramp_launch_min_speed:
			var launch_vy := minf(ramp_launch_base + spd * ramp_launch_speed_factor, ramp_launch_max_vy)
			player.velocity.y = launch_vy
			state.ramp_launch_applied = true
		state.ramp_contact_time = 0.0
		if state.wall_jump_grace > 0:
			state.wall_jump_grace -= delta
		elif not state.is_sliding:
			var is_strafing: bool = abs(input_dir.x) > 0.08
			var turn_matches_strafe: bool = (input_dir.x * state.mouse_turn_accum) > 0
			var is_bunny_hopping: bool = is_strafing and turn_matches_strafe and abs(state.mouse_turn_accum) > 1.0
			if direction.length_squared() > 0.01 and is_bunny_hopping:
				var vel_dir := horizontal_velocity.normalized() if current_speed > 0.5 else Vector2(direction.x, direction.z)
				var wish_dir := Vector2(direction.x, direction.z)
				var dot_val: float = vel_dir.dot(wish_dir)
				var strafe_factor: float = 1.0 - clampf(dot_val, 0.0, 1.0)
				var ramp: float = maxf(0.0, 1.0 - current_speed / speed_reference)
				var add_speed: float = air_acceleration * delta * strafe_factor * ramp
				player.velocity.x += direction.x * add_speed
				player.velocity.z += direction.z * add_speed
			elif direction.length_squared() > 0.01:
				player.velocity.x = move_toward(player.velocity.x, direction.x * walk_speed, air_control * delta)
				player.velocity.z = move_toward(player.velocity.z, direction.z * walk_speed, air_control * delta)
			else:
				var drag_factor := 1.0 - air_drag * delta
				player.velocity.x *= drag_factor
				player.velocity.z *= drag_factor
		horizontal_velocity = _get_horizontal_velocity()

	var preserve_on_ramp := is_on_ramp
	var saved_hv := _get_horizontal_velocity() if preserve_on_ramp else Vector2.ZERO
	var preserve_in_air_slide := state.is_sliding and not on_floor
	var saved_hv_air := _get_horizontal_velocity() if preserve_in_air_slide else Vector2.ZERO

	player.move_and_slide()

	if preserve_on_ramp:
		var floor_normal := player.get_floor_normal()
		var slope_2d := _get_slope_down_2d(floor_normal)
		var spd := saved_hv.length()
		var dir_2d: Vector2
		if spd > 0.5:
			var dot_slope := saved_hv.normalized().dot(slope_2d)
			dir_2d = slope_2d if dot_slope > SLOPE_DOT_THRESHOLD else saved_hv.normalized()
		else:
			dir_2d = slope_2d
		player.velocity.x = dir_2d.x * spd
		player.velocity.z = dir_2d.y * spd
		player.velocity.y = -(player.velocity.x * floor_normal.x + player.velocity.z * floor_normal.z) / floor_normal.y if abs(floor_normal.y) > 0.01 else 0.0
	if preserve_in_air_slide:
		player.velocity.x = saved_hv_air.x
		player.velocity.z = saved_hv_air.y

	if state.slide_force_zero_next:
		player.velocity.x = 0
		player.velocity.z = 0

	state.was_on_ramp = on_floor and is_on_ramp

	state.is_on_wall = false
	if not on_floor:
		_detect_wall_raycast()
		if not state.is_on_wall and state.wall_coyote_timer <= 0:
			state.wall_normal = Vector3.ZERO

	if player.global_position.y < void_y:
		if not state.is_dead:
			state.is_dead = true
			if on_die.is_valid():
				on_die.call()

	state.mouse_turn_accum = 0.0
