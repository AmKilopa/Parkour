class_name PlayerShotgun
extends RefCounted

const PELLET_SCENE := preload("res://scenes/player/pellet.tscn")
const MUZZLE_FLASH_SCENE := preload("res://scenes/effects/muzzle_flash.tscn")
const PELLET_SPEED := 80.0
const PELLET_SPREAD := 0.12
const RECOIL_VERTICAL_CAP := 5.0
const MAX_PELLETS := 25

var player: CharacterBody3D
var state: PlayerState
var cooldown := 0.0
var recoil_force := 6.0
var cooldown_time := 1.0
var fired_this_frame := false

func _init(p: CharacterBody3D, s: PlayerState) -> void:
	player = p
	state = s

func process(delta: float) -> void:
	fired_this_frame = false
	if not state.has_shotgun or state.is_ledge_hanging:
		return
	cooldown = maxf(0.0, cooldown - delta)
	if cooldown <= 0.0 and Input.is_action_just_pressed("fire"):
		_fire()

func _fire() -> void:
	fired_this_frame = true
	cooldown = cooldown_time
	LevelState.deduct_score(5)
	var camera: Camera3D = player.get_node_or_null(PlayerNodes.CAMERA_3D)
	var shot_dir: Vector3
	if camera:
		shot_dir = -camera.global_transform.basis.z
	else:
		shot_dir = -player.global_transform.basis.z
	shot_dir = shot_dir.normalized()

	var hit_explosive := _check_explosives(shot_dir, camera)

	_spawn_muzzle_flash(shot_dir, camera)

	_spawn_pellets(shot_dir, camera)

	if not hit_explosive:
		var recoil := -shot_dir * recoil_force
		recoil.y = clampf(recoil.y, -RECOIL_VERTICAL_CAP, RECOIL_VERTICAL_CAP)
		state.recoil_impulse = recoil

const RAY_LENGTH := 50.0

func _check_explosives(base_dir: Vector3, camera: Camera3D) -> bool:
	var origin: Vector3
	if camera:
		origin = camera.global_position + base_dir * 0.5
	else:
		origin = player.global_position + Vector3(0, 1.5, 0) + base_dir * 0.5
	var space := player.get_world_3d().direct_space_state
	if not space:
		return false
	for i in 5:
		var dir := base_dir + Vector3(
			randf_range(-PELLET_SPREAD, PELLET_SPREAD),
			randf_range(-PELLET_SPREAD, PELLET_SPREAD),
			randf_range(-PELLET_SPREAD, PELLET_SPREAD)
		)
		dir = dir.normalized()
		var query := PhysicsRayQueryParameters3D.create(origin, origin + dir * RAY_LENGTH)
		query.exclude = [player.get_rid()]
		var result := space.intersect_ray(query)
		if not result.is_empty():
			var collider = result.collider
			if collider and collider.is_in_group("explosive"):
				if collider.has_method("explode"):
					collider.explode(result.position)
				return true
	return false

func _spawn_muzzle_flash(shot_dir: Vector3, camera: Camera3D) -> void:
	var root := player.get_tree().current_scene
	if not root:
		return
	var spawn_pos: Vector3
	if camera:
		spawn_pos = camera.global_position + shot_dir * 0.85
	else:
		spawn_pos = player.global_position + Vector3(0, 1.5, 0) + shot_dir * 0.85
	var flash: Node3D = MUZZLE_FLASH_SCENE.instantiate()
	root.add_child(flash)
	flash.global_position = spawn_pos
	flash.look_at(spawn_pos + shot_dir, Vector3.UP)

func _spawn_pellets(base_dir: Vector3, camera: Camera3D) -> void:
	var root := player.get_tree().current_scene
	if not root:
		return
	var pellets := root.get_tree().get_nodes_in_group("pellet")
	var to_free := maxi(0, pellets.size() + 5 - MAX_PELLETS)
	for i in to_free:
		if i < pellets.size() and pellets[i].is_inside_tree():
			pellets[i].queue_free()
	var spawn_pos: Vector3
	if camera:
		spawn_pos = camera.global_position + base_dir * 0.5
	else:
		spawn_pos = player.global_position + Vector3(0, 1.5, 0) + base_dir * 0.5

	for i in 5:
		var dir := base_dir + Vector3(
			randf_range(-PELLET_SPREAD, PELLET_SPREAD),
			randf_range(-PELLET_SPREAD, PELLET_SPREAD),
			randf_range(-PELLET_SPREAD, PELLET_SPREAD)
		)
		dir = dir.normalized()
		var pellet: Node3D = PELLET_SCENE.instantiate()
		root.add_child(pellet)
		pellet.global_position = spawn_pos
		pellet.setup(dir * PELLET_SPEED)
