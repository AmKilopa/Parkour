class_name ExplosiveBarrel
extends StaticBody3D

@export var explosion_radius := 10.0
@export var explosion_force := 680.0
@export var explosion_lift := 0.25
@export var explosion_far_radius := 18.0
@export var barrel_height := 3.0
@export var upper_part_threshold := 0.6

const EXPLOSION_SCENE := preload("res://scenes/effects/explosion.tscn")

func explode(hit_position: Vector3 = Vector3.ZERO) -> void:
	_spawn_explosion()
	RecordsManager.record_barrel_explosion(global_position, LevelState.current_time)
	var p := get_tree().get_first_node_in_group("player") as CharacterBody3D
	if not p:
		_destroy_barrel()
		return
	var origin := global_position
	var to_player := p.global_position - origin
	var dist := to_player.length()
	if dist > explosion_far_radius:
		_destroy_barrel()
		return
	if dist < 0.1:
		dist = 0.1
	var falloff: float
	if dist <= explosion_radius:
		falloff = 1.0 - dist / explosion_radius
	else:
		var t := (dist - explosion_radius) / (explosion_far_radius - explosion_radius)
		falloff = (1.0 - t) * 0.25
	var dir: Vector3
	var hit_local := to_local(hit_position)
	var top_y := barrel_height * upper_part_threshold
	if hit_local.y >= top_y:

		var to_h := Vector3(to_player.x, 0, to_player.z)
		if to_h.length() < 0.1:
			to_h = -global_transform.basis.z
		dir = (to_h + Vector3(0, 0.08, 0)).normalized()
	else:

		dir = (to_player + Vector3(0, explosion_lift, 0)).normalized()
	var impulse := dir * explosion_force * falloff
	var state: PlayerState = p.get_state() if p.has_method("get_state") else null
	if state:
		state.recoil_impulse += impulse
	_destroy_barrel()

func _spawn_explosion() -> void:
	var tree := get_tree()
	if not tree or not tree.current_scene:
		return
	var exp_node: Node3D = EXPLOSION_SCENE.instantiate()
	tree.current_scene.add_child(exp_node)
	exp_node.global_position = global_position + Vector3(0, barrel_height * 0.5, 0)

func _destroy_barrel() -> void:
	$Mesh.visible = false
	$CollisionShape3D.disabled = true
	get_tree().create_timer(0.5).timeout.connect(queue_free)
