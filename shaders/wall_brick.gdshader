shader_type spatial;
render_mode blend_mix, cull_back, depth_draw_opaque;

uniform vec4 brick_color : source_color = vec4(0.58, 0.45, 0.38, 1.0);
uniform vec4 mortar_color : source_color = vec4(0.4, 0.38, 0.36, 1.0);
uniform float brick_scale : hint_range(1.0, 10.0) = 3.0;
uniform float mortar_width : hint_range(0.0, 0.2) = 0.05;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	vec2 uv = UV * brick_scale;
	uv.x += floor(uv.y) * 0.5;
	vec2 brick_id = floor(uv);
	vec2 brick_uv = fract(uv);

	float mortar = smoothstep(mortar_width, 0.0, min(brick_uv.x, 1.0 - brick_uv.x)) * smoothstep(mortar_width, 0.0, min(brick_uv.y, 1.0 - brick_uv.y));
	vec3 color = mix(mortar_color.rgb, brick_color.rgb, mortar);

	float variation = hash(brick_id) * 0.12 + 0.94;
	color *= variation;

	ROUGHNESS = 0.82 + hash(brick_id + 1.0) * 0.12;
	ALBEDO = color;
	METALLIC = 0.0;
}
