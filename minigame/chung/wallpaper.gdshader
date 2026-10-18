shader_type spatial;
render_mode cull_back;

uniform sampler2D wallpaper : source_color, filter_linear_mipmap, repeat_disable;
uniform vec2 wall_size = vec2(48.0, 52.0);
uniform float wall_top = 36.0;
uniform float artwork_height = 12.0;
uniform vec4 tint : source_color = vec4(1.0);
uniform bool receive_lighting = false;

void fragment() {
	// Repeat horizontally; extend the sky and ground edge colors vertically.
	// Artwork keeps its proportions instead of stretching up the entire room.
	float artwork_bottom = -2.0;
	float artwork_top = artwork_bottom + artwork_height;
	vec2 artwork_uv = vec2(
		fract(UV.x * wall_size.x / (artwork_height * 4.0)),
		clamp((UV.y * wall_size.y - (wall_top - artwork_top)) / artwork_height, 0.001, 0.999)
	);
	vec3 color = texture(wallpaper, artwork_uv).rgb * tint.rgb;
	ALBEDO = receive_lighting ? color : vec3(0.0);
	EMISSION = receive_lighting ? vec3(0.0) : color;
	ROUGHNESS = 1.0;
}
