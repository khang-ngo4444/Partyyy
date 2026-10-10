class_name DanhMucVatPham
extends Resource

## Danh mục hình vật phẩm (`danh_muc_vat_pham.tres`), gắn qua Inspector.

@export var ds: Array[VatPhamHinh] = []


func tim(id: String) -> VatPhamHinh:
	for h in ds:
		if h != null and h.id == id:
			return h
	return null
