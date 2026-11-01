shader_type canvas_item;

// Màn chuyển chấm tròn: chấm lớn dần quét chéo qua màn (0 → 1 che kín),
// rồi đục lỗ tròn cũng quét chéo để lộ cảnh mới (1 → 2).

uniform float tien_do : hint_range(0.0, 2.0) = 0.0;
uniform vec4 mau_nen : source_color = vec4(0.557, 0.361, 0.969, 1.0);
uniform vec4 mau_soc : source_color = vec4(0.647, 0.478, 0.984, 1.0);
uniform vec4 mau_vien : source_color = vec4(0.169, 0.106, 0.239, 1.0);
uniform float so_cham_doc = 11.0;
uniform float be_rong_vet = 0.35;
uniform float be_day_vien = 0.07;
uniform float toc_do_soc = 1.5;
uniform float so_soc = 18.0;

const float BAN_KINH_KIN = 0.8; // Hơn nửa đường chéo ô (0,707) để các chấm liền nhau.
const float CAN_BAC_HAI_NUA = 0.7071068;


float ban_kinh(float pha, float vi_tri_quet) {
	return clamp((pha * (1.0 + be_rong_vet) - vi_tri_quet) / be_rong_vet, 0.0, 1.0) * BAN_KINH_KIN;
}


void fragment() {
	float ti_le = SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x;
	vec2 diem = UV * vec2(ti_le, 1.0);
	// Lưới xoay 45 độ cho khác lưới vuông thường.
	mat2 xoay = mat2(vec2(CAN_BAC_HAI_NUA, CAN_BAC_HAI_NUA), vec2(-CAN_BAC_HAI_NUA, CAN_BAC_HAI_NUA));
	vec2 luoi = xoay * diem * so_cham_doc;
	vec2 goc_o = floor(luoi) + 0.5;
	float kc = length(luoi - goc_o);
	// Mốc quét lấy theo tâm ô để cả chấm lớn đều, không bị vát.
	vec2 tam = transpose(xoay) * goc_o / so_cham_doc;
	float vi_tri_quet = clamp((tam.x + tam.y) / (ti_le + 1.0), 0.0, 1.0);

	float r_che = ban_kinh(min(tien_do, 1.0), vi_tri_quet);
	float r_lo = ban_kinh(tien_do - 1.0, vi_tri_quet);
	float mem = fwidth(kc);

	float trong_cham = r_che <= 0.0 ? 0.0 : 1.0 - smoothstep(r_che - mem, r_che + mem, kc);
	float ngoai_lo = r_lo <= 0.0 ? 1.0 : smoothstep(r_lo - mem, r_lo + mem, kc);

	float soc = step(0.0, sin((diem.x + diem.y) * so_soc + TIME * toc_do_soc));
	vec3 mau = mix(mau_nen.rgb, mau_soc.rgb, soc);
	float gan_mep_che = r_che < BAN_KINH_KIN ? smoothstep(r_che - be_day_vien - mem, r_che - be_day_vien + mem, kc) : 0.0;
	float gan_mep_lo = r_lo > 0.0 ? 1.0 - smoothstep(r_lo + be_day_vien - mem, r_lo + be_day_vien + mem, kc) : 0.0;
	mau = mix(mau, mau_vien.rgb, max(gan_mep_che, gan_mep_lo));

	COLOR = vec4(mau, trong_cham * ngoai_lo);
}
