class_name NhanCamera
extends RefCounted

## Nội dung thẻ camera ở bàn party: chế độ, đang xem ai, tới lượt ai.

const MAU_TU_DO := UIKit.TROI
const MAU_THEO_LUOT := UIKit.LA
const MAU_THEO_NGUOI := UIKit.HONG
const MAU_NGAM_DO := UIKit.CAM


static func tu_do(ten_luot: String) -> Dictionary:
	return _tao("CAM TỰ DO", _dong_luot(ten_luot), MAU_TU_DO)


static func theo_luot(ten_xem: String) -> Dictionary:
	return _tao("THEO LƯỢT", "Đang xem %s" % ten_xem, MAU_THEO_LUOT)


static func theo_nguoi(ten_xem: String, ten_luot: String) -> Dictionary:
	return _tao("THEO · %s" % ten_xem, _dong_luot(ten_luot), MAU_THEO_NGUOI)


static func ngam_do() -> Dictionary:
	return _tao("NGẮM ĐỒ", "Đang dùng camera của bạn", MAU_NGAM_DO)


static func _dong_luot(ten_luot: String) -> String:
	return "Chưa tới lượt ai" if ten_luot.is_empty() else "Lượt của %s" % ten_luot


static func _tao(tieu_de: String, chi_tiet: String, mau: Color) -> Dictionary:
	return {"tieu_de": tieu_de, "chi_tiet": chi_tiet, "mau": mau}
