shader_type spatial;
// Vật tự sáng (cửa sổ, đèn, pha lê): màu lấy từ màu đỉnh.
uniform float do_sang = 2.4;
void fragment() {
	ALBEDO = COLOR.rgb * 0.4;
	EMISSION = COLOR.rgb * do_sang;
	ROUGHNESS = 0.4;
}
