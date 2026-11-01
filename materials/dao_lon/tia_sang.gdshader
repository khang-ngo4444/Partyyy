shader_type spatial;
render_mode blend_add, unshaded, cull_disabled, depth_draw_never;
// Tia đèn biển: màu đỉnh A giảm dần theo chiều dài, mờ đi ở mép nón.
uniform vec3 mau_tia : source_color = vec3(1.0, 0.9, 0.62);
void fragment() {
	float mep = pow(abs(dot(normalize(NORMAL), normalize(VIEW))), 1.4);
	ALBEDO = mau_tia;
	ALPHA = COLOR.a * mep * 0.55;
}
