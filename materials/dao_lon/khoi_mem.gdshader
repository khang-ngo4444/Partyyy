shader_type spatial;
render_mode blend_mix, unshaded, depth_draw_never, cull_disabled;
// Khói hạt: cuộn tròn viền vỡ theo nhiễu, lớn dần theo tuổi, mời dần khi chạm vật khác.
uniform sampler2D tex_do_sau : hint_depth_texture, filter_nearest;
uniform float do_day = 0.85;
uniform float khoang_mo_cham = 1.2;
uniform float to_luc_dau = 0.45;
uniform float to_luc_cuoi = 1.5;
varying float v_tuoi;
varying float v_hat;

float ngau(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}
float nhieu(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(ngau(i), ngau(i + vec2(1.0, 0.0)), u.x), mix(ngau(i + vec2(0.0, 1.0)), ngau(i + vec2(1.0, 1.0)), u.x), u.y);
}
float fbm(vec2 p) {
	return nhieu(p) * 0.55 + nhieu(p * 2.1 + 3.7) * 0.3 + nhieu(p * 4.3 + 9.1) * 0.15;
}
void vertex() {
	v_tuoi = INSTANCE_CUSTOM.y;
	v_hat = INSTANCE_CUSTOM.x;
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(MAIN_CAM_INV_VIEW_MATRIX[0], MAIN_CAM_INV_VIEW_MATRIX[1], MAIN_CAM_INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
	float c = cos(v_hat);
	float s = sin(v_hat);
	float to = length(MODEL_MATRIX[0].xyz) * mix(to_luc_dau, to_luc_cuoi, v_tuoi);
	VERTEX.xy = mat2(vec2(c, s), vec2(-s, c)) * VERTEX.xy * to;
	MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
}
void fragment() {
	vec2 tam = UV * 2.0 - 1.0;
	float n = fbm(UV * 3.2 + vec2(v_hat * 7.3, v_hat * 3.1 - TIME * 0.08));
	float cuon = 1.0 - smoothstep(0.15, 1.0, length(tam) + (n - 0.5) * 0.9);
	float z = texture(tex_do_sau, SCREEN_UV).r;
	vec4 sau = INV_PROJECTION_MATRIX * vec4(SCREEN_UV * 2.0 - 1.0, z, 1.0);
	float cham = clamp((VERTEX.z - sau.z / sau.w) / khoang_mo_cham, 0.0, 1.0);
	float sang = 0.78 + 0.34 * n;
	ALBEDO = COLOR.rgb * sang;
	ALPHA = COLOR.a * cuon * cuon * do_day * cham;
}
