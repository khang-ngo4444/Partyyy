shader_type spatial;
// Đất đảo: màu đỉnh R cát, G cỏ, B đá, A đất đường. Triplanar để vách đá không bị kéo giãn.
uniform sampler2D tex_cat : source_color, repeat_enable, filter_linear_mipmap_anisotropic;
uniform sampler2D tex_co : source_color, repeat_enable, filter_linear_mipmap_anisotropic;
uniform sampler2D tex_da : source_color, repeat_enable, filter_linear_mipmap_anisotropic;
uniform vec3 mau_dat_duong : source_color = vec3(0.60, 0.43, 0.27);
uniform vec3 mau_da_tuoi : source_color = vec3(1.25, 1.12, 0.95);
uniform vec3 mau_nui_lua : source_color = vec3(0.13, 0.11, 0.12);
uniform float muc_nuoc = -4.0;
uniform float ti_le_co = 0.17;
uniform float ti_le_da = 0.09;
uniform float ti_le_cat = 0.14;
varying vec3 v_goc;
varying vec3 v_phap;

vec3 triplanar(sampler2D t, vec3 p, vec3 w, float s) {
	return texture(t, p.zy * s).rgb * w.x + texture(t, p.xz * s).rgb * w.y + texture(t, p.xy * s).rgb * w.z;
}
float bien_thien(vec2 p) {
	return sin(p.x * 0.13 + sin(p.y * 0.21) * 1.7) * 0.5 + sin(p.y * 0.17 + sin(p.x * 0.09) * 2.1) * 0.5;
}
void vertex() {
	v_goc = VERTEX;
	v_phap = NORMAL;
}
void fragment() {
	vec3 w = pow(abs(normalize(v_phap)), vec3(5.0));
	w /= w.x + w.y + w.z;
	vec3 cat = triplanar(tex_cat, v_goc, w, ti_le_cat);
	vec3 co = triplanar(tex_co, v_goc, w, ti_le_co);
	vec3 da = triplanar(tex_da, v_goc, w, ti_le_da) * mau_da_tuoi;
	float lon = bien_thien(v_goc.xz);
	co *= mix(vec3(0.92, 1.0, 0.72), vec3(1.05, 1.08, 0.9), lon * 0.5 + 0.5);
	vec3 ket_hop = cat * COLOR.r + co * COLOR.g + da * COLOR.b;
	float vun = smoothstep(0.25, 0.7, COLOR.a + (co.g - 0.3) * 0.5);
	ket_hop = mix(ket_hop, mau_dat_duong * (0.8 + cat * 0.5), vun);
	// Tro núi lửa ở gần đỉnh, ánh đỏ gần miệng.
	float tam_dao = length(v_goc.xz);
	float tro = smoothstep(14.0, 26.0, v_goc.y) * smoothstep(20.0, 13.0, tam_dao);
	ket_hop = mix(ket_hop, da * mau_nui_lua * 2.8, tro);
	float gan_mieng = smoothstep(6.5, 3.5, tam_dao) * smoothstep(28.0, 33.0, v_goc.y);
	// Dưới nước: nhuộm xanh, sóng vân sáng.
	float sau = clamp((muc_nuoc - v_goc.y) / 9.0, 0.0, 1.0);
	float van = sin(v_goc.x * 1.3 + TIME * 0.7 + sin(v_goc.z * 1.1 + TIME * 0.5)) * sin(v_goc.z * 1.5 - TIME * 0.6);
	ket_hop = mix(ket_hop, ket_hop * vec3(0.55, 0.85, 0.85) + vec3(0.02, 0.07, 0.08) * (van * 0.5 + 0.5), step(0.001, sau));
	ALBEDO = ket_hop;
	ROUGHNESS = mix(0.95, 0.7, COLOR.b);
	SPECULAR = 0.25;
	EMISSION = vec3(1.0, 0.25, 0.04) * gan_mieng * 0.9;
}
