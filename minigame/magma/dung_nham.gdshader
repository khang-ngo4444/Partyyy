shader_type spatial;
render_mode cull_disabled;
varying vec3 world_position;

vec2 hash2(vec2 p) {
	return fract(sin(vec2(dot(p, vec2(127.1, 311.7)),
		dot(p, vec2(269.5, 183.3)))) * 43758.5453);
}

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 p = world_position.xz * 0.65 + vec2(TIME * 0.055, TIME * -0.035);
	vec2 cell = floor(p);
	vec2 local = fract(p);
	float first = 8.0;
	float second = 8.0;
	for (int y = -1; y <= 1; y++) {
		for (int x = -1; x <= 1; x++) {
			vec2 offset = vec2(float(x), float(y));
			vec2 seed = hash2(cell + offset);
			vec2 point = offset + 0.5 + 0.30 * sin(TIME * 0.35 + seed * 6.28318) - local;
			float distance_squared = dot(point, point);
			if (distance_squared < first) {
				second = first;
				first = distance_squared;
			} else {
				second = min(second, distance_squared);
			}
		}
	}
	float veins = 1.0 - smoothstep(0.025, 0.16, second - first);
	float pulse = 0.5 + 0.5 * sin(TIME * 1.5 + world_position.x * 0.7 + world_position.z * 0.4);
	vec3 crust = mix(vec3(0.05, 0.008, 0.003), vec3(0.16, 0.018, 0.006), pulse);
	vec3 molten = mix(vec3(1.0, 0.12, 0.01), vec3(1.0, 0.42, 0.035), pulse);
	ALBEDO = mix(crust, molten, veins);
	EMISSION = molten * (veins * 0.9 + 0.08);
	ROUGHNESS = 0.8;
}
