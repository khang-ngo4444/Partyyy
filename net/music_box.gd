class_name MusicBox
extends Node

## Máy nhạc phòng chờ: hàng đợi chung, cả phòng nghe cùng một bài.
## Photon chỉ chở hàng đợi (RPC trần 512 byte); file nhạc đi HTTP trực tiếp từ máy người thêm bài
## (`TCPServer`, chỉ phục vụ file chủ máy đã thêm). Phát Ogg/MP3; định dạng khác qua ffmpeg.

signal hang_doi_doi
## Bắt đầu chuyển mã một bài.
signal dang_chuyen_ma(ten: String)
## Báo lỗi lên màn hình máy nhạc.
signal bao_loi(ly_do: String)

const CONG_DAU := 8777
const CONG_CUOI := 8787
## Chặn file quá to.
const CO_TOI_DA := 32 * 1024 * 1024
## Godot phát thẳng được.
const DUOI_NHAN := ["ogg", "mp3"]
## Phải chuyển mã qua ffmpeg trước.
const DUOI_CHUYEN := ["flac", "dsf", "dff", "wav", "aiff", "aif", "m4a",
		"ape", "wv", "opus", "aac", "alac"]
## Bản đã chuyển mã, đặt tên theo key.
const THU_MUC_TAM := "user://nhac_tam"
## Trần kho tạm; vượt thì xoá file cũ nhất.
const KHO_TAM_TOI_DA := 4 * 1024 * 1024 * 1024
## Chỉ băm chừng này byte đầu file để làm key.
const BAM_DAU := 1 << 20
## Chọn bài mà sau chừng này giây vẫn chưa kêu thì bỏ qua.
const CHO_KEU := 25.0
## Byte gửi mỗi khung cho mỗi người tải.
const GUI_MOI_KHUNG := 256 * 1024

## Mỗi mục: {key, ten, giay, dia_chi}.
var hang_doi: Array[Dictionary] = []
## Rỗng = im lặng.
var dang_phat := ""

## Key -> đường dẫn file trên máy này (chỉ những file này được phục vụ).
var _chia_se: Dictionary = {}
var _kho: Dictionary = {}
var _dang_tai: Dictionary = {}

## Key -> {pid, ra, ten, dia} của các bản đang chuyển mã.
var _dang_chuyen: Dictionary = {}
var _chon_luc := 0.0
var _ffmpeg := ""
var _may_chu: TCPServer = null
var _cong := 0
var _khach: Array = []
var _loa: AudioStreamPlayer3D = null


func _ready() -> void:
	add_to_group("music_box")
	Fusion.register_broadcast_receiver(self)
	_mo_server()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(THU_MUC_TAM))
	_ffmpeg = _tim_ffmpeg()
	_don_kho_tam()


## Tìm ffmpeg trên PATH hoặc cạnh file exe (không đóng gói kèm game).
func _tim_ffmpeg() -> String:
	var ra := []
	if OS.execute("ffmpeg", ["-version"], ra, true) == 0:
		return "ffmpeg"
	var canh := OS.get_executable_path().get_base_dir().path_join(
			"ffmpeg.exe" if OS.get_name() == "Windows" else "ffmpeg")
	if FileAccess.file_exists(canh):
		return canh
	return ""


func co_ffmpeg() -> bool:
	return _ffmpeg != ""


func _don_kho_tam() -> void:
	var thu := ProjectSettings.globalize_path(THU_MUC_TAM)
	var d := DirAccess.open(thu)
	if d == null:
		return
	var ds := []
	var tong := 0
	for ten in d.get_files():
		var dd := thu.path_join(ten)
		var f := FileAccess.open(dd, FileAccess.READ)
		if f == null:
			continue
		var co := f.get_length()
		f.close()
		tong += co
		ds.append({"d": dd, "co": co, "gio": FileAccess.get_modified_time(dd)})
	if tong <= KHO_TAM_TOI_DA:
		return
	ds.sort_custom(func(a, b): return a["gio"] < b["gio"])
	for m in ds:
		if tong <= KHO_TAM_TOI_DA:
			return
		DirAccess.remove_absolute(m["d"])
		tong -= int(m["co"])


## Mở server HTTP, thử lần lượt vài cổng.
func _mo_server() -> void:
	_may_chu = TCPServer.new()
	for c in range(CONG_DAU, CONG_CUOI + 1):
		if _may_chu.listen(c) == OK:
			_cong = c
			return
	push_error("MusicBox: khong mo duoc cong nao trong %d-%d" % [CONG_DAU, CONG_CUOI])
	_may_chu = null


## Các địa chỉ để máy khác lấy file (nối bằng `|`, ưu tiên dải LAN gia đình) — máy Windows
## có nhiều card mạng ảo nên gửi vài địa chỉ cho bên tải thử lần lượt.
func dia_chi_phuc_vu() -> String:
	if _cong == 0:
		return ""
	var ds: Array[String] = []
	for d in IP.get_local_addresses():
		var s := String(d)
		# Bỏ loopback và IPv6.
		if s.begins_with("127.") or ":" in s:
			continue
		ds.append(s)
	ds.sort_custom(func(a: String, b: String): return _hang_dia_chi(a) < _hang_dia_chi(b))
	var ra: Array[String] = []
	# RPC chỉ chở được 512 byte.
	for s in ds.slice(0, 3):
		ra.append("http://%s:%d" % [s, _cong])
	return "|".join(ra)


## Nhỏ hơn = thử trước (192.168 → 10.x → 172.16–31 vì hay là card ảo).
static func _hang_dia_chi(s: String) -> int:
	if s.begins_with("192.168."):
		return 0
	if s.begins_with("10."):
		return 1
	if s.begins_with("172."):
		return 3
	# 169.254.x là APIPA, không gọi tới được.
	if s.begins_with("169.254."):
		return 4
	return 2


# ───────────────────────────── phục vụ file ─────────────────────────────

func _process(_delta: float) -> void:
	_chay_server()
	_theo_doi_chuyen_ma()
	_theo_doi_bai()


func _chay_server() -> void:
	if _may_chu == null:
		return
	while _may_chu.is_connection_available():
		var p := _may_chu.take_connection()
		if p != null:
			_khach.append({"p": p, "vao": PackedByteArray(), "ra": PackedByteArray(), "i": 0})

	var con := []
	for k in _khach:
		if _phuc_vu_mot(k):
			con.append(k)
	_khach = con


## false = xong hoặc hỏng.
func _phuc_vu_mot(k: Dictionary) -> bool:
	var p: StreamPeerTCP = k["p"]
	p.poll()
	if p.get_status() != StreamPeerTCP.STATUS_CONNECTED:
		return false

	var vao: PackedByteArray = k["vao"]
	var ra: PackedByteArray = k["ra"]
	if ra.is_empty():
		var co := p.get_available_bytes()
		if co > 0:
			vao.append_array(p.get_data(co)[1])
			k["vao"] = vao
		var txt: String = vao.get_string_from_utf8()
		if not txt.contains("\r\n\r\n"):
			# Yêu cầu HTTP hợp lệ không dài thế này.
			return vao.size() < 8192
		ra = _dung_tra_loi(txt)
		k["ra"] = ra

	var het: int = ra.size()
	var i: int = k["i"]
	var n: int = mini(GUI_MOI_KHUNG, het - i)
	if n > 0:
		if p.put_data(ra.slice(i, i + n)) != OK:
			return false
		k["i"] = i + n
	return int(k["i"]) < het


## Dựng câu trả lời HTTP. Key chỉ dùng để tra `_chia_se` — không bao giờ mở file theo đường dẫn
## lấy từ yêu cầu.
func _dung_tra_loi(yeu_cau: String) -> PackedByteArray:
	var dong := yeu_cau.get_slice("\r\n", 0).split(" ")
	if dong.size() < 2 or dong[0] != "GET":
		return _loi(405, "chi nhan GET")

	var duong := dong[1]
	if not duong.begins_with("/f/"):
		return _loi(404, "khong co")
	var key := duong.substr(3).get_slice("?", 0)

	if not _chia_se.has(key):
		return _loi(404, "khong chia se key nay")
	var tep := FileAccess.open(_chia_se[key], FileAccess.READ)
	if tep == null:
		return _loi(404, "khong mo duoc tep")
	var than := tep.get_buffer(tep.get_length())
	tep.close()

	var dau := ("HTTP/1.1 200 OK\r\nContent-Length: %d\r\n" % than.size()
			+ "Content-Type: application/octet-stream\r\nConnection: close\r\n\r\n")
	var ra := dau.to_utf8_buffer()
	ra.append_array(than)
	return ra


func _loi(ma: int, ly_do: String) -> PackedByteArray:
	var dau := "HTTP/1.1 %d %s\r\nContent-Length: 0\r\nConnection: close\r\n\r\n" % [ma, ly_do]
	return dau.to_utf8_buffer()


# ───────────────────────────── thêm bài ─────────────────────────────

## Quét thư mục → [{ten, duong, giay}] (`giay` = 0, chỉ đọc lúc sắp phát).
static func quet_thu_muc(duong: String) -> Array[Dictionary]:
	var ra: Array[Dictionary] = []
	var d := DirAccess.open(duong)
	if d == null:
		return ra
	for ten in d.get_files():
		var duoi := ten.get_extension().to_lower()
		if not (DUOI_NHAN.has(duoi) or DUOI_CHUYEN.has(duoi)):
			continue
		ra.append({"ten": ten, "duong": duong.path_join(ten),
				"can_chuyen": not DUOI_NHAN.has(duoi)})
	ra.sort_custom(func(a, b): return a["ten"] < b["ten"])
	return ra


## Key = băm 1 MB đầu + kích thước file nguồn.
static func _bam_tep(duong: String) -> String:
	var f := FileAccess.open(duong, FileAccess.READ)
	if f == null:
		return ""
	var co := f.get_length()
	var dau := f.get_buffer(mini(co, BAM_DAU))
	f.close()
	var hc := HashingContext.new()
	hc.start(HashingContext.HASH_SHA256)
	hc.update(dau)
	hc.update(str(co).to_utf8_buffer())
	return hc.finish().hex_encode().substr(0, 24)


## Thêm bài vào hàng đợi chung; định dạng không phát được thì chuyển mã một lần.
func them_bai(duong: String, ten: String) -> void:
	var dia := dia_chi_phuc_vu()
	if dia == "":
		push_error("MusicBox: chua co dia chi phuc vu, khong them bai duoc")
		return
	var key := _bam_tep(duong)
	if key == "":
		return

	if DUOI_NHAN.has(duong.get_extension().to_lower()):
		var f := FileAccess.open(duong, FileAccess.READ)
		if f != null and f.get_length() > CO_TOI_DA:
			f.close()
			bao_loi.emit("%s qua %d MB" % [ten, CO_TOI_DA / 1048576])
			return
		if f != null:
			f.close()
		_chia_se[key] = duong
		Fusion.rpc(_net_them, key, ten.left(60), 0, dia)
		return

	# Đã chuyển mã lần trước thì dùng lại.
	var tam := "%s/%s.ogg" % [THU_MUC_TAM, key]
	if FileAccess.file_exists(tam):
		_chia_se[key] = ProjectSettings.globalize_path(tam)
		Fusion.rpc(_net_them, key, ten.left(60), 0, dia)
		return

	if _dang_chuyen.has(key):
		return
	if not co_ffmpeg():
		bao_loi.emit("Can ffmpeg de doc %s. Cai ffmpeg roi mo lai game." % duong.get_extension())
		return

	var ra := ProjectSettings.globalize_path(tam)
	# -vn bỏ ảnh bìa, -ac 2 -ar 48000 về stereo 48 kHz, -q:a 5 ≈ 160 kbps.
	var pid := OS.create_process(_ffmpeg, [
			"-y", "-v", "error", "-i", duong, "-vn", "-map_metadata", "-1",
			"-ac", "2", "-ar", "48000", "-c:a", "libvorbis", "-q:a", "5", ra])
	if pid <= 0:
		bao_loi.emit("Khong chay duoc ffmpeg")
		return
	_dang_chuyen[key] = {"pid": pid, "ra": ra, "ten": ten, "dia": dia}
	dang_chuyen_ma.emit(ten)


## Theo dõi các tiến trình ffmpeg đang chạy.
func _theo_doi_chuyen_ma() -> void:
	if _dang_chuyen.is_empty():
		return
	for key in _dang_chuyen.keys():
		var m: Dictionary = _dang_chuyen[key]
		if OS.is_process_running(int(m["pid"])):
			continue
		_dang_chuyen.erase(key)
		if not FileAccess.file_exists(m["ra"]):
			bao_loi.emit("ffmpeg khong chuyen duoc %s" % m["ten"])
			continue
		_chia_se[key] = m["ra"]
		Fusion.rpc(_net_them, key, String(m["ten"]).left(60), 0, m["dia"])


@rpc("any_peer", "call_local")
func _net_them(key: String, ten: String, co: int, dia_chi: String) -> void:
	hang_doi.append({"key": key, "ten": ten, "co": co, "dia_chi": dia_chi})
	hang_doi_doi.emit()


func don_hang_doi() -> void:
	Fusion.rpc(_net_don)


@rpc("any_peer", "call_local")
func _net_don() -> void:
	hang_doi.clear()
	dang_phat = ""
	if _tim_loa() != null:
		_loa.stop()
	hang_doi_doi.emit()


func bo_qua() -> void:
	Fusion.rpc(_net_bo_qua)


@rpc("any_peer", "call_local")
func _net_bo_qua() -> void:
	if not hang_doi.is_empty():
		hang_doi.remove_at(0)
	dang_phat = ""
	if _tim_loa() != null:
		_loa.stop()
	hang_doi_doi.emit()


# ───────────────────────────── phát ─────────────────────────────

## Master quyết bài phát; mọi máy tự tải và tự phát. Hết bài thì nghe `finished` của loa
## (không hỏi `playing`, vì nó cũng false lúc đang tải).
func _theo_doi_bai() -> void:
	if not NetManager.is_master() or hang_doi.is_empty():
		return
	_tim_loa()
	if dang_phat == "":
		Fusion.rpc(_net_phat, String(hang_doi[0]["key"]))
		return
	# Chọn bài mà mãi không kêu thì bỏ qua.
	if _loa != null and not _loa.playing and not _loa.stream_paused:
		if _gio() - _chon_luc > CHO_KEU:
			push_warning("MusicBox: %s khong keu sau %d giay, bo qua" % [dang_phat, CHO_KEU])
			Fusion.rpc(_net_bo_qua)


static func _gio() -> float:
	return Time.get_ticks_msec() / 1000.0


## Chỉ master chuyển bài.
func _het_bai() -> void:
	if NetManager.is_master() and dang_phat != "":
		Fusion.rpc(_net_bo_qua)


## Chưa phát thì bắt đầu; đang phát thì tạm dừng/chạy tiếp.
func bat_dau_hoac_tiep() -> void:
	if dang_phat == "":
		if not hang_doi.is_empty():
			Fusion.rpc(_net_phat, String(hang_doi[0]["key"]))
		return
	Fusion.rpc(_net_tam_dung, not dang_tam_dung())


func dang_tam_dung() -> bool:
	return _loa != null and is_instance_valid(_loa) and _loa.stream_paused


@rpc("any_peer", "call_local")
func _net_tam_dung(x: bool) -> void:
	if _tim_loa() != null:
		_loa.stream_paused = x
	hang_doi_doi.emit()


@rpc("any_peer", "call_local")
func _net_phat(key: String) -> void:
	dang_phat = key
	_chon_luc = _gio()
	if _tim_loa() != null:
		_loa.stream_paused = false
	if NetManager.is_master():
		var ms := get_tree().get_first_node_in_group("match_state") as MatchState
		if ms != null:
			ms.nhac_key = key
	_nap_roi_phat(key)
	# Tải trước bài kế.
	if hang_doi.size() > 1:
		_tai(String(hang_doi[1]["key"]))


func _nap_roi_phat(key: String) -> void:
	if _kho.has(key):
		_dat_vao_loa(key)
		return
	# File trên máy này thì đọc thẳng từ đĩa.
	if _chia_se.has(key):
		var f := FileAccess.open(_chia_se[key], FileAccess.READ)
		if f != null:
			_kho[key] = f.get_buffer(f.get_length())
			f.close()
			_dat_vao_loa(key)
			return
	_tai(key)


## Tải file từ máy người thêm bài, thử lần lượt từng địa chỉ.
func _tai(key: String, thu := 0) -> void:
	if _kho.has(key) or _dang_tai.has(key):
		return
	var muc := _muc(key)
	if muc.is_empty():
		return
	var ds := String(muc["dia_chi"]).split("|", false)
	if thu >= ds.size():
		push_warning("MusicBox: thu het %d dia chi ma khong tai duoc %s" % [ds.size(), key])
		return

	var req := HTTPRequest.new()
	req.use_threads = true
	add_child(req)
	_dang_tai[key] = req
	req.request_completed.connect(func(_kq, ma: int, _h, than: PackedByteArray):
		_dang_tai.erase(key)
		req.queue_free()
		if ma != 200:
			_tai(key, thu + 1)  # thử địa chỉ kế
			return
		_kho[key] = than
		if dang_phat == key:
			_dat_vao_loa(key))
	req.request("%s/f/%s" % [ds[thu], key])


func _dat_vao_loa(key: String) -> void:
	if _tim_loa() == null:
		return
	var than: PackedByteArray = _kho[key]
	# Thử Ogg rồi MP3 theo nội dung (bài đã chuyển mã vẫn giữ đuôi gốc).
	var st: AudioStream = AudioStreamOggVorbis.load_from_buffer(than)
	if st == null:
		st = AudioStreamMP3.load_from_buffer(than)
	var ten := String(_muc(key).get("ten", ""))
	if st == null:
		push_warning("MusicBox: khong doc duoc %s" % ten)
		return
	_loa.stream = st
	_loa.play()


func _muc(key: String) -> Dictionary:
	for m in hang_doi:
		if m["key"] == key:
			return m
	return {}


## Loa ở tháp đồng hồ trong sảnh (sảnh nạp sau nên tìm lại mỗi lần).
func _tim_loa() -> AudioStreamPlayer3D:
	if _loa != null and is_instance_valid(_loa):
		return _loa
	_loa = get_tree().get_first_node_in_group("loa_nhac") as AudioStreamPlayer3D
	if _loa != null and not _loa.finished.is_connected(_het_bai):
		_loa.finished.connect(_het_bai)
	return _loa


## Người vào muộn: tải bài đang phát (nghe từ đầu bài).
func dong_bo_vao_muon() -> void:
	var ms := get_tree().get_first_node_in_group("match_state") as MatchState
	if ms != null and ms.nhac_key != "" and dang_phat == "":
		dang_phat = ms.nhac_key
		_nap_roi_phat(ms.nhac_key)
