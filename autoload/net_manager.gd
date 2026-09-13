extends Node

## Autoload. Sở hữu DUY NHẤT luồng kết nối Photon và danh tính người chơi ở máy này.
##
## KHÔNG spawn gì, KHÔNG biết gameplay, KHÔNG proxy mọi hàm của Fusion.
## Mọi hệ thống khác chạm vào mạng qua signal của node này, không gọi thẳng Fusion.

signal connected
signal connect_failed(reason: String)
signal room_joined
signal room_left
signal room_list_changed(rooms: Array)
signal peer_joined(id: int, user_id: String)
signal peer_left(id: int, is_inactive: bool)
signal master_changed(new_id: int, old_id: int)

const MAX_PLAYERS := 10

## Bảng màu người chơi. Phải phân biệt được từ xa VÀ khi mù màu -> khác nhau cả độ sáng.
const PLAYER_COLORS: Array[Color] = [
	Color("e5484d"), Color("3e63dd"), Color("f5d90a"), Color("46a758"),
	Color("d6409f"), Color("f76b15"), Color("00b8d4"), Color("8e4ec6"),
	Color("978365"), Color("e5e5e5"),
]

## Danh tính CHỈ dùng ở máy này. Tên hiển thị cho người khác thấy phải là property
## replicate trên object player — user_id của Photon nhìn từ máy khác về rỗng
## (đã kiểm chứng, xem ROADMAP mục 1f).
var player_name := ""
var color_index := 0

## Photon chi day danh sach phong xuong khi no muon. Nguoi mo menu truoc luc ai do tao
## phong co the ngoi nhin danh sach rong. Doc lai ban cache dinh ky cho chac.
const ROOM_LIST_REFRESH := 1.5


var _refresh_timer := 0.0


## Dem thang trong _process thay vi tao mot node Timer. Editor co tao instance cua autoload
## NGOAI cay scene de kiem tra, luc do Timer.start() bao loi va lam ngap bang Errors —
## che mat loi that. Bo node di la het ca loai van de do.
func _process(delta: float) -> void:
	_refresh_timer += delta
	if _refresh_timer >= ROOM_LIST_REFRESH:
		_refresh_timer = 0.0
		_publish_room_list()


func _ready() -> void:
	Fusion.connected_to_photon.connect(_on_connected)
	Fusion.connection_failed.connect(_on_connect_failed)
	Fusion.room_joined.connect(func(): room_joined.emit())
	Fusion.room_left.connect(func(): room_left.emit())
	Fusion.room_list_updated.connect(_on_room_list_updated)
	Fusion.player_joined.connect(func(id, uid): peer_joined.emit(id, uid))
	Fusion.player_left.connect(func(id, inactive): peer_left.emit(id, inactive))
	Fusion.master_client_changed.connect(func(a, b): master_changed.emit(a, b))


## Kết nối tới Photon. Chưa vào phòng nào — chỉ để lấy được danh sách phòng.
func connect_to_photon() -> bool:
	if not has_app_id():
		connect_failed.emit("Chưa có App ID trong Project Settings > Fusion > Connection")
		return false
	_connect_next_frame()
	return true


## Fusion tự add_child một node dịch vụ khi bắt đầu kết nối. Gọi thẳng trong _ready()
## của bất kỳ node nào thì cây đang dựng dở -> add_child thất bại -> Fusion không có
## vòng lặp xử lý và IM LẶNG không kết nối. Hoãn một frame là hết.
func _connect_next_frame() -> void:
	await get_tree().process_frame
	Fusion.connect_to_photon(_make_user_id())


## Ten phong DUY NHAT moi lan tao.
##
## Truoc day ten phong = ten nguoi choi. Choi hai phien lien tiep thi hai phong trung ten,
## va neu phong cu chua kip chet thi ban be bam vao danh sach se roi vao PHONG CU — moi
## nguoi ngoi mot phong ma khong ai biet. Trieu chung dung nhu da gap: chu phong ngoi mot
## minh, nguoi kia lai "thay nhan vat" (thuc ra la nhan vat con sot trong phong cu).
##
## Duoi thanh 4 ky tu ngau nhien lam hai phong khong the trung ten nua.
func _room_suffix() -> String:
	const CHU := "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
	var out := ""
	for i in 4:
		out += CHU[randi() % CHU.length()]
	return out


func host_room() -> void:
	var opts := FusionRoomOptions.new()
	opts.set_max_players(MAX_PLAYERS)
	opts.set_is_open(true)
	opts.set_is_visible(true)
	# Nguoi mat ket noi bi bo suat ngay, khong giu cho. Con giu cho thi phong khong bao gio
	# rong, ma phong khong rong thi `empty_room_ttl_ms(0)` khong bao gio don duoc no.
	opts.set_player_ttl_ms(0)
	# Photon giu phong rong song tiep sau khi moi nguoi thoat. Khong tat thi danh sach
	# phong day cac phong ma cua nhung lan choi truoc, va nguoi ta bam vao mot phong
	# rong con cache object cu.
	opts.set_empty_room_ttl_ms(0)
	room_name = "%s-%s" % [_safe_name(), _room_suffix()]
	Fusion.create_room(room_name, opts)


## Ten phong dang o. Fusion `get_room().get_name()` tra ve CHUOI RONG nen phai tu giu.
var room_name := ""


func join_room(ten: String) -> void:
	room_name = ten
	Fusion.join_room(ten, null)


func leave_room() -> void:
	room_name = ""
	Fusion.leave_room()


func is_master() -> bool:
	return Fusion.is_master_client()


func local_id() -> int:
	return Fusion.get_local_player_id()


func rtt_ms() -> int:
	return int(Fusion.get_rtt() * 1000.0)


func has_app_id() -> bool:
	return not String(ProjectSettings.get_setting("fusion/connection/app_id", "")).is_empty()


## Id của mọi người đang ở trong phòng, KỂ CẢ người vào trước mình.
## Cần hàm này vì signal player_joined chỉ bắn cho người vào SAU mình.
func peers_in_room() -> Array:
	var room := Fusion.get_room()
	return room.get_players() if room != null else []


func color_for(index: int) -> Color:
	return PLAYER_COLORS[index % PLAYER_COLORS.size()]


func _on_connected() -> void:
	connected.emit()


func _on_connect_failed(reason: String) -> void:
	connect_failed.emit(reason)


## Đổi danh sách phòng của Fusion sang mảng Dictionary thuần, để UI không phải
## đụng vào kiểu dữ liệu của Fusion.
func _on_room_list_updated(_raw: Array) -> void:
	_publish_room_list()


func _publish_room_list() -> void:
	# Trong phong thi khong con o master server nua -> goi get_room_list() se bao loi.
	if not Fusion.is_connected_to_photon() or Fusion.is_in_room():
		return
	var out: Array = []
	for listing in Fusion.get_room_list():
		if not listing.get_is_open():
			continue
		out.append({
			"id": listing.get_name(),
			"label": listing.get_name(),
			"players": listing.get_player_count(),
			"max": listing.get_max_players(),
		})
	room_list_changed.emit(out)


func _make_user_id() -> String:
	return "%s_%d" % [_safe_name(), randi()]


func _safe_name() -> String:
	var n := player_name.strip_edges()
	return n if not n.is_empty() else "Player"
