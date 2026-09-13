class_name MatchState
extends Node3D

## Trang thai chung cua tran dau. Master client so huu (owner_mode = MASTER_CLIENT).
##
## Chi chua thu KHONG thuoc ve rieng ai: pha, vong, dong ho. Diem song cua tung nguoi
## nam tren chinh object player cua ho.
##
## Master doi giua chung thi Photon tu chuyen quyen so huu sang master moi va object
## KHONG chet theo — nhung bien local thi khong sang theo. Vi vay dong ho dem nguoc
## PHAI la property replicate, khong duoc la mot `var timer` trong script.

signal changed

enum { PHASE_LOBBY, PHASE_COUNTDOWN, PHASE_PLAYING }

@export var min_players := 2
@export var countdown_seconds := 5.0

@onready var sync: FusionSharedReplicator = $Replicator

@export var phase: int = PHASE_LOBBY:
	set(value):
		phase = value
		changed.emit()

@export var countdown: float = 0.0:
	set(value):
		countdown = value
		changed.emit()

## Mat ban co hien tai (0 = co vua, 1 = co tuong). O day chu khong o ChessBoard, vi ban co
## nam trong lobby duoc nap cuc bo -> khong phai object mang. Nguoi vao muon doc gia tri nay
## de dung dung mat ban.
@export var board_mode: int = 0:
	set(value):
		board_mode = value
		changed.emit()

@export var round_index: int = 0:
	set(value):
		round_index = value
		changed.emit()


func _ready() -> void:
	add_to_group("match_state")


## Dem so nguoi san sang. Chay duoc tren MOI may — chi doc, khong ghi.
func ready_count() -> int:
	var n := 0
	for p: Player in get_tree().get_nodes_in_group("players"):
		if p.is_ready:
			n += 1
	return n


func player_count() -> int:
	return get_tree().get_nodes_in_group("players").size()


func _process(delta: float) -> void:
	# CHI master duoc ghi. May khac chay ham nay cung khong sao — chung khong qua duoc cong nay.
	if not sync.has_authority():
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
				phase = PHASE_LOBBY      # co nguoi buoc ra khoi o -> huy dem nguoc
				countdown = 0.0
			else:
				countdown = maxf(0.0, countdown - delta)
				if countdown <= 0.0:
					phase = PHASE_PLAYING
					round_index += 1
		PHASE_PLAYING:
			pass
