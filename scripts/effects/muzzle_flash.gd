extends Node3D

@onready var particles: GPUParticles3D = $Particles

func _ready() -> void:
	if particles:
		particles.emitting = true

		await get_tree().create_timer(particles.lifetime + 0.05).timeout
	queue_free()
