shader_type canvas_item;

// Sóng biển: nước dâng từ đáy lên che kín (0 → 1), rồi rút tiếp lên đỉnh để lộ cảnh mới (1 → 2).

uniform float tien_do : hint_range(0.0, 2.0) = 0.0;
uniform vec4 mau_nuoc : source_color = vec4(0.102, 0.561, 0.776, 1.0);
uniform vec4 mau_sau : source_color = vec4(0.067, 0.416, 0.631, 1.0);
uniform vec4 mau_bot : source_color = vec4(0.925, 0.984, 1.0, 1.0);
uniform vec4 mau_vien : source_color = vec4(0.169, 0.106, 0.239, 1.0);
uniform float bien_do_song = 0.035;
uniform float be_day_bot = 0.035;
uniform float be_day_vien = 0.008;

// Dư ra hai đầu để đỉnh sóng không lộ mép ở lúc che kín.
const float DU_MEP = 0.2;


float mat_song(vec2 uv, float pha) {
	return bien_do_song * sin(uv.x * 9.0 + TIME * 2.2 + pha) + bien_do_song * 0.5 * sin(uv.x * 21.0 - TIME * 3.1 + pha);
}


void fragment() {
	vec2 uv = UV;
	float song = mat_song(uv, 0.0);
	float song_duoi = mat_song(uv, 2.1);
	// Mép trên chạy từ dưới đáy lên đỉnh trong pha che, mép dưới chạy tương tự trong pha lộ.
	float muc_tren = mix(1.0 + DU_MEP, -DU_MEP, clamp(tien_do, 0.0, 1.0));
	float muc_duoi = mix(1.0 + DU_MEP, -DU_MEP, clamp(tien_do - 1.0, 0.0, 1.0));
	float cach_tren = uv.y - (muc_tren + song);
	float cach_duoi = (muc_duoi + song_duoi) - uv.y;
	float mem = fwidth(uv.y);

	float trong_nuoc = smoothstep(-mem, mem, cach_tren) * smoothstep(-mem, mem, cach_duoi);

	float gon = step(0.0, sin(uv.y * 34.0 + sin(uv.x * 7.0 + TIME) * 1.6));
	vec3 mau = mix(mau_nuoc.rgb, mau_sau.rgb, gon);
	float gan_mep = min(cach_tren, cach_duoi);
	mau = mix(mau_bot.rgb, mau, smoothstep(be_day_vien + be_day_bot - mem, be_day_vien + be_day_bot + mem, gan_mep));
	mau = mix(mau_vien.rgb, mau, smoothstep(be_day_vien - mem, be_day_vien + mem, gan_mep));

	COLOR = vec4(mau, trong_nuoc);
}
