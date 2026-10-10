shader_type spatial;
render_mode unshaded, cull_disabled;

// Lượt 2 của viền ngắm (next_pass của `vien_ghi`): vỏ nở ra (vẽ hai mặt, để lá bài/mặt phẳng mỏng
// cũng có viền), chỉ vẽ chỗ stencil != 1 nên chỉ còn vành quanh vật. Màu cố định, không phụ thuộc màu/vật liệu gốc; bị tường che như thường.
stencil_mode read, compare_not_equal, 1;

uniform vec4 mau : source_color = vec4(0.1, 0.9, 1.0, 1.0);
uniform float sang = 2.5;
uniform float day_px = 3.0;
// Tâm và nửa kích thước hộp bao của lưới (hệ toạ độ lưới) — script đặt từ `get_aabb()`.
uniform vec3 tam = vec3(0.0);
uniform vec3 nua = vec3(1.0);
// Pha pháp tuyến vào hướng nở; 0 = thuần theo vị trí.
uniform float theo_phap_tuyen = 0.35;

void vertex() {
	// Hướng nở là hàm của VỊ TRÍ đỉnh nên các đỉnh trùng nhau (mép cứng của mesh flat-shaded)
	// luôn nở cùng chiều, không hở; nhờ chia theo nửa kích thước nên mặt phẳng mỏng vẫn nở trong mặt.
	vec3 huong = (VERTEX - tam) / max(nua, vec3(0.001));
	huong = normalize(huong + NORMAL * theo_phap_tuyen + vec3(0.0001));
	vec4 p = PROJECTION_MATRIX * MODELVIEW_MATRIX * vec4(VERTEX, 1.0);
	vec2 d = (PROJECTION_MATRIX * (MODELVIEW_MATRIX * vec4(huong, 0.0))).xy;
	// Nở đúng day_px điểm ảnh ở mọi khoảng cách.
	p.xy += normalize(d + vec2(0.0001)) * day_px * 2.0 / VIEWPORT_SIZE * p.w;
	POSITION = p;
}

void fragment() {
	ALBEDO = mau.rgb * sang;
	ALPHA = mau.a;
}
