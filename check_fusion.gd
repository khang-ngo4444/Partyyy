extends SceneTree

## Kiểm GDExtension Fusion đã nạp: godot --headless --path . --script res://check_fusion.gd

const REQUIRED_CLASSES := [
	"FusionSharedReplicator", "FusionServerReplicator", "FusionSpawner",
	"FusionRoomOptions", "FusionInterestArea", "FusionReplicationConfig",
]


func _init() -> void:
	var ok := true

	if not Engine.has_singleton("Fusion"):
		printerr("FAIL: singleton 'Fusion' không tồn tại — GDExtension chưa nạp.")
		quit(1)
		return
	print("OK  singleton 'Fusion'")

	for c in REQUIRED_CLASSES:
		if ClassDB.class_exists(c):
			print("OK  class %s" % c)
		else:
			printerr("FAIL: thiếu class %s" % c)
			ok = false

	var f := Engine.get_singleton("Fusion")
	print("    region mặc định : %s" % f.call("get_default_region"))
	print("    app_id đã cấu hình: '%s'" % f.call("get_configured_app_id"))
	if String(f.call("get_configured_app_id")).is_empty():
		print("    ^ trống — điền Project Settings > fusion/connection/app_id trước khi test kết nối")

	print("\n%s" % ("PASS" if ok else "FAIL"))
	quit(0 if ok else 1)
