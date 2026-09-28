class_name Pressable
extends Node3D

## Nút bấm. Khuôn chung cho nút reset, nút lật bàn, máy đổi nhạc, chỗ cấp xu.
##
## Nút KHÔNG tự làm gì cả — nó chỉ phát signal `pressed` ở máy người bấm. Ai nghe signal đó
## thì tự quyết định việc gì xảy ra và có cần bảo các máy khác không.

signal pressed

## Do phat sang cua khoi nut luc san sang va luc dang cho het `cooldown`.
const SANG_SAN_SANG := 0.6
const SANG_DANG_CHO := 0.05

@export var label := "NÚT"
@export var color := Color("e5484d")
## Tầm bấm, đo từ camera như cơ chế nhặt đồ.
@export var press_range := 3.0
## Cho bao lau moi cho bam lai, giay. 0 = bam bao nhieu cung duoc.
##
## MAC DINH LA 0. Phan lon Pressable trong game khong phai "cai nut" theo nghia thong thuong
## — chung la DIEM CHAM tren mot vat: coc Thap Ha Noi, la bai Liar Bar, o dat cuoc. Bam
## chung lien tay la cach choi binh thuong va khong ton gi ca, chan lai chi lam game ì.
##
## Chi bat len o nut nao mot cai bam keo theo viec NANG: despawn/spawn ca bo quan co, tween
## lat ban 1.2 giay, don 200 quan caro. Do la cho hai lan bam chen vao giua `await` cua nhau
## roi cung spawn mot bo — loi quan co nhan doi (xem `main.gd::_dang_xep`).
##
## Dat trong .tscn hoac canh `press_range` trong code:
##     play.cooldown = 1.5
@export var cooldown := 0.0
## Nút GẮN MẶT PHẲNG: bỏ cột và thu nhỏ, để đặt lên mặt bàn hay mặt trước một cái tủ.
## Nút có cột chỉ hợp khi nó mọc từ sàn.
@export var compact := false
## Cỡ chữ trên nhãn. Nút nhỏ mà chữ to như nút sàn thì chữ che mất cả cái tủ.
@export var label_size := 64
## Nhân thêm vào cỡ nút phẳng. Nút phải NHỎ HƠN khoảng cách giữa hai nút cạnh nhau, nếu
## không chúng dính thành một mảng liền không phân biệt được nút nào với nút nào.
@export var button_scale := 1.0

@onready var text: Label3D = $Label

## Cỡ của khối nút lúc mới dựng. Hiệu ứng bấm phải quay về đúng cỡ này.
var _co_goc := Vector3.ONE
## Luc bam gan nhat, giay may. Am sau de nut bam duoc ngay tu frame dau.
var _bam_luc := -1000.0
## Vat lieu cua khoi nut. Giu lai de lam mo trong luc cho (xem `_flash`).
var _mat: StandardMaterial3D = null


func _ready() -> void:
	add_to_group("pressable")
	if compact:
		# Cột và khối va chạm của nó chỉ có nghĩa khi nút mọc từ sàn.
		$Post.queue_free()
		$Stand.queue_free()
		($Mesh as MeshInstance3D).position.y = 0.05
		var k := 0.55 * button_scale
		_co_goc = Vector3(k, 0.5 * button_scale, k)
		($Mesh as MeshInstance3D).scale = _co_goc
		text.position.y = 0.1 + 0.3 * button_scale
		# `font_size` to ma `pixel_size` giu nguyen thi chu van cao bang nut san. Phai ha
		# ca hai — day moi la con so quyet dinh chu cao bao nhieu MET.
		text.pixel_size = 0.0022
	text.font_size = label_size
	# Vien theo co chu, dat O DAY vi day moi la cho biet co chu THAT. Luat chung
	# (`main.gd::_sua_chu_3d`) chay luc node vao cay — luc do `label_size` chua duoc ap nen
	# no tinh nham theo co mac dinh. Nut do code dung (Thap Ha Noi, Liar Bar) khong dat vien nao.
	text.outline_size = maxi(text.outline_size, roundi(label_size * 0.2))
	text.text = label
	text.modulate = color
	_mat = StandardMaterial3D.new()
	_mat.albedo_color = color
	_mat.emission_enabled = true
	_mat.emission = color
	_mat.emission_energy_multiplier = SANG_SAN_SANG
	($Mesh as MeshInstance3D).material_override = _mat
	_dung_vung_ngam()


## Vung NGAM cua nut: mot Area3D om lay hinh nut, rieng mot lop chi de tia ngam ban vao.
##
## KHONG dung StaticBody3D: nut phang nam tren mat tu, mot than cung o do se chan quan co lan
## qua va day nguoi choi. Area3D khong day gi, chi de tia co cai ma trung.
##
## Hop bao duoc do TU CHINH CAC LUOI dang co, khong chep cung so do tu `pressable.tscn`. Hai
## cho tu dung nut rieng:
##   `hanoi_tower._dung_coc()` — `Mesh` la cai coc tru mong, cong mot dia tron duoi chan
##   `liar_bar`               — `Mesh` la hop det (la bai), khong phai hinh tru
## Doc thang `$Mesh` roi ep sang CylinderMesh la vo o cho thu hai, va o cho thu nhat thi vung
## ngam chi rong 3 cm — dia duoi chan coc khong tinh vao.
##
## Bo qua `Post`: cai cot chi de nut moc len tu san, nham vao cot khong phai la nham vao nut.
## Co bao gom SCALE that (`button_scale` da thu nho $Mesh o tren) vi AABB nhan voi phep bien doi.
func _dung_vung_ngam() -> void:
	var bao := AABB()
	var co := false
	var ve_goc := global_transform.affine_inverse()
	for m: MeshInstance3D in find_children("*", "MeshInstance3D", true, false):
		if m.mesh == null or m.name == &"Post":
			continue
		var a := (ve_goc * m.global_transform) * m.mesh.get_aabb()
		bao = a if not co else bao.merge(a)
		co = true
	if not co:
		push_error("Pressable %s khong co luoi nao — khong ngam vao duoc." % name)
		return

	var hinh := BoxShape3D.new()
	hinh.size = bao.size
	var cs := CollisionShape3D.new()
	cs.shape = hinh
	cs.position = bao.get_center()
	var vung := Area3D.new()
	vung.name = "VungNgam"
	vung.collision_layer = Player.LOP_NGAM
	vung.collision_mask = 0
	# Khong theo doi ai ra vao — chi ton tai de `intersect_ray` trung phai.
	vung.monitoring = false
	vung.add_child(cs)
	add_child(vung)


## Đổi chữ trên nút lúc đang chạy. Đường đua dùng nó để hiện số người đã tin con này.
func set_label(txt: String) -> void:
	label = txt
	if text != null:
		text.text = txt


## Chỗ người chơi phải ngắm vào để bấm được nút này: chính cái khối nút.
##
## Trước đây bên Player cộng cứng 1.0 m vào vị trí nút — con số đó viết cho nút mọc từ sàn
## (đầu nút ở độ cao 1.0 m). Nút phẳng gắn trên mặt tủ thì đầu nút chỉ cao vài xăng-ti-mét,
## nên phải ngắm cao hơn nó cả mét mới trúng: nhìn thẳng vào nút thì KHÔNG bấm được.
func diem_ngam() -> Vector3:
	return ($Mesh as MeshInstance3D).global_position


## Nguoi choi goi. Chi chay o may nguoi bam.
##
## Dang trong thoi gian cho thi KHONG phat signal, cung khong nhay — im hoan toan. Nut da
## toi san tu luc bam truoc nen nguoi choi nhin la biet chua den luc.
func press() -> void:
	if not san_sang():
		return
	_bam_luc = _gio()
	pressed.emit()
	_flash()


## Da qua thoi gian cho chua.
func san_sang() -> bool:
	return _gio() - _bam_luc >= cooldown


func _gio() -> float:
	return Time.get_ticks_msec() / 1000.0


## Phản hồi tại chỗ cho người bấm: nhún một cái rồi TỐI ĐI cho hết `cooldown`, sáng lại
## khi bấm được. Là SỰ KIỆN nên không đồng bộ — người khác thấy kết quả của việc bấm,
## không cần thấy cái nhấp nháy.
##
## Không có phần tối/sáng thì bấm trong lúc chờ là bấm vào khoảng lặng — người chơi tưởng
## nút hỏng và bấm thêm chục cái nữa, đúng cái việc mà `cooldown` sinh ra để chặn.
##
## Nhún theo CỠ GỐC CỦA CHÍNH NÚT, không phải về `Vector3.ONE`. Nút phẳng đã bị thu nhỏ
## lúc dựng (`button_scale`); tween về `Vector3.ONE` là xoá luôn cỡ đó — bấm một cái là nút
## phình về cỡ nút sàn và ở luôn như thế.
func _flash() -> void:
	var m := $Mesh as MeshInstance3D
	var tween := create_tween()
	tween.tween_property(m, "scale", _co_goc * 0.85, 0.06)
	tween.tween_property(m, "scale", _co_goc, 0.12)
	_mat.emission_energy_multiplier = SANG_DANG_CHO
	tween.tween_interval(maxf(cooldown - 0.18, 0.0))
	tween.tween_property(_mat, "emission_energy_multiplier", SANG_SAN_SANG, 0.15)
