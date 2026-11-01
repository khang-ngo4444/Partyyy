shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_disabled;
// Sông và thác: UV.y theo mét dọc dòng, UV.x ngang dòng; màu đỉnh R = độ dốc.
uniform vec3 mau_nuoc : source_color = vec3(0.10, 0.70, 0.78);
uniform vec3 mau_bot : source_color = vec3(0.93, 0.99, 1.0);
uniform float toc_chay = 2.4;
float vat(vec2 p) {
	return sin(p.x * 11.0 + sin(p.y * 2.3) * 1.5) * 0.5 + sin(p.y * 3.7 + p.x * 6.0) * 0.5;
}
void fragment() {
	float doc = COLOR.r;
	float chay = TIME * toc_chay * (1.0 + doc * 2.5);
	vec2 uv = vec2(UV.x, UV.y - chay);
	float n = vat(uv) * 0.6 + vat(uv * 1.9 + 3.1) * 0.4;
	float mep = smoothstep(0.0, 0.16, UV.x) * smoothstep(1.0, 0.84, UV.x);
	float bot = smoothstep(0.55 - doc * 1.0, 0.8, n * 0.5 + 0.5) * (0.2 + doc * 1.1);
	bot = max(bot, (1.0 - mep) * 0.5 * (0.6 + n * 0.4));
	ALBEDO = mix(mau_nuoc, mau_bot, clamp(bot, 0.0, 1.0));
	EMISSION = ALBEDO * 0.22;
	ALPHA = clamp(0.72 + bot * 0.4 + doc * 0.3, 0.0, 1.0);
	ROUGHNESS = mix(0.08, 0.7, bot);
	SPECULAR = 0.6;
	NORMAL_MAP = normalize(vec3(n * 0.2 + 0.5, 0.5 - n * 0.1, 1.0));
}
