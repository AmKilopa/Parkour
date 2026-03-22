shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear;
uniform float blur_amount : hint_range(0.0, 1.0) = 0.0;
uniform vec2 blur_dir = vec2(0.0, 0.0);
uniform float vignette_amount : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec2 uv = SCREEN_UV;
	vec4 color = textureLod(screen_texture, uv, 0.0);

	if (blur_amount > 0.001 && length(blur_dir) > 0.01) {
		vec2 dir = normalize(blur_dir);
		float pixel_size = max(SCREEN_PIXEL_SIZE.x, SCREEN_PIXEL_SIZE.y);
		float stretch = blur_amount * 6.0 * pixel_size;

		float w0 = 0.22;
		float w1 = 0.19;
		float w2 = 0.12;
		float w3 = 0.08;
		float w4 = 0.04;

		vec4 sum = color * w0;
		sum += textureLod(screen_texture, uv + dir * stretch * 0.5, 0.0) * w1;
		sum += textureLod(screen_texture, uv - dir * stretch * 0.5, 0.0) * w1;
		sum += textureLod(screen_texture, uv + dir * stretch * 1.2, 0.0) * w2;
		sum += textureLod(screen_texture, uv - dir * stretch * 1.2, 0.0) * w2;
		sum += textureLod(screen_texture, uv + dir * stretch * 2.0, 0.0) * w3;
		sum += textureLod(screen_texture, uv - dir * stretch * 2.0, 0.0) * w3;
		sum += textureLod(screen_texture, uv + dir * stretch * 2.8, 0.0) * w4;
		sum += textureLod(screen_texture, uv - dir * stretch * 2.8, 0.0) * w4;

		color = sum / (w0 + w1 * 2.0 + w2 * 2.0 + w3 * 2.0 + w4 * 2.0);
	}

	float dist = length(uv - 0.5) * 1.5;
	float vignette = 1.0 - vignette_amount * smoothstep(0.25, 0.9, dist);
	color.rgb *= vignette;

	COLOR = color;
}
