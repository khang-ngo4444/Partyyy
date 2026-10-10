class_name ChuBay
extends Label3D

## Chữ nổi bay lên rồi mờ dần trong giây cuối, tự xoá (báo ghi điểm, thắng).


func bay(noi_dung: String, cao: float, giay: float) -> void:
	text = noi_dung
	var tre := maxf(giay - 1.0, 0.0)
	var tw := create_tween()
	tw.tween_property(self, "position:y", position.y + cao, giay)
	tw.parallel().tween_property(self, "modulate:a", 0.0, giay - tre).set_delay(tre)
	tw.tween_callback(queue_free)
