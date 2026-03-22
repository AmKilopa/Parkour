shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear;
uniform vec2 blur_direction = vec2(0.0, 0.0);
uniform int samples : hint_range(4, 32) = 16;

void fragment() {
	vec4 color = vec4(0.0);
	for (int i = 0; i < samples; i++) {
		float offset = float(i) / float(samples - 1) - 0.5;
		vec2 uv_offset = blur_direction * offset;
		color += texture(screen_texture, SCREEN_UV + uv_offset);
	}
	COLOR = color / float(samples);
}
