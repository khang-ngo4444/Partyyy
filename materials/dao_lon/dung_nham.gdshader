shader_type spatial;
render_mode cull_disabled, specular_disabled;
// Dung nham: lớp vỏ đen nứt, lõi phát sáng chảy theo UV.
uniform vec3 mau_nong : source_color = vec3(1.0, 0.72, 0.16);
uniform vec3 mau_do : source_color = vec3(1.0, 0.16, 0.02);
uniform vec3 mau_vo : source_color = vec3(0.07, 0.03, 0.03);
uniform float do_sang = 3.2;
float te_bao(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	float d = 1.0;
	for (int y = -1; y <= 1; y++) {
		for (int x = -1; x <= 1; x++) {
			vec2 o = vec2(float(x), float(y));
			vec2 h = fract(sin(vec2(dot(i + o, vec2(127.1, 311.7)), dot(i + o, vec2(269.5, 183.3)))) * 43758.5453);
			vec2 r = o + 0.5 + 0.45 * sin(TIME * 0.25 + 6.2831 * h) - f;
			d = min(d, dot(r, r));
		}
	}
	return sqrt(d);
}
void fragment() {
	vec2 uv = UV * vec2(1.6, 1.0) - vec2(0.0, TIME * 0.12);
	float c = te_bao(uv * 1.5);
	float nut = smoothstep(0.62, 0.22, c);
	float lo = sin(TIME * 0.9 + UV.y * 3.0) * 0.08 + 0.92;
	vec3 chay = mix(mau_do, mau_nong, nut);
	vec3 v = mix(mau_vo, chay, smoothstep(0.75, 0.25, c));
	ALBEDO = v * 0.4;
	EMISSION = chay * smoothstep(0.8, 0.28, c) * do_sang * lo;
	ROUGHNESS = 0.8;
}
