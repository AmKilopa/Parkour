extends Camera3D

@export_range(0.0, 0.5) var strength: float = 0.06
@export_range(4, 20) var blur_samples: int = 8
@export_range(0.0, 1.0) var smoothing: float = 0.96
@export var max_blur_uv: float = 0.006

var prev_pos := Vector3.ZERO
var prev_basis := Basis()
var current_blur := Vector2.ZERO
var blur_overlay: ColorRect
var _canvas: CanvasLayer

func _ready() -> void:
	blur_overlay = ColorRect.new()
	blur_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	blur_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/motionblur.gdshader")
	mat.set_shader_parameter("samples", blur_samples)
	blur_overlay.material = mat

	_canvas = CanvasLayer.new()
	_canvas.layer = 0
	add_child(_canvas)
	_canvas.add_child(blur_overlay)

	prev_pos = global_position
	prev_basis = global_transform.basis

func _physics_process(delta: float) -> void:
	if delta <= 0:
		return

	blur_overlay.visible = SettingsManager.get_motion_blur_enabled()
	if not blur_overlay.visible:
		return

	var mat := blur_overlay.material as ShaderMaterial
	if not mat:
		return

	var linear_vel := (global_position - prev_pos) / delta
	var delta_basis: Basis = prev_basis.inverse() * global_transform.basis
	var delta_quat := Quaternion(delta_basis)

	var angular_vel := Vector3.ZERO
	if absf(delta_quat.w) < 1.0:
		var half_angle := acos(clampf(delta_quat.w, -1.0, 1.0))
		if half_angle > 0.0001:
			var sin_half := sin(half_angle)
			angular_vel = Vector3(delta_quat.x, delta_quat.y, delta_quat.z) / sin_half * (2.0 * half_angle / delta)

	var local_vel: Vector3 = global_transform.basis.inverse() * linear_vel

	var raw_blur := Vector2(
		-angular_vel.y - local_vel.x,
		angular_vel.x + local_vel.y
	) * strength * delta

	var blur_len := raw_blur.length()
	var blur_threshold := 0.0008

	var t := 1.0 - pow(smoothing, delta * 60.0)
	current_blur = current_blur.lerp(raw_blur if blur_len > blur_threshold else Vector2.ZERO, t)

	var limited := current_blur
	if limited.length() > max_blur_uv:
		limited = limited.normalized() * max_blur_uv

	mat.set_shader_parameter("blur_direction", limited)

	prev_pos = global_position
	prev_basis = global_transform.basis
