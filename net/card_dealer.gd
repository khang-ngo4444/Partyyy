class_name CardDealer
extends Node

## HAI GAME BAI — HE THONG LAM NHA CAI
##
## "He thong" la may MASTER: no chia bai, lat bai, tuyen ket qua. Nguoi choi chi gui hai
## lua chon (rut/dung, theo/bo).
##
## NHIEU NGUOI CUNG CHOI. Moi nguoi quyet DOC LAP — khong ai phai cho luot ai. Khi tat ca
## da xong thi nha cai moi danh MOT lan roi so voi tung nguoi. Sòng bai that cung the, va
## cach nay ne duoc toan bo chuyen dong bo thu tu luot.
##
## Moi thu nguoi khac nhin thay la LA BAI THAT nam tren ban — chung da replicate san.
## Chi bang thong bao phai gui rieng bang RPC, vi no la CHU chu khong phai vat the.

const CARD_SCENE := preload("res://lobby/objects/card.tscn")

const PHA_CHO := 0
const PHA_GOI := 1        # co nguoi ngoi, dang dem nguoc cho nguoi khac kip vao
const PHA_CHOI := 2
const PHA_XONG := 3
## Ngoi vao roi bao lau moi chia. Du de nguoi khac chay toi ngoi cung, khong du lau de chan.
const DOI_GOI := 8.0
## Xem ket qua bao lau roi don ban.
const DON_BAN_SAU := 7.0
## Xi dach: moi nguoi quyet cung luc nen chi MOT han chung. Het han ai chua chot thi tu DUNG.
const GIAY_XI_DACH := 20.0

## Ban sao cua `_pha` tren MOI may, cap nhat qua RPC. HUD doc no de biet co nhac phim khong.
var pha_ban: Dictionary = {}

var _spawner: FusionSpawner = null
## Chi may master dung toi: so bo bai -> nhung la da rut khoi bo do.
## Hai ban hai bo rieng, rut o ban nay khong lam het bai ban kia.
var _da_rut: Dictionary = {}
## bo bai -> { ghe -> id nguoi choi }
var _ngoi: Dictionary = {}
## bo bai -> { ghe -> Array[Card] }
var _bai: Dictionary = {}
## bo bai -> { ghe -> true } khi nguoi do da dung / qua 21 / da quyet
var _xong: Dictionary = {}
## bo bai -> Array[Card] cua nha cai (xi dach) / 5 la CHUNG (poker)
var _bai_cai: Dictionary = {}
## POKER: bo bai -> vong dang danh. 0 = truoc flop, 1 = sau flop, 2 = sau turn, 3 = sau river.
var _vong: Dictionary = {}
## POKER: bo bai -> { ghe -> true } cho nguoi da bo bai.
var _bo: Dictionary = {}
var _pha: Dictionary = {}


## Main goi MOT lan luc khoi dong. Nhan spawner tu ben ngoai thay vi tu di tim trong cay —
## nha cai khong can biet no nam o dau trong scene.
func setup(spawner: FusionSpawner) -> void:
	_spawner = spawner
	_spawner.add_spawnable_scene(CARD_SCENE)
	# RPC broadcast di toi moi node da dang ky, khong can qua mot object mang cu the.
	Fusion.register_broadcast_receiver(self)
	add_to_group("card_dealer")
	NetManager.peer_left.connect(func(id, _inactive): _roi_ban(id))
	NetManager.peer_joined.connect(func(_id, _uid): _gui_lai_trang_thai())


## Ban ma nguoi choi o may NAY dang ngoi, -1 neu khong ngoi dau. Ghe tu doc trang thai ban
## master phat ve (`CardSeat.toi_dang_ngoi`), nen may nao cung biet, khong can hoi them.
func ban_dang_ngoi() -> int:
	for s: CardSeat in get_tree().get_nodes_in_group("card_seat"):
		if s.toi_dang_ngoi:
			return s.deck
	return -1


## Phim 1 / 2 thay cho nut noi giua phong. Chi an khi dang ngoi va dang toi luot chon.
func _unhandled_input(event: InputEvent) -> void:
	var deck := ban_dang_ngoi()
	if deck < 0 or int(pha_ban.get(deck, PHA_CHO)) != PHA_CHOI:
		return
	var t := _table(deck)
	if t != null and t.poker:
		return                      # poker doc phim o HUD, vi co nam lua chon
	if event.is_action_pressed("card_yes"):
		request_yes(deck)
	elif event.is_action_pressed("card_no"):
		request_no(deck)


func request_sit(deck: int, seat: int) -> void:
	Fusion.rpc(_net_sit, deck, seat, NetManager.local_id())


func request_stand_up(deck: int, seat: int) -> void:
	Fusion.rpc(_net_stand_up, deck, seat, NetManager.local_id())


## CHI XI DACH. Poker dung `request_hanh_dong()` vi no co nam lua chon chu khong phai hai.
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
	# Ghe KHOA trong luc dang danh: vao giua van khong co bai, chi ngoi nhin.
	if pha == PHA_CHOI:
		return
	# Mot nguoi chi ngoi MOT ghe trong ca phong — nguoi da duoc dat len ghe thi khong o hai cho.
	for d in _ngoi:
		for k in _ngoi[d]:
			if int(_ngoi[d][k]) == player_id:
				return
	g[seat] = player_id
	# Ghe cua moi may doc ten nguoi ngoi tu trang thai nay — phai gui ngay, khong doi van.
	_day_trang_thai(deck)
	if pha == PHA_CHO:
		# Nguoi dau tien ngoi xuong la mo dem nguoc. Khong co nut nao ca.
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
	# Dang danh thi KHONG cho dung day — phai choi het van. Roi phong thi di duong `_roi_ban`.
	if int(_pha.get(deck, PHA_CHO)) == PHA_CHOI:
		return
	g.erase(seat)
	if g.is_empty():
		_don_ban(deck)
	else:
		_day_trang_thai(deck)


## Nguoi roi phong giua chung: master tu cho ho roi ghe, va bo bai neu dang trong van poker.
##
## `Player.ten_theo_id` luc nay thuong ra "#id" — nhan vat cua ho bi Fusion go truoc khi tin nay toi.
##
## ponytail: may MASTER roi phong thi khong ai chay ham nay, va master moi khong co trang thai
## ban nao (ghe, bai, chip deu chi o may master cu). Muon song sot qua doi master thi phai
## replicate trang thai ban — chua lam.
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


## Nguoi vao sau KHONG nhan duoc cac RPC trang thai gui truoc do (RPC la su kien, khong phai
## trang thai). Master gui lai pha + trang thai moi ban cho ca phong.
func _gui_lai_trang_thai() -> void:
	if not NetManager.is_master():
		return
	# Doi nguoi moi dung xong phong cho va dang ky nhan RPC.
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


## Bao KEM pha, de may nao cung biet co dang toi luot chon hay khong — HUD dua vao do de
## nhac phim. Chi master biet `_pha`, nen phai gui di.
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


## Dem nguoc roi tu chia. Chi may master chay.
##
## Gui MOT lan so giay con lai, khong gui moi giay: may nao cung tu dem tu con so do (xem
## `_net_cuoc`), ban tren ban cap nhat tung giay. Truoc day vong lap gui chu roi cho CUNG
## 2 giay — bang nhay 8, 6, 4, 2 va ton mot RPC moi lan.
##
## Het gio thi `_process` goi `_het_gio` — dung chung mot dong ho voi luot poker. Moi nguoi
## dung day het giua chung thi `_don_ban` xoa han, dong ho tu tat.
func _dem_nguoc(deck: int) -> void:
	_han[deck] = _gio() + DOI_GOI
	_bao(deck, "%d nguoi da ngoi. Chia bai khi dong ho ve 0." % _ghe(deck).size())
	_day_trang_thai(deck)


## Rut mot la khoi bo. Tra ve -1 khi het bai.
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


## Master dat CA vi tri lan goc xoay. La bai khong cam len duoc nen day la vi tri cuoi cung
## — khong ai xe dich duoc no.
func _dat_bai(deck: int, cho: Transform3D, up: bool, co := 0.0) -> Card:
	var idx := _rut_khoi_bo(deck)
	if idx < 0:
		return null
	var c: Card = _spawner.spawn(CARD_SCENE)
	c.deck_id = deck
	c.card_index = idx
	c.face_down = up
	if co > 0.0:
		c.card_size = co
	c.global_transform = cho
	return c


## Xep lai ca hang bai cho can giua o. CHI BAN POKER.
##
## Xi dach thi khong: nguoi choi rut them lien tuc, hang bai nhay sang trai sang phai moi lan
## rut thi roi mat. Bai xi dach cu xep tu trai qua nhu chia tay that.
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
	# Nhieu nguoi x nhieu la co the vuot 52 la — xao lai moi van cho chac.
	_da_rut[deck] = []
	_bai[deck] = {}
	_xong[deck] = {}
	_vong[deck] = 0
	_bo[deck] = {}
	if t.poker:
		_mo_cuoc(deck)
	# Poker (Texas Hold'em): moi nguoi 2 la RIENG. Xi dach: 2 la mo dau, rut them sau.
	var so_la := 2
	var cho_danh_san := so_la if t.poker else t.hand_size()
	for seat in _ghe(deck):
		var tay: Array[Card] = []
		for i in so_la:
			# Poker: bai rieng chia UP voi CA LANG. May cua chinh chu bai tu lat hinh len
			# cho ho xem (xem `Card.lo_cuc_bo`). Xi dach van ngua nhu cu — khong co gi de giau.
			var c := _dat_bai(deck, t.slot(int(seat), i, cho_danh_san), t.poker)
			if c != null:
				tay.append(c)
		(_bai[deck] as Dictionary)[seat] = tay
		_xep_ghe(deck, seat)
	var cai: Array[Card] = []
	if t.poker:
		# 5 la CHUNG dat san nhung UP het — lat dan qua tung vong.
		for i in 5:
			var c := _dat_bai(deck, t.slot_cai(i, 5), true, t.card_size_cai())
			if c != null:
				cai.append(c)
	else:
		# Xi dach: nha cai 1 la ngua, 1 la tay up.
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
		# Truoc day xi dach KHONG co han: mot nguoi treo may la ca ban dung mai.
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


## Nguoi bo bai: up het bai rieng cua ho lai cho de nhin, va danh dau da bo.
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


## Phat chip cho ai chua co, xoay nut dealer sang nguoi ke tiep.
func _mo_cuoc(deck: int) -> void:
	if not _chip.has(deck):
		_chip[deck] = {}
	var chip: Dictionary = _chip[deck]
	for k in _ghe(deck):
		# Ai chua co chip, hoac chay sach chip van truoc, thi duoc phat lai. Chip la dao cu.
		if int(chip.get(k, 0)) <= 0:
			chip[k] = CHIP_DAU
	_cuoc[deck] = {}
	_gop[deck] = {}
	_da_hd[deck] = {}
	_allin[deck] = {}
	_pot[deck] = 0
	_muc[deck] = 0
	_dealer[deck] = _ghe_con(deck, int(_dealer.get(deck, -1)))


## Small blind ngoi ben trai dealer, big blind ben trai SB. Chi con hai nguoi thi dealer
## dat SB — dung luat heads-up.
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
			Player.ten_theo_id(get_tree(), int(_ghe(deck)[sb])), SB, Player.ten_theo_id(get_tree(), int(_ghe(deck)[bb])), BB])
	# Truoc flop nguoi di dau la nguoi ben trai BB.
	_bat_luot(deck, _ghe_con(deck, bb))


## Mo mot vong cuoc moi: xoa muc cuoc cu, ai cung phai hanh dong lai.
func _mo_vong(deck: int) -> void:
	_cuoc[deck] = {}
	_muc[deck] = 0
	_da_hd[deck] = {}
	# Sau flop, nguoi di dau la nguoi con lai ben trai dealer.
	_bat_luot(deck, _ghe_con(deck, int(_dealer.get(deck, -1))))


func _bat_luot(deck: int, seat: int) -> void:
	# Bo qua nguoi da all-in — ho khong con gi de quyet.
	var t := _table(deck)
	var i := seat
	for b in t.seats:
		if i >= 0 and not bool((_allin[deck] as Dictionary).get(i, false)) 				and not bool((_bo[deck] as Dictionary).get(i, false)):
			break
		i = _ghe_con(deck, i)
	_luot[deck] = i
	_han[deck] = _gio() + GIAY_MOI_LUOT if i >= 0 else 0.0
	_day_trang_thai(deck)


## Dong ho luot. Chi may master dem — no la nguoi duy nhat duoc quyet dinh bo bai thay.
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


## Ten tung chang, dung thuat ngu that de khop voi bang luat dung canh ban.
const TEN_VONG := ["TRUOC FLOP", "SAU FLOP", "SAU TURN", "SAU RIVER"]
## Vong nao lat them may la chung. Flop lat 3, turn 1, river 1.
const LAT_TOI := [0, 3, 4, 5]


func _con_choi(deck: int) -> Array:
	var ds: Array = []
	for seat in _ghe(deck):
		if not bool((_bo[deck] as Dictionary).get(seat, false)):
			ds.append(seat)
	return ds


func _bang_poker(deck: int) -> String:
	var v := int(_vong.get(deck, 0))
	return "%s  -  con %d nguoi  -  THEO hay BO?" % [TEN_VONG[v], _con_choi(deck).size()]


## Het mot vong thi lat them bai chung roi hoi lai. Het river thi ha bai.
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


## Ha bai: ghep 2 la rieng + 5 la chung, chon bo 5 la manh nhat, ai cao nhat thi thang.
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


## CHI XI DACH. Nha cai lat la tay roi rut toi khi du 17 — luat chuan, khong co quyet dinh
## nao de gian. Poker khong co nha cai danh bai; xem `_ha_bai()`.
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
	# Doi bai cu di. Con nguoi ngoi thi tu mo van moi — dung day la nghi.
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
	# La bai KHONG con o nhom "pickable" (khong cam len duoc nua) nen phai quet nhom "card".
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


## Tra ve DIEM day du (hang + la cao + kicker), khong phai chi hang.
##
## Chi so hang thi ba nguoi cung "mot doi" se hoa ca ba, trong khi doi K phai an doi 5.
func _hang_poker(bai: Array) -> int:
	var r: Array[int] = []
	var s: Array[int] = []
	for c: Card in bai:
		if is_instance_valid(c):
			r.append(c.rank())
			s.append(c.suit())
	return CardSpot.best_score(r, s)

# ============================================================================
# CUOC POKER — TEXAS HOLD'EM
#
# Chip la DAO CU. Moi nguoi ngoi xuong duoc phat CHIP_DAU, het thi ván sau lai day lai —
# khong ai mat gi that. Nhung trong MOT van thi chip la that: het chip la khong theo duoc.
#
# LUOT LA TUAN TU. Day la lan dau du an co thu tu luot — hai game bai truoc cо y cho moi
# nguoi quyet doc lap de ne dong bo. Cuoc thi khong ne duoc: khong the hai nguoi cung to.
# Master giu con tro luot va phat cho moi may qua mot RPC duy nhat.
# ============================================================================

const CHIP_DAU := 1000
const SB := 10
const BB := 20
## Het gio thi tu bo bai. Ban khong bao gio dung im vi mot nguoi treo may.
const GIAY_MOI_LUOT := 20.0

const HD_CHECK := 0
const HD_CALL := 1
const HD_RAISE := 2
const HD_FOLD := 3
const HD_ALLIN := 4

## Ban sao tren MOI may, master gui qua `_net_cuoc`. Doc bang `chip_cua()`, `pot_cua()`...
## Dang: bo_bai -> { "pot", "muc", "luot", "dealer", "han", ghe -> [chip, cuoc, co] }
var ban_cuoc: Dictionary = {}

# --- chi master dung ---
var _chip: Dictionary = {}      # bo -> { ghe -> chip con lai }
var _cuoc: Dictionary = {}      # bo -> { ghe -> da dat trong VONG nay }
var _gop: Dictionary = {}       # bo -> { ghe -> da dat trong CA VAN } (de hoan tien all-in)
var _pot: Dictionary = {}
var _muc: Dictionary = {}       # muc cuoc cao nhat trong vong nay
var _luot: Dictionary = {}      # ghe dang toi luot, -1 = khong ai
var _dealer: Dictionary = {}
var _da_hd: Dictionary = {}     # bo -> { ghe -> da hanh dong ke tu lan to gan nhat }
var _allin: Dictionary = {}
## bo -> moc het gio, theo dong ho CUA MAY MASTER. Khong bao gio gui thang moc nay di (xem
## `_day_trang_thai`).
var _han: Dictionary = {}
## bo -> dong "Het gio! ..." cho in kem bang ket qua.
var _ghi_chu: Dictionary = {}


# ---------------------------------------------------------------- doc tu moi may

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


## co: bit 0 = da bo bai, bit 1 = all-in
func co_cua(deck: int, seat: int) -> int:
	var o: Array = _ban(deck).get(seat, [])
	return int(o[2]) if o.size() > 2 else 0


## Id nguoi dang ngoi ghe nay, 0 neu trong. Moi may doc duoc — ghe dua vao day de hien ten,
## Player dua vao day de biet minh co dang ngoi khong.
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


## Dong ho cuc bo cua may nay, giay. Chi dung de so voi moc CUNG may.
func _gio() -> float:
	return float(Time.get_ticks_msec()) / 1000.0


## Giay con lai cua dong ho tren ban (cho chia bai, luot poker, han xi dach), -1 neu khong dem.
func con_lai(deck: int) -> float:
	var h: float = float(_ban(deck).get("han", 0.0))
	if h <= 0.0:
		return -1.0
	return maxf(0.0, h - _gio())


## Nguoi o may NAY co dang toi luot khong.
func toi_toi_luot(deck: int) -> bool:
	var seat := ghe_cua_toi(deck)
	return seat >= 0 and luot_cua(deck) == seat


func ghe_cua_toi(deck: int) -> int:
	for s: CardSeat in get_tree().get_nodes_in_group("card_seat"):
		if s.toi_dang_ngoi and s.deck == deck:
			return s.index
	return -1


## Nhung hanh dong HOP LE cho nguoi o may nay, dung thu tu de HUD ve nut.
##
## Chua ai cuoc trong vong nay -> Check hoac Raise. Da co nguoi cuoc -> Call, Raise, Fold.
## Loc o day mot lan, HUD chi ve theo danh sach — khong de nguoi choi bam nham roi bi chan
## im lang.
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


## Muc to THAP NHAT hop le: theo cho bang muc hien tai roi cong them dung mot lan muc do.
func to_toi_thieu(deck: int) -> int:
	var seat := ghe_cua_toi(deck)
	var can := muc_cua(deck) - cuoc_cua(deck, seat)
	return mini(can + maxi(muc_cua(deck), BB), chip_cua(deck, seat))


# ---------------------------------------------------------------- nguoi choi gui len

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


# ---------------------------------------------------------------- master xu ly

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
			# To la dat lai vong: ai da hanh dong roi cung phai tra loi lan nua.
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


## Chuyen chip tu tay vao pot.
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


## Con ai phai hanh dong nua khong. Het thi sang vong sau.
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


## Ghe TIEP THEO con phai hanh dong, -1 neu vong da xong.
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


## Ghe co nguoi ngoi, chua bo bai, ke tiep theo vong tron. -1 neu khong co.
func _ghe_con(deck: int, tu: int) -> int:
	var t := _table(deck)
	for b in range(1, t.seats + 1):
		var i := (tu + b) % t.seats
		if _ghe(deck).has(i) and not bool((_bo[deck] as Dictionary).get(i, false)):
			return i
	return -1


## Mot dong ho, ba viec: het cho nguoi vao thi chia; xi dach het han thi ai chua chot tu DUNG;
## poker het luot thi nguoi do tu BO.
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
	# Check duoc thi check cho hien — nhung nguoi choi da chot la BO.
	_ghi_chu[deck] = "Het gio! %s tu dong BO BAI" % Player.ten_theo_id(get_tree(), int(_ghe(deck)[seat]))
	_lam(deck, seat, HD_FOLD, 0)
	# Van con danh tiep thi bao ngay. Van ket thuc luon thi `_ket_thuc` da in ghi chu roi.
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
	# Doc pot TRUOC khi chia: `_chia_pot` dua pot ve 0, doc sau thi bang luon ghi "+0 chip".
	var pot := int(_pot.get(deck, 0))
	_chia_pot(deck, [seat])
	_ket_thuc(deck, "%s THANG (moi nguoi khac da bo bai)  +%d chip" % [ten, pot])


## Chia pot cho danh sach nguoi thang. Hoa thi chia deu.
##
## ponytail: KHONG lam side pot. Ai all-in it hon thi phan chip vuot qua duoc tra lai nguoi
## da dat nhieu hon, roi con lai chia cho nguoi thang. Du dung cho van thuong; van nhieu muc
## all-in long nhau thi chia khong hoan toan chuan — lam side pot that neu sau nay thay sai.
func _chia_pot(deck: int, thang: Array) -> void:
	var chip: Dictionary = _chip[deck]
	var gop: Dictionary = _gop[deck]
	var pot: int = int(_pot.get(deck, 0))

	# Tra lai phan vuot qua muc gop cao nhat cua nguoi thang.
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


# ---------------------------------------------------------------- day trang thai di

## Mot RPC duy nhat cho ca ban.
##
## Nhieu con so nho (chip tung ghe, pot, muc, luot, dealer, han) ma gui rieng tung cai thi
## co luc may khac thay pot moi voi luot cu. Goi ca cum vao MOT CHUOI: hoac thay het trang
## thai moi, hoac thay het trang thai cu, khong bao gio thay nua noi nua kia.
##
## ⚠️ Goi bang CHUOI chu khong phai `PackedInt32Array`. Fusion khong serialize duoc kieu do:
##     "FusionRpcSerializer: Unsupported type 30 in RPC argument - will deserialize as NIL"
## Va phep thu bang `call_local` KHONG bat duoc loi nay, vi goi tai cho khong di qua bo
## serialize — nhin thi thay chay ngon, ma may kia nhan duoc NIL.
func _day_trang_thai(deck: int) -> void:
	var t := _table(deck)
	if t == null:
		return
	var goi: PackedStringArray = []
	goi.append(str(int(_pot.get(deck, 0))))
	goi.append(str(int(_muc.get(deck, 0))))
	goi.append(str(int(_luot.get(deck, -1))))
	goi.append(str(int(_dealer.get(deck, -1))))
	# Gui SO MILI-GIAY CON LAI, khong gui moc gio. Moc gio la `Time.get_ticks_msec()` cua RIENG
	# may master — dem tu luc master mo game. May khac tru bang dong ho cua chinh no thi ra so
	# sai han (trieu chung cu: dong ho poker o may khach hien sai giay).
	var han: float = float(_han.get(deck, 0.0))
	goi.append(str(roundi(maxf(0.0, han - _gio()) * 1000.0) if han > 0.0 else 0))
	# Doc bang `.get(deck, {})` chu khong `_chip[deck]`: ham nay duoc goi ca luc don ban,
	# khi chua co van nao mo va cac bang chip/cuoc chua ton tai.
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
	# Doi so giay con lai ra moc gio CUA MAY NAY. Tru nua RTT: goi tin mat chung ay moi toi noi.
	var con_ms := int(o[4])
	var tre := 0.0 if NetManager.is_master() else NetManager.rtt_ms() / 2000.0
	b["han"] = 0.0 if con_ms <= 0 else _gio() + con_ms / 1000.0 - tre
	var i := 5
	# Moi ghe 5 so: ghe, chip, cuoc, co, id nguoi ngoi.
	while i + 4 < o.size():
		b[int(o[i])] = [int(o[i + 1]), int(o[i + 2]), int(o[i + 3]), int(o[i + 4])]
		i += 5
	ban_cuoc[deck] = b
