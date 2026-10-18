class_name PoolMiniGame
extends RefCounted

## Túi rút không hoàn lại; dữ liệu JSON nằm trong MatchState để đổi chủ phòng vẫn giữ pool.
static func con_lai(state: Dictionary, codes: PackedStringArray) -> Array[String]:
	var remaining: Array[String] = []
	var source: Array = state.get("remaining", Array(codes))
	for code: Variant in source:
		if codes.has(str(code)) and not remaining.has(str(code)):
			remaining.append(str(code))
	if remaining.is_empty():
		for code: String in codes:
			if not remaining.has(code):
				remaining.append(code)
	return remaining


static func chon(state: Dictionary, codes: PackedStringArray, rng: RandomNumberGenerator,
		preferred: String = "") -> String:
	var remaining := con_lai(state, codes)
	if remaining.is_empty():
		return ""
	if remaining.has(preferred):
		return preferred
	# Qua chu kỳ mới cũng tránh lặp ngay trò cuối cùng nếu còn lựa chọn khác.
	var last := str(state.get("last", ""))
	if remaining.size() > 1 and remaining.size() == codes.size():
		remaining.erase(last)
	return remaining[rng.randi_range(0, remaining.size() - 1)]


static func da_choi(state: Dictionary, codes: PackedStringArray, code: String) -> Dictionary:
	var remaining := con_lai(state, codes)
	remaining.erase(code)
	return {"remaining": remaining, "last": code}
