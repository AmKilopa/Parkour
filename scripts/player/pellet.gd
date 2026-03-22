class_name Pellet
extends Node3D

var _velocity := Vector3.ZERO
var _lifetime := 0.35

func _ready() -> void:
	add_to_group("pellet")

func setup(vel: Vector3) -> void:
	_velocity = vel

func _physics_process(delta: float) -> void:
	global_position += _velocity * delta
	_lifetime -= delta
	if _lifetime <= 0:
		queue_free()
