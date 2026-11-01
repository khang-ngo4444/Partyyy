shader_type canvas_item;

// Ô bàn cờ: từng ô bung ra từ giữa màn hình tỏa ra rìa (0 → 1), rồi thu lại cùng thứ tự (1 → 2).

uniform float tien_do : hint_range(0.0, 2.0) = 0.0;
uniform vec4 mau_o_sang : source_color = vec4(0.953, 0.89, 0.737, 1.0);
uniform vec4 mau_o_toi : source_color = vec4(0.424, 0.753, 0.29, 1.0);
uniform vec4 mau_vien : source_color = vec4(0.169, 0.106, 0.239, 1.0);
uniform float so_o_doc = 8.0;
uniform float be_rong_vet = 0.3;
uniform float be_day_vien = 0.07;

// Cạnh ô phải vượt 0,5 thì mới lấp kín, gồm cả lúc ô xoay nghiêng.
const float NUA_CANH_KIN = 0.56;
const float GOC_NGHIENG_TOI_DA = 0.9;


float nua_canh(float pha, float vi_tri_quet) {
	return clamp((pha * (1.0 + be_rong_vet) - vi_tri_quet) / be_rong_vet, 0.0, 1.0) * NUA_CANH_KIN;
}


vec2 xoay(vec2 diem, float goc) {
	float c = cos(goc);
	float s = sin(goc);
	return vec2(c * diem.x - s * diem.y, s * diem.x + c * diem.y);
}


void fragment() {
	float ti_le = SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x;
	vec2 diem = UV * vec2(ti_le, 1.0);
	vec2 luoi = diem * so_o_doc;
	vec2 o = floor(luoi);
	vec2 trong_o = luoi - o - 0.5;
	vec2 tam_man = vec2(ti_le, 1.0) * 0.5 * so_o_doc;
	float xa_toi_da = length(tam_man);
	float vi_tri_quet = clamp(length(o + 0.5 - tam_man) / xa_toi_da, 0.0, 1.0);

	float n_che = nua_canh(min(tien_do, 1.0), vi_tri_quet);
	float n_lo = nua_canh(tien_do - 1.0, vi_tri_quet);
	// Ô vừa xoay vừa bung, tới cỡ đầy thì nằm thẳng khít lưới.
	float kc_che = max(abs(xoay(trong_o, (1.0 - n_che / NUA_CANH_KIN) * GOC_NGHIENG_TOI_DA).x),
			abs(xoay(trong_o, (1.0 - n_che / NUA_CANH_KIN) * GOC_NGHIENG_TOI_DA).y));
	float kc_lo = max(abs(xoay(trong_o, n_lo / NUA_CANH_KIN * GOC_NGHIENG_TOI_DA).x),
			abs(xoay(trong_o, n_lo / NUA_CANH_KIN * GOC_NGHIENG_TOI_DA).y));
	float mem = fwidth(luoi.x);

	float trong_che = n_che <= 0.0 ? 0.0 : 1.0 - smoothstep(n_che - mem, n_che + mem, kc_che);
	// Pha lộ: ô thu nhỏ dần về tâm thay vì đục lỗ.
	float con_lai = NUA_CANH_KIN - n_lo;
	float kc_con = kc_lo;
	float trong_lo = con_lai <= 0.0 ? 0.0 : 1.0 - smoothstep(con_lai - mem, con_lai + mem, kc_con);
	float dang_lo = step(1.0, tien_do);
	float hien = mix(trong_che, trong_lo, dang_lo);

	float la_o_sang = mod(o.x + o.y, 2.0);
	vec3 mau = mix(mau_o_toi.rgb, mau_o_sang.rgb, la_o_sang);
	float nua = dang_lo > 0.5 ? con_lai : n_che;
	float kc = dang_lo > 0.5 ? kc_con : kc_che;
	// Viền chỉ hiện khi ô còn đang bung/thu; ô đủ cỡ thì khít nhau, không kẻ lưới.
	float co_vien = step(nua, NUA_CANH_KIN - 0.001);
	float vien = smoothstep(nua - be_day_vien - mem, nua - be_day_vien + mem, kc) * co_vien;
	mau = mix(mau, mau_vien.rgb, vien);

	COLOR = vec4(mau, hien);
}
