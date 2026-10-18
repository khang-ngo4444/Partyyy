shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never;

instance uniform float urgency : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	float pulse = 0.5 + 0.5 * sin(TIME * mix(4.0, 12.0, urgency));
	ALBEDO = mix(vec3(1.0, 0.5, 0.12), vec3(1.0, 0.08, 0.04), urgency);
	ALPHA = 0.24 + 0.36 * urgency + 0.1 * pulse;
}
