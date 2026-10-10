extends Node

## Autoload: kết nối Photon và danh tính người chơi ở máy này. Hệ khác dùng signal của nó.

signal connected
signal connect_failed(reason: String)
signal room_joined
signal room_left
signal room_list_changed(rooms: Array)
signal peer_joined(id: int, user_id: String)
signal peer_left(id: int, is_inactive: bool)
signal master_changed(new_id: int, old_id: int)

const MAX_PLAYERS := 10

## Màu người chơi — khác nhau cả độ sáng (dễ phân biệt khi mù màu).
const PLAYER_COLORS: Array[Color] = [
	Color("e5484d"), Color("3e63dd"), Color("f5d90a"), Color("46a758"),
	Color("d6409f"), Color("f76b15"), Color("00b8d4"), Color("8e4ec6"),
	Color("978365"), Color("e5e5e5"),
]

## Đọc lại danh sách phòng định kỳ (Photon không tự đẩy xuống ngay).
const ROOM_LIST_REFRESH := 1.5
## `FusionClient::ConnectionStatus.ConnectedToPhoton` (xem `addons/fusion/cs/Core/FusionEnums.cs`).
const KET_NOI_SANH := 2

## Danh tính cục bộ; tên cho người khác thấy nằm trên property replicate của Player.
var player_name := ""
var color_index := 0

## Ngoại hình chọn trước khi vào phòng; Player chép vào property replicate khi spawn.
var model_index := 0
var accent_index := 1
var accessory_enabled := true

## Tên phòng (Fusion trả về chuỗi rỗng nên phải tự giữ).
var room_name := ""
var _refresh_timer := 0.0


## Đếm giờ trong `_process` thay vì Timer (editor tạo autoload ngoài cây).
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


## Kết nối Photon (chưa vào phòng), để lấy danh sách phòng.
func connect_to_photon() -> bool:
	if not has_app_id():
		connect_failed.emit("Chưa có App ID trong Project Settings > Fusion > Connection")
		return false
	_connect_next_frame()
	return true


## Hoãn một khung: gọi trong `_ready` thì Fusion không add_child được và im lặng không kết nối.
func _connect_next_frame() -> void:
	await get_tree().process_frame
	Fusion.connect_to_photon(_make_user_id())


## Đuôi ngẫu nhiên cho tên phòng để không trùng phòng cũ.
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
	# Không giữ chỗ cho người mất kết nối (để phòng rỗng còn bị dọn).
	opts.set_player_ttl_ms(0)
	# Dọn phòng rỗng ngay.
	opts.set_empty_room_ttl_ms(0)
	room_name = "%s-%s" % [_safe_name(), _room_suffix()]
	Fusion.create_room(room_name, opts)


func join_room(ten: String) -> void:
	room_name = ten
	Fusion.join_room(ten, null)


## UI yêu cầu cập nhật danh sách phòng ngay.
func refresh_room_list() -> void:
	_refresh_timer = 0.0
	_publish_room_list()


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


## Mọi người trong phòng, kể cả người vào trước mình.
func peers_in_room() -> Array:
	var room := Fusion.get_room()
	return room.get_players() if room != null else []


func color_for(index: int) -> Color:
	return PLAYER_COLORS[index % PLAYER_COLORS.size()]


func _on_connected() -> void:
	connected.emit()


func _on_connect_failed(reason: String) -> void:
	connect_failed.emit(reason)


## Danh sách phòng của Fusion → mảng Dictionary thuần cho UI.
func _on_room_list_updated(_raw: Array) -> void:
	_publish_room_list()


func _publish_room_list() -> void:
	# Chỉ đọc được khi đang ở master server (không đang vào phòng hay đã trong phòng).
	if Fusion.get_connection_status() != KET_NOI_SANH:
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
