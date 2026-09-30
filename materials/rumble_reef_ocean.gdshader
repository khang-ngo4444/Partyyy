shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;
uniform vec4 deep_color : source_color = vec4(0.015, 0.12, 0.22, 1.0);
uniform vec4 shallow_color : source_color = vec4(0.02, 0.48, 0.58, 1.0);
uniform vec4 crest_color : source_color = vec4(0.45, 0.95, 0.9, 1.0);
uniform float wave_height : hint_range(0.0, 2.0) = 0.30;
uniform float wave_scale : hint_range(0.01, 1.0) = 0.095;
uniform float wave_speed : hint_range(0.0, 3.0) = 0.65;
uniform float detail_scale : hint_range(0.01, 2.0) = 0.48;
varying float v_wave;
varying vec3 v_world_pos;
void vertex() {
	float t = TIME * wave_speed;
	float w1 = sin((VERTEX.x + t * 5.0) * wave_scale);
	float w2 = sin((VERTEX.z - t * 3.2) * wave_scale * 1.37);
	float w3 = sin((VERTEX.x + VERTEX.z + t * 2.1) * detail_scale) * 0.20;
	float waves = (w1 + w2) * 0.5 + w3;
	VERTEX.y += waves * wave_height;
	v_wave = waves;
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float dx = cos((VERTEX.x + t * 5.0) * wave_scale) * wave_scale * wave_height * 0.5;
	float dz = cos((VERTEX.z - t * 3.2) * wave_scale * 1.37) * wave_scale * 1.37 * wave_height * 0.5;
	NORMAL = normalize(vec3(-dx, 1.0, -dz));
}
void fragment() {
	float fresnel = pow(1.0 - clamp(dot(normalize(NORMAL), normalize(VIEW)), 0.0, 1.0), 3.5);
	float foam_noise = sin(v_world_pos.x * 0.75 + TIME) * sin(v_world_pos.z * 0.63 - TIME * 0.8);
	float crest = smoothstep(0.88, 1.18, v_wave + foam_noise * 0.10);
	vec3 base = mix(deep_color.rgb, shallow_color.rgb, 0.27 + v_wave * 0.08);
	ALBEDO = mix(base, crest_color.rgb, crest * 0.14);
	METALLIC = 0.18;
	ROUGHNESS = mix(0.16, 0.38, crest);
	SPECULAR = 0.92;
	EMISSION = shallow_color.rgb * (0.025 + fresnel * 0.055) + crest_color.rgb * crest * 0.08;
}
