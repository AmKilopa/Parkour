extends Node3D

@onready var fire: GPUParticles3D = $Fire
@onready var smoke: GPUParticles3D = $Smoke

func _ready() -> void:
	var max_lifetime := 0.0
	if fire:
		fire.emitting = true
		max_lifetime = maxf(max_lifetime, fire.lifetime)
	if smoke:
		smoke.emitting = true
		max_lifetime = maxf(max_lifetime, smoke.lifetime)
	await get_tree().create_timer(max_lifetime + 0.2).timeout
	queue_free()
