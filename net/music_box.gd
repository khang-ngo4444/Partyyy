class_name MusicBox
extends Node

## Máy nhạc của phòng chờ. Ai cũng trỏ được vào thư mục nhạc trên máy mình, thêm bài vào hàng
## đợi chung, và CẢ PHÒNG nghe cùng một bài.
##
## ## Vì sao file nhạc KHÔNG đi qua Photon
##
## Đã đo trên chính bản Fusion Godot 3.0.0 Preview 555 này: không có `RpcChannel`, chỉ có
## `rpc` / `rpc_to` / `rpc_to_player` — tức là mọi RPC đều là RPC thường, dính trần 512 byte
## và bị huỷ IM LẶNG khi vượt. Cộng thêm hai giới hạn của Photon Cloud:
##
##   - Bộ đệm phía server 500 KB cho mỗi client. Đẩy một bài 5.8 MB vào là tràn đệm và người
##     nhận bị NGẮT KẾT NỐI, không phải chậm mà là văng khỏi phòng.
##   - Free tier 3 GB mỗi CCU mỗi tháng, tính cả chiều vào lẫn chiều ra. Lưu lượng nhân theo
##     số người nghe: phòng 10 người nghe Ogg 192k là 240 KB/s, ăn hết hạn mức sau ~69 giờ.
##
## Nên ở đây Photon chỉ chở HÀNG ĐỢI — key, tên bài, độ dài, địa chỉ lấy file. Vài chục byte
## mỗi bài. Byte nhạc đi đường HTTP riêng.
##
## ## Ai phục vụ file
##
## Chính máy người THÊM bài. Mỗi máy mở một server HTTP tí hon (`TCPServer`, có sẵn trong
## Godot, không cần addon), và chỉ phục vụ đúng những file chủ máy đã tự tay thêm vào hàng đợi.
##
## Chạy thẳng trong mạng LAN, không cần hạ tầng gì. Qua Internet thì máy phục vụ cần mở cổng —
## hoặc thay `dia_chi_phuc_vu()` bằng URL của một relay, phần còn lại của file này giữ nguyên.
##
## ## Định dạng
##
## Ogg Vorbis và MP3. Godot 4.7.1 KHÔNG có `AudioStreamFLAC` (đã đo) — FLAC không phát được
## kể cả trên máy chủ sở hữu nó, nên bộ chọn thư mục lọc nó ra ngay từ đầu.

signal hang_doi_doi
## Bat dau chuyen ma mot bai (ten bai). Man hinh may nhac hien trang thai.
signal dang_chuyen_ma(ten: String)
## Co chuyen khong lam duoc — noi thang ra man hinh thay vi im lang.
signal bao_loi(ly_do: String)

const CONG_DAU := 8777
const CONG_CUOI := 8787
## Chặn file quá to: một bài Ogg 192k dài 10 phút cũng chỉ ~14 MB.
const CO_TOI_DA := 32 * 1024 * 1024
## Godot phat thang duoc hai duoi nay.
const DUOI_NHAN := ["ogg", "mp3"]
## Nhung duoi phai chuyen ma truoc. ffmpeg doc het — da do tren may nay: `flac`,
## `dsd_lsbf`/`dsd_msbf` (cho .dsf/.dff), `alac`, `ape`, `wavpack`.
const DUOI_CHUYEN := ["flac", "dsf", "dff", "wav", "aiff", "aif", "m4a",
		"ape", "wv", "opus", "aac", "alac"]
## Ban nhac da chuyen ma nam o day, dat ten theo key.
const THU_MUC_TAM := "user://nhac_tam"
## Tran kho tam. Vuot thi xoa dan file cu nhat.
const KHO_TAM_TOI_DA := 4 * 1024 * 1024 * 1024
## Bam tung nay byte dau file de lam key. KHONG doc ca file: mot ban DSD la vai tram MB, doc
## het chi de bam la khung may vai giay va an sach RAM.
const BAM_DAU := 1 << 20
## Chon bai xong ma qua tung nay giay loa van chua keu thi bo qua. File hong, tai truot,
## hay ffmpeg ra file rong deu roi vao day. Rong rai vi mot ban FLAC dai co the mat vai
## giay chuyen ma cong vai giay tai ve.
const CHO_KEU := 25.0
## Gửi chừng này byte mỗi khung hình cho mỗi người tải. 256 KB/khung ở 60 fps là thừa sức
## bơm đầy một mạng LAN mà không làm khựng khung hình.
const GUI_MOI_KHUNG := 256 * 1024

## Hàng đợi chung. Mỗi mục: {key, ten, giay, dia_chi}.
var hang_doi: Array[Dictionary] = []
## Bài đang phát, rỗng = im lặng.
var dang_phat := ""

## Key -> đường dẫn file trên máy NÀY. Chỉ những file trong đây mới được phục vụ ra ngoài.
var _chia_se: Dictionary = {}
## Key -> PackedByteArray đã tải về.
var _kho: Dictionary = {}
var _dang_tai: Dictionary = {}

## Key -> {pid, ra, ten, dia} cua cac ban dang chuyen ma.
var _dang_chuyen: Dictionary = {}
## Giay may luc chon bai hien tai — de biet no da "im" bao lau.
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


## ffmpeg co san tren PATH thi dung luon; khong thi tim ngay canh file exe.
##
## KHONG dong goi ffmpeg vao ban build: no nang ~80 MB tren mot ban da 190 MB, va giay phep
## thi tuy ban compile (LGPL hay GPL) — de nguoi dung tu cai thi khong phai gu roi chuyen do.
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


## Xoa bot ban chuyen ma cu khi kho tam vuot tran. Xoa theo thu tu cu nhat truoc.
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


## Mở server HTTP tí hon. Thử lần lượt vài cổng — hai bản game chạy trên cùng một máy (hay
## để lại một cổng chưa kịp nhả) thì cổng đầu đã bận.
func _mo_server() -> void:
	_may_chu = TCPServer.new()
	for c in range(CONG_DAU, CONG_CUOI + 1):
		if _may_chu.listen(c) == OK:
			_cong = c
			return
	push_error("MusicBox: khong mo duoc cong nao trong %d-%d" % [CONG_DAU, CONG_CUOI])
	_may_chu = null


## Các địa chỉ người khác dùng để lấy file của máy này, nối bằng `|`, xếp theo thứ tự đáng
## thử trước.
##
## TRẢ VỀ NHIỀU ĐỊA CHỈ chứ không một cái. Máy Windows đời thật có cả đống card mạng ảo —
## WSL, Hyper-V, Docker, VPN — và `IP.get_local_addresses()` KHÔNG đảm bảo thứ tự. Đã đo trên
## chính máy build này: địa chỉ đầu tiên trả về là `172.31.240.1`, card ảo của WSL, không máy
## nào trong LAN gọi tới được. Lấy đại cái đầu tiên là tính năng chết ngay lần dùng thật.
##
## Nên xếp ưu tiên theo dải LAN gia đình hay gặp rồi gửi vài cái; bên tải thử lần lượt tới khi
## có cái chạy (xem `_tai`).
##
## ĐÂY LÀ CHỖ CẮM RELAY. Trả về URL gốc của relay thay vì danh sách IP, và đổi `them_bai`
## thành một lần PUT — phần còn lại của file này giữ nguyên.
func dia_chi_phuc_vu() -> String:
	if _cong == 0:
		return ""
	var ds: Array[String] = []
	for d in IP.get_local_addresses():
		var s := String(d)
		# Bỏ loopback và IPv6: máy khác không gọi được về 127.0.0.1, còn IPv6 trong LAN gia
		# đình thường là địa chỉ tạm, đổi liên tục.
		if s.begins_with("127.") or ":" in s:
			continue
		ds.append(s)
	ds.sort_custom(func(a: String, b: String): return _hang_dia_chi(a) < _hang_dia_chi(b))
	var ra: Array[String] = []
	# Ba cái là đủ, và RPC chỉ chở được 512 byte.
	for s in ds.slice(0, 3):
		ra.append("http://%s:%d" % [s, _cong])
	return "|".join(ra)


## Nhỏ hơn = thử trước. 192.168 là dải router gia đình phổ biến nhất; 10.x hay gặp trong mạng
## công ty; 172.16–31 thì đúng là dải riêng THẬT, nhưng cũng chính là chỗ WSL/Docker/Hyper-V
## hay chiếm — nên để sau cùng.
static func _hang_dia_chi(s: String) -> int:
	if s.begins_with("192.168."):
		return 0
	if s.begins_with("10."):
		return 1
	if s.begins_with("172."):
		return 3
	# 169.254.x là APIPA — địa chỉ máy tự bịa ra khi KHÔNG xin được DHCP. Không bao giờ gọi
	# tới được. Đo trên máy build: có hai cái, và chúng chiếm mất hai trong ba suất gửi đi.
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


## Trả về false khi xong (hoặc hỏng) để gỡ khỏi danh sách.
func _phuc_vu_mot(k: Dictionary) -> bool:
	var p: StreamPeerTCP = k["p"]
	p.poll()
	if p.get_status() != StreamPeerTCP.STATUS_CONNECTED:
		return false

	# Còn đang đọc yêu cầu.
	var vao: PackedByteArray = k["vao"]
	var ra: PackedByteArray = k["ra"]
	if ra.is_empty():
		var co := p.get_available_bytes()
		if co > 0:
			vao.append_array(p.get_data(co)[1])
			k["vao"] = vao
		var txt: String = vao.get_string_from_utf8()
		if not txt.contains("\r\n\r\n"):
			# Yeu cau HTTP hop le khong bao gio dai the nay. Cat som, dung nuot vo han.
			return vao.size() < 8192
		ra = _dung_tra_loi(txt)
		k["ra"] = ra

	# Dang gui.
	var het: int = ra.size()
	var i: int = k["i"]
	var n: int = mini(GUI_MOI_KHUNG, het - i)
	if n > 0:
		if p.put_data(ra.slice(i, i + n)) != OK:
			return false
		k["i"] = i + n
	return int(k["i"]) < het


## Dựng nguyên một câu trả lời HTTP.
##
## KHÔNG BAO GIỜ lấy đường dẫn từ yêu cầu rồi đem đi mở file. Đây là một cái cổng mở trên máy
## người chơi; để họ tự chọn đường dẫn là bất kỳ ai trong mạng cũng đọc được mọi file trên đĩa
## của họ. Key trong yêu cầu chỉ dùng để TRA `_chia_se` — là bảng do chính chủ máy tự thêm vào
## khi họ bỏ bài vào hàng đợi. Ngoài bảng đó ra, không có đường nào chạm tới hệ thống file.
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

	var dau := "HTTP/1.1 200 OK\r\nContent-Length: %d\r\nContent-Type: application/octet-stream\r\nConnection: close\r\n\r\n" % than.size()
	var ra := dau.to_utf8_buffer()
	ra.append_array(than)
	return ra


func _loi(ma: int, ly_do: String) -> PackedByteArray:
	return ("HTTP/1.1 %d %s\r\nContent-Length: 0\r\nConnection: close\r\n\r\n" % [ma, ly_do]).to_utf8_buffer()


# ───────────────────────────── thêm bài ─────────────────────────────

## Quét một thư mục trên máy này. Trả về danh sách {ten, duong, giay}.
##
## `giay` để 0: đọc độ dài thật phải nạp cả file lên rồi hỏi `AudioStream.get_length()`, mà
## một thư mục vài trăm bài thì đó là vài GB. Độ dài chỉ cần biết lúc SẮP phát.
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


## Bam 1 MB dau + kich thuoc file lam key.
##
## KHONG doc ca file: mot ban DSD la vai tram MB. Hai file khac nhau ma trung ca 1 MB dau lan
## tong dung luong thi gan nhu khong co.
##
## Bam NGUON, khong bam ban da chuyen ma: cung mot ban FLAC thi ai them cung ra cung mot key,
## nen ai da tai roi khong tai lai.
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


## Them mot file tren may nay vao hang doi chung.
##
## Ogg/MP3 thi chia se thang file goc. Moi thu khac (FLAC, DSD, WAV, ALAC...) di qua ffmpeg
## mot lan roi nho ban da chuyen lai trong `user://nhac_tam`.
##
## CHI chuyen ma dung bai duoc them, dung luc duoc them. Khong ai phai ngoi chuyen ca thu vien
## 100 GB sang Ogg de nghe vai bai trong phong cho.
func them_bai(duong: String, ten: String) -> void:
	var dia := dia_chi_phuc_vu()
	if dia == "":
		push_error("MusicBox: chua co dia chi phuc vu, khong them bai duoc")
		return
	var key := _bam_tep(duong)
	if key == "":
		return

	# Phat thang duoc: khong dong vao ffmpeg.
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

	# Da chuyen ma lan truoc roi thi dung lai.
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
	# -vn: bo anh bia. FLAC hay nhung anh bia vai MB, de nguyen thi no chui vao file Ogg va
	#      Godot doc ra mot stream hong.
	# -ac 2 -ar 48000: DSD chay o 2.8 MHz va nhieu ban FLAC la da kenh — phai ha ve stereo
	#      48 kHz thi Godot moi phat duoc.
	# -q:a 5: ~160 kbps, bai 4 phut ra ~4.8 MB. Qua loa may tinh trong phong cho thi khong
	#      phan biet duoc voi ban goc.
	var pid := OS.create_process(_ffmpeg, [
			"-y", "-v", "error", "-i", duong, "-vn", "-map_metadata", "-1",
			"-ac", "2", "-ar", "48000", "-c:a", "libvorbis", "-q:a", "5", ra])
	if pid <= 0:
		bao_loi.emit("Khong chay duoc ffmpeg")
		return
	_dang_chuyen[key] = {"pid": pid, "ra": ra, "ten": ten, "dia": dia}
	dang_chuyen_ma.emit(ten)


## Theo doi cac ban ffmpeg dang chay. `OS.create_process` khong chan khung hinh, nen chi viec
## hoi xem no xong chua.
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

## Master quyết bài nào phát. Mọi máy tự tải và tự phát — không ai phát hộ ai.
##
## HẾT BÀI thì nghe tín hiệu `finished` của loa, KHÔNG hỏi `_loa.playing` mỗi khung hình.
## `playing` không phân biệt được "chưa bắt đầu" với "đã hết": suốt quãng bài còn đang chuyển
## mã hoặc còn đang tải, nó là `false`. Bản trước hỏi nó rồi kết luận "bài vừa hết" nên bắn
## `_net_bo_qua` ngay lập tức, `dang_phat` về rỗng, khung sau lại chọn bài kế — một vòng lặp
## RPC 60 lần mỗi giây nuốt sạch hàng đợi trước khi có nốt nhạc nào kịp kêu.
func _theo_doi_bai() -> void:
	if not NetManager.is_master() or hang_doi.is_empty():
		return
	_tim_loa()
	if dang_phat == "":
		Fusion.rpc(_net_phat, String(hang_doi[0]["key"]))
		return
	# Đã chọn bài mà mãi không kêu: bỏ qua thay vì để hàng đợi đứng im vĩnh viễn.
	if _loa != null and not _loa.playing and not _loa.stream_paused:
		if _gio() - _chon_luc > CHO_KEU:
			push_warning("MusicBox: %s khong keu sau %d giay, bo qua" % [dang_phat, CHO_KEU])
			Fusion.rpc(_net_bo_qua)


static func _gio() -> float:
	return Time.get_ticks_msec() / 1000.0


## Loa báo hết bài. Chỉ master được quyết chuyển bài, không thì mười máy cùng bắn một lệnh.
func _het_bai() -> void:
	if NetManager.is_master() and dang_phat != "":
		Fusion.rpc(_net_bo_qua)


## Bấm PHÁT: chưa có gì kêu thì bắt đầu từ đầu hàng đợi, đang kêu thì tạm dừng / chạy tiếp.
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
	# Tải trước bài kế ngay bây giờ, trong lúc bài này còn đang phát — đến lúc chuyển bài là
	# file đã nằm sẵn trong RAM, không có khoảng lặng chờ tải.
	if hang_doi.size() > 1:
		_tai(String(hang_doi[1]["key"]))


func _nap_roi_phat(key: String) -> void:
	if _kho.has(key):
		_dat_vao_loa(key)
		return
	# File nam ngay tren may nay thi doc thang tu dia — khong di duong mang vong ve chinh minh.
	if _chia_se.has(key):
		var f := FileAccess.open(_chia_se[key], FileAccess.READ)
		if f != null:
			_kho[key] = f.get_buffer(f.get_length())
			f.close()
			_dat_vao_loa(key)
			return
	_tai(key)


## Tải file về từ máy người đã thêm bài.
##
## Thử lần lượt từng địa chỉ họ gửi kèm: cái đầu có thể là card ảo không ai gọi tới được
## (xem `dia_chi_phuc_vu`). Hết danh sách mới chịu thua.
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
	# Giữ nguyên trong RAM: nhạc là thứ dùng xong bỏ, không rải file lạ lên đĩa người chơi.
	req.use_threads = true
	add_child(req)
	_dang_tai[key] = req
	req.request_completed.connect(func(_kq, ma: int, _h, than: PackedByteArray):
		_dang_tai.erase(key)
		req.queue_free()
		if ma != 200:
			_tai(key, thu + 1)          # địa chỉ này không ăn, thử cái kế
			return
		_kho[key] = than
		if dang_phat == key:
			_dat_vao_loa(key))
	req.request("%s/f/%s" % [ds[thu], key])


func _dat_vao_loa(key: String) -> void:
	if _tim_loa() == null:
		return
	var than: PackedByteArray = _kho[key]
	# Thu Ogg truoc roi MP3 — KHONG doan theo duoi ten bai. Bai FLAC da qua ffmpeg thi noi
	# dung la Ogg trong khi ten van la ".flac"; doan theo duoi la sai ngay truong hop chinh.
	# Ca hai lop deu tu tra ve null khi noi dung khong khop.
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


## Loa nằm ở tháp đồng hồ trong lobby — lobby nạp sau MusicBox nên phải tìm lại mỗi lần.
func _tim_loa() -> AudioStreamPlayer3D:
	if _loa != null and is_instance_valid(_loa):
		return _loa
	_loa = get_tree().get_first_node_in_group("loa_nhac") as AudioStreamPlayer3D
	if _loa != null and not _loa.finished.is_connected(_het_bai):
		_loa.finished.connect(_het_bai)
	return _loa


## Người vào muộn: đọc bài đang phát từ MatchState rồi tự tải về. Không đồng bộ tới từng giây —
## nhạc nền phòng chờ, vào giữa bài là nghe từ đầu bài đó.
func dong_bo_vao_muon() -> void:
	var ms := get_tree().get_first_node_in_group("match_state") as MatchState
	if ms != null and ms.nhac_key != "" and dang_phat == "":
		dang_phat = ms.nhac_key
		_nap_roi_phat(ms.nhac_key)
