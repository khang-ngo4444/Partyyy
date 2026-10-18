shader_type spatial;

uniform sampler2D paint_map : source_color, filter_nearest, repeat_disable;
uniform vec2 arena_origin = vec2(0.0);
uniform float map_size = 28.0;
varying vec3 world_position;
varying vec3 world_normal;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = MODEL_NORMAL_MATRIX * NORMAL;
}

void fragment() {
	vec2 map_uv = (world_position.xz - arena_origin) / map_size + vec2(0.5);
	vec3 paint = texture(paint_map, clamp(map_uv, vec2(0.0), vec2(1.0))).rgb;
	float top = step(0.5, world_normal.y);
	ALBEDO = mix(vec3(0.22, 0.28, 0.4), paint, top);
	ROUGHNESS = 0.65;
}
