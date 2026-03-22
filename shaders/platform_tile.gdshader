shader_type spatial;
render_mode blend_mix, cull_back, depth_draw_opaque;

uniform vec4 base_color : source_color = vec4(0.5, 0.56, 0.66, 1.0);
uniform vec4 accent_color : source_color = vec4(0.36, 0.42, 0.52, 1.0);
uniform float tile_scale : hint_range(2.0, 12.0) = 6.0;
uniform float edge_width : hint_range(0.0, 0.2) = 0.04;
uniform float glow_strength : hint_range(0.0, 1.0) = 0.0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	vec2 uv = UV * tile_scale;
	vec2 tile_id = floor(uv);
	vec2 tile_uv = fract(uv);
	float pattern = mod(tile_id.x + tile_id.y, 2.0);
	vec3 color = mix(base_color.rgb, accent_color.rgb, pattern);

	float variation = hash(tile_id) * 0.08 + 0.96;
	color *= variation;

	float edge_x = smoothstep(edge_width, 0.0, min(tile_uv.x, 1.0 - tile_uv.x));
	float edge_y = smoothstep(edge_width, 0.0, min(tile_uv.y, 1.0 - tile_uv.y));
	float edge = edge_x * edge_y;
	color *= mix(0.65, 1.0, edge);

	ALBEDO = color;
	ROUGHNESS = 0.45;
	METALLIC = 0.03;
	EMISSION = base_color.rgb * glow_strength;
	ALPHA = 1.0;
}
