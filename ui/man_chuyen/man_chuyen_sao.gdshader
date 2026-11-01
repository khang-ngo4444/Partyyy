shader_type canvas_item;

// Ngôi sao: màn đêm khép lại quanh một ngôi sao đến khi tối hẳn (0 → 1), rồi sao mở lớn dần (1 → 2).

uniform float tien_do : hint_range(0.0, 2.0) = 0.0;
uniform vec4 mau_dem : source_color = vec4(0.169, 0.106, 0.239, 1.0);
uniform vec4 mau_dem_sang : source_color = vec4(0.247, 0.165, 0.341, 1.0);
uniform vec4 mau_vang : source_color = vec4(1.0, 0.835, 0.31, 1.0);
uniform float ban_kinh_lon_nhat = 1.9;
uniform float be_day_vien = 0.03;
uniform float so_cham_nen = 26.0;

const float TAU_CUA_SAO = 6.2831853;
const float SO_CANH = 5.0;
const float BAN_KINH_TRONG = 0.42;


// Khoảng cách có dấu tới hình sao năm cánh cạnh thẳng, đỉnh ở bán kính 1 (âm là bên trong).
// Gấp mặt phẳng về một nửa cánh rồi đo tới đoạn nối đỉnh cánh với góc lõm.
float kc_sao(vec2 p) {
	float goc = atan(p.x, -p.y);
	float buoc = TAU_CUA_SAO / SO_CANH;
	float lech = abs(mod(goc + buoc * 0.5, buoc) - buoc * 0.5);
	vec2 diem = length(p) * vec2(cos(lech), sin(lech));
	vec2 dinh = vec2(1.0, 0.0);
	vec2 lom = BAN_KINH_TRONG * vec2(cos(buoc * 0.5), sin(buoc * 0.5));
	vec2 canh = normalize(lom - dinh);
	return dot(diem - dinh, vec2(-canh.y, canh.x)) * -1.0;
}


vec2 xoay(vec2 p, float goc) {
	float c = cos(goc);
	float s = sin(goc);
	return vec2(c * p.x - s * p.y, s * p.x + c * p.y);
}


void fragment() {
	float ti_le = SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x;
	vec2 p = (UV - 0.5) * vec2(ti_le, 1.0);
	float mo_rong = tien_do <= 1.0 ? 1.0 - tien_do : tien_do - 1.0;
	float r = ban_kinh_lon_nhat * mo_rong * mo_rong;

	// r = 0 thì che kín hoàn toàn, tránh chia cho 0.
	float kc = r <= 0.001 ? 1.0 : kc_sao(xoay(p, (1.0 - mo_rong) * 1.4) / r) * r;
	float mem = fwidth(p.y);
	float ngoai_sao = smoothstep(-mem, mem, kc);

	vec2 luoi = fract(p * so_cham_nen) - 0.5;
	float cham = 1.0 - smoothstep(0.1, 0.13, length(luoi));
	vec3 mau = mix(mau_dem.rgb, mau_dem_sang.rgb, cham);
	mau = mix(mau_vang.rgb, mau, smoothstep(be_day_vien - mem, be_day_vien + mem, kc));

	COLOR = vec4(mau, ngoai_sao);
}
