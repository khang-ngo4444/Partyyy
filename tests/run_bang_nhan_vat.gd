extends SceneTree

## Tên nhân vật dài không được đẩy rộng bảng; xem trước nhân vật phải khử răng cưa.

const SO_KHUNG_CHO_BO_CUC := 3
const SAI_SO_BE_RONG := 0.5
const KICH_THUOC_MAN := Vector2i(1920, 1080)

var failures := 0


func _initialize() -> void:
	_run.call_deferred()


func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)


func _run() -> void:
	root.size = KICH_THUOC_MAN
	var bang: Control = load("res://ui/character_creator.tscn").instantiate()
	root.add_child(bang)
	bang.open()
	await _cho_bo_cuc()
	var san: Control = bang.get_node("Margin/Columns/Stage")
	var tuy_chon: Control = bang.get_node("Margin/Columns/Options")
	var rong_san := san.size.x
	var nhan: Label = bang.archetype_name
	for i in bang.models.size():
		bang._select_model(i)
		await _cho_bo_cuc()
		var ten := nhan.text
		check(absf(san.size.x - rong_san) <= SAI_SO_BE_RONG, "%s keeps the stage width" % ten)
		check(tuy_chon.get_global_rect().end.x <= root.size.x + SAI_SO_BE_RONG, "%s keeps options on screen" % ten)
		var font := nhan.get_theme_font("font")
		var co := nhan.get_theme_font_size("font_size")
		var rong_chu := font.get_string_size(ten, HORIZONTAL_ALIGNMENT_LEFT, -1, co).x
		check(rong_chu <= nhan.size.x + SAI_SO_BE_RONG, "%s fits its label" % ten)
	var xem_truoc: SubViewport = bang.get_node("Margin/Columns/Stage/VBox/ViewportContainer/PreviewViewport")
	check(xem_truoc.msaa_3d == Viewport.MSAA_8X and xem_truoc.scaling_3d_scale > 1.0, "Preview is supersampled")
	print("BANG NHAN VAT: %d failures" % failures)
	quit(failures)


func _cho_bo_cuc() -> void:
	for _khung in SO_KHUNG_CHO_BO_CUC:
		await process_frame
