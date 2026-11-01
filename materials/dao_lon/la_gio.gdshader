shader_type spatial;
render_mode cull_disabled, diffuse_burley;
// Lá cây: màu đỉnh RGB; A là độ đung đưa theo gió. Vân lá lấy từ độ sáng texture cỏ.
uniform sampler2D tex_la : source_color, repeat_enable, filter_linear_mipmap_anisotropic;
uniform float ti_le_la = 0.55;
uniform float cuong_do_gio = 0.09;
uniform float toc_gio = 1.4;
uniform vec3 xuyen_la : source_color = vec3(0.55, 0.75, 0.2);
varying vec3 v_goc;
varying vec3 v_phap;

void vertex() {
	v_goc = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_phap = NORMAL;
	float lan = sin(TIME * toc_gio + v_goc.x * 0.32 + v_goc.z * 0.26);
	float rung = sin(TIME * toc_gio * 3.1 + (v_goc.x + v_goc.y + v_goc.z) * 1.7) * 0.35;
	float s = COLOR.a * COLOR.a;
	VERTEX.x += (lan + rung) * cuong_do_gio * s * 3.0;
	VERTEX.z += (lan * 0.6 - rung) * cuong_do_gio * s * 2.0;
	VERTEX.y += rung * cuong_do_gio * s;
}
void fragment() {
	vec3 w = pow(abs(normalize(v_phap)), vec3(3.0));
	w /= w.x + w.y + w.z;
	vec3 t = texture(tex_la, v_goc.zy * ti_le_la).rgb * w.x + texture(tex_la, v_goc.xz * ti_le_la).rgb * w.y + texture(tex_la, v_goc.xy * ti_le_la).rgb * w.z;
	float sang = dot(t, vec3(0.3, 0.6, 0.1));
	ALBEDO = COLOR.rgb * clamp(sang * 3.0, 0.45, 1.5);
	BACKLIGHT = xuyen_la * COLOR.a;
	AO = clamp(sang * 3.0, 0.5, 1.0);
	ROUGHNESS = 0.66;
	SPECULAR = 0.25;
}
