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

## So nguoi toi thieu de bat dau dem nguoc.
##
## De 1 de CHAY THU MOT MINH duoc. Choi that thi keo len 2 trong Inspector cua
## match_state.tscn — mot minh vao minigame doi khang thi thang ngay lap tuc.
@export var min_players := 1
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

## Mau anh sang ca phong, goi thanh 0xRRGGBB. -1 = de nguyen mau goc cua map.
##
## O day chu khong o Lobby, vi lobby duoc nap CUC BO tren tung may -> no khong phai object
## mang. Nguoi vao muon doc gia tri nay de bat dung mau.
##
## Goi vao INT chu khong khai bao mot property kieu Color: int thi chac chan replicate duoc
## (ca file nay dang dung int va float), con Color thi phai do lai moi biet Fusion co nuot
## khong — goi lai la het phai hoi.
##
## MOI LAN GHI LA MOT GIA TRI TUYET DOI, khong phai "chi so ke tiep". Ban truoc luu chi so
## roi cong don: `request_light` gui `mau_den() + 1` trong khi `mau_den()` da `posmod` 6, nen
## tu lan bam thu 6 tro di `light_index` (=6) khong bao gio bang `mau_den()` (=0) nua. Ma
## `changed` thi ban moi lan BAT KY property nao replicate (`countdown` dem lien tuc), nen cai
## so sanh "lech thi dong bo lai" o main.gd bat lien tuc: quet lai ca cay node va dung lai
## radiance cubemap cua bau troi moi nhip mang. Do la nguyen nhan lag, glitch va nhat do
## khong noi sau khi doi mau den vai lan.
@export var light_rgb: int = -1:
	set(value):
		light_rgb = value
		changed.emit()

## Mau thu hai cua gradient anh sang. -1 = chi dung mot mau (`light_rgb` phu ca phong).
@export var light_rgb_b: int = -1:
	set(value):
		light_rgb_b = value
		changed.emit()

## Key cua bai dang phat, de nguoi vao muon bat kip. Rong = khong co nhac.
##
## Chi key, KHONG co moc thoi gian: dong bo toi tung giay thi phai co dong ho chung, ma
## nhac nen phong cho khong dang mot bo may nhu the — vao giua bai thi nghe tu dau bai do.
@export var nhac_key: String = "":
	set(value):
		nhac_key = value
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
