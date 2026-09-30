class_name CameraRig
extends Node3D

## Camera. Chuột ngang xoay THÂN người chơi (để hướng đi bám theo
## hướng nhìn, và người khác thấy mình quay), chuột dọc chỉ xoay camera.
##
## KHONG giu canh tay rieng. Truoc day node nay co mot hop go ten `Arm` lam tay gia, hien ra
## khi dang cam do. Model nhan vat CO xuong tay that (Kenney: `arm-left` / `arm-right`; KayKit:
## `upperarm` / `lowerarm` / `hand` / `handslot` moi ben) va co luoi tay rieng, nen goc nhin thu
## nhat gio de nguyen than that, chi giau phan dau (xem `Player._apply_model`).
##
## Cho dat vat dang cam van do `Player.diem_cam` tinh — may khac cung phai tinh ra duoc, ma
## chung khong co node nay.
##
## Node này chỉ tồn tại trên máy sở hữu; máy khác đã queue_free() nó.

## Node bị xoay ngang. Mặc định là node cha, tức thân người chơi.
##
## Dùng NodePath chứ KHÔNG dùng `@export var body: Node3D`: kiểu Node export chỉ phân giải
## khi gán bằng node-picker trong editor. Viết tay `body = NodePath("..")` vào .tscn thì nó
## về null, và trước đây code bỏ qua im lặng nên camera không xoay ngang được.
@export var body_path: NodePath = ^".."
@export var sensitivity := 0.0012
@export var pitch_limit_deg := 85.0

## Camera lùi ra sau bao xa. 0 = góc nhìn thứ nhất.
##
## Bản trước để 0 NHƯNG lại cho hiện cả thân người chơi ở góc nhìn 1 — camera nằm ở 1.65 m,
## tức là NẰM TRONG lồng ngực, và màn hình chỉ thấy một khối nâu. Hai thứ đó không đi với nhau:
## góc nhìn 1 thì phải giấu thân, còn muốn thấy thân thì camera phải lùi ra.
##
## Chọn lùi ra: bàn party cần thấy nhân vật đứng trên ô nào.
@export var lui_xa := 4.2
## Nâng camera cao hơn điểm ngắm chừng này — nhìn hơi chúi xuống, thấy được mặt sàn.
@export var nang_cao := 1.1
## Camera đâm xuyên tường thì kéo sát lại. Chừa mép này để không dính sát mặt tường.
@export var chua_tuong := 0.35

@onready var camera: Camera3D = $Camera3D

## Góc ngồi ghế bàn bài: mắt thấp xuống, cúi nhìn mặt bàn, tầm nhìn hẹp lại một chút.
@export var mat_ngoi := 1.2
@export var cui_ngoi_deg := -15.0
@export var fov_ngoi := 68.0

## Góc BÀN PARTY: camera lùi hẳn ra sau, nâng cao và chúc xuống — nhìn bàn từ trên xuống
## chứ không đứng ngang tầm mắt với nó.
##
## ROADMAP chốt: *"Muốn quân cờ trông nhỏ thì kéo camera ra xa và hạ góc — Mario Party làm
## vậy"*. Không thu nhỏ model: đổi scale là kéo theo tốc độ, độ cao nhảy, sải chân animation
## và chiều cao collision, mà nhân vật thì dùng chung cho cả ba nơi.
##
## Rumble Reef rộng hơn bàn cũ gần ba lần, nên rig lùi 22 m, nâng nhẹ và cúi 42°. Người chơi
## vẫn đọc được ô sắp tới nhưng đồng thời thấy landmark, đảo vệ tinh và đường chân trời. Offset
## 1.5 m giữ quân cờ ở nửa dưới khung hình thay vì để hải đăng che tâm ngắm.
@export var lui_ban := 34.0
@export var cao_ban := 3.2
@export var cui_ban_deg := -48.0
@export var fov_ban := 65.0

var _body: Node3D = null
## Độ cao mắt, FOV, khoảng lùi lúc đứng — đọc từ scene lúc khởi động, không chép cứng số ở đây.
var _mat_dung := 0.0
var _fov_dung := 0.0
var _lui_dung := 0.0
var _cao_dung := 0.0
var _ban_co := false
var _tween: Tween = null


func _ready() -> void:
	_mat_dung = position.y
	_fov_dung = camera.fov
	_lui_dung = lui_xa
	_cao_dung = nang_cao
	_body = get_node_or_null(body_path) as Node3D
	if _body == null:
		push_error("CameraRig: không tìm thấy body ở '%s' — sẽ không xoay ngang được." % body_path)


## Đặt camera lùi ra sau điểm ngắm, kéo sát lại nếu đâm vào tường.
##
## Chạy mỗi khung hình ở `_process` chứ không chỉ khi chuột động: người chơi đi lùi vào tường
## thì camera phải tự thu vào dù chuột đứng yên.
func _process(_delta: float) -> void:
	if camera == null or not is_instance_valid(camera):
		return
	if lui_xa <= 0.01:
		camera.position = Vector3.ZERO
		return

	var muon := Vector3(0.0, nang_cao, lui_xa)
	var goc := global_position
	var dich := global_transform * muon
	var q := PhysicsRayQueryParameters3D.create(goc, dich, Pickable.LOP_THE_GIOI)
	q.exclude = [_body.get_rid()] if _body is CollisionObject3D else []
	var trung := get_world_3d().direct_space_state.intersect_ray(q)
	if trung.is_empty():
		camera.position = muon
		return
	# Đâm tường: đặt camera ở điểm va chạm, lùi vào một chút.
	var xa := goc.distance_to(trung["position"]) - chua_tuong
	camera.position = muon.normalized() * maxf(xa, 0.0)


func make_current() -> void:
	camera.current = true


## Chuyển giữa góc đứng và góc ngồi. Lúc ngồi đặt sẵn góc cúi để nhìn thấy bàn ngay; lúc
## đứng dậy thì giữ nguyên góc đang nhìn.
func set_ngoi(ngoi: bool) -> void:
	if _tween != null:
		_tween.kill()
	_tween = create_tween().set_parallel(true)
	_tween.tween_property(self, "position:y", mat_ngoi if ngoi else _mat_dung, 0.35)
	_tween.tween_property(camera, "fov", fov_ngoi if ngoi else _fov_dung, 0.35)
	if ngoi:
		_tween.tween_property(self, "rotation:x", deg_to_rad(cui_ngoi_deg), 0.35)


## Vào / ra pha bàn party.
##
## Chặn gọi lại khi không đổi: `PhaBanCo` bật chế độ này ở MỌI gói trạng thái (mỗi lượt vài
## gói), không chặn thì tween khởi động lại liên tục và camera giật từng nhịp mạng.
##
## Chỉ đặt góc cúi lúc VÀO. Lúc ra thì giữ nguyên góc đang nhìn, y như `set_ngoi` — kéo giật
## đầu người chơi về một góc họ không chọn là thứ khó chịu nhất một camera làm được.
func set_ban_co(bat: bool) -> void:
	if _ban_co == bat:
		return
	_ban_co = bat
	if _tween != null:
		_tween.kill()
	_tween = create_tween().set_parallel(true)
	_tween.tween_property(self, "lui_xa", lui_ban if bat else _lui_dung, 0.5)
	_tween.tween_property(self, "nang_cao", cao_ban if bat else _cao_dung, 0.5)
	_tween.tween_property(camera, "fov", fov_ban if bat else _fov_dung, 0.5)
	if bat:
		_tween.tween_property(self, "rotation:x", deg_to_rad(cui_ban_deg), 0.5)


## Dùng _input chứ không phải _unhandled_input: khi chuột đang bị khoá thì việc nhìn quanh
## không nên bị bất kỳ Control nào chặn.
## KHÔNG đụng vào `Input.mouse_mode` ở đây. Màn hình Esc (`ui/pause_menu.gd`) giữ quyền đó.
## Trước kia node này cũng bắt Esc, nên mở menu ra là camera khoá chuột lại ngay, không bấm
## được nút nào — hai bên tranh nhau một biến toàn cục.
func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		if _body != null:
			_body.rotate_y(-event.relative.x * sensitivity)
		var limit := deg_to_rad(pitch_limit_deg)
		rotation.x = clampf(rotation.x - event.relative.y * sensitivity, -limit, limit)
