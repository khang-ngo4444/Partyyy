extends MiniGame3D

## BOUNDING BLOCKS — giẫm lên ô là ô đổi sang màu mình. Hết 60 giây, ai nhiều ô hơn thì thắng.
##
## Khuôn T3 đầu tiên: sàn chia ô, ô đổi chủ theo dấu chân. Không ai chết, không ai bị hất —
## trò duy nhất trong ba trò T3 mà kết quả thuần là đếm.
##
## ## 0 gói tin — thật sự là 0
##
## Chủ ô suy ra từ VỊ TRÍ người chơi, mà vị trí thì `FusionSharedReplicator` đã gửi sẵn cho
## mọi máy rồi (nó phải gửi, không thì không ai nhìn thấy ai). Nên mỗi máy tự sơn lấy cả bàn cờ
## từ dữ liệu đã có trên tay. Cả ván không thêm một byte nào — kể cả gói `"tôi chết"` cũng
## không, vì ở đây không ai chết.
##
## ## Vì sao master vẫn là người chốt bảng
##
## Replication có độ trễ, nên hai máy có thể bất đồng về ô cuối cùng ai giẫm trước. Chênh một
## ô thì thường không đổi thứ hạng, nhưng "thường" không đủ: một trận sát nút mà mỗi máy hiện
## một bảng khác nhau là hỏng cả lượt chơi. Master gửi bảng của nó một lần lúc hết giờ.
##
## ## Vì sao ô KHÔNG nhả chủ khi người chơi rời đi
##
## Giẫm lên là chiếm luôn, tới khi người khác giẫm đè. Nhả ra thì chiến thuật duy nhất là đứng
## yên giữ một ô — ngược hẳn với cái tên của trò.

## Cao hơn mặt ô quá chừng này thì coi như đang bay, không tính giẫm. Nhân vật nhảy qua ô
## không được chiếm nó — nếu không, nhảy vòng quanh sàn là cách ăn gian rẻ nhất.
const CAO_TINH_GIAM := 1.1

## Vật liệu theo chỉ số màu người chơi, khớp `NetManager.PLAYER_COLORS`.
@export var vat_lieu_nguoi: Array[StandardMaterial3D] = []

var _o: Array[OSan] = []
## Ô thứ i thuộc về ai. 0 = chưa ai giẫm. Cùng thứ tự với `_o`.
var _chu: PackedInt32Array = PackedInt32Array()
## Nửa cạnh một ô, đo từ chính mesh trong `.tscn` — không chép tay con số 1,6 ở đây.
var _nua_o := 0.8


func _ready() -> void:
	super()
	ten = "BOUNDING BLOCKS"
	luat = "WASD chạy · giẫm lên ô để chiếm · hết giờ ai nhiều ô hơn thì thắng"
	giay_van = 60.0


func _dung_san() -> void:
	_o.assign(san.find_children("*", "OSan", true, false))
	_chu.resize(_o.size())
	_chu.fill(0)
	for o in _o:
		o.dat(true)
		o.son(null)
	if _o.is_empty():
		push_error("BoundingBlocks: san khong co o nao")
		return
	var hinh := (_o[0].get_node("Mat") as MeshInstance3D).mesh as BoxMesh
	if hinh != null:
		_nua_o = hinh.size.x * 0.5


func _luat_moi_nhip() -> void:
	for p: Player in get_tree().get_nodes_in_group("players"):
		if not _song.has(p.player_id()):
			continue
		var i := _o_duoi_chan(p)
		if i >= 0 and _chu[i] != p.player_id():
			_chu[i] = p.player_id()
			_o[i].son(_vat_lieu(p.color_index))


## Chỉ số ô ngay dưới chân người này, hoặc -1.
##
## Quét thẳng cả 169 ô thay vì tính chỉ số từ toạ độ: bố cục lưới nằm trong `.tscn` (bước lưới,
## gốc lưới, số hàng), tính ngược lại trong code là chép cùng một con số ở hai nơi — đúng thứ
## đã đẻ ra lỗi hộp va chạm lệch mesh ở Laser Leap. Quét tốn ~1000 phép so sánh mỗi khung hình,
## rẻ hơn nhiều so với một bố cục sai mà không ai thấy.
func _o_duoi_chan(p: Player) -> int:
	var v := p.global_position
	for i in _o.size():
		var o := _o[i].global_position
		if v.y - o.y > CAO_TINH_GIAM or v.y < o.y:
			continue
		if absf(v.x - o.x) <= _nua_o and absf(v.z - o.z) <= _nua_o:
			return i
	return -1


func _vat_lieu(chi_so_mau: int) -> StandardMaterial3D:
	if vat_lieu_nguoi.is_empty():
		return null
	return vat_lieu_nguoi[chi_so_mau % vat_lieu_nguoi.size()]


## Số ô mỗi người đang giữ: `player_id -> số ô`.
func dem_o() -> Dictionary:
	var d: Dictionary = {}
	for id in _song:
		d[int(id)] = 0
	for c in _chu:
		if d.has(c):
			d[c] = int(d[c]) + 1
	return d


# ───────────────────────── xếp hạng theo số ô, không theo mạng ─────────────────────────

func _chot_ket_qua() -> void:
	_chay = false
	set_process(false)
	var dem := dem_o()
	var xep: Array = []
	for id in dem:
		xep.append(int(id))
	xep.sort_custom(func(a: int, b: int) -> bool: return int(dem[a]) > int(dem[b]))
	Fusion.rpc(_net_xep_hang, xep)
