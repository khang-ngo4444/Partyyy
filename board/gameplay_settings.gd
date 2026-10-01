class_name GameplaySettings
extends RefCounted

## Cấu hình luật dùng chung cho màn tạo phòng, MatchState và bàn party.
## Chỉ lưu kiểu JSON-safe để có thể replicate nguyên gói qua Fusion.

const DEFAULTS := {
	"tile_land": 40,
	"tile_health": 20,
	"tile_money": 25,
	"tile_equipment": 15,
	"max_health": 10,
	"start_gold": 0,
	"health_gain": 3,
	"money_gain": 15,
	"chest_cost": 100,
	"respawn_steps": 18,
	"tax_health": 2,
	"tax_money": 10,
	"minigame_second_gold": 30,
	"minigame_reward_drop": 10,
	"minigame_min_gold": 5,
}

const PERCENT_KEYS := ["tile_land", "tile_health", "tile_money", "tile_equipment"]


static func defaults() -> Dictionary:
	return DEFAULTS.duplicate(true)


static func sanitize(raw: Dictionary) -> Dictionary:
	var out := defaults()
	for key in out:
		if raw.has(key):
			out[key] = int(raw[key])
	for key in PERCENT_KEYS:
		out[key] = clampi(int(out[key]), 0, 100)
	out["max_health"] = clampi(int(out["max_health"]), 1, 100)
	out["start_gold"] = clampi(int(out["start_gold"]), 0, 9999)
	out["health_gain"] = clampi(int(out["health_gain"]), 1, int(out["max_health"]))
	out["money_gain"] = clampi(int(out["money_gain"]), 1, 999)
	out["chest_cost"] = clampi(int(out["chest_cost"]), 1, 9999)
	out["respawn_steps"] = clampi(int(out["respawn_steps"]), 1, 999)
	out["tax_health"] = clampi(int(out["tax_health"]), 1, int(out["max_health"]))
	out["tax_money"] = clampi(int(out["tax_money"]), 1, 999)
	out["minigame_second_gold"] = clampi(int(out["minigame_second_gold"]), 0, 999)
	out["minigame_reward_drop"] = clampi(int(out["minigame_reward_drop"]), 0, 999)
	out["minigame_min_gold"] = clampi(int(out["minigame_min_gold"]), 0, 999)
	return out


static func percent_total(settings: Dictionary) -> int:
	var total := 0
	for key in PERCENT_KEYS:
		total += int(settings.get(key, 0))
	return total


static func valid(settings: Dictionary) -> bool:
	return percent_total(settings) == 100


static func encode(settings: Dictionary) -> String:
	return JSON.stringify(sanitize(settings))


static func decode(value: String) -> Dictionary:
	var parsed = JSON.parse_string(value)
	return sanitize(parsed if parsed is Dictionary else {})
