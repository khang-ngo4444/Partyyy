class_name CardDealer
extends Node

## Hai game bài (xì dách, poker) — máy master làm nhà cái: chia, lật, tuyên kết quả.
## Lá bài là object replicate; bảng thông báo gửi riêng bằng RPC.

const PHA_CHO := 0
const PHA_GOI := 1  # có người ngồi, đang đếm ngược chờ người khác vào
const PHA_CHOI := 2
const PHA_XONG := 3

## Có người ngồi rồi bao lâu mới chia.
const DOI_GOI := 8.0

## Xem kết quả bao lâu rồi dọn bàn.
const DON_BAN_SAU := 7.0

## Hạn chung cho xì dách; hết hạn ai chưa chốt thì tự DỪNG.
const GIAY_XI_DACH := 20.0
const TEN_VONG := ["TRUOC FLOP", "SAU FLOP", "SAU TURN", "SAU RIVER"]

## Số lá chung đã lật sau mỗi vòng (flop 3, turn 1, river 1).
const LAT_TOI := [0, 3, 4, 5]
const CHIP_DAU := 1000
const SB := 10
const BB := 20

## Hết giờ lượt poker thì tự bỏ bài.
const GIAY_MOI_LUOT := 20.0
const HD_CHECK := 0
const HD_CALL := 1
const HD_RAISE := 2
const HD_FOLD := 3
const HD_ALLIN := 4

## Lá bài Fusion sinh ra.
@export var card_scene: PackedScene = null

var pha_ban: Dictionary = {}

## Bản sao trên mọi máy: bo_bai -> {"pot", "muc", "luot", "dealer", "han", ghe -> [chip, cuoc, co]}.
var ban_cuoc: Dictionary = {}
var _spawner: FusionSpawner = null

## Chỉ master: bộ bài -> các lá đã rút.
var _da_rut: Dictionary = {}

## bộ bài -> {ghế -> id người chơi}
var _ngoi: Dictionary = {}

## bộ bài -> {ghế -> Array[Card]}
var _bai: Dictionary = {}

## bộ bài -> {ghế -> true} khi đã dừng / quá 21 / đã quyết
var _xong: Dictionary = {}

## bộ bài -> bài nhà cái (xì dách) / 5 lá chung (poker)
var _bai_cai: Dictionary = {}

## POKER: bộ bài -> vòng (0 trước flop … 3 sau river).
var _vong: Dictionary = {}

## POKER: bộ bài -> {ghế -> true} người đã bỏ bài.
var _bo: Dictionary = {}
var _pha: Dictionary = {}

# ─── chỉ master dùng ───
var _chip: Dictionary = {}  # bộ → { ghế → chip còn lại }
var _cuoc: Dictionary = {}  # bộ → { ghế → đã đặt trong vòng này }
var _gop: Dictionary = {}  # bộ → { ghế → đã đặt cả ván } (hoàn tiền all-in)
var _pot: Dictionary = {}
var _muc: Dictionary = {}  # mức cược cao nhất trong vòng này
var _luot: Dictionary = {}  # ghế đang tới lượt, -1 = không ai
var _dealer: Dictionary = {}
var _da_hd: Dictionary = {}  # bộ → { ghế → đã hành động kể từ lần tố gần nhất }
var _allin: Dictionary = {}

## bộ -> mốc hết giờ theo đồng hồ máy master (không gửi thẳng đi).
var _han: Dictionary = {}

## bộ -> dòng "Hết giờ! ..." in kèm kết quả.
var _ghi_chu: Dictionary = {}


# ─── đọc từ mọi máy ───


## Main gọi một lần lúc khởi động.
func setup(spawner: FusionSpawner) -> void:
	_spawner = spawner
	_spawner.add_spawnable_scene(card_scene)
	Fusion.register_broadcast_receiver(self)
	add_to_group("card_dealer")
	NetManager.peer_left.connect(func(id, _inactive): _roi_ban(id))
	NetManager.peer_joined.connect(func(_id, _uid): _gui_lai_trang_thai())


## Bàn người chơi máy này đang ngồi; -1 = không ngồi.
func ban_dang_ngoi() -> int:
	for s: CardSeat in get_tree().get_nodes_in_group("card_seat"):
		if s.toi_dang_ngoi:
			return s.deck
	return -1


## Phím 1/2 cho xì dách khi đang ngồi và tới lượt chọn.
func _unhandled_input(event: InputEvent) -> void:
	var deck := ban_dang_ngoi()
	if deck < 0 or int(pha_ban.get(deck, PHA_CHO)) != PHA_CHOI:
		return
	var t := _table(deck)
	if t != null and t.poker:
		return  # poker đọc phím ở HUD
	if event.is_action_pressed("card_yes"):
		request_yes(deck)
	elif event.is_action_pressed("card_no"):
		request_no(deck)


func request_sit(deck: int, seat: int) -> void:
	Fusion.rpc(_net_sit, deck, seat, NetManager.local_id())


func request_stand_up(deck: int, seat: int) -> void:
	Fusion.rpc(_net_stand_up, deck, seat, NetManager.local_id())


## CHỈ XÌ DÁCH (poker dùng `request_hanh_dong`).
func request_yes(deck: int) -> void:
	Fusion.rpc(_net_choose, deck, NetManager.local_id(), true)


func request_no(deck: int) -> void:
	Fusion.rpc(_net_choose, deck, NetManager.local_id(), false)


@rpc("any_peer", "call_local")
func _net_sit(deck: int, seat: int, player_id: int) -> void:
	if not NetManager.is_master():
		return
	var g := _ghe(deck)
	if g.has(seat):
		return
	var pha := int(_pha.get(deck, PHA_CHO))
	# Đang đánh thì khoá ghế.
	if pha == PHA_CHOI:
		return
	# Mỗi người chỉ ngồi một ghế.
	for d in _ngoi:
		for k in _ngoi[d]:
			if int(_ngoi[d][k]) == player_id:
				return
	g[seat] = player_id
	_day_trang_thai(deck)
	if pha == PHA_CHO:
		# Người đầu tiên ngồi xuống là mở đếm ngược.
		_pha[deck] = PHA_GOI
		_dem_nguoc(deck)
	elif pha == PHA_GOI:
		_bao(deck, "%d nguoi da ngoi." % g.size())
	else:
		_bao_them(deck, "%s ngoi roi — cho van sau." % Player.ten_theo_id(get_tree(), player_id))


@rpc("any_peer", "call_local")
func _net_stand_up(deck: int, seat: int, player_id: int) -> void:
	if not NetManager.is_master():
		return
	var g := _ghe(deck)
	if not g.has(seat) or int(g[seat]) != player_id:
		return
	# Đang đánh thì không cho đứng dậy.
	if int(_pha.get(deck, PHA_CHO)) == PHA_CHOI:
		return
	g.erase(seat)
	if g.is_empty():
		_don_ban(deck)
	else:
		_day_trang_thai(deck)


## Người rời phòng giữa chừng: rời ghế, bỏ bài nếu đang trong ván poker.
## ponytail: master rời phòng thì trạng thái bàn mất (chưa replicate).
func _roi_ban(player_id: int) -> void:
	if not NetManager.is_master():
		return
	for deck in _ngoi.keys():
		var seat := _ghe_cua(deck, player_id)
		if seat < 0:
			continue
		var t := _table(deck)
		var dang_danh := int(_pha.get(deck, PHA_CHO)) == PHA_CHOI
		if dang_danh and t != null and t.poker and not bool((_bo[deck] as Dictionary).get(seat, false)):
			_ghi_chu[deck] = "%s roi phong — tu dong BO BAI" % Player.ten_theo_id(get_tree(), player_id)
			if int(_luot.get(deck, -1)) == seat:
				_lam(deck, seat, HD_FOLD, 0)
			else:
				_bo_bai(deck, seat)
		_ghe(deck).erase(seat)
		var van_con := int(_pha.get(deck, PHA_CHO)) == PHA_CHOI
		if _ghe(deck).is_empty():
			_don_ban(deck)
		elif van_con and t != null and not t.poker:
			_kiem_xong_het(deck)
		elif van_con and _con_choi(deck).size() <= 1:
			_ket_van_som(deck)
		else:
			_day_trang_thai(deck)
			if van_con and _ghi_chu.has(deck):
				_bao_them(deck, "%s\n%s" % [_ghi_chu[deck], _bang_poker(deck)])
				_ghi_chu.erase(deck)


## Người vào sau không nhận được RPC cũ — master gửi lại trạng thái mọi bàn.
func _gui_lai_trang_thai() -> void:
	if not NetManager.is_master():
		return
	# Đợi người mới dựng xong phòng chờ.
	await get_tree().create_timer(1.5).timeout
	for t: CardTable in get_tree().get_nodes_in_group("card_table"):
		Fusion.rpc(_net_pha, t.deck_id, int(_pha.get(t.deck_id, PHA_CHO)))
		_day_trang_thai(t.deck_id)


@rpc("any_peer", "call_local")
func _net_choose(deck: int, player_id: int, yes: bool) -> void:
	if not NetManager.is_master() or int(_pha.get(deck, PHA_CHO)) != PHA_CHOI:
		return
	var seat := _ghe_cua(deck, player_id)
	if seat < 0 or bool((_xong[deck] as Dictionary).get(seat, false)):
		return
	var t := _table(deck)
	if t == null or t.poker:
		return
	if yes:
		_rut_them(deck, seat)
	else:
		(_xong[deck] as Dictionary)[seat] = true
		_kiem_xong_het(deck)


@rpc("any_peer", "call_local")
func _net_board(deck: int, txt: String) -> void:
	var t := _table(deck)
	if t != null:
		t.set_board(txt)


## Gửi kèm pha để HUD biết có nhắc phím không.
@rpc("any_peer", "call_local")
func _net_pha(deck: int, pha: int) -> void:
	pha_ban[deck] = pha


func _table(deck: int) -> CardTable:
	for t: CardTable in get_tree().get_nodes_in_group("card_table"):
		if t.deck_id == deck:
			return t
	return null


func _ghe(deck: int) -> Dictionary:
	if not _ngoi.has(deck):
		_ngoi[deck] = {}
	return _ngoi[deck]


func _ghe_cua(deck: int, player_id: int) -> int:
	for k in _ghe(deck):
		if int(_ghe(deck)[k]) == player_id:
			return int(k)
	return -1


func _bao(deck: int, txt: String) -> void:
	Fusion.rpc(_net_pha, deck, int(_pha.get(deck, PHA_CHO)))
	Fusion.rpc(_net_board, deck, txt)


func _bao_them(deck: int, txt: String) -> void:
	Fusion.rpc(_net_board, deck, txt)


## Chỉ master: gửi số giây còn lại một lần, mọi máy tự đếm.
func _dem_nguoc(deck: int) -> void:
	_han[deck] = _gio() + DOI_GOI
	_bao(deck, "%d nguoi da ngoi. Chia bai khi dong ho ve 0." % _ghe(deck).size())
	_day_trang_thai(deck)


## -1 = hết bài.
func _rut_khoi_bo(deck: int) -> int:
	var rut: Array = _da_rut.get(deck, [])
	var con_lai: Array[int] = []
	for i in Card.DECK_SIZE:
		if not rut.has(i):
			con_lai.append(i)
	if con_lai.is_empty():
		return -1
	var idx: int = con_lai[randi() % con_lai.size()]
	rut.append(idx)
	_da_rut[deck] = rut
	return idx


## Master đặt vị trí và góc xoay lá bài.
func _dat_bai(deck: int, cho: Transform3D, up: bool, co := 0.0) -> Card:
	var idx := _rut_khoi_bo(deck)
	if idx < 0:
		return null
	var c: Card = _spawner.spawn(card_scene)
	c.deck_id = deck
	c.card_index = idx
	c.face_down = up
	if co > 0.0:
		c.card_size = co
	c.global_transform = cho
	return c


## Xếp hàng bài cân giữa ô (chỉ poker).
func _xep_ghe(deck: int, seat) -> void:
	var t := _table(deck)
	if t == null or not t.poker:
		return
	var tay: Array = (_bai[deck] as Dictionary).get(seat, [])
	for i in tay.size():
		var c: Card = tay[i]
		if is_instance_valid(c):
			c.global_transform = t.slot(int(seat), i, tay.size())


func _xep_cai(deck: int) -> void:
	var t := _table(deck)
	if t == null or not t.poker:
		return
	var cai: Array = _bai_cai.get(deck, [])
	for i in cai.size():
		var c: Card = cai[i]
		if is_instance_valid(c):
			c.global_transform = t.slot_cai(i, cai.size())


func _chia_bai(deck: int) -> void:
	var t := _table(deck)
	if t == null:
		return
	_xoa_bai(deck)
	# Nhiều người có thể vượt 52 lá — xáo lại mỗi ván.
	_da_rut[deck] = []
	_bai[deck] = {}
	_xong[deck] = {}
	_vong[deck] = 0
	_bo[deck] = {}
	if t.poker:
		_mo_cuoc(deck)
	# Poker: 2 lá riêng. Xì dách: 2 lá mở đầu.
	var so_la := 2
	var cho_danh_san := so_la if t.poker else t.hand_size()
	for seat in _ghe(deck):
		var tay: Array[Card] = []
		for i in so_la:
			# Poker: bài riêng úp, máy chủ bài tự lật cho họ xem (`Card.lo_cuc_bo`).
			var c := _dat_bai(deck, t.slot(int(seat), i, cho_danh_san), t.poker)
			if c != null:
				tay.append(c)
		(_bai[deck] as Dictionary)[seat] = tay
		_xep_ghe(deck, seat)
	var cai: Array[Card] = []
	if t.poker:
		# 5 lá chung úp sẵn, lật dần theo vòng.
		for i in 5:
			var c := _dat_bai(deck, t.slot_cai(i, 5), true, t.card_size_cai())
			if c != null:
				cai.append(c)
	else:
		# Xì dách: nhà cái 1 lá ngửa, 1 lá úp.
		var c0 := _dat_bai(deck, t.slot_cai(0, 5), false)
		var c1 := _dat_bai(deck, t.slot_cai(1, 5), true)
		for c in [c0, c1]:
			if c != null:
				cai.append(c)
	_bai_cai[deck] = cai
	_pha[deck] = PHA_CHOI
	if t.poker:
		_dat_blind(deck)
	else:
		_han[deck] = _gio() + GIAY_XI_DACH
		_day_trang_thai(deck)
	_bao(deck, _bang_poker(deck) if t.poker else "RUT THEM hay DUNG?")


func _rut_them(deck: int, seat: int) -> void:
	var t := _table(deck)
	var tay: Array = (_bai[deck] as Dictionary).get(seat, [])
	if tay.size() >= t.hand_size():
		(_xong[deck] as Dictionary)[seat] = true
		_kiem_xong_het(deck)
		return
	var c := _dat_bai(deck, t.slot(seat, tay.size(), t.hand_size()), false)
	if c == null:
		(_xong[deck] as Dictionary)[seat] = true
		_kiem_xong_het(deck)
		return
	tay.append(c)
	(_bai[deck] as Dictionary)[seat] = tay
	_xep_ghe(deck, seat)
	if _tong_bj(tay) > 21:
		(_xong[deck] as Dictionary)[seat] = true
		_kiem_xong_het(deck)


## Úp bài riêng lại và đánh dấu đã bỏ.
func _bo_bai(deck: int, seat: int) -> void:
	(_bo[deck] as Dictionary)[seat] = true
	for c: Card in (_bai[deck] as Dictionary).get(seat, []):
		if is_instance_valid(c):
			c.face_down = true


func _kiem_xong_het(deck: int) -> void:
	if int(_pha.get(deck, PHA_CHO)) != PHA_CHOI:
		return
	var g := _ghe(deck)
	if g.is_empty():
		_don_ban(deck)
		return
	for seat in g:
		if bool((_bo[deck] as Dictionary).get(seat, false)):
			continue
		if not bool((_xong[deck] as Dictionary).get(seat, false)):
			return
	var t := _table(deck)
	if t != null and t.poker:
		_vong_tiep(deck)
	else:
		_luot_nha_cai(deck)


## Phát chip cho ai chưa có, xoay nút dealer.
func _mo_cuoc(deck: int) -> void:
	if not _chip.has(deck):
		_chip[deck] = {}
	var chip: Dictionary = _chip[deck]
	for k in _ghe(deck):
		# Hết chip thì được phát lại (chip là đạo cụ).
		if int(chip.get(k, 0)) <= 0:
			chip[k] = CHIP_DAU
	_cuoc[deck] = {}
	_gop[deck] = {}
	_da_hd[deck] = {}
	_allin[deck] = {}
	_pot[deck] = 0
	_muc[deck] = 0
	_dealer[deck] = _ghe_con(deck, int(_dealer.get(deck, -1)))


## SB bên trái dealer, BB bên trái SB; còn hai người thì dealer đặt SB.
func _dat_blind(deck: int) -> void:
	var d: int = int(_dealer.get(deck, -1))
	if d < 0:
		return
	var ds := _con_choi(deck)
	var sb := d if ds.size() == 2 else _ghe_con(deck, d)
	var bb := _ghe_con(deck, sb)
	if sb < 0 or bb < 0:
		return
	_dat(deck, sb, mini(SB, int((_chip[deck] as Dictionary).get(sb, 0))))
	_dat(deck, bb, mini(BB, int((_chip[deck] as Dictionary).get(bb, 0))))
	_muc[deck] = BB
	_bao_them(deck, "%s dat SB %d, %s dat BB %d" % [
			Player.ten_theo_id(get_tree(), int(_ghe(deck)[sb])), SB,
			Player.ten_theo_id(get_tree(), int(_ghe(deck)[bb])), BB])
	# Trước flop, người bên trái BB đi đầu.
	_bat_luot(deck, _ghe_con(deck, bb))


## Vòng cược mới: ai cũng phải hành động lại.
func _mo_vong(deck: int) -> void:
	_cuoc[deck] = {}
	_muc[deck] = 0
	_da_hd[deck] = {}
	# Sau flop, người còn lại bên trái dealer đi đầu.
	_bat_luot(deck, _ghe_con(deck, int(_dealer.get(deck, -1))))


func _bat_luot(deck: int, seat: int) -> void:
	# Bỏ qua người đã all-in.
	var t := _table(deck)
	var i := seat
	for b in t.seats:
		if i >= 0 and not bool((_allin[deck] as Dictionary).get(i, false)) \
				and not bool((_bo[deck] as Dictionary).get(i, false)):
			break
		i = _ghe_con(deck, i)
	_luot[deck] = i
	_han[deck] = _gio() + GIAY_MOI_LUOT if i >= 0 else 0.0
	_day_trang_thai(deck)


## Chỉ master đếm giờ lượt.
func _process(_delta: float) -> void:
	if not NetManager.is_master():
		return
	for deck in _han.keys():
		var h: float = float(_han.get(deck, 0.0))
		if h <= 0.0:
			continue
		if _gio() >= h:
			_han[deck] = 0.0
			_het_gio(deck)


func _con_choi(deck: int) -> Array:
	var ds: Array = []
	for seat in _ghe(deck):
		if not bool((_bo[deck] as Dictionary).get(seat, false)):
			ds.append(seat)
	return ds


func _bang_poker(deck: int) -> String:
	var v := int(_vong.get(deck, 0))
	return "%s  -  con %d nguoi  -  THEO hay BO?" % [TEN_VONG[v], _con_choi(deck).size()]


## Hết vòng thì lật thêm bài chung; hết river thì hạ bài.
func _vong_tiep(deck: int) -> void:
	if _con_choi(deck).is_empty():
		_ket_thuc(deck, "Ai cung bo bai - khong co ai thang")
		return
	var v := int(_vong.get(deck, 0)) + 1
	if v >= TEN_VONG.size():
		_ha_bai(deck)
		return
	_vong[deck] = v
	var chung: Array = _bai_cai.get(deck, [])
	for i in mini(LAT_TOI[v], chung.size()):
		var c: Card = chung[i]
		if is_instance_valid(c):
			c.face_down = false
	_xong[deck] = {}
	_mo_vong(deck)
	_bao(deck, _bang_poker(deck))


## Chọn bộ 5 lá mạnh nhất của mỗi người, cao nhất thắng.
func _ha_bai(deck: int) -> void:
	var chung: Array = _bai_cai.get(deck, [])
	for c: Card in chung:
		if is_instance_valid(c):
			c.face_down = false

	var dong: PackedStringArray = []
	var cao_nhat := -1
	var thang: Array[String] = []
	var ghe_thang: Array = []
	var pot_truoc: int = int(_pot.get(deck, 0))
	for seat in _ghe(deck):
		var ten := Player.ten_theo_id(get_tree(), int(_ghe(deck)[seat]))
		if bool((_bo[deck] as Dictionary).get(seat, false)):
			dong.append("%s: bo bai" % ten)
			continue
		var bo: Array = (_bai[deck] as Dictionary).get(seat, []).duplicate()
		bo.append_array(chung)
		var h := _hang_poker(bo)
		dong.append("%s: %s" % [ten, CardSpot.ten_hang(h)])
		if h > cao_nhat:
			cao_nhat = h
			thang = [ten]
			ghe_thang = [seat]
		elif h == cao_nhat:
			thang.append(ten)
			ghe_thang.append(seat)
	if cao_nhat >= 0:
		_chia_pot(deck, ghe_thang)
		dong.append("=> %s THANG voi %s  (+%d chip)" % [
				", ".join(thang), CardSpot.ten_hang(cao_nhat), pot_truoc])
	_luot[deck] = -1
	_han[deck] = 0.0
	_day_trang_thai(deck)
	_ket_thuc(deck, "\n".join(dong))


## CHỈ XÌ DÁCH: nhà cái lật lá úp rồi rút tới khi đủ 17.
func _luot_nha_cai(deck: int) -> void:
	var t := _table(deck)
	var cai: Array = _bai_cai.get(deck, [])
	for c: Card in cai:
		if is_instance_valid(c):
			c.face_down = false
	while _tong_bj(cai) < 17 and cai.size() < t.hand_size():
		var c := _dat_bai(deck, t.slot_cai(cai.size(), t.hand_size()), false)
		if c == null:
			break
		cai.append(c)
	_bai_cai[deck] = cai
	_xep_cai(deck)

	var dong: PackedStringArray = []
	var tc := _tong_bj(cai)
	dong.append("NHA CAI: %d%s" % [tc, " - QUA 21" if tc > 21 else ""])
	for seat in _ghe(deck):
		var ten := Player.ten_theo_id(get_tree(), int(_ghe(deck)[seat]))
		var tn := _tong_bj((_bai[deck] as Dictionary).get(seat, []))
		var kq := ""
		if tn > 21:
			kq = "thua (qua 21)"
		elif tc > 21 or tn > tc:
			kq = "THANG"
		elif tn == tc:
			kq = "HOA"
		else:
			kq = "thua"
		dong.append("%s: %d - %s" % [ten, tn, kq])
	_ket_thuc(deck, "\n".join(dong))


func _ket_thuc(deck: int, kq: String) -> void:
	_pha[deck] = PHA_XONG
	_han[deck] = 0.0
	_day_trang_thai(deck)
	var ghi: String = _ghi_chu.get(deck, "")
	_ghi_chu.erase(deck)
	_bao(deck, kq if ghi == "" else "%s\n%s" % [ghi, kq])
	await get_tree().create_timer(DON_BAN_SAU).timeout
	if int(_pha.get(deck, PHA_CHO)) != PHA_XONG:
		return
	_xoa_bai(deck)
	if _ghe(deck).is_empty():
		_don_ban(deck)
	else:
		_pha[deck] = PHA_GOI
		_dem_nguoc(deck)


func _don_ban(deck: int) -> void:
	_xoa_bai(deck)
	_ngoi[deck] = {}
	_pha[deck] = PHA_CHO
	_bao(deck, "NGOI VAO GHE DE CHIA BAI")


func _xoa_bai(deck: int) -> void:
	# Lá bài không còn trong nhóm "pickable" — quét nhóm "card".
	for p in get_tree().get_nodes_in_group("card"):
		if p is Card and p.deck_id == deck:
			_spawner.despawn(p)
	_bai[deck] = {}
	_bai_cai[deck] = []
	_xong[deck] = {}
	_bo[deck] = {}
	_vong[deck] = 0
	_luot[deck] = -1
	_han[deck] = 0.0
	_day_trang_thai(deck)


func _tong_bj(bai: Array) -> int:
	var r: Array[int] = []
	for c: Card in bai:
		if is_instance_valid(c):
			r.append(c.rank())
	return CardSpot.blackjack_total(r)


## Điểm đầy đủ (hạng + lá cao + kicker) để phân thắng khi cùng hạng.
func _hang_poker(bai: Array) -> int:
	var r: Array[int] = []
	var s: Array[int] = []
	for c: Card in bai:
		if is_instance_valid(c):
			r.append(c.rank())
			s.append(c.suit())
	return CardSpot.best_score(r, s)

# ─── Cược poker (Texas Hold'em): chip là đạo cụ, lượt tuần tự do master giữ ───


func _ban(deck: int) -> Dictionary:
	if not ban_cuoc.has(deck):
		ban_cuoc[deck] = {}
	return ban_cuoc[deck]


func chip_cua(deck: int, seat: int) -> int:
	var o: Array = _ban(deck).get(seat, [])
	return int(o[0]) if o.size() > 0 else 0


func cuoc_cua(deck: int, seat: int) -> int:
	var o: Array = _ban(deck).get(seat, [])
	return int(o[1]) if o.size() > 1 else 0


## bit 0 = đã bỏ bài, bit 1 = all-in
func co_cua(deck: int, seat: int) -> int:
	var o: Array = _ban(deck).get(seat, [])
	return int(o[2]) if o.size() > 2 else 0


## Id người ngồi ghế; 0 = trống.
func nguoi_o_ghe(deck: int, seat: int) -> int:
	var o: Array = _ban(deck).get(seat, [])
	return int(o[3]) if o.size() > 3 else 0


func pot_cua(deck: int) -> int:
	return int(_ban(deck).get("pot", 0))


func muc_cua(deck: int) -> int:
	return int(_ban(deck).get("muc", 0))


func luot_cua(deck: int) -> int:
	return int(_ban(deck).get("luot", -1))


func dealer_cua(deck: int) -> int:
	return int(_ban(deck).get("dealer", -1))


## Đồng hồ cục bộ (giây) — chỉ so với mốc cùng máy.
func _gio() -> float:
	return float(Time.get_ticks_msec()) / 1000.0


## Giây còn lại của đồng hồ trên bàn; -1 = không đếm.
func con_lai(deck: int) -> float:
	var h: float = float(_ban(deck).get("han", 0.0))
	if h <= 0.0:
		return -1.0
	return maxf(0.0, h - _gio())


func toi_toi_luot(deck: int) -> bool:
	var seat := ghe_cua_toi(deck)
	return seat >= 0 and luot_cua(deck) == seat


func ghe_cua_toi(deck: int) -> int:
	for s: CardSeat in get_tree().get_nodes_in_group("card_seat"):
		if s.toi_dang_ngoi and s.deck == deck:
			return s.index
	return -1


## Hành động hợp lệ cho người máy này (HUD vẽ nút theo).
func hanh_dong_hop_le(deck: int) -> Array[int]:
	if not toi_toi_luot(deck):
		return []
	var seat := ghe_cua_toi(deck)
	var chip := chip_cua(deck, seat)
	var can := muc_cua(deck) - cuoc_cua(deck, seat)
	var ds: Array[int] = []
	if can <= 0:
		ds.append(HD_CHECK)
	else:
		ds.append(HD_CALL)
	if chip > can:
		ds.append(HD_RAISE)
	if can > 0:
		ds.append(HD_FOLD)
	if chip > 0:
		ds.append(HD_ALLIN)
	return ds


## Mức tố thấp nhất hợp lệ.
func to_toi_thieu(deck: int) -> int:
	var seat := ghe_cua_toi(deck)
	var can := muc_cua(deck) - cuoc_cua(deck, seat)
	return mini(can + maxi(muc_cua(deck), BB), chip_cua(deck, seat))


# ─── người chơi gửi lên ───


func request_hanh_dong(deck: int, hd: int, so_tien: int) -> void:
	Fusion.rpc(_net_hanh_dong, deck, NetManager.local_id(), hd, so_tien)


@rpc("any_peer", "call_local")
func _net_hanh_dong(deck: int, player_id: int, hd: int, so_tien: int) -> void:
	if not NetManager.is_master():
		return
	var t := _table(deck)
	if t == null or not t.poker or int(_pha.get(deck, PHA_CHO)) != PHA_CHOI:
		return
	var seat := _ghe_cua(deck, player_id)
	if seat < 0 or seat != int(_luot.get(deck, -1)):
		return
	_lam(deck, seat, hd, so_tien)


# ─── master xử lý ───


func _lam(deck: int, seat: int, hd: int, so_tien: int) -> void:
	var chip: Dictionary = _chip[deck]
	var cuoc: Dictionary = _cuoc[deck]
	var can: int = int(_muc[deck]) - int(cuoc.get(seat, 0))
	var ten := Player.ten_theo_id(get_tree(), int(_ghe(deck)[seat]))

	match hd:
		HD_FOLD:
			_bo_bai(deck, seat)
			_bao_them(deck, "%s: bo bai" % ten)
		HD_CHECK:
			if can > 0:
				return
			_bao_them(deck, "%s: check" % ten)
		HD_CALL:
			if can <= 0:
				return
			_dat(deck, seat, mini(can, int(chip[seat])))
			_bao_them(deck, "%s: theo %d" % [ten, mini(can, int(chip[seat]) + can)])
		HD_RAISE:
			var muc_moi: int = maxi(so_tien, to_toi_thieu_master(deck, seat))
			muc_moi = mini(muc_moi, int(chip[seat]))
			if muc_moi <= can:
				return
			_dat(deck, seat, muc_moi)
			_muc[deck] = int(cuoc[seat])
			# Tố thì ai cũng phải trả lời lại.
			for k in _ghe(deck):
				if int(k) != seat:
					(_da_hd[deck] as Dictionary)[k] = false
			_bao_them(deck, "%s: to len %d" % [ten, int(_muc[deck])])
		HD_ALLIN:
			var het: int = int(chip[seat])
			if het <= 0:
				return
			_dat(deck, seat, het)
			(_allin[deck] as Dictionary)[seat] = true
			if int(cuoc[seat]) > int(_muc[deck]):
				_muc[deck] = int(cuoc[seat])
				for k in _ghe(deck):
					if int(k) != seat:
						(_da_hd[deck] as Dictionary)[k] = false
			_bao_them(deck, "%s: ALL-IN %d" % [ten, het])

	(_da_hd[deck] as Dictionary)[seat] = true
	_sau_hanh_dong(deck)


func _dat(deck: int, seat: int, so: int) -> void:
	var chip: Dictionary = _chip[deck]
	var cuoc: Dictionary = _cuoc[deck]
	var gop: Dictionary = _gop[deck]
	so = clampi(so, 0, int(chip[seat]))
	chip[seat] = int(chip[seat]) - so
	cuoc[seat] = int(cuoc.get(seat, 0)) + so
	gop[seat] = int(gop.get(seat, 0)) + so
	_pot[deck] = int(_pot.get(deck, 0)) + so
	if int(chip[seat]) <= 0:
		(_allin[deck] as Dictionary)[seat] = true


func to_toi_thieu_master(deck: int, seat: int) -> int:
	var can: int = int(_muc[deck]) - int((_cuoc[deck] as Dictionary).get(seat, 0))
	return can + maxi(int(_muc[deck]), BB)


## Còn ai phải hành động không; hết thì sang vòng sau.
func _sau_hanh_dong(deck: int) -> void:
	var con := _con_choi(deck)
	if con.size() <= 1:
		_ket_van_som(deck)
		return
	var ke := _ghe_ke(deck, int(_luot[deck]))
	if ke < 0:
		_luot[deck] = -1
		_han[deck] = 0.0
		_day_trang_thai(deck)
		_vong_tiep(deck)
		return
	_luot[deck] = ke
	_han[deck] = _gio() + GIAY_MOI_LUOT
	_day_trang_thai(deck)


## Ghế kế tiếp còn phải hành động; -1 = vòng xong.
func _ghe_ke(deck: int, tu: int) -> int:
	var t := _table(deck)
	var n: int = t.seats
	for b in range(1, n + 1):
		var i := (tu + b) % n
		if not _ghe(deck).has(i):
			continue
		if bool((_bo[deck] as Dictionary).get(i, false)):
			continue
		if bool((_allin[deck] as Dictionary).get(i, false)):
			continue
		var da: bool = bool((_da_hd[deck] as Dictionary).get(i, false))
		var du: bool = int((_cuoc[deck] as Dictionary).get(i, 0)) >= int(_muc[deck])
		if not da or not du:
			return i
	return -1


## Ghế có người, chưa bỏ bài, kế tiếp theo vòng; -1 = không có.
func _ghe_con(deck: int, tu: int) -> int:
	var t := _table(deck)
	for b in range(1, t.seats + 1):
		var i := (tu + b) % t.seats
		if _ghe(deck).has(i) and not bool((_bo[deck] as Dictionary).get(i, false)):
			return i
	return -1


## Hết giờ: chia bài / xì dách tự DỪNG / poker tự BỎ.
func _het_gio(deck: int) -> void:
	var pha := int(_pha.get(deck, PHA_CHO))
	if pha == PHA_GOI:
		if _ghe(deck).is_empty():
			_don_ban(deck)
		else:
			_chia_bai(deck)
		return
	if pha != PHA_CHOI:
		return
	var t := _table(deck)
	if t != null and not t.poker:
		var ten: PackedStringArray = []
		for seat in _ghe(deck):
			if not bool((_xong[deck] as Dictionary).get(seat, false)):
				(_xong[deck] as Dictionary)[seat] = true
				ten.append(Player.ten_theo_id(get_tree(), int(_ghe(deck)[seat])))
		if not ten.is_empty():
			_ghi_chu[deck] = "Het gio! %s tu dong DUNG" % ", ".join(ten)
		_kiem_xong_het(deck)
		return
	var seat: int = int(_luot.get(deck, -1))
	if seat < 0:
		return
	_ghi_chu[deck] = "Het gio! %s tu dong BO BAI" % Player.ten_theo_id(get_tree(),
			int(_ghe(deck)[seat]))
	_lam(deck, seat, HD_FOLD, 0)
	# Ván còn tiếp thì báo ngay.
	if int(_pha.get(deck, PHA_CHO)) == PHA_CHOI and _ghi_chu.has(deck):
		_bao_them(deck, "%s\n%s" % [_ghi_chu[deck], _bang_poker(deck)])
		_ghi_chu.erase(deck)


func _ket_van_som(deck: int) -> void:
	var con := _con_choi(deck)
	if con.is_empty():
		_ket_thuc(deck, "Ai cung bo bai")
		return
	var seat: int = int(con[0])
	var ten := Player.ten_theo_id(get_tree(), int(_ghe(deck)[seat]))
	# Đọc pot trước khi chia (chia xong pot về 0).
	var pot := int(_pot.get(deck, 0))
	_chia_pot(deck, [seat])
	_ket_thuc(deck, "%s THANG (moi nguoi khac da bo bai)  +%d chip" % [ten, pot])


## Chia pot cho người thắng (hoà thì chia đều).
## ponytail: không có side pot — phần vượt của người all-in nhiều hơn được trả lại.
func _chia_pot(deck: int, thang: Array) -> void:
	var chip: Dictionary = _chip[deck]
	var gop: Dictionary = _gop[deck]
	var pot: int = int(_pot.get(deck, 0))

	var tran := 0
	for s in thang:
		tran = maxi(tran, int(gop.get(s, 0)))
	for k in _ghe(deck):
		var du: int = int(gop.get(k, 0)) - tran
		if du > 0:
			chip[k] = int(chip.get(k, 0)) + du
			pot -= du
			gop[k] = tran

	if thang.is_empty() or pot <= 0:
		_pot[deck] = 0
		return
	@warning_ignore("integer_division")
	var moi_nguoi: int = pot / thang.size()
	for s in thang:
		chip[s] = int(chip.get(s, 0)) + moi_nguoi
	_pot[deck] = 0


# ─── đẩy trạng thái đi ───


## Một RPC cho cả bàn, gói vào một chuỗi để máy khác không thấy nửa mới nửa cũ.
## ⚠️ Không gửi PackedInt32Array — Fusion nhận thành NIL.
func _day_trang_thai(deck: int) -> void:
	var t := _table(deck)
	if t == null:
		return
	var goi: PackedStringArray = []
	goi.append(str(int(_pot.get(deck, 0))))
	goi.append(str(int(_muc.get(deck, 0))))
	goi.append(str(int(_luot.get(deck, -1))))
	goi.append(str(int(_dealer.get(deck, -1))))
	# Gửi số mili-giây còn lại, không gửi mốc giờ (đồng hồ mỗi máy khác nhau).
	var han: float = float(_han.get(deck, 0.0))
	goi.append(str(roundi(maxf(0.0, han - _gio()) * 1000.0) if han > 0.0 else 0))
	# Dùng `.get` vì hàm này chạy cả lúc dọn bàn.
	var chip: Dictionary = _chip.get(deck, {})
	var cuoc: Dictionary = _cuoc.get(deck, {})
	var bo: Dictionary = _bo.get(deck, {})
	var ai: Dictionary = _allin.get(deck, {})
	for i in t.seats:
		if not _ghe(deck).has(i):
			continue
		var co := 0
		if bool(bo.get(i, false)):
			co |= 1
		if bool(ai.get(i, false)):
			co |= 2
		goi.append(str(i))
		goi.append(str(int(chip.get(i, 0))))
		goi.append(str(int(cuoc.get(i, 0))))
		goi.append(str(co))
		goi.append(str(int(_ghe(deck)[i])))
	Fusion.rpc(_net_cuoc, deck, ",".join(goi))


@rpc("any_peer", "call_local")
func _net_cuoc(deck: int, chuoi: String) -> void:
	var b := {}
	var o := chuoi.split(",", false)
	if o.size() < 5:
		ban_cuoc[deck] = b
		return
	b["pot"] = int(o[0])
	b["muc"] = int(o[1])
	b["luot"] = int(o[2])
	b["dealer"] = int(o[3])
	# Đổi ra mốc giờ của máy này, trừ nửa RTT.
	var con_ms := int(o[4])
	var tre := 0.0 if NetManager.is_master() else NetManager.rtt_ms() / 2000.0
	b["han"] = 0.0 if con_ms <= 0 else _gio() + con_ms / 1000.0 - tre
	var i := 5
	# Mỗi ghế 5 số: ghế, chip, cược, cờ, id.
	while i + 4 < o.size():
		b[int(o[i])] = [int(o[i + 1]), int(o[i + 2]), int(o[i + 3]), int(o[i + 4])]
		i += 5
	ban_cuoc[deck] = b
