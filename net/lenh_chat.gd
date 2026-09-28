class_name LenhChat
extends RefCounted

## LỆNH gõ trong ô chat phòng chờ. Gõ `/mg tank` là cả phòng bị kéo vào ván Tank.
##
## Cả file này là **hàm thuần**: không đụng node, không đụng Fusion, không đụng autoload. Nó
## chỉ bóc một dòng chữ ra thành `(tên lệnh, đối số)` và trả lời "ai được phép chạy". Việc thi
## hành nằm ở `main.gd` — nơi vốn đã cầm `quan_tro`.
##
## Tách ra vì hai lý do: kiểm được bằng `assert` mà không cần dựng phòng, và **luật phân
## quyền nằm ở đúng MỘT chỗ** thay vì rải trong chat lẫn main.
##
## ## LỚP XÁC THỰC — chỉ CHỦ PHÒNG được chạy lệnh
##
## Ba tầng, cố ý chồng lên nhau:
##
##   1. **Máy gõ tự kiểm.** Không phải chủ phòng thì báo ngay tại chỗ, không tốn một gói tin
##      nào. Đây chỉ là tiện nghi — client bị sửa thì bỏ qua được tầng này.
##   2. **Lệnh đi RPC tới MỌI máy, nhưng chỉ máy đang là master mới thi hành.** Máy khác nhận
##      gói rồi thôi. Đúng luật xuyên suốt dự án (`GUIDE.md` mục 3).
##   3. **Master chỉ nhận lệnh do CHÍNH NÓ phát** — `id_nguoi_gui == local_id`. Một client bị
##      sửa có tự phát gói lệnh thì master vẫn bỏ, vì id trong gói không phải id của master.
##
## Tầng 2 và 3 mới là xác thực thật; tầng 1 chỉ để người chơi biết vì sao lệnh không chạy.
##
## > ⚠️ **Không chống được chính chủ phòng.** Master là một người chơi bình thường được giao
## > thêm việc (`GUIDE.md` mục 15). Lớp này chặn người KHÁC, không chặn chủ phòng tự lạm quyền.
## > Với bài tập thì chấp nhận được, nhưng phải nói rõ chứ đừng gọi nó là chống gian lận.

## Ký tự mở đầu một dòng lệnh. Dòng không bắt đầu bằng nó là chat bình thường.
const DAU := "/"

## Tên lệnh -> câu mô tả một dòng, dùng cho `/help`.
const LENH := {
	"mg": "/mg <mã>  —  chạy minigame. Gõ /mg không kèm gì để xem danh sách",
	"help": "/help  —  xem danh sách lệnh",
}

## Người không phải chủ phòng gõ lệnh thì thấy câu này.
const KHONG_PHAI_CHU := "Chỉ chủ phòng mới chạy được lệnh."


## Dòng này có phải lệnh không. Chỉ `/` ở ĐẦU dòng mới tính — "10/10 máu" vẫn là chat thường.
static func la_lenh(dong: String) -> bool:
	var s := dong.strip_edges()
	# `/` trơ trọi không phải lệnh: người chơi gõ nhầm thì cứ để nó thành chat.
	return s.length() > 1 and s.begins_with(DAU)


## Bóc `/mg tank` thành `["mg", "tank"]`. Phần tử 0 luôn là tên lệnh, viết thường.
##
## Trả về mảng rỗng nếu không phải lệnh — người gọi khỏi phải kiểm hai lần.
static func tach(dong: String) -> PackedStringArray:
	if not la_lenh(dong):
		return PackedStringArray()
	var ra := PackedStringArray()
	for m in dong.strip_edges().substr(DAU.length()).split(" ", false):
		ra.append(str(m).strip_edges())
	if ra.size() > 0:
		ra[0] = ra[0].to_lower()
	return ra


static func co_lenh(ten: String) -> bool:
	return LENH.has(ten.to_lower())


## Tầng 3 của lớp xác thực: máy này có được thi hành lệnh do `id_nguoi_gui` phát không.
##
## Đúng khi VÀ CHỈ KHI máy này đang là master **và** lệnh do chính nó phát. Hai vế, không phải
## một: thiếu vế đầu thì mọi máy cùng chạy một lệnh; thiếu vế sau thì ai phát master cũng nghe.
static func duoc_thi_hanh(id_nguoi_gui: int, id_may_nay: int, may_nay_la_master: bool) -> bool:
	return may_nay_la_master and id_nguoi_gui == id_may_nay


## Danh sách lệnh cho `/help`.
static func bang_tro_giup() -> String:
	var dong := PackedStringArray(["Lệnh (chỉ chủ phòng):"])
	for t in LENH:
		dong.append("  " + str(LENH[t]))
	return "\n".join(dong)
