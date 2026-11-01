shader_type spatial;
render_mode cull_disabled;
// Cánh vỗ: đỉnh càng xa thân (trục x) càng nhấc mạnh.
uniform float toc_vo = 6.0;
uniform float bien_do = 0.35;
void vertex() {
	float pha = MODEL_MATRIX[3].x * 3.1 + MODEL_MATRIX[3].z * 1.7;
	VERTEX.y += abs(VERTEX.x) * sin(TIME * toc_vo + pha) * bien_do;
}
void fragment() {
	ALBEDO = COLOR.rgb;
	ROUGHNESS = 0.7;
}
