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

## Tam voi de nhat do va bam nut, cung la DO DAI TIA NGAM (xem `_ngam`).
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
## Vo sang lay DO SANG tu chinh vat, chi giu SAC va DO BAO HOA co dinh: quan den ra xanh
## tham, quan trang ra xanh nhat.
##
## Mot mau cyan co dinh cho moi vat thi tren quan trang no gan nhu bien mat (sang tren sang),
## con tren quan den no choi den muc nuot mat hinh con quan.
const VIEN_SAC := 0.5              # cyan tren vong mau 0..1
const VIEN_BAO_HOA := 0.85
## San do sang. Vat den tuyet doi (luminance 0) van phai con thay duoc vien.
const VIEN_SANG_TOI_THIEU := 0.28
## Vo sang to hon vat chung nay. Chi 6% — du de thay quang sang lo ra quanh mep, chua du de
## no thanh mot khoi rieng che mat vat.
const VIEN_NOI := 1.06
## Mo vua du de nhin xuyen qua thay vat that ben trong.
const VIEN_ALPHA := 0.5
const VIEN_SANG := 2.5

@onready var sync: FusionSharedReplicator = $Replicator
@onready var rig: CameraRig = $CameraRig
@onready var name_tag: Label3D = $NameTag
@onready var model_root: Node3D = $ModelRoot

var is_mine := false
## Pha ban party khoa WASD lai: di lai do xuc xac quyet, khong do phim.
var khoa_di_chuyen := false

## Chế độ SÂN ĐẤU (minigame pha 3): camera là một cái CỐ ĐỊNH trên cao, dùng chung cả phòng.
##
## Hai thứ đổi cùng lúc, và phải cùng lúc:
##   1. WASD đi theo **trục thế giới**, không theo hướng thân — không ai có camera riêng để mà
##      đi theo hướng nhìn của mình nữa.
##   2. Thân **tự quay theo hướng chạy** — chuột không còn xoay thân, không tự quay thì nhân
##      vật trượt ngang như bị kéo.
##
## Cục bộ, không replicate: góc xoay thân đã nằm trong Auto replication rồi.
var che_do_san := false
## Thân quay theo hướng chạy nhanh cỡ nào, radian/giây.
const XOAY_THEO_HUONG := 12.0

## Vận tốc bị ĐẨY, giữ tách khỏi vận tốc đi lại.
##
## `_physics_process` GÁN THẲNG `velocity.x/z` từ phím mỗi khung hình, nên cộng xung lực vào
## `velocity` là khung sau nó bị xoá sạch — đẩy không ăn thua gì. Phải giữ riêng rồi cộng vào
## ở bước cuối, và cho tắt dần.
var _day := Vector3.ZERO
## Lực đẩy tắt dần bao nhiêu m/s mỗi giây.
const DAY_TAT_DAN := 9.0

## Sàn trơn tới mức nào: số GIÂY để tăng tốc từ đứng yên lên `speed` — và cũng là số giây để
## dừng lại. `0` = bám sàn như thường (gán thẳng vận tốc, dừng tức thì). Sân tuyết bật lên,
## mọi chỗ khác để nguyên 0.
var truot := 0.0
## Vận tốc ngang do CHÂN người chơi, không kể lực đẩy. Phải giữ riêng: trên băng, vận tốc là
## thứ tích luỹ qua nhiều khung hình, mà `velocity` thì bị `_day` cộng vào rồi tắt dần.
var _van := Vector2.ZERO


## Đẩy nhân vật này một xung lực.
##
## Luật xuyên suốt dự án: **thứ gì đẩy người chơi đều rẻ, miễn là chính họ tự áp lên mình**.
## Chỉ gọi hàm này cho nhân vật CỦA MÁY MÌNH — vị trí người khác do replicator lo, đẩy hộ họ
## là đánh nhau với chính cái replicator đó.
func day(xung: Vector3) -> void:
	_day.x += xung.x
	_day.z += xung.z
	if xung.y > 0.0:
		velocity.y = maxf(velocity.y, xung.y)


## Mắt người chơi cao chừng này khi đứng — khớp vị trí CameraRig trong camera_rig.tscn. Máy
## khác không có CameraRig của người này (bị queue_free), nên dựng lại camera từ con số này.
const MAT_CAO := 1.65
## Nguoi choi nam o lop va cham rieng. Vat nhat duoc (Pickable.LOP_VAT) khong va voi lop nay:
## di ngang ban co khong xo do quan, quan co khong chan chan nguoi.
const LOP_NGUOI := 1 << 1
## Lop NGAM: chi de ban tia ngam trung, khong day gi va khong chan gi. Nut bam va ghe khong
## co than vat ly (co y — nut nam tren mat tu se chan do dat tren do, di xuyen ghe khong con
## la ngoi), nen chung deo mot Area3D rieng o lop nay de tia co cai ma trung.
const LOP_NGAM := 1 << 4

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
## Camera lùi ít hơn chừng này mét thì coi như đang dán vào gáy — phải giấu thân đi.
const GAN_GAY := 1.0
## Đang giấu thân hay không. Nhớ lại để không gán `cast_shadow` cho mọi mesh ở mọi khung hình.
var _dang_giau := false
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

## Kieu bong bong chat (xem `SpeechBubble.Kieu`). Replicate vi bong bong duoc VE O MAY KHAC:
## ho phai biet minh chon kieu nao. Khong can setter — `Chat` doc gia tri nay ngay truoc moi
## lan cho bong bong noi.
@export var bubble_shape: int = 0


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
			# Ghe sofa dung day duoc ngay; ghe bai phai xin master (dang giua van thi bi tu choi).
			if _ghe is GheNgoi:
				(_ghe as GheNgoi).dung_day()
			else:
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
		if _dang_ngam is GheNgoi:
			# Sofa khong co van bai de tranh luot — ngoi thang, khong xin ai.
			(_dang_ngam as GheNgoi).ngoi_xuong()
			return
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


## Vat dang ngam: BAN MOT TIA tu camera. Trung cai gi thi ngam cai do — khong trung gi thi
## khong ngam gi.
##
## Truoc day moi loai muc tieu co mot vong quet rieng (`_nearest_pickable`, `_nearest_pressable`,
## `_nearest_seat`) roi cham diem "nam giua tam nhin toi dau". Nguong la tich vo huong 0.5 —
## mot hinh NON 60 do. O tam voi 3.2 m, cai non do trum mot vong tron duong kinh 3.7 m: nhin
## lech han ra ngoai quan co van sang len, va giua chum quan co canh nhau thi khong con nao
## chi dich danh duoc con nao.
##
## Tia lay ca LOP_THE_GIOI vao mat na: tuong, mat ban, mat tu CHAN tia. Khong the ngam xuyen
## tuong sang vat o phong ben, cung khong nhat duoc quan co nam khuat sau chan ban.
func _ngam() -> Node3D:
	if rig == null or not is_instance_valid(rig):
		return null
	var cam := rig.camera.global_transform
	var q := PhysicsRayQueryParameters3D.create(cam.origin, cam.origin - cam.basis.z * pick_range,
			Pickable.LOP_THE_GIOI | Pickable.LOP_VAT | LOP_NGAM)
	# Nut va ghe la Area3D, khong phai than vat ly — khong bat cai nay thi tia xuyen qua chung.
	q.collide_with_areas = true
	q.exclude = [get_rid()]
	var trung := get_world_3d().direct_space_state.intersect_ray(q)
	if trung.is_empty():
		return null
	return _chu_cua(trung["collider"], cam.origin)


## Tu thu ma tia trung tro len tim CHU cua no. Hinh va cham cua Pickable nam ngay tren than
## vat; nut va ghe thi vung ngam la mot Area3D con, phai tro len cha moi ra chu.
##
## Tra ve null = trung mot thu khong ngam duoc (tuong, mat ban, vat dang co nguoi cam).
func _chu_cua(va_cham: Object, mat: Vector3) -> Node3D:
	var n := va_cham as Node
	while n != null:
		if n is Pickable:
			return n if (n as Pickable).holder_id == 0 else null
		if n is Pressable:
			# Tam bam rieng tung nut, co nut chinh xuong 2.2 m — tia dai 3.2 m nen phai loc lai.
			var nut := n as Pressable
			return nut if mat.distance_to(nut.diem_ngam()) <= nut.press_range else null
		if n is CardSeat:
			return n
		n = n.get_parent()
	return null


func _physics_process(delta: float) -> void:
	# Đang ngồi: đứng yên hẳn, không trọng lực, không move_and_slide. Ghế sát bàn nên khối va
	# chạm của người chạm mép bàn — để move_and_slide chạy là bị đẩy bật khỏi ghế.
	if _ghe != null or khoa_di_chuyen:
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
	var tho := Vector3(input.x, 0.0, input.y)
	# Sân đấu giữ nguyên trục thế giới; phòng chờ xoay theo hướng thân.
	var dir := (tho if che_do_san else transform.basis * tho).normalized()
	var muon := Vector2(dir.x, dir.z) * speed
	# Trên băng thì chân không ăn sàn: vận tốc bò dần tới thứ mình muốn, và khi buông phím cũng
	# bò dần về 0 — đó chính là cái trượt.
	_van = _van.move_toward(muon, speed / truot * delta) if truot > 0.0 else muon
	velocity.x = _van.x + _day.x
	velocity.z = _van.y + _day.z
	_day = _day.move_toward(Vector3.ZERO, DAY_TAT_DAN * delta)

	# Godot coi -Z là hướng trước, nên yaw cần là `atan2(-x, -z)` của hướng chạy.
	if che_do_san and dir.length_squared() > 0.01:
		rotation.y = rotate_toward(rotation.y, atan2(-dir.x, -dir.z), XOAY_THEO_HUONG * delta)

	move_and_slide()


## Animation KHÔNG cần đồng bộ — mỗi máy tự suy ra từ velocity, mà velocity thì Auto
## replication đã gửi sẵn cho CharacterBody. Bớt một property phải truyền.
func _process(_delta: float) -> void:
	var holding := carried() != null
	if is_mine:
		nhin_doc = rig.rotation.x
		_theo_ghe()
		_cap_nhat_muc_tieu(holding)
		# Ở sân đấu camera nhìn từ trên xuống: giấu thân là mất luôn nhân vật của mình.
		_giau_than(rig.lui_xa < GAN_GAY and not che_do_san)

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
		# MOT tia quyet dinh tat ca. Khong con man so diem giua nut, vat va ghe — thu nao che
		# tam mat truoc thi thu do duoc ngam, dung nhu mat nguoi choi thay.
		muc_tieu = _ngam()

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
## Cach nay: nhan ban CHINH cai luoi, phong to 6%, to xanh trong suot co phat sang — do sang
## cua mau lay tu chinh vat (xem `_mau_vien`). No om
## đúng đường nét của vật nên không có cạnh cứng nào, và nhìn góc nào cũng thấy quầng sáng
## ló ra quanh mép.
func _bat_vien(node: Node3D) -> void:
	for m in _luoi_cua(node):
		# Mot vat lieu RIENG cho tung luoi: mot vat co the co nhieu luoi khac mau (quan co tuong
		# co dia go va chu muc), va do sang cua vo phai bam theo dung cai luoi no dang boc.
		var mat := StandardMaterial3D.new()
		var mau := _mau_vien(m)
		mat.albedo_color = Color(mau, VIEN_ALPHA)
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.emission_enabled = true
		mat.emission = mau
		mat.emission_energy_multiplier = VIEN_SANG
		# Ve ca hai mat: luoi ho (quan co, la bai) ma chi ve mot mat thi nhin tu phia kia la mat.
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		# Ve SAU vat that, neu khong lop trong suot bi chinh vat ghi de.
		mat.render_priority = 1
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


## Mau vo sang cho MOT luoi: giu sac cyan, lay do sang tu mau goc cua chinh luoi do.
##
## `get_active_material` tra ve dung cai vat lieu dang co hieu luc (override > surface override
## > vat lieu cua mesh), nen quan co — von duoc to bang `material_override` trong
## `chess_piece.gd` — doc ra dung mau trang/den cua no.
##
## ponytail: chi doc `albedo_color`, khong lay mau tu texture. Kit Kenney dung mot atlas chung
## voi albedo trang, nen do vat giu nguyen mau atlas se deu ra vien sang. Chua thanh van de vi
## moi thu nhat duoc trong phong deu to bang albedo_color; neu sau nay co thi lay mau trung
## binh cua texture mot lan roi nho lai.
func _mau_vien(m: MeshInstance3D) -> Color:
	var goc := m.get_active_material(0)
	var sang := 1.0
	if goc is BaseMaterial3D:
		sang = (goc as BaseMaterial3D).albedo_color.get_luminance()
	return Color.from_hsv(VIEN_SAC, VIEN_BAO_HOA, maxf(sang, VIEN_SANG_TOI_THIEU))


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
		# Goc nhin thu BA: khong giau gi ca, ke ca cua chinh minh — thay duoc nhan vat minh dang
		# dieu khien la diem chinh cua goc nhin nay.
		#
		# Chi giau phan dau khi camera dan sat vao gay (`CameraRig.lui_xa` gan 0), xem `_giau_dau`.
		if is_mine:
			m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON

	# Mesh vua dung lai tu dau: ep `_giau_than` ap lai trang thai o khung hinh sau.
	_dang_giau = false
	_apply_tint()


## Giấu thân khi camera dán sát vào gáy (góc nhìn thứ nhất).
##
## Không đặt `visible = false` mà dùng `SHADOWS_ONLY`: thân biến mất khỏi tầm mắt nhưng **vẫn
## đổ bóng**, nên người chơi nhìn bóng mình trên sàn là biết mình đang đứng đâu và quay mặt
## hướng nào. Tắt hẳn thì mất luôn cái mốc đó.
##
## Chỉ chạy khi trạng thái ĐỔI — gán `cast_shadow` cho từng mesh mỗi khung hình là việc thừa.
##
## Vật đang cầm không bị giấu: điểm cầm gắn vào CAMERA chứ không vào thân (GUIDE mục 1t), nên
## nó vẫn hiện đúng trước mặt.
func _giau_than(giau: bool) -> void:
	if giau == _dang_giau:
		return
	_dang_giau = giau
	for m in _meshes:
		m.cast_shadow = (GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY if giau
				else GeometryInstance3D.SHADOW_CASTING_SETTING_ON)


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


func _apply_name() -> void:
	name_tag.text = player_name
	# Tên của chính mình thì không cần thấy — camera góc một nhìn xuyên qua nó.
	name_tag.visible = not is_mine
