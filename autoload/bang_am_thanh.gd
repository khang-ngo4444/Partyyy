class_name BangAmThanh
extends RefCounted

## Luật chọn âm thanh (thuần, không đụng node): lúc nào phát bản nào, file nằm đâu.
## Cách thay file: xem `asset/audio/README.md`.

const THU_MUC_NHAC := "res://asset/audio/nhac"
const THU_MUC_SFX := "res://asset/audio/sfx"
const DUOI_FILE: Array[String] = ["ogg", "mp3", "wav"]

## Thư mục nhạc của menu chính và bàn cờ chính; minigame dùng mã trò (tên file scene).
const MA_MENU := "menu"
const MA_BAN_CO := "ban_co"

const PHA_DEM_NGUOC := "dem_nguoc"
const PHA_CHOI := "choi"
const PHA_KET_QUA := "ket_qua"

const SFX_BAM_NUT := &"bam_nut"
const SFX_CHUYEN_CANH := &"chuyen_canh"
const SFX_XUC_XAC := &"xuc_xac"
const SFX_BUOC_CHAN := &"buoc_chan"
const SFX_LUOT_MOI := &"luot_moi"
const SFX_NHAN_TIEN := &"nhan_tien"
const SFX_MAT_MAU := &"mat_mau"
const SFX_NHAN_CUP := &"nhan_cup"
const SFX_DUNG_DO := &"dung_do"
const SFX_THANG_VAN := &"thang_van"
const SFX_DEM_NGUOC := &"dem_nguoc"
const SFX_BAT_DAU := &"bat_dau"
const SFX_THANG := &"thang"
const SFX_THUA := &"thua"
const SFX_DANH := &"danh"
const SFX_CHUONG := &"chuong"
const SFX_LOAI := &"loai"
const SFX_BAN := &"ban"
const SFX_NO := &"no"
const SFX_VO := &"vo"
const SFX_CHUYEN_BOM := &"chuyen_bom"
const SFX_DOI_MIEN := &"doi_mien"
const SFX_GO_CHU := &"go_chu"
const SFX_TRA_LOI := &"tra_loi"
const SFX_VE_DICH := &"ve_dich"
const SFX_PHUN := &"phun"
const SFX_LASER := &"laser"
const SFX_SONG := &"song"
const SFX_SON := &"son"

const TAT_CA_SFX: Array[StringName] = [
	SFX_BAM_NUT, SFX_CHUYEN_CANH, SFX_XUC_XAC, SFX_BUOC_CHAN, SFX_LUOT_MOI, SFX_NHAN_TIEN, SFX_MAT_MAU, SFX_NHAN_CUP, SFX_DUNG_DO,
	SFX_THANG_VAN, SFX_DEM_NGUOC, SFX_BAT_DAU, SFX_THANG, SFX_THUA, SFX_DANH, SFX_CHUONG, SFX_LOAI,
	SFX_BAN, SFX_NO, SFX_VO, SFX_CHUYEN_BOM, SFX_DOI_MIEN, SFX_GO_CHU, SFX_TRA_LOI, SFX_VE_DICH,
	SFX_PHUN, SFX_LASER, SFX_SONG, SFX_SON,
]


## "mã/pha" của bản cần phát; "" = không phát (phòng chờ nghe máy nhạc của sảnh).
## Minigame phủ lên bàn nên được ưu tiên.
static func khoa_nhac(menu_dang_mo: bool, ban_dang_chay: bool, ma_minigame: String, pha_minigame: String) -> String:
	if not ma_minigame.is_empty() and not pha_minigame.is_empty():
		return "%s/%s" % [ma_minigame, pha_minigame]
	if ban_dang_chay:
		return "%s/%s" % [MA_BAN_CO, PHA_CHOI]
	return "%s/%s" % [MA_MENU, PHA_CHOI] if menu_dang_mo else ""


## Bảng kết quả là câu nhạc ngắn, phát một lần.
static func co_lap(khoa: String) -> bool:
	return not khoa.ends_with("/" + PHA_KET_QUA)


## Đường dẫn thử lần lượt: đúng pha trước, rồi tới bản chơi của cùng bộ.
static func ung_vien_nhac(khoa: String) -> PackedStringArray:
	var ra := _cac_duoi("%s/%s" % [THU_MUC_NHAC, khoa])
	var ma := khoa.get_slice("/", 0)
	if khoa != "%s/%s" % [ma, PHA_CHOI]:
		ra.append_array(_cac_duoi("%s/%s/%s" % [THU_MUC_NHAC, ma, PHA_CHOI]))
	return ra


static func ung_vien_sfx(ten: StringName) -> PackedStringArray:
	return _cac_duoi("%s/%s" % [THU_MUC_SFX, ten])


## Đường dẫn đầu tiên có thật; "" nếu không có file nào.
static func tim_file(ung_vien: PackedStringArray) -> String:
	for duong_dan: String in ung_vien:
		if ResourceLoader.exists(duong_dan):
			return duong_dan
	return ""


## SFX ứng với thay đổi trạng thái bàn (mọi máy nhận cùng gói nên kêu giống nhau).
static func su_kien_ban(cu: Dictionary, moi: Dictionary) -> Array[StringName]:
	var ra: Array[StringName] = []
	if cu.is_empty():
		return ra
	if int(cu.get("luot", 0)) != int(moi.get("luot", 0)):
		ra.append(SFX_LUOT_MOI)
	if _co_nguoi_doi(cu, moi, "tien", 1):
		ra.append(SFX_NHAN_TIEN)
	if _co_nguoi_doi(cu, moi, "coc", 1):
		ra.append(SFX_NHAN_CUP)
	if _co_nguoi_doi(cu, moi, "mau", -1):
		ra.append(SFX_MAT_MAU)
	return ra


static func _cac_duoi(goc: String) -> PackedStringArray:
	var ra := PackedStringArray()
	for duoi: String in DUOI_FILE:
		ra.append("%s.%s" % [goc, duoi])
	return ra


## Có ai trong bảng `khoa` tăng (`chieu` = 1) hoặc giảm (`chieu` = -1) không.
static func _co_nguoi_doi(cu: Dictionary, moi: Dictionary, khoa: String, chieu: int) -> bool:
	var bang_cu: Dictionary = cu.get(khoa, {})
	var bang_moi: Dictionary = moi.get(khoa, {})
	for nguoi: Variant in bang_moi:
		if not bang_cu.has(nguoi):
			continue
		if (float(bang_moi[nguoi]) - float(bang_cu[nguoi])) * chieu > 0.0:
			return true
	return false
