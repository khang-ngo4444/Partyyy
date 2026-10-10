class_name VatPhamHinh
extends Resource

## Model 3D, icon và hiệu ứng thế giới (scene trong `board/hieu_ung/`) của một vật phẩm.

@export var id := ""
@export var mo_hinh: PackedScene = null
@export var icon: Texture2D = null

## Scene `HieuUng` mọi máy dựng khi món được dùng; null = món không có hiệu ứng riêng
## (Rào tre, Vỏ sầu riêng, Dây thun đã có hình đặt trên ô).
@export var hieu_ung: PackedScene = null
