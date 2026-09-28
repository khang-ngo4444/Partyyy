class_name DaLan
extends Area3D

## MỘT tảng đá đang lăn ngược làn về phía người chơi.
##
## Hình cầu và hộp va chạm nằm trong `da_lan.tscn` và bằng nhau. Script chỉ lo **lăn và tự tan**.
##
## Lăn thẳng đều theo `+Z` nên mọi máy tính ra cùng một đường đi từ cùng một gói dữ liệu
## `(lúc sinh, chỗ sinh)` — mà gói đó thì không ai phải gửi, nó suy ra từ hạt giống.

## Lăn nhanh cỡ nào, m/s. Người chơi chạy ~6 m/s ngược chiều, nên tốc độ gặp nhau là ~20 m/s.
const TOC_DO := 14.0
## Sống bao lâu rồi tan. Đủ để lăn hết tầm nhìn rồi ra sau lưng người chơi.
const SONG := 14.0

var _con := SONG


func lan(tu: Vector3) -> void:
	global_position = tu


func _physics_process(delta: float) -> void:
	global_position.z += TOC_DO * delta
	# Lăn thật: quay quanh trục X theo quãng đường, không phải hiệu ứng trang trí — đá trượt
	# mà không quay thì mắt đọc ngay ra là một quả cầu bị kéo đi.
	($Mat as Node3D).rotate_x(TOC_DO * delta / 1.3)
	_con -= delta
	if _con <= 0.0:
		queue_free()
