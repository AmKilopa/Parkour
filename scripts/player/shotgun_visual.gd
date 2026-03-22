class_name ShotgunVisual
extends Node3D

const DEFAULT_MATERIAL_PATH := "res://assets/texture/shotgun_material.tres"

@export var barrel_tip_distance := 1.9

@export var min_pull_distance := 0.15

@export var pull_smooth_speed := 12.0

@export var material_override: Material

var _default_position: Vector3
var _current_pull_back: float = 0.0

func _ready() -> void:
	if not material_override:
		material_override = load(DEFAULT_MATERIAL_PATH) as Material
	for node in find_children("*", "MeshInstance3D", true, false):
		(node as MeshInstance3D).material_override = material_override
	_default_position = position

func _process(delta: float) -> void:

	if Engine.get_process_frames() % 2 != 0:
		position = _default_position + Vector3(0, 0, _current_pull_back)
		return
	var pull_back := _get_wall_pull_back()
	if pull_smooth_speed > 0:
		_current_pull_back = lerpf(_current_pull_back, pull_back, pull_smooth_speed * delta)
	else:
		_current_pull_back = pull_back
	position = _default_position + Vector3(0, 0, _current_pull_back)

func _get_wall_pull_back() -> float:
	var player := _get_player()
	if not player:
		return 0.0
	var camera: Camera3D = player.get_node_or_null(PlayerNodes.CAMERA_3D)
	if not camera:
		return 0.0
	var origin := camera.global_position
	var forward := -camera.global_transform.basis.z
	forward = forward.normalized()
	var space := player.get_world_3d().direct_space_state
	if not space:
		return 0.0
	var query := PhysicsRayQueryParameters3D.create(origin, origin + forward * barrel_tip_distance)
	query.exclude = [player.get_rid()]
	var result := space.intersect_ray(query)
	if result.is_empty():
		return 0.0
	var hit_dist: float = origin.distance_to(result.position)
	var pull := barrel_tip_distance - hit_dist
	if pull < min_pull_distance:
		return 0.0
	return pull

func _get_player() -> CharacterBody3D:
	var n := get_parent()
	while n:
		if n is CharacterBody3D:
			return n as CharacterBody3D
		n = n.get_parent()
	return null
