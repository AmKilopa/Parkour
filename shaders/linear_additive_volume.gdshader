shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_test_disabled;

uniform sampler2D depth_texture : hint_depth_texture;
uniform vec3 color : source_color = vec3(0.9, 0.92, 1.0);
uniform float density := 0.02;

void fragment() {
	vec3 scene_clip_pos = vec3(SCREEN_UV * 2.0 - 1.0, texture(depth_texture, SCREEN_UV).r);
	vec4 scene_view_pos = INV_PROJECTION_MATRIX * vec4(scene_clip_pos, 1.0);
	scene_view_pos.xyz /= scene_view_pos.w;
	float scene_dist = length(scene_view_pos.xyz);

	float dist = length(VERTEX);

	if (!FRONT_FACING) {
		dist = min(dist, scene_dist);
	} else {
		dist = -dist;
		dist = max(dist, -scene_dist);
	}
	ALBEDO = dist * color * density;
}
