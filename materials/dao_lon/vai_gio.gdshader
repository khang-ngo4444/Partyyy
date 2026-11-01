shader_type spatial;
render_mode cull_disabled;
// Vải: cờ, buồm, dây cờ. Màu đỉnh A là độ bay theo gió.
uniform float bien_do = 0.09;
uniform float toc_do = 5.0;
void vertex() {
	float pha = dot(VERTEX, vec3(1.3, 0.9, 1.1)) + MODEL_MATRIX[3].x;
	float lan = sin(TIME * toc_do + pha) + sin(TIME * toc_do * 1.7 + pha * 2.3) * 0.4;
	VERTEX += vec3(0.4, 0.15, 1.0) * lan * bien_do * COLOR.a;
}
void fragment() {
	ALBEDO = COLOR.rgb;
	ROUGHNESS = 0.85;
	SPECULAR = 0.2;
	BACKLIGHT = COLOR.rgb * 0.35;
}
