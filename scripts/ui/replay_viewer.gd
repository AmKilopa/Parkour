class_name ReplayViewer
extends Node3D

const RECORDS_SCENE := "res://scenes/ui/records_screen.tscn"
const PLAYER_SCENE := "res://scenes/player.tscn"

var _record: Dictionary
var _frames: Array = []
var _total_time: float
var _current_time: float
var _paused := false
var _free_cam := true
var _rmb_held := false
var _fly_speed := 15.0
var _fly_speed_min := 3.0
var _fly_speed_max := 80.0
var _fly_rot := Vector2.ZERO
var _mouse_delta := Vector2.ZERO
var _shotgun_local_offset := Vector3(0.32, 0.15, 1.40)
var _shotgun_local_basis := Basis.IDENTITY

@onready var level_container := $LevelContainer
@onready var ghost := $Ghost
@onready var camera_pivot := $CameraPivot
@onready var camera := $CameraPivot/Camera3D
@onready var time_slider := $UI/SliderContainer/TimeSlider
@onready var pause_label := $UI/PauseLabel

func _ready() -> void:
	_record = ReplayViewerData.record
	if _record.is_empty():
		_back()
		return
	_frames = _record.get("frames", [])
	_total_time = float(_record.get("time", 0.0))
	_current_time = 0.0
	_load_level()
	_setup_ghost()
	camera.current = true
	time_slider.min_value = 0.0
	time_slider.max_value = _total_time
	time_slider.value = 0.0
	time_slider.value_changed.connect(_on_slider_changed)
	_init_free_cam_position()
	_update_mouse_mode()
	if pause_label:
		pause_label.visible = _paused

func _load_level() -> void:
	var path := ReplayViewerData.level_path
	if path.is_empty():
		path = LevelState.DEFAULT_LEVEL_PATH
	var scene := load(path) as PackedScene
	if not scene:
		return
	var level: Node = scene.instantiate() as Node
	level.set_script(null)
	var player: Node = level.get_node_or_null("Player")
	if player:
		player.queue_free()
	level_container.add_child(level)

func _update_mouse_mode() -> void:
	if _paused:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if _rmb_held else Input.MOUSE_MODE_VISIBLE
	elif _free_cam:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	else:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _init_free_cam_position() -> void:
	if _frames.is_empty():
		return
	var f: Dictionary = _frames[0]
	var rec_v: int = int(_record.get("v", 1))
	var pos_y: float = float(f["y"]) if rec_v >= 2 else float(f["y"]) + 0.875
	camera_pivot.global_position = Vector3(float(f["x"]), pos_y + 2.0, float(f["z"]) + 4.0)
	_fly_rot.y = float(f["ry"])
	_fly_rot.x = 0.3
	camera_pivot.rotation.y = _fly_rot.y
	camera_pivot.rotation.x = _fly_rot.x
	camera.position = Vector3.ZERO
	camera.rotation = Vector3.ZERO

func _setup_ghost() -> void:
	var mesh := CapsuleMesh.new()
	mesh.radius = 0.35
	mesh.height = 1.75
	ghost.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.4, 0.7, 1.0, 0.7)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ghost.material_override = mat
	var sg := preload("res://scenes/player/shotgun.tscn").instantiate() as Node3D
	sg.name = "Shotgun"
	sg.set_script(null)
	var player_scene := load(PLAYER_SCENE) as PackedScene
	if player_scene:
		var player_temp: Node = player_scene.instantiate()
		var player_sg: Node = player_temp.get_node_or_null(PlayerNodes.SHOTGUN)
		if player_sg:
			var t: Transform3D = player_sg.transform
			_shotgun_local_basis = t.basis
		player_temp.queue_free()
	var ghost_mat := StandardMaterial3D.new()
	ghost_mat.albedo_color = Color(0.4, 0.7, 1.0, 0.7)
	ghost_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	for c in sg.find_children("*", "MeshInstance3D", true, false):
		(c as MeshInstance3D).material_override = ghost_mat
	add_child(sg)
	var ray := MeshInstance3D.new()
	ray.name = "ForwardRay"
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.03
	cyl.bottom_radius = 0.03
	cyl.height = 0.9
	ray.mesh = cyl
	var ray_mat := StandardMaterial3D.new()
	ray_mat.albedo_color = Color(1.0, 0.85, 0.2, 0.9)
	ray_mat.emission_enabled = true
	ray_mat.emission = Color(1.0, 0.9, 0.3)
	ray_mat.emission_energy_multiplier = 0.5
	ray.material_override = ray_mat
	ray.transform = Transform3D(Basis.from_euler(Vector3(TAU / 4, 0, 0)), Vector3(0, 0.5, -0.45))
	ghost.add_child(ray)

const CROUCH_HEIGHT := 0.9
const STAND_HEIGHT := 1.75
const WALL_RUN_TILT := 0.25

func _get_frame_at(t: float) -> Dictionary:
	if _frames.is_empty():
		return {}
	if t <= 0:
		return _frames[0]
	if t >= _frames[_frames.size() - 1]["t"]:
		return _frames[_frames.size() - 1]
	for i in range(_frames.size() - 1):
		var a: Dictionary = _frames[i]
		var b: Dictionary = _frames[i + 1]
		if t >= a["t"] and t <= b["t"]:
			var k: float = (t - a["t"]) / (b["t"] - a["t"]) if b["t"] > a["t"] else 1.0
			var fa: int = 1 if a.get("f", 0) else 0
			var fb: int = 1 if b.get("f", 0) else 0
			var sa: int = 1 if a.get("s", 0) else 0
			var sb: int = 1 if b.get("s", 0) else 0
			var ca: int = 1 if a.get("c", 0) else 0
			var cb: int = 1 if b.get("c", 0) else 0
			var la: int = 1 if a.get("l", 0) else 0
			var lb: int = 1 if b.get("l", 0) else 0
			var wa: int = 1 if a.get("w", 0) else 0
			var wb: int = 1 if b.get("w", 0) else 0
			var ha: int = 1 if a.get("h", 1) else 0
			var hb: int = 1 if b.get("h", 1) else 0
			var result: Dictionary = {
				"x": lerpf(float(a["x"]), float(b["x"]), k),
				"y": lerpf(float(a["y"]), float(b["y"]), k),
				"z": lerpf(float(a["z"]), float(b["z"]), k),
				"ry": lerp_angle(float(a["ry"]), float(b["ry"]), k),
				"cp": lerpf(float(a["cp"]), float(b["cp"]), k),
				"f": 1 if (fa or fb) else 0,
				"s": 1 if lerpf(float(sa), float(sb), k) > 0.5 else 0,
				"c": 1 if lerpf(float(ca), float(cb), k) > 0.5 else 0,
				"l": 1 if lerpf(float(la), float(lb), k) > 0.5 else 0,
				"w": 1 if lerpf(float(wa), float(wb), k) > 0.5 else 0,
				"h": 1 if lerpf(float(ha), float(hb), k) > 0.5 else 0
			}
			if wa or wb:
				result["wx"] = lerpf(float(a.get("wx", 0.0)), float(b.get("wx", 0.0)), k)
				result["wz"] = lerpf(float(a.get("wz", 0.0)), float(b.get("wz", 0.0)), k)
			return result
	return _frames[0]

func _update_ghost() -> void:
	var f: Dictionary = _get_frame_at(_current_time)
	if f.is_empty():
		return
	var sliding: bool = f.get("s", 0) != 0
	var crouching: bool = f.get("c", 0) != 0
	var ledge_hanging: bool = f.get("l", 0) != 0
	var on_wall: bool = f.get("w", 0) != 0
	var rec_v: int = int(_record.get("v", 1))
	var half_h: float = (CROUCH_HEIGHT if crouching else STAND_HEIGHT) * 0.5
	var pos_y: float = float(f["y"]) if rec_v >= 2 else float(f["y"]) + half_h
	ghost.global_position = Vector3(float(f["x"]), pos_y, float(f["z"]))
	ghost.rotation.y = float(f["ry"])
	if sliding:
		ghost.rotation.x = 0.35
	elif ledge_hanging:
		ghost.rotation.x = -0.2
	elif on_wall:
		var wx: float = float(f.get("wx", 0.0))
		var wz: float = float(f.get("wz", 0.0))
		if abs(wx) >= 0.1:
			ghost.rotation.z = -sign(wx) * WALL_RUN_TILT
		else:
			ghost.rotation.z = sign(wz) * WALL_RUN_TILT
		ghost.rotation.x = 0.0
	else:
		ghost.rotation.x = 0.0
		ghost.rotation.z = 0.0
	var capsule: CapsuleMesh = ghost.mesh as CapsuleMesh
	if capsule:
		capsule.height = CROUCH_HEIGHT if crouching else STAND_HEIGHT
	var sg := get_node_or_null("Shotgun")
	if sg:
		var has_sg: bool = f.get("h", 1) != 0
		sg.visible = has_sg
		if has_sg:
			sg.global_transform = ghost.global_transform * Transform3D(_shotgun_local_basis, _shotgun_local_offset)
	_apply_barrel_visibility()

func _update_camera_follow() -> void:
	if _free_cam:
		return
	var f: Dictionary = _get_frame_at(_current_time)
	if f.is_empty():
		return
	var rec_v: int = int(_record.get("v", 1))
	var pos_y: float = float(f["y"]) if rec_v >= 2 else float(f["y"]) + 0.875
	var pos: Vector3 = Vector3(float(f["x"]), pos_y, float(f["z"]))
	camera_pivot.global_position = pos
	camera_pivot.rotation.y = float(f["ry"])
	camera_pivot.rotation.x = float(f["cp"])
	camera.position = Vector3(0, 1.5, 3)
	camera.rotation = Vector3.ZERO

func _process(delta: float) -> void:
	if _free_cam:
		_process_free_cam(delta)
	if not _paused:
		_current_time += delta
		_current_time = clampf(_current_time, 0.0, _total_time)
		time_slider.set_value_no_signal(_current_time)
	_update_ghost()
	if not _free_cam:
		_update_camera_follow()

func _process_free_cam(delta: float) -> void:
	var move := Vector3.ZERO
	if Input.is_action_pressed("move_forward"): move -= camera.global_transform.basis.z
	if Input.is_action_pressed("move_back"): move += camera.global_transform.basis.z
	if Input.is_action_pressed("move_left"): move -= camera.global_transform.basis.x
	if Input.is_action_pressed("move_right"): move += camera.global_transform.basis.x
	if Input.is_action_pressed("jump"): move += Vector3.UP
	if Input.is_action_pressed("slide"): move -= Vector3.UP
	if Input.is_action_pressed("camera_down"): move -= Vector3.UP
	if Input.is_action_pressed("camera_up"): move += Vector3.UP
	if move.length() > 0.01:
		camera_pivot.global_position += move.normalized() * _fly_speed * delta
	if not _paused or _rmb_held:
		var inv_y := -1.0 if SettingsManager.get_invert_y() else 1.0
		_fly_rot.y -= _mouse_delta.x * 0.002
		_fly_rot.x += _mouse_delta.y * 0.002 * inv_y
		_fly_rot.x = clampf(_fly_rot.x, -1.57, 1.57)
	_mouse_delta = Vector2.ZERO
	camera_pivot.rotation.y = _fly_rot.y
	camera_pivot.rotation.x = _fly_rot.x
	camera.position = Vector3.ZERO
	camera.rotation = Vector3.ZERO

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_mouse_delta = event.relative
	if event is InputEventMouseButton and (_rmb_held or _free_cam) and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_fly_speed = minf(_fly_speed_max, _fly_speed + 5.0)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_fly_speed = maxf(_fly_speed_min, _fly_speed - 5.0)
	if event.is_action_pressed("replay_pause"):
		_paused = not _paused
		_rmb_held = false
		_update_mouse_mode()
		if pause_label:
			pause_label.visible = _paused
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		if event.pressed:
			_rmb_held = true
			if _paused:
				_update_mouse_mode()
		else:
			_rmb_held = false
			if _paused:
				_update_mouse_mode()
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		if _paused:
			_back()

func _apply_barrel_visibility() -> void:
	var barrels: Array = _record.get("barrels", [])
	for node in level_container.find_children("*", "StaticBody3D", true, false):
		if not node.is_in_group("explosive"):
			continue
		var mesh_node: Node3D = node.get_node_or_null("Mesh") as Node3D
		if not mesh_node:
			continue
		var node_pos: Vector3 = node.global_position
		var should_hide := false
		for barrel_data in barrels:
			if barrel_data.get("t", 0.0) > _current_time:
				continue
			var bpos := Vector3(barrel_data["x"], barrel_data["y"], barrel_data["z"])
			if node_pos.distance_to(bpos) < 2.0:
				should_hide = true
				break
		mesh_node.visible = not should_hide

func _on_slider_changed(v: float) -> void:
	_current_time = clampf(v, 0.0, _total_time)

func _back() -> void:
	get_tree().change_scene_to_file(RECORDS_SCENE)
