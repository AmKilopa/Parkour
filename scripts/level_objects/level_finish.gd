class_name LevelFinish
extends Area3D

@export var trigger_size := Vector3(10, 2, 10)

@export var mesh_height := 0.2

func _ready() -> void:
	_apply_size()
	body_entered.connect(_on_body_entered)

func _apply_size() -> void:
	var col := get_node_or_null("CollisionShape3D")
	if col and col.shape is BoxShape3D:
		(col.shape as BoxShape3D).size = trigger_size
	var mesh_inst := get_node_or_null("MeshInstance3D")
	if mesh_inst and mesh_inst.mesh is BoxMesh:
		(mesh_inst.mesh as BoxMesh).size = Vector3(trigger_size.x, mesh_height, trigger_size.z)

func _on_body_entered(body: Node3D) -> void:
	if body and body.is_in_group("player"):
		LevelState.complete_level()
