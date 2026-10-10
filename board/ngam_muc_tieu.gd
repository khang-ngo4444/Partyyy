class_name NgamMucTieu
extends RefCounted

## Raycast của master: từ gốc + hướng camera của người dùng, ai bị trúng.

## Nửa góc nón (Vợt bắt cá), độ.
const NUA_GOC_NON := 25.0
## Tầm "không giới hạn" (Kính lúp).
const TAM_VO_HAN := 400.0
## Tia dài thêm chừng này vì camera đứng sau người chơi.
const DU_CAMERA := 25.0
const CAO_NGUC := 1.0


static func tam_met(tam_o: int) -> float:
	return TAM_VO_HAN if tam_o <= 0 else tam_o * VatPham.MET_MOI_O


## Người đầu tiên tia chạm, trong tầm; tường chắn thì trượt.
static func tia(nguoi: Player, goc: Vector3, huong: Vector3, tam_o: int) -> Player:
	var tam := tam_met(tam_o)
	var trung := _ray(nguoi, goc, goc + huong * (tam + DU_CAMERA))
	var p := trung.get("collider") as Player
	if p == null or p == nguoi or p.global_position.distance_to(nguoi.global_position) > tam:
		return null
	return p


## Người trong nón, trong tầm, không bị che; lấy người gần tâm nón nhất.
static func non(nguoi: Player, goc: Vector3, huong: Vector3, tam_o: int) -> Player:
	var tam := tam_met(tam_o)
	var tot: Player = null
	var goc_tot := NUA_GOC_NON
	for p: Player in nguoi.get_tree().get_nodes_in_group("players"):
		if p == nguoi or p.global_position.distance_to(nguoi.global_position) > tam:
			continue
		var dich := p.global_position + Vector3.UP * CAO_NGUC
		var lech := rad_to_deg(huong.angle_to(dich - goc))
		if lech > goc_tot:
			continue
		if _ray(nguoi, goc, dich).get("collider") != p:
			continue
		goc_tot = lech
		tot = p
	return tot


static func _ray(nguoi: Player, tu: Vector3, toi: Vector3) -> Dictionary:
	var q := PhysicsRayQueryParameters3D.create(tu, toi, Pickable.LOP_THE_GIOI | Player.LOP_NGUOI)
	q.exclude = [nguoi.get_rid()]
	return nguoi.get_world_3d().direct_space_state.intersect_ray(q)
