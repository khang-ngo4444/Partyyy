shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_back, diffuse_burley, specular_schlick_ggx;
// Biển: sóng gộp, đổi màu theo độ sâu thật, bọt quanh bờ, khúc xạ màn hình.
uniform sampler2D tex_man_hinh : hint_screen_texture, filter_linear_mipmap;
uniform sampler2D tex_do_sau : hint_depth_texture, filter_nearest;
uniform vec3 mau_nong : source_color = vec3(0.13, 0.88, 0.82);
uniform vec3 mau_giua : source_color = vec3(0.02, 0.52, 0.72);
uniform vec3 mau_sau : source_color = vec3(0.006, 0.17, 0.42);
uniform vec3 mau_bot : source_color = vec3(0.96, 1.0, 0.98);
uniform float cao_song : hint_range(0.0, 2.0) = 0.34;
uniform float toc_song : hint_range(0.0, 3.0) = 0.7;
uniform float sau_nong : hint_range(0.1, 10.0) = 2.4;
uniform float sau_toi_da : hint_range(1.0, 60.0) = 13.0;
uniform float rong_bot : hint_range(0.05, 4.0) = 0.85;
varying vec3 v_the_gioi;
varying float v_song;

vec3 song_gerstner(vec2 p, vec2 d, float dai, float bien, float t) {
	float k = 6.2832 / dai;
	float f = k * dot(d, p) + t * sqrt(9.8 * k);
	return vec3(d.x * bien * cos(f), bien * sin(f), d.y * bien * cos(f));
}
vec3 tong_song(vec2 p, float t) {
	vec3 c = song_gerstner(p, normalize(vec2(1.0, 0.35)), 31.0, 0.55, t);
	c += song_gerstner(p, normalize(vec2(-0.5, 1.0)), 17.0, 0.3, t * 1.1);
	c += song_gerstner(p, normalize(vec2(0.8, -0.9)), 9.0, 0.16, t * 1.2);
	return c;
}
float nhieu_vat(vec2 p, float t) {
	float n = sin(p.x * 0.9 + t * 0.9 + sin(p.y * 0.7 - t * 0.5) * 1.4);
	n += sin(p.y * 1.3 - t * 1.1 + sin(p.x * 1.7 + t * 0.4) * 1.1);
	n += sin((p.x + p.y) * 2.6 + t * 1.6) * 0.5;
	return n / 2.5;
}
void vertex() {
	float t = TIME * toc_song;
	float eps = 0.6;
	vec3 cx = tong_song(VERTEX.xz + vec2(eps, 0.0), t) * cao_song;
	vec3 cz = tong_song(VERTEX.xz + vec2(0.0, eps), t) * cao_song;
	vec3 c0 = tong_song(VERTEX.xz, t) * cao_song;
	NORMAL = normalize(vec3(-(cx.y - c0.y) / eps, 1.0, -(cz.y - c0.y) / eps));
	VERTEX += c0;
	v_song = c0.y;
	v_the_gioi = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}
void fragment() {
	float t = TIME * toc_song;
	float z = texture(tex_do_sau, SCREEN_UV).r;
	vec4 sau_dau = INV_PROJECTION_MATRIX * vec4(SCREEN_UV * 2.0 - 1.0, z, 1.0);
	sau_dau.xyz /= sau_dau.w;
	float sau = clamp(VERTEX.z - sau_dau.z, 0.0, 200.0);
	float m1 = nhieu_vat(v_the_gioi.xz * 0.55, t * 0.9);
	float m2 = nhieu_vat(v_the_gioi.zx * 1.35 + 7.0, t * 1.3);
	// Gợn nhỏ tắt dần theo khoảng cách để biển xa không bị nhiễu.
	float gan = exp(VERTEX.z * 0.012);
	vec3 lech = vec3(m1 + m2, 3.0, m2 - m1) * 0.05 * gan;
	NORMAL = normalize(mat3(VIEW_MATRIX) * (normalize(mat3(INV_VIEW_MATRIX) * NORMAL) + vec3(lech.x, 0.0, lech.z)));
	vec2 uv_khuc = SCREEN_UV + lech.xz * 0.04 * smoothstep(0.0, 2.0, sau);
	float z2 = texture(tex_do_sau, uv_khuc).r;
	vec4 d2 = INV_PROJECTION_MATRIX * vec4(uv_khuc * 2.0 - 1.0, z2, 1.0);
	if (d2.z / d2.w > VERTEX.z) {
		uv_khuc = SCREEN_UV;
	}
	vec3 day = textureLod(tex_man_hinh, uv_khuc, 0.0).rgb;
	float tn = 1.0 - exp(-sau / sau_nong);
	float ts = 1.0 - exp(-sau / sau_toi_da);
	vec3 mau_nuoc = mix(mau_nong, mau_giua, tn);
	mau_nuoc = mix(mau_nuoc, mau_sau, ts);
	float trong = exp(-sau / (sau_nong * 1.4));
	vec3 ket_qua = mix(mau_nuoc, day * mix(vec3(1.0), mau_nong * 1.2, 0.5), trong * 0.85);
	// Bọt: viền bờ gợn sóng và ngọn sóng.
	float vien = 1.0 - smoothstep(0.0, rong_bot * (0.75 + 0.45 * sin(t * 0.8 + m1 * 3.0)), sau);
	float vong = smoothstep(0.82, 1.0, sin(sau * 3.2 - t * 1.6 + m2 * 2.2)) * exp(-sau * 0.75);
	float vun = smoothstep(0.1, 0.6, m1 * 0.5 + m2 * 0.5 + 0.2);
	float bot = clamp(vien + vong * vun, 0.0, 1.0);
	float ngon = smoothstep(0.26, 0.42, v_song) * smoothstep(0.35, 0.75, m2) * gan;
	bot = max(bot, ngon * 0.7);
	ket_qua = mix(ket_qua, mau_bot, bot);
	ALBEDO = ket_qua * 0.02;
	EMISSION = ket_qua * 0.98 * (1.0 - bot * 0.3);
	float fresnel = pow(1.0 - clamp(dot(normalize(NORMAL), normalize(VIEW)), 0.0, 1.0), 4.0);
	EMISSION += vec3(0.55, 0.78, 0.95) * fresnel * 0.35;
	METALLIC = 0.0;
	ROUGHNESS = mix(0.07, 0.6, bot);
	SPECULAR = 0.55;
	ALPHA = 1.0;
}
