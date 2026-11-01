shader_type spatial;
render_mode diffuse_lambert_wrap, specular_disabled;
// Mây: sáng mềm, viền rực phía ngược sáng, đáy mây lấy màu trời.
uniform vec3 mau_vien : source_color = vec3(1.0, 0.96, 0.86);
void fragment() {
	float fresnel = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 2.5);
	ALBEDO = COLOR.rgb;
	EMISSION = COLOR.rgb * 0.28 + mau_vien * fresnel * 0.35;
	ROUGHNESS = 1.0;
}
