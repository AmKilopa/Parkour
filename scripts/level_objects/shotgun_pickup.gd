class_name ShotgunPickup
extends Area3D

@export var pickup_sound: AudioStream = preload("res://assets/sounds/land.mp3")

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	if not body or not body.is_in_group("player"):
		return
	var player := body as CharacterBody3D
	if not player or not player.has_method("give_shotgun"):
		return
	body_entered.disconnect(_on_body_entered)
	set_deferred("monitoring", false)

	var audio := AudioStreamPlayer3D.new()
	audio.stream = pickup_sound
	audio.volume_db = SettingsManager.get_sfx_volume_db()
	add_child(audio)
	audio.global_position = global_position
	audio.play()
	player.give_shotgun()
	get_tree().create_timer(0.5).timeout.connect(queue_free)
