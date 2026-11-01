shader_type spatial;
render_mode blend_mix, unshaded, cull_disabled, depth_draw_never;
// Vệt bọt sau thuyền: A mờ dần về cuối, vân chảy ngược hướng đi.
varying vec3 v_goc;
void vertex() {
	v_goc = VERTEX;
}
void fragment() {
	float z = v_goc.z + TIME * 3.0;
	// Vân chỉ làm mềm mép, không tạo ô lưới khi nhìn xa.
	float van = sin(z * 0.45 + sin(v_goc.x * 0.8) * 1.5) * 0.5 + 0.5;
	ALBEDO = vec3(0.95, 1.0, 1.0);
	ALPHA = COLOR.a * mix(0.6, 1.0, van) * 0.32;
}
