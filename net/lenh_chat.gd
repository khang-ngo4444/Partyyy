class_name LenhChat
extends RefCounted

## Lệnh chat (`/mg tank`...): tách lệnh và kiểm quyền (hàm thuần). Thi hành ở `main.gd`.
## Chỉ chủ phòng chạy được: máy gõ tự kiểm, lệnh RPC tới mọi máy, master chỉ nhận lệnh do
## chính nó phát. Không chống được chính chủ phòng.

const DAU := "/"

## Tên lệnh -> mô tả (cho `/help`).
const LENH := {
	"mg": "/mg <mã>  —  chạy minigame. Gõ /mg không kèm gì để xem danh sách",
	"help": "/help  —  xem danh sách lệnh",
}

const KHONG_PHAI_CHU := "Chỉ chủ phòng mới chạy được lệnh."


## Chỉ `/` ở đầu dòng mới là lệnh.
static func la_lenh(dong: String) -> bool:
	var s := dong.strip_edges()
	# `/` trơ trọi là chat.
	return s.length() > 1 and s.begins_with(DAU)


## `/mg tank` → ["mg", "tank"]; không phải lệnh → mảng rỗng.
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


## Đúng khi máy này là master VÀ lệnh do chính nó phát.
static func duoc_thi_hanh(id_nguoi_gui: int, id_may_nay: int, may_nay_la_master: bool) -> bool:
	return may_nay_la_master and id_nguoi_gui == id_may_nay


static func bang_tro_giup() -> String:
	var dong := PackedStringArray(["Lệnh (chỉ chủ phòng):"])
	for t in LENH:
		dong.append("  " + str(LENH[t]))
	return "\n".join(dong)
