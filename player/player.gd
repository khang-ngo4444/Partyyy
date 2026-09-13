class_name Player
extends CharacterBody3D

## Nhân vật. Cùng script này chạy trên MỌI máy, cho MỌI người chơi — nên mọi thứ ghi vào
## trạng thái đều phải qua cổng has_authority().
##
## Máy không sở hữu: không xử lý input, không có camera, vị trí do replicator ghi vào
## (Root Replication Mode = Auto tự đồng bộ position + rotation + velocity).

## Mỗi nhân vật là một scene riêng trong player/characters/ — cỡ (quy về 1.8 m) và hướng xoay đã
## chỉnh sẵn trong scene đó (Kenney quay mặt về +Z nên xoay 180°). Thêm/đổi nhân vật: sửa mảng
## này trong Inspector của player.tscn.
##
## KayKit không có animation nhúng sẵn trong model nhân vật (animation nằm riêng ở thư mục
## Animations/, dùng chung cho cả bộ) — `_apply_model()` không tìm thấy AnimationPlayer thì
## cứ đứng yên, không animation, vẫn hiển thị model bình thường.
@export var models: Array[PackedScene] = []
## glTF import vào Godot mặc định KHÔNG lặp — animation chạy một lượt rồi dừng, im lặng.
## Mọi animation dùng làm TRẠNG THÁI đều phải có ở đây; chỉ animation một phát mới để nguyên.
const LOOPING_ANIMS := ["idle", "walk", "sprint", "fall", "crouch", "sit",
		"holding-right", "holding-left", "holding-both"]

## Tầm với để nhặt đồ, đo từ CAMERA (xem _nearest_pickable).
@export var pick_range := 3.2
## Ném tích lực: giữ E để nạp, thả E để ném. Tốc độ ném từ min tới max theo thời gian giữ.
@export var luc_nem_min := 3.0
@export var luc_nem_max := 15.0
@export var giay_nap_day := 1.2
@export var speed := 6.0
@export var jump_height := 1.2
## So lan nhay lien tiep truoc khi cham dat. 2 = nhay doi.
@export var so_lan_nhay := 2
@export var gravity := 20.0
## Xanh cyan. Không vật nào trong phòng có màu này nên nó không lẫn vào nền.
const VIEN_MAU := Color("00ffff")
## Vỏ sáng to hơn vật chừng này. Chỉ 6% — đủ để thấy quầng sáng ló ra quanh mép, chưa đủ để
## nó thành một khối riêng che mất vật.
const VIEN_NOI := 1.06
## Mờ vừa đủ để nhìn xuyên qua thấy vật thật bên trong.
const VIEN_ALPHA := 0.5
const VIEN_SANG := 2.5
## Ngoài 60° so với hướng nhìn thì thôi không tô nữa.
const NGAM_TOI_THIEU := 0.5

@onready var sync: FusionSharedReplicator = $Replicator
@onready var rig: CameraRig = $CameraRig
@onready var name_tag: Label3D = $NameTag
@onready var model_root: Node3D = $ModelRoot

var is_mine := false

## Mắt người chơi cao chừng này khi đứng — khớp vị trí CameraRig trong camera_rig.tscn. Máy
## khác không có CameraRig của người này (bị queue_free), nên dựng lại camera từ con số này.
const MAT_CAO := 1.65
## Nguoi choi nam o lop va cham rieng. Vat nhat duoc (Pickable.LOP_VAT) khong va voi lop nay:
## di ngang ban co khong xo do quan, quan co khong chan chan nguoi.
const LOP_NGUOI := 1 << 1

## Góc cúi/ngửa của camera (radian). Máy sở hữu ghi mỗi frame, replicate tới mọi máy — để
## vật đang cầm ở máy nào cũng nằm đúng trước MẮT người cầm, kể cả khi họ ngước nhìn rổ.
## Hướng ngang đã có sẵn trong góc xoay thân (Auto replication).
@export var nhin_doc := 0.0


## Chỗ cầm đồ: trước camera người chơi, lệch theo `offset` của vật (hệ toạ độ camera: +X phải,
## +Y lên, −Z phía trước). Xoay theo hướng nhìn.
##
## Máy sở hữu dùng camera THẬT. Máy khác dựng lại từ vị trí + góc xoay thân + `nhin_doc` — cùng
## một công thức, nên máy nào cũng đặt vật cùng một chỗ (chỉ trễ theo nhịp replication).
func diem_cam(offset: Vector3) -> Transform3D:
	var cam: Transform3D
	if is_mine and rig != null and is_instance_valid(rig):
		cam = rig.camera.global_transform
	else:
		var b := global_transform.basis.orthonormalized() * Basis(Vector3.RIGHT, nhin_doc)
		cam = Transform3D(b, global_position + Vector3.UP * MAT_CAO)
	return Transform3D(cam.basis, cam * offset)

## Vỏ sáng đang bám trên vật đang ngắm. Giữ danh sách để gỡ đúng những cái mình tạo ra.
var _vien: Array[MeshInstance3D] = []
var _dang_ngam: Node3D = null
## So lan da nhay tu lan cham dat gan nhat.
var _lan_nhay := 0
## Ghế người ở MÁY NÀY đang ngồi, null nếu đứng. Chỉ máy sở hữu dùng.
var _ghe: CardSeat = null
## Lúc bắt đầu giữ E khi đang cầm vật, giây. -1 = không nạp.
var _nap_tu := -1.0


## Tên hiện của người chơi theo id. Mọi thứ cần in tên (bảng điểm, ghế, bàn bài) dùng chung.
static func ten_theo_id(tree: SceneTree, id: int) -> String:
	for n in tree.get_nodes_in_group("players"):
		if n is Player and n.player_id() == id:
			return n.player_name if n.player_name != "" else "#%d" % id
	return "#%d" % id


## Mức nạp 0..1 khi đang giữ E cầm vật, -1 nếu không nạp. HUD vẽ thanh lực theo số này.
func muc_nap() -> float:
	if _nap_tu < 0.0 or carried() == null:
		return -1.0
	return clampf((Time.get_ticks_msec() / 1000.0 - _nap_tu) / giay_nap_day, 0.0, 1.0)


func luc_dang_nap() -> float:
	return lerpf(luc_nem_min, luc_nem_max, maxf(muc_nap(), 0.0))
var _anim: AnimationPlayer = null
var _meshes: Array[MeshInstance3D] = []
var _playing := ""
var _loaded_model := -1

## Danh tính người chơi. KHÔNG dùng user_id của Photon — nhìn từ máy khác nó về rỗng.
##
## BẮT BUỘC có @export: biến script thuần thì Fusion không thấy (Words: 0, hỏng im lặng).
## Đường dẫn trong player_replication.tres là ":player_name" — tương đối với root_path.
@export var player_name: String = "":
	set(value):
		player_name = value
		if is_node_ready():
			_apply_name()

@export var color_index: int = 0:
	set(value):
		color_index = value
		if is_node_ready():
			_apply_tint()

## Người chơi TỰ bật cờ sẵn sàng của chính mình — họ sở hữu object này nên không có tranh
## chấp quyền. Ô sẵn sàng chỉ là công tắc vật lý, không lưu trạng thái.
@export var is_ready: bool = false

## Điểm SỐNG nằm trên player (họ tự ghi). Điểm LƯU TRỮ khi họ thoát thì master chép sang
## MatchState — vì object này là PLAYER_ATTACHED, chết theo chủ.
@export var score: int = 0

@export var model_index: int = 0:
	set(value):
		model_index = value
		if is_node_ready():
			_apply_model()


## HUD gọi hàm này khi bấm nút đổi nhân vật. Chỉ đổi được model CỦA CHÍNH MÌNH — gán thẳng
## `model_index` (không qua RPC) vì đây là property replicate, Fusion tự gửi đi cho máy khác,
## giống hệt cách `color_index` đã làm lúc vào phòng.
func next_model() -> void:
	if is_mine:
		model_index = (model_index + 1) % models.size()


func _ready() -> void:
	add_to_group("players")
	collision_layer = LOP_NGUOI
	is_mine = sync.has_authority()

	if is_mine:
		player_name = NetManager.player_name
		color_index = (NetManager.local_id() - 1) % NetManager.PLAYER_COLORS.size()
		model_index = (NetManager.local_id() - 1) % models.size()

	_apply_model()
	_apply_name()

	if not is_mine:
		# Camera và input CHỈ tồn tại trên máy sở hữu. queue_free() chứ không phải tắt
		# process — không bao giờ có hai camera cùng active.
		rig.queue_free()
		set_physics_process(false)
		return

	rig.make_current()
	_apply_tint()


## Id người chơi sở hữu object này. Lấy từ replicator chứ KHÔNG lưu biến riêng —
## một nguồn sự thật duy nhất.
func player_id() -> int:
	return sync.get_owner_id()


## Vo sang highlight gan tren vat KHAC, khong phai con cua player — phai tu go khi player roi di.
func _exit_tree() -> void:
	_tat_vien()


func _unhandled_input(event: InputEvent) -> void:
	if not is_mine:
		return

	# Đang gõ chat thì M là CHỮ, không phải lệnh đổi nhân vật.
	if event.is_action_pressed("change_model") \
			and not (get_viewport().gui_get_focus_owner() is LineEdit):
		next_model()
		return

	# Đang ngồi: E không nhặt gì cả, Q là xin đứng dậy. Đang có ván thì master từ chối — HUD
	# đã ghi sẵn "chờ hết ván mới đứng dậy được".
	if _ghe != null:
		if event.is_action_pressed("drop"):
			var d := get_tree().get_first_node_in_group("card_dealer") as CardDealer
			if d != null:
				d.request_stand_up(_ghe.deck, _ghe.index)
		return

	var held := carried()

	# Thả E: ném với lực đã nạp. Bắt TRƯỚC mọi thứ — sự kiện thả phím không phải "pressed".
	# Nhặt đồ bằng E không nạp gì (lúc bấm chưa cầm), nên thả E sau khi nhặt không ném nhầm.
	if event.is_action_released("interact") and _nap_tu >= 0.0:
		var toc_do := luc_dang_nap()
		_nap_tu = -1.0
		if held != null:
			held.throw(-rig.camera.global_transform.basis.z, toc_do)
		return

	# Q: đặt xuống ngay dưới chân. E khi đang cầm: ném theo hướng nhìn.
	if event.is_action_pressed("drop"):
		_nap_tu = -1.0
		if held != null:
			held.drop()
		return

	if not event.is_action_pressed("interact"):
		return

	if held != null:
		# Bắt đầu nạp. Ném lúc THẢ phím (xem trên).
		_nap_tu = Time.get_ticks_msec() / 1000.0
		return

	# Bấm ĐÚNG cái đang được tô sáng, không tự chọn lại theo luật riêng.
	#
	# Trước đây chỗ này "nút luôn thắng", còn phần tô sáng thì chọn cái nằm giữa tầm nhìn hơn.
	# Hai luật lệch nhau: quân xe ở góc bàn sáng lên, chữ ghi "E — NHAT", bấm E lại trúng
	# nút XEP LAI CO sau bệ. Giờ chỉ còn MỘT chỗ quyết định mục tiêu là `_cap_nhat_muc_tieu`.
	if _dang_ngam == null or not is_instance_valid(_dang_ngam):
		return
	if _dang_ngam is Pressable:
		(_dang_ngam as Pressable).press()
	elif _dang_ngam is Pickable:
		(_dang_ngam as Pickable).request_pick()
	elif _dang_ngam is CardSeat and (_dang_ngam as CardSeat).con_trong():
		# Chỉ XIN ngồi. Người được đặt lên ghế khi master đồng ý (xem `_theo_ghe`).
		var d := get_tree().get_first_node_in_group("card_dealer") as CardDealer
		if d != null:
			d.request_sit((_dang_ngam as CardSeat).deck, (_dang_ngam as CardSeat).index)


## Không lưu biến _carried: suy ra từ holder_id đã replicate. Một nguồn sự thật duy nhất,
## và không thể lệch với thứ mà máy khác đang thấy.
##
## ponytail: quét cả nhóm mỗi lần gọi, mà _process gọi nó mỗi frame cho mỗi người chơi.
## 10 người và 60 quân cờ là 600 vòng lặp mỗi frame. Chưa đáng lo; nếu đo thấy tốn thì cho
## Pickable báo cho người cầm qua signal thay vì để người cầm đi tìm.
func carried() -> Pickable:
	var me := player_id()
	for p: Pickable in get_tree().get_nodes_in_group("pickable"):
		if p.holder_id == me:
			return p
	return null


## Đo từ CAMERA chứ không từ điểm cầm: điểm cầm đong đưa theo góc nhìn, nên đo từ nó thì chỉ
## cần ngước lên một chút là vật dưới chân bỗng ngoài tầm.
##
## Trong tầm với, chọn vật NẰM GIỮA TẦM NHÌN NHẤT — để giữa đống quân cờ còn lấy đúng con
## mình đang nhìn.
func _nearest_pickable() -> Pickable:
	if rig == null or not is_instance_valid(rig):
		return null
	var eye := rig.camera.global_position
	var look := -rig.camera.global_transform.basis.z
	var best: Pickable = null
	var best_score := -1.0
	for p: Pickable in get_tree().get_nodes_in_group("pickable"):
		if p.holder_id != 0:
			continue
		var to_obj := p.global_position - eye
		if to_obj.length() > pick_range:
			continue
		var centered := look.dot(to_obj.normalized())
		if centered < NGAM_TOI_THIEU:
			continue                      # lệch quá 60° so với hướng nhìn
		if centered > best_score:
			best_score = centered
			best = p
	return best


## Mục tiêu nằm giữa tầm nhìn tới đâu. -1 nghĩa là không có gì.
func _cham_diem(diem: Vector3, co: bool) -> float:
	if not co or rig == null or not is_instance_valid(rig):
		return -1.0
	var eye := rig.camera.global_position
	var look := -rig.camera.global_transform.basis.z
	return look.dot((diem - eye).normalized())


## Ghế gần nhất đang nhìn vào.
func _nearest_seat() -> CardSeat:
	if rig == null or not is_instance_valid(rig):
		return null
	var eye := rig.camera.global_position
	var look := -rig.camera.global_transform.basis.z
	var best: CardSeat = null
	var best_score := 0.75
	for s in get_tree().get_nodes_in_group("card_seat"):
		var ghe := s as CardSeat
		var toi := ghe.global_position + Vector3(0.0, 0.5, 0.0) - eye
		if toi.length() > 3.2:
			continue
		var centered := look.dot(toi.normalized())
		if centered > best_score:
			best_score = centered
			best = ghe
	return best


## Cùng cách chấm điểm với _nearest_pickable: trong tầm, chọn cái nằm giữa tầm nhìn nhất.
func _nearest_pressable() -> Pressable:
	if rig == null or not is_instance_valid(rig):
		return null
	var eye := rig.camera.global_position
	var look := -rig.camera.global_transform.basis.z
	var best: Pressable = null
	var best_score := 0.55          # phải nhắm khá thẳng vào nút mới tính
	for b: Pressable in get_tree().get_nodes_in_group("pressable"):
		var to_btn := b.diem_ngam() - eye
		if to_btn.length() > b.press_range:
			continue
		var centered := look.dot(to_btn.normalized())
		if centered > best_score:
			best_score = centered
			best = b
	return best


func _physics_process(delta: float) -> void:
	# Đang ngồi: đứng yên hẳn, không trọng lực, không move_and_slide. Ghế sát bàn nên khối va
	# chạm của người chạm mép bàn — để move_and_slide chạy là bị đẩy bật khỏi ghế.
	if _ghe != null:
		velocity = Vector3.ZERO
		return
	# Đang gõ chat thì WASD và Space là CHỮ. `Input.get_vector` đọc thẳng bàn phím, không quan
	# tâm ô chữ đang giữ focus — không chặn ở đây thì gõ "wow" là nhân vật chạy đi.
	var dang_go := get_viewport().gui_get_focus_owner() is LineEdit
	if is_on_floor():
		_lan_nhay = 0
	else:
		velocity.y -= gravity * delta
		# Buoc hut khoi mep ma khong nhay thi coi nhu da dung lan dau — tren khong chi con MOT lan.
		_lan_nhay = maxi(_lan_nhay, 1)
	if not dang_go and Input.is_action_just_pressed("jump") and _lan_nhay < so_lan_nhay:
		# Dat thang van toc len (khong cong them): nhay lan hai luc dang roi van cao du jump_height.
		velocity.y = sqrt(2.0 * gravity * jump_height)
		_lan_nhay += 1

	var input := Vector2.ZERO if dang_go else Input.get_vector(
			"move_left", "move_right", "move_forward", "move_back")
	var dir := (transform.basis * Vector3(input.x, 0.0, input.y)).normalized()
	velocity.x = dir.x * speed
	velocity.z = dir.z * speed

	move_and_slide()


## Animation KHÔNG cần đồng bộ — mỗi máy tự suy ra từ velocity, mà velocity thì Auto
## replication đã gửi sẵn cho CharacterBody. Bớt một property phải truyền.
func _process(_delta: float) -> void:
	var holding := carried() != null
	if is_mine:
		nhin_doc = rig.rotation.x
		_theo_ghe()
		rig.set_holding(holding)
		_cap_nhat_muc_tieu(holding)

	if _anim == null:
		return
	var want := "holding-right" if holding else _pick_anim()
	if want != _playing:
		_playing = want
		_anim.play(want, 0.15)


## Chon vat dang ngam va boc vo sang quanh no. Phim E lam dung tren vat nay (xem `_unhandled_input`).
##
## Khong con dong chu "E — ..." noi tren vat: no chong len chu cua chinh cai nut (anh: "LAT MAT BAN"
## hai lan de nhau) — vo sang da du bao vat nao se bi bam.
func _cap_nhat_muc_tieu(holding: bool) -> void:
	var muc_tieu: Node3D = null
	# Dang cam thi E la NEM, khong phai nhat — dung ngam cai khac.
	if not holding and _ghe == null:
		# So DIEM NGAM giua nut va vat, khong uu tien nut vo dieu kien: dung tren ban co nhin thang
		# vao quan tot ma van bam trung nut cach 2.5 m o ria ban.
		var nut := _nearest_pressable()
		var vat := _nearest_pickable()
		var d_nut := _cham_diem(nut.diem_ngam() if nut != null else Vector3.ZERO, nut != null)
		var d_vat := _cham_diem(vat.global_position if vat != null else Vector3.ZERO, vat != null)
		if nut != null and d_nut >= d_vat:
			muc_tieu = nut
		elif vat != null:
			muc_tieu = vat
		else:
			muc_tieu = _nearest_seat()

	if muc_tieu != _dang_ngam:
		_tat_vien()
		_dang_ngam = muc_tieu
		if muc_tieu != null:
			_bat_vien(muc_tieu)


## Vỏ PHÁT SÁNG ôm theo đúng hình dạng vật.
##
## Đã thử hai cách trước, cả hai đều hỏng theo kiểu riêng:
##
##   Vỏ lộn mặt (chỉ vẽ mặt sau) — chỉ đẹp trên khối kín. Quân cờ tiện hở đáy, lá bài là hai
##   tấm phẳng, nhãn chữ là mặt phẳng một chiều: trên mấy thứ đó nó chỉ hiện được vài cạnh.
##
##   Khung dây 12 cạnh — thấy đủ từ mọi phía, nhưng là một cái hộp thô bao quanh, trông như
##   công cụ gỡ lỗi chứ không phải hiệu ứng trong game.
##
## Cách này: nhân bản CHÍNH cái lưới, phóng to 6%, tô cyan trong suốt có phát sáng. Nó ôm
## đúng đường nét của vật nên không có cạnh cứng nào, và nhìn góc nào cũng thấy quầng sáng
## ló ra quanh mép.
func _bat_vien(node: Node3D) -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(VIEN_MAU.r, VIEN_MAU.g, VIEN_MAU.b, VIEN_ALPHA)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.emission_enabled = true
	mat.emission = VIEN_MAU
	mat.emission_energy_multiplier = VIEN_SANG
	# Vẽ cả hai mặt: lưới hở (quân cờ, lá bài) mà chỉ vẽ một mặt thì nhìn từ phía kia là mất.
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	# Vẽ SAU vật thật, nếu không lớp trong suốt bị chính vật ghi đè.
	mat.render_priority = 1

	for m in _luoi_cua(node):
		var vo := MeshInstance3D.new()
		vo.mesh = m.mesh
		vo.material_override = mat
		vo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		vo.add_to_group("vien_ngam")
		# Phóng to quanh TÂM CỦA CHÍNH LƯỚI, không quanh gốc toạ độ của node.
		#
		# Gốc toạ độ của lưới thường không nằm giữa nó (quân cờ lấy chân đế làm gốc). Nhân
		# thẳng scale thì vỏ trượt lệch đi thay vì nở đều ra — phần đáy phình, phần đỉnh hụt.
		var tam: Vector3 = m.mesh.get_aabb().get_center()
		vo.scale = Vector3.ONE * VIEN_NOI
		vo.position = tam * (1.0 - VIEN_NOI)
		m.add_child(vo)
		_vien.append(vo)


## Mọi lưới trong `node`, TRỪ những cái vỏ sáng do chính hàm này đẻ ra.
##
## Vỏ là con của lưới gốc, nên không lọc thì lần tô sau lại bọc vỏ của lần trước — mỗi lần
## ngắm là vỏ phình thêm 6%.
func _luoi_cua(node: Node3D) -> Array[MeshInstance3D]:
	var ds: Array[MeshInstance3D] = []
	if node is MeshInstance3D and not node.is_in_group("vien_ngam"):
		ds.append(node)
	for m: MeshInstance3D in node.find_children("*", "MeshInstance3D", true, false):
		if m.is_in_group("vien_ngam") or m.mesh == null:
			continue
		ds.append(m)
	return ds


func _tat_vien() -> void:
	for v in _vien:
		if v != null and is_instance_valid(v):
			v.queue_free()
	_vien.clear()


## CHỈ dựa vào velocity, không dùng is_on_floor(). Máy khác đã tắt _physics_process nên
## move_and_slide() không chạy, và is_on_floor() ở đó là giá trị cũ kẹt lại, không tin được.
## Ngồi hay đứng là do MASTER quyết (xem `CardDealer._net_sit`). Máy này chỉ nhìn trạng thái
## ghế rồi đặt người theo: thấy tên mình trên ghế thì lên ghế, mất tên thì đứng dậy.
##
## Master tự cho người rời ghế (rớt mạng, dọn bàn) cũng đi đúng một đường này — không có
## đường thứ hai để lệch nhau.
func _theo_ghe() -> void:
	var ghe: CardSeat = null
	for n in get_tree().get_nodes_in_group("card_seat"):
		if n is CardSeat and n.toi_dang_ngoi:
			ghe = n
	if ghe == _ghe:
		return
	if ghe == null and _ghe != null and is_instance_valid(_ghe):
		global_position = _ghe.diem_dung_day()
	_ghe = ghe
	velocity = Vector3.ZERO
	if _ghe != null:
		global_transform = _ghe.diem_ngoi()
	rig.set_ngoi(_ghe != null)


func _pick_anim() -> String:
	# Ngồi: MỌI máy tự suy ra từ trạng thái ghế, không replicate thêm gì.
	for n in get_tree().get_nodes_in_group("card_seat"):
		if n is CardSeat and n.nguoi != 0 and n.nguoi == player_id():
			return "sit"
	if absf(velocity.y) > 1.0:
		return "jump" if velocity.y > 0.0 else "fall"
	return "sprint" if Vector2(velocity.x, velocity.z).length() > 0.3 else "idle"


## Fusion ghi giá trị replicate NGƯỢC VỀ cả cho chủ sở hữu, nên setter có thể bắn lại sau
## _ready(). Không chặn thì model bị dựng lại lần hai, và _playing còn giữ tên cũ nên
## _process không bao giờ gọi play() trên AnimationPlayer mới, animation đứng im.
func _apply_model() -> void:
	if _loaded_model == model_index and _anim != null:
		return
	_loaded_model = model_index
	_playing = ""
	for c in model_root.get_children():
		c.queue_free()
	_meshes.clear()
	_anim = null

	var inst := models[model_index % models.size()].instantiate() as Node3D
	model_root.add_child(inst)

	_anim = inst.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if _anim != null:
		for a in LOOPING_ANIMS:
			if _anim.has_animation(a):
				_anim.get_animation(a).loop_mode = Animation.LOOP_LINEAR

	for m: MeshInstance3D in inst.find_children("*", "MeshInstance3D", true, false):
		_meshes.append(m)
		if is_mine:
			# Góc nhìn thứ nhất: ẩn hẳn thân mình, kể cả bóng.
			m.visible = false

	_apply_tint()


## Kenney dùng một texture atlas chung. Không dùng material_override trơn (mất texture) —
## nhân bản material gốc rồi chỉ đổi albedo_color làm màu nhuộm.
func _apply_tint() -> void:
	var tint := NetManager.color_for(color_index)
	name_tag.modulate = tint
	for m in _meshes:
		var src := m.get_active_material(0)
		if src == null:
			continue
		var mat := src.duplicate()
		if mat is StandardMaterial3D:
			(mat as StandardMaterial3D).albedo_color = tint
		m.set_surface_override_material(0, mat)
	if is_mine and rig != null and is_instance_valid(rig):
		rig.tint_arm(tint)


func _apply_name() -> void:
	name_tag.text = player_name
	# Tên của chính mình thì không cần thấy — camera góc một nhìn xuyên qua nó.
	name_tag.visible = not is_mine
