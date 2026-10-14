class_name HuongDanNhanh
extends RefCounted

## Chỉ mục tiêu và thao tác chính trước ván. Luật đầy đủ nằm trong Cách chơi.
const TRO := {
	"tank_battle": ["Sống sót tới cuối trận", "WASD di chuyển · J / Space bắn", "10_tank"],
	"breaking_blocks": ["Né nhóm sàn sắp rớt, đừng ngã", "WASD di chuyển · Space nhảy", "11_breaking_blocks"],
	"laser_leap": ["Né tia laser đang quét sân", "WASD di chuyển", "12_laser_leap"],
	"spotlights": ["Nhớ vị trí, né spotlight khi tối", "WASD di chuyển", "13_spotlights"],
	"magma": ["Hất đối thủ vào dung nham đang dâng", "WASD di chuyển · Chuột ngắm / bắn", "14_magma"],
	"explosive": ["Chuyền bom trước khi nổ", "WASD di chuyển · E chuyền", "15_explosive"],
	"crown": ["Giữ vương miện lâu nhất", "WASD di chuyển · Chạm để cướp", "16_crown"],
	"temporal_trails": ["Né tường sáng, sống sót tới cuối", "A / D rẽ · Nhân vật tự chạy", "17_temporal_trails"],
	"word_wars": ["Ghép đúng từ trên đầu", "WASD di chuyển · E nhập chữ", "18_word_wars"],
	"dem_thu": ["Đếm đúng loại thú được hỏi", "W / S chỉnh số · Space chốt", "19_dem_thu"],
	"toy_factory": ["Ghép đủ 5 mảnh tại bàn của mình", "WASD chạy · E nhặt / lắp · Chuột bắn", "23_toy_factory"],
	"wave_hide": ["Trú sau đá để tránh sóng biển", "WASD chạy · E đẩy", "24_wave_hide"],
	"minefield": ["Luồn qua đường mìn, tránh xe lu", "WASD chạy · Chuột phải dò mìn · 2 mạng", "26_minefield"],
	"paint": ["Phủ màu của mình nhiều nhất trên sân", "WASD rải sơn · Chuột trái / F đánh", "25_paint"],
	"lo_da": ["Lên đỉnh, né đá và thiên thạch", "WASD di chuyển", "20_lo_da"],
}

static func tom_tat(code: String) -> String:
	var info: Array = TRO.get(code, [])
	return "%s\n%s" % [info[0], info[1]] if info.size() >= 2 else ""

static func trang_chi_tiet(code: String) -> String:
	var info: Array = TRO.get(code, [])
	return str(info[2]) if info.size() >= 3 else ""

static func co_diem_rieng(code: String) -> bool:
	return code in ["word_wars", "crown", "dem_thu", "toy_factory", "wave_hide", "minefield", "paint"]

static func hang_gon(ranking: Array, local_id: int) -> Array:
	var result := ranking.slice(0, 2)
	if ranking.has(local_id) and not result.has(local_id):
		result.append(local_id)
	return result
