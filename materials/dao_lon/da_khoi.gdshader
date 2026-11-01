shader_type spatial;
// Đá công trình: texture đá triplanar nhuộm màu đỉnh, không kéo giãn khi co giãn mesh.
uniform sampler2D tex_da : source_color, repeat_enable, filter_linear_mipmap_anisotropic;
uniform float ti_le = 0.28;
uniform float do_tuong_phan = 0.55;
varying vec3 v_goc;
varying vec3 v_phap;
void vertex() {
	v_goc = VERTEX;
	v_phap = NORMAL;
}
void fragment() {
	vec3 w = pow(abs(normalize(v_phap)), vec3(4.0));
	w /= w.x + w.y + w.z;
	vec3 t = texture(tex_da, v_goc.zy * ti_le).rgb * w.x + texture(tex_da, v_goc.xz * ti_le).rgb * w.y + texture(tex_da, v_goc.xy * ti_le).rgb * w.z;
	float sang = dot(t, vec3(0.33));
	vec3 chi_tiet = mix(vec3(1.0), vec3(sang * 4.8), do_tuong_phan);
	ALBEDO = COLOR.rgb * chi_tiet;
	ROUGHNESS = 0.82;
	SPECULAR = 0.3;
}
