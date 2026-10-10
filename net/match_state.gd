class_name MatchState
extends Node3D

## Trạng thái chung của trận (master sở hữu): pha, đồng hồ, luật phòng, màu đèn, nhạc.
## Phải là property replicate để sống sót khi đổi master.

signal changed

enum { PHASE_LOBBY, PHASE_COUNTDOWN, PHASE_PLAYING }

## Số người tối thiểu để đếm ngược (1 = chạy thử một mình).
@export var min_players := 1
@export var countdown_seconds := 5.0
@export var phase: int = PHASE_LOBBY:
	set(value):
		phase = value
		changed.emit()
@export var countdown: float = 0.0:
	set(value):
		countdown = value
		changed.emit()

## Luật phòng do chủ phòng chốt; người vào muộn đọc lại từ đây.
@export var gameplay_settings_json: String = "":
	set(value):
		gameplay_settings_json = value
		changed.emit()
@export var setup_complete := false:
	set(value):
		setup_complete = value
		changed.emit()

## Mặt bàn cờ (0 = cờ vua, 1 = cờ tướng) cho người vào muộn.
@export var board_mode: int = 0:
	set(value):
		board_mode = value
		changed.emit()

## Màu đèn cả phòng dạng 0xRRGGBB; -1 = màu gốc. Mỗi lần ghi là giá trị tuyệt đối.
@export var light_rgb: int = -1:
	set(value):
		light_rgb = value
		changed.emit()

## Màu thứ hai của gradient; -1 = một màu.
@export var light_rgb_b: int = -1:
	set(value):
		light_rgb_b = value
		changed.emit()

## Key bài đang phát; rỗng = không nhạc. Người vào muộn nghe từ đầu bài.
@export var nhac_key: String = "":
	set(value):
		nhac_key = value
		changed.emit()
@export var round_index: int = 0:
	set(value):
		round_index = value
		changed.emit()

@onready var sync: FusionSharedReplicator = $Replicator


func _ready() -> void:
	add_to_group("match_state")


func gameplay_settings() -> Dictionary:
	return GameplaySettings.decode(gameplay_settings_json)


func ready_count() -> int:
	var n := 0
	for p: Player in get_tree().get_nodes_in_group("players"):
		if p.is_ready:
			n += 1
	return n


func player_count() -> int:
	return get_tree().get_nodes_in_group("players").size()


func _process(delta: float) -> void:
	# Chỉ master được ghi.
	if not sync.has_authority():
		return
	if not setup_complete:
		return

	var total := player_count()
	var n_ready := ready_count()
	var all_ready := total >= min_players and n_ready == total

	match phase:
		PHASE_LOBBY:
			if all_ready:
				phase = PHASE_COUNTDOWN
				countdown = countdown_seconds
		PHASE_COUNTDOWN:
			if not all_ready:
				phase = PHASE_LOBBY  # có người bước ra khỏi ô
				countdown = 0.0
			else:
				countdown = maxf(0.0, countdown - delta)
				if countdown <= 0.0:
					phase = PHASE_PLAYING
					round_index += 1
		PHASE_PLAYING:
			pass
