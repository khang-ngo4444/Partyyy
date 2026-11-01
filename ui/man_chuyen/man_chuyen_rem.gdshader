shader_type canvas_item;

// Rèm sân khấu: hai tấm rèm khép vào giữa (0 → 1), rồi kéo ngược ra hai bên (1 → 2).

uniform float tien_do : hint_range(0.0, 2.0) = 0.0;
uniform vec4 mau_rem : source_color = vec4(0.835, 0.184, 0.227, 1.0);
uniform vec4 mau_nep : source_color = vec4(0.612, 0.106, 0.173, 1.0);
uniform vec4 mau_tua : source_color = vec4(1.0, 0.835, 0.31, 1.0);
uniform vec4 mau_vien : source_color = vec4(0.169, 0.106, 0.239, 1.0);
uniform float so_nep = 34.0;
uniform float be_day_tua = 0.014;
uniform float be_day_vien = 0.005;
uniform float do_gon_mep = 0.012;

// Tràn qua giữa một chút để hai mép gợn sóng không hở khe lúc khép kín.
const float PHU_QUA_GIUA = 0.04;


void fragment() {
	float khep = tien_do <= 1.0 ? tien_do : 2.0 - tien_do;
	// Chậm dần ở cuối hành trình, như rèm nặng.
	khep = 1.0 - pow(1.0 - clamp(khep, 0.0, 1.0), 2.0);

	float tu_mep = abs(UV.x - 0.5);
	float gon = sin(UV.y * 18.0) * do_gon_mep;
	// `tu_mep` = 0,5 ở rìa màn, 0 ở giữa; rèm phủ từ rìa vào.
	float bien = 0.5 - khep * (0.5 + PHU_QUA_GIUA) + gon;
	float cach = tu_mep - bien;
	float mem = fwidth(UV.x);

	float trong_rem = smoothstep(-mem, mem, cach);
	// Nếp rèm dồn dày lại khi rèm kéo ra, giãn ra khi khép.
	float nep = 0.5 + 0.5 * sin(cach * so_nep * 6.2831 / max(khep, 0.2) * 0.25);
	vec3 mau = mix(mau_nep.rgb, mau_rem.rgb, smoothstep(0.25, 0.75, nep));
	mau = mix(mau_tua.rgb, mau, smoothstep(be_day_vien + be_day_tua - mem, be_day_vien + be_day_tua + mem, cach));
	mau = mix(mau_vien.rgb, mau, smoothstep(be_day_vien - mem, be_day_vien + mem, cach));

	COLOR = vec4(mau, trong_rem);
}
