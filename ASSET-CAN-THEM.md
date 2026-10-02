# Asset còn thiếu, theo từng node

Ghi lại thứ nào đang là **hình tạm dựng bằng code** (`BoxMesh`, `CylinderMesh`, `ArrayMesh`,
`draw_rect`) và thứ nào đã dùng asset thật. Không có bảng này thì phải đọc lại toàn bộ code
mới biết cái nào đã xong, cái nào đang chờ.

Khi có asset thật: gắn vào **`.tscn`**, không gắn trong `.gd`.

| Trạng thái | Nghĩa |
|---|---|
| ✅ | Đã có asset thật |
| 🟡 | Hình tạm, **cố ý giữ** — không cần asset |
| 🔴 | Hình tạm, **cần asset thật** |

---

## minigame/tank — `tank_battle.tscn`

| Node | Hiện tại | Cần |
|---|---|---|
| `BanDo/Tuong/T_*` — `o_tuong.tscn` | 🟡 `ColorRect` 32×32, hai màu gạch/thép | Sprite gạch + sprite thép. Đổi trong `o_tuong.tscn` là **cả 136 ô đổi theo** |
| `XeTang` — `xe_tang.tscn` | 🟡 `ColorRect` thân + nòng | MỘT sprite xe tăng nhìn từ trên xuống, chĩa về +x. Node tự xoay theo hướng nên không cần 4 hình |
| `Dan` — `dan.tscn` | 🟡 `ColorRect` 8×8 vàng | **Không cần.** Chấm nhỏ đủ đọc, sprite đạn ở cỡ này không khác gì |
| `BanDo/Nen`, `BanDo/Vien` | 🟡 `ColorRect` | **Không cần.** Nền tối + viền thép, có texture cũng không đọc nhanh hơn |
| Âm thanh | 🔴 chưa có | Tiếng bắn, tiếng nổ, tiếng vỡ gạch. `asset/kenney_impact-sounds/` đã có sẵn trong repo. |
| Xe chết | 🔴 chỉ `hide()` | Xác xe cháy nằm lại trên bản đồ — biết chỗ vừa có người chết là biết chỗ nguy hiểm |

Màu xe **lấy từ màu nhân vật** (`NetManager.color_for`) — không có bảng màu riêng.

> **Đã sửa:** trước đây cả đấu trường vẽ bằng `draw_rect` trong `tank_battle.gd`, và tường
> rải ngẫu nhiên theo hạt giống. Giờ tường là instance `o_tuong.tscn` nằm sẵn trong
> `ban_do_tank.tscn` — **kéo được trong editor** — trên một bản đồ dựng tay, đối xứng bốn
> phía, 10 chỗ sinh đặt bằng `Marker2D`. Hạt giống chỉ còn dùng để xoay thứ tự chỗ sinh.

## lobby — thứ đang là hình tạm

| Node | Hiện tại | Cần |
|---|---|---|
| `ClockTower/*` | 🔴 `BoxMesh` xếp chồng | Model tháp đồng hồ |
| `WallStation/Panel` + `Trim` | 🔴 `BoxMesh` | Bảng gắn tường |
| `ChessBoard` (ô, đường kẻ, cung) | 🔴 dựng trong `chess_board.gd` | Mặt bàn có texture |
| `Pressable` (mọi nút) | 🟡 `CylinderMesh` | Nút phát sáng đủ đọc rồi, không gấp |
| `SpeechBubble` | 🟡 `ArrayMesh` + `QuadMesh` | Cố ý: hình phải co theo độ dài chữ, asset cố định không làm được |
| Quân cờ | ✅ `asset/chess_set/` | — |
| Nhân vật | ✅ Kenney mini + KayKit | — |
| Bàn bài, ghế, cây, sofa | ✅ Kenney / Quaternius | — |

## Đang thiếu hẳn, chưa có node

- **Animation cho 10 model KayKit** — chúng đứng im hoàn toàn. File có sẵn ở
  `asset/KayKit_*/Animations/gltf/Rig_Medium/`, tên khác hệ tên code đang dùng
  (`Idle_A` vs `idle`), cần bảng ánh xạ.
- **Nhạc nền phòng chờ** — máy nhạc phát file người chơi tự trỏ, chưa có nhạc mặc định.
- **Icon / ảnh bìa** cho bản build.

---

# VẬT THỂ SINH BẰNG CODE — danh sách đầy đủ và lý do

**Quy ước:** vật thể dựng trong `.tscn`, kéo vào node có sẵn. Code **chỉ lo logic**. Thứ nào
bắt buộc phải `Node3D.new()` / `MeshInstance3D.new()` lúc chạy thì phải có tên trong bảng này
kèm lý do. Không có lý do thì phải chuyển về `.tscn`.

Lý do hợp lệ chỉ có hai: **hình dạng phụ thuộc trạng thái lúc chạy**, hoặc **là scene có sẵn
được `instantiate()`** — cái sau không tính là dựng bằng code.

| Nơi | Sinh cái gì | Lý do | Trạng thái |
|---|---|---|---|
| `board/pha_ban_co.gd` → `_bao_dam_co_ban()` | `ban_party.tscn` | **`instantiate()` một scene có sẵn**, không dựng hình. Phải làm lúc chạy vì bàn chỉ tồn tại trong pha party và nằm ở `y = 100` | ✅ |
| `board/pha_ban_co.gd` → vụ nổ bom | **không sinh gì** | Vụ nổ là trạng thái thuần: trừ máu rồi phát gói | 🟡 Cần hiệu ứng thấy được — xem bảng dưới |
| `board/o_ban.gd` | **không sinh gì** | Chỉ gán `material_override` và `Label3D.text` theo `loai`. Tám vật liệu là `.tres` kéo vào scene | ✅ |
| `board/ban_duong.gd` | **không sinh gì** | Chỉ đọc các node `OBan` con rồi sắp theo `so`. `dat_loai()` đổi loại ô lúc chạy (rương di chuyển) bằng cách gán `OBan.loai` — setter tự đổi vật liệu, không dựng lại node nào | ✅ |
| `minigame/tank/ban_do_tank.gd` | **không sinh gì** | Chỉ đọc các node `OTuong` + `Marker2D` con vào một lưới | ✅ |
| `minigame/tank/tank_battle.gd` → `bat_dau()` | `xe_tang.tscn` | **`instantiate()` scene có sẵn.** Số xe bằng số người trong phòng, chỉ biết lúc chạy | ✅ |
| `minigame/tank/tank_battle.gd` → `_net_ban()` | `dan.tscn` | **`instantiate()` scene có sẵn.** Đạn sinh ra khi có người bóp cò | ✅ |

> **Đã sửa:** `ban_duong.gd` trước đây dựng 24 ô bằng code (`Node3D.new()`, `BoxMesh`,
> `StandardMaterial3D`, `StaticBody3D`, `Label3D` — khoảng 6 node mỗi ô). Giờ 24 ô là instance
> của `o_ban.tscn` đặt sẵn trong `ban_party.tscn`, **kéo được trong editor**. Vị trí được tính
> một lần bằng công cụ rồi nướng vào scene; các node mốc `Moc*` cũ đã bỏ vì không còn ai đọc.

## Cấu trúc scene — mỗi scene một việc

| Scene | Việc duy nhất của nó |
|---|---|
| `board/o_ban.tscn` | MỘT ô: mặt, va chạm, nhãn. Đổi hình dáng ô thì sửa đúng đây, 24 ô đổi theo |
| `board/ban_party.tscn` | Bản đồ: 24 ô đặt thành vòng, mỗi ô mang `so` + `loai` |
| `minigame/tank/o_tuong.tscn` | MỘT ô tường: hình + màu theo `loai` (gạch / thép) |
| `minigame/tank/xe_tang.tscn` | MỘT chiếc xe: thân, nòng, viền — và tự lái, tự đụng tường |
| `minigame/tank/dan.tscn` | MỘT viên đạn: hình + tự bay |
| `minigame/tank/ban_do_tank.tscn` | Đấu trường: 136 ô tường + 10 `Marker2D` chỗ sinh |
| `minigame/tank/tank_battle.tscn` | Ghép bản đồ + lớp xe + lớp đạn + đồng hồ |
| `ui/bang_ban.tscn` | Bảng trạng thái bàn ở góc phải màn hình |
| `ui/bang_thang.tscn` | Bảng THẮNG cuối ván: ai thắng, mấy cốc. Chỉ hiện chữ |
| `main.tscn` | Scene tổng, ghép mọi thứ lại |

Đổi bản đồ = làm một `.tscn` khác rồi trỏ `PhaBanCo.ban_scene` sang nó. Không sửa code. Bản đồ
Tank cũng vậy: thay node `BanDo` trong `tank_battle.tscn` bằng scene khác, `rong`/`cao` đặt
trong Inspector.

## Tách logic

| File | Chứa gì | Không chứa gì |
|---|---|---|
| `board/luat_ban.gd` | Luật chơi: máu, chìa, cốc, tầm nổ, cửa hàng. **Hàm thuần** | Node, Fusion, autoload |
| `board/pha_ban_co.gd` | Mạng + vòng lượt + cây scene | Luật chơi |
| `board/ban_duong.gd` | Hỏi đáp về bàn: ô số mấy loại gì, ở đâu, đi 5 bước tới đâu | Dựng hình |
| `ui/bang_ban.gd` | Đổ chữ ra bảng | Trạng thái riêng, đọc thẳng vào `PhaBanCo` |
| `player/camera_rig.gd` | Góc nhìn: đứng / ngồi ghế / bàn party | Biết mình đang ở pha nào — ai cần thì tự gọi |

`LuatBan` không đụng autoload nên kiểm được bằng `godot --headless --script` — `--script`
KHÔNG nạp autoload, file nào chạm `NetManager` là không biên dịch nổi.

## Bàn party — asset còn thiếu, theo từng node

| Node | Hiện tại | Cần |
|---|---|---|
| `O_*` (mặt ô, 8 loại) | 🔴 `BoxMesh` phẳng + `Label3D` chữ THƯỜNG | Model ô thật: Trống, Chìa, Sát thương, Bí ẩn, Rương, Nghĩa địa, Cửa hàng, Nguy hiểm. Biểu tượng nổi trên mặt ô thay cho chữ |
| Rương + cốc | 🔴 chỉ là ô vàng | Model rương mở được + model cốc. Cốc là thứ để THẮNG nên phải nhìn ra ngay |
| Vụ nổ bom | 🔴 chưa có gì, chỉ có dòng chữ trên HUD | Hiệu ứng nổ trên các ô trúng: `GPUParticles3D` đặt sẵn trong `ban_party.tscn` rồi bật theo ô, **không sinh bằng code**. Âm thanh có sẵn ở `asset/kenney_impact-sounds/` |
| Thanh máu trên đầu nhân vật | 🔴 chưa có, máu chỉ hiện ở bảng góc phải | Bảng máu 3D gắn vào nhân vật — nhìn bàn là biết ai sắp chết, không phải đọc bảng |
| Biểu tượng vật phẩm | 🔴 hiện là chữ "Bom / Khiên / Bom lớn" | 3 icon 2D cho HUD |
| Nghĩa địa | 🔴 chỉ là ô xám | Bia mộ — `asset/kenney_graveyard-kit/` **đã có sẵn** nhưng đang bị loại khỏi build |
| Xúc xắc bàn cờ | 🔴 chưa dựng | Có thể dùng lại `lobby/objects/die.tscn` |
| `BangBan` (bảng góc phải) | ✅ đã nằm trong `ui/hud.tscn` | — |
| `BangThang` (bảng thắng cuối ván) | 🟡 chữ trên nền mờ | Không cần asset. Có nhạc thắng thì hay — `asset/kenney_interface-sounds/` |

> `kenney_graveyard-kit` đang nằm trong `exclude_filter` của `export_presets.cfg`. Dùng tới nó
> thì **phải gỡ khỏi danh sách loại trừ**, không thì editor chạy ngon mà bản build thiếu model.

> **Đã xoá:** `board/demo_map.tscn` — bản đồ thử đời đầu, dùng `so_o` / `loai_dat_rieng` / các
> node `Moc*` mà `BanDuong` đã bỏ từ lâu, và không file nào trỏ tới. Bảng loại ô của nó đã nằm
> sẵn trong `ban_party.tscn`. Cần bản đồ thứ hai thì nhân bản `ban_party.tscn` rồi kéo lại ô.

## Minigame sắp làm — ghi trước để khỏi quên

| Node | Cần |
|---|---|
| 12 avatar 2D của nhân vật | 🔴 Chụp sẵn 12 ảnh PNG từ 12 model bằng `SubViewport`, **chụp một lần rồi lưu file**, không render lúc chạy. Dùng cho trò nhịp và bóng chày, lấy theo `model_index` |
| Nhạc + bản đồ nốt cho Rockin Rhythm | 🔴 Đúng MỘT bài. Đây là thứ tốn thời gian nhất của trò đó — code thì rẻ, nội dung thì không |
| Con thú cho trò Đếm thú | 🔴 3 loại thú chạy lẫn nhau. Quaternius có animal pack |

## Minigame pha 3 — khuôn T2 (Breaking Blocks · Laser Leap · Searing Spotlights)

**Không vật thể nào sinh bằng code.** Sàn, ô sàn, thanh tia, đèn rọi, vùng va chạm, camera —
tất cả là node đặt sẵn trong `.tscn`; script chỉ bật/tắt, đổi vật liệu, đổi `position`/`rotation`.

> **Hộp va chạm PHẢI là node nhìn thấy được.** Bản đầu tự tính hình học trong code: tia nhìn
> rộng 0,70 m nhưng giết ở 0,55 m, vùng đèn nhìn bán kính 3,90 m nhưng trừ máu ở 3,40 m —
> người chơi đứng rõ ràng trong tia/trong sáng mà không hề gì. Hai con số chép tay ở hai nơi
> thì sớm muộn cũng lệch. Giờ dùng `Area3D` + `CollisionShape3D` lấy đúng kích thước của mesh,
> và có assert bắt chúng phải bằng nhau.

| Node | Hiện tại | Cần |
|---|---|---|
| `o_san.tscn` → `Mat` | 🟡 `BoxMesh` 1,6 m + vật liệu phát sáng | Cố ý: ô phải đọc được trạng thái trong một cái liếc (trắng / cam / mất) |
| `san_tron.tscn` → `Mat` | 🟡 `CylinderMesh` bán kính 11,5 m | Như trên |
| `san_laser.tscn` → `Tia*/Mat` | 🔴 `BoxMesh` màu cam | Hiệu ứng tia thật (`GPUParticles3D` hoặc vật liệu phát sáng có chuyển động) |
| `san_laser.tscn` → `Tia*/Vung` | ✅ `Area3D` + `BoxShape3D` đúng bằng mesh | — |
| `san_spot.tscn` → `Den*/Bong` | ✅ `SpotLight3D` thật | — |
| `san_spot.tscn` → `Den*/Tia` | 🟡 nón `mesh_tia_den.tres` + `mat_tia_den.tres` (cộng sáng, trong suốt) | Chùm sáng thật: volumetric fog hoặc `GPUParticles3D` bụi trong tia |
| `san_spot.tscn` → `Den*/Vung` | ✅ `Area3D` + `CylinderShape3D` khớp vệt sáng của nón đèn | — |
| `VienSan` (mốc định hướng) | 🟡 `TorusMesh` phát sáng yếu | Cố ý: là NÚM CHỈNH độ khó, càng mờ trò càng căng |
| UI cho Breaking Blocks / Laser Leap | 🔴 chưa có | `GUIDE_PARTYGAME.md` ghi cả hai cần `CanvasLayer (UI)`. Spotlights đã có thanh máu |
| Âm thanh (ô tan, tia quét, mất máu) | 🔴 chưa có | `asset/kenney_impact-sounds/` và `kenney_interface-sounds/` đã có sẵn trong repo |

### Nhân vật

12 model Kenney Mini **đã bỏ** — khổ vuông, rộng 2,06 m, chiếm quá nhiều diện tích sân.
Còn **10 model KayKit**, mỗi model bóp về đúng **1,30 m** bề ngang (scale nằm trong từng file
`player/characters/*.tscn`, không nằm trong code). Vừa trong ô sàn 1,6 m.

Hệ quả: scale đều nên chiều cao cũng giảm còn 1,45–1,78 m. Bóp riêng trục X thì nhân vật dẹt.

## Minigame pha 3 — khuôn T1 (Magma & Mages · …)

Trò đầu tiên có **nút đòn**. Vẫn không vật thể nào sinh bằng code theo nghĩa dựng hình: quả cầu
lửa là `cau_lua.tscn` đặt sẵn, script chỉ `instantiate()` rồi cho nó bay.

> **Vì sao cầu lửa phải instantiate.** Đây là vật thể *số lượng không biết trước* — mỗi người
> bắn bao nhiêu phát là tuỳ họ. Đặt sẵn N quả trong `.tscn` thì N là con số bịa, và phải viết
> thêm code quản lý hồ bơi để tái dùng. Hình dạng, vật liệu, hộp va chạm, đèn đều nằm trong
> `.tscn`; code không dựng một mesh nào.

| Node | Hiện tại | Cần |
|---|---|---|
| `cau_lua.tscn` → `Mat` | 🟡 `SphereMesh` 0,45 m + vật liệu cam phát sáng | `GPUParticles3D` đuôi lửa — `GUIDE_PARTYGAME.md` có ghi, đang thiếu |
| `cau_lua.tscn` → `Hinh` | ✅ `SphereShape3D` đúng bán kính mesh (có assert) | — |
| `cau_lua.tscn` → `Sang` | ✅ `OmniLight3D` cam | — |
| `san_magma.tscn` → `DungNham` | 🟡 `PlaneMesh` 90 m phát sáng cam, **chỉ để nhìn** | Mặt dung nham có sóng (shader) hoặc `GPUParticles3D` khói |
| Hoạt ảnh bắn của nhân vật | 🔴 chưa có | Model KayKit có `Attack` — cần nối vào `AnimationPlayer` lúc bắn |
| UI cho Magma | 🔴 chưa có | `GUIDE_PARTYGAME.md` ghi cần `CanvasLayer (UI)`. Cùng món nợ với Breaking Blocks / Laser Leap |
| Âm thanh (bắn, trúng, rơi vào dung nham) | 🔴 chưa có | `asset/kenney_impact-sounds/` đã có sẵn |

Dung nham **không phải `StaticBody3D`** như guide ghi: rơi khỏi sàn đã chết sẵn nhờ luật
`ROI_KHOI_SAN` của `MiniGame3D`, thêm thân va chạm chỉ để xác chết nằm trên đó.

### T1 — bốn trò còn lại

(Snowy Spin đã bị xoá khỏi trò, nên hàng `san_tuyet.tscn` cũng đi theo.)

| Node | Hiện tại | Cần |
|---|---|---|
| `bom_chuyen.tscn` → `Mat` | 🟡 `SphereMesh` cam | Quả bom có ngòi cháy |
| `bom_chuyen.tscn` → `Dem` | ✅ `Label3D` đếm ngược trên đầu người ôm | — |
| `vuong_mien.tscn` → `Mat` | 🔴 `TorusMesh` đồng — trông như cái vòng, không ra vương miện | Model vương miện thật. Quaternius/KayKit có |
| Hoạt ảnh "đang ôm bom" / "đang đội miện" | 🔴 chưa có | Model KayKit có sẵn tư thế; cần nối `AnimationPlayer` |
| Hai đòn tay không (F đánh = choáng, G chưởng = hất; `MiniGame3D.co_danh`) — Crown + Word Wars | 🔴 không có hoạt ảnh, không có dấu hiệu choáng — chỉ thấy nạn nhân bị hất/đứng sững | KayKit có `Attack`/`Unarmed_Melee`; nối vào `AnimationPlayer` lúc `_net_danh` + tiếng `asset/kenney_impact-sounds/` |
| UI cho cả 5 trò T1 | 🔴 chưa có | Cùng món nợ `CanvasLayer (UI)` với T2 |

> **Sàn trơn nằm trong `Player`, không nằm trong sân.** `Player.truot` —
> số giây để tăng tốc lên `speed` và cũng là số giây để dừng. `0` = như cũ. Trò nào cần thì
> bật, và `dung_som()` PHẢI tắt lại, không thì người chơi trượt băng giữa phòng chờ.

> **Chỉ hai trò T1 cần trọng tài** — Explosive Exchange (`_ai_om`) và Crown Capture (`_ai_giu`).
> Ba trò kia 0 gói tin ngoài "tôi chết": cầu lửa gửi đúng một gói lúc bắn rồi tự bay, thanh
> xoay và lịch bom đều là hàm thuần của hạt giống + thời gian.

## Minigame pha 3 — khuôn T3 (Temporal Trails · Word Wars — Bounding Blocks đã xoá)



| Node | Hiện tại | Cần |
|---|---|---|
| `vet.tscn` → `Mat` (Temporal Trails, tường xe ánh sáng) | 🟡 `BoxMesh` 0,3 × 1 m phát sáng màu nhân vật (`mat_vet_loi`), hộp va chạm bằng đúng mesh | Shader tường có vân/nhịp chạy dọc; hiệu ứng nổ khi đâm (giờ chỉ biến mất) |
| `o_chu.tscn` → `Mat` + `Chu` (26 ô A–Z trong `san_chu.tscn/Bang`) | 🟡 `BoxMesh` 2,2 m phẳng + `Label3D` nằm trên mặt | Tấm sàn kim loại/đèn viền kiểu ảnh mẫu, chữ phát sáng |
| `o_chu.tscn` → `Vung` | ✅ `Area3D` 2,2 m đúng bằng mặt ô | — |
| `chu_tren_dau.tscn` | 🟡 `Label3D` từ của từng người, gắn lên đầu nhân vật lúc vào ván | Khung/bảng nhỏ sau chữ cho dễ đọc trên nền sáng |
| Hoạt ảnh đấm | 🔴 chưa có | KayKit có `Attack`; cần nối `AnimationPlayer` vào `_dam()` |
| Âm thanh (chiếm ô, chạm tường, đấm trúng/trượt) | 🔴 chưa có | `asset/kenney_impact-sounds/` |
| UI cho cả 3 trò | 🔴 chưa có | Word Wars đang mượn `Bang` trong sân thay `CanvasLayer` |

### Vật thể sinh bằng code ở T3 — và lý do

| Sinh bằng code | Vì sao không đặt sẵn trong `.tscn` |
|---|---|
| `vet.tscn` (Temporal Trails) | Tường mọc theo đường người chơi tự lái — chỉ biết lúc chạy. Sống tới hết ván |

### Lệch guide ở T3 — có lý do

- **Word Wars không dùng `RigidBody3D`.** Vật lý Godot không hứa hẹn cho cùng kết quả trên hai
  máy khác cấu hình. Đây là trò ĐUA ghép cùng một từ: người thấy chữ "H" ngay chân mà người kia
  thấy nó văng ra mép sân là thua vì máy chứ không phải vì tay. Khối rơi thẳng tới chỗ tính sẵn
  từ hạt giống → mọi máy bày ra đúng một bàn cờ, 0 gói tin.
- **Word Wars gửi 1 gói/TỪ ghép xong, không phải 1 gói/cú đấm.** Đấm là chuyện riêng của từng
  máy (khối không bị tiêu thụ, ai đấm cũng được), nên không có gì để kể cho người khác nghe cho
  tới lúc có điểm.
- **Temporal Trails hỏi `intersect_shape()` một lần** thay vì gọi `overlaps_body()` lên từng
  đoạn vệt. Cuối ván có ~250 đoạn; để engine lo phần chia lưới là việc của engine.

## Minigame pha 3 — khuôn T4 (Sidestep Slope · Slippery Sprint — Nhặt quà đã xoá)

Khuôn thứ hai của pha 3, nằm ở `minigame/chung/mini_game_lan.gd`. Khác T1–T3 đúng hai điểm:
**không có camera chung** (mỗi người nhìn làn của mình từ sau lưng, dùng lại `CameraRig` sẵn có
của phòng chờ) và **làn tách rời** cách nhau 40 m.

> **T4 KHÔNG bật `Player.che_do_san`.** Bật là hỏng: WASD sẽ theo trục thế giới trong khi
> camera lại gắn vào thân, mà thân thì tự xoay theo hướng chạy — camera quay vòng mỗi lần né
> sang bên. T4 giữ nguyên điều khiển kiểu phòng chờ.

> **Sàn băng của Slippery Sprint dùng `Player.truot`**, không viết
> thêm gì. Về đích dùng lại nguyên đường ống `xin_chet()` của lớp cha — cùng một sự kiện
> "người chơi rời cuộc tại giây thứ N, do chính máy của họ tuyên", chỉ khác chiều xếp hạng.

| Node | Hiện tại | Cần |
|---|---|---|
| `lan.tscn` → `MatSan` | 🟡 `BoxMesh` 10 × 400 m, vật liệu sáng | Texture đường/tuyết; Sidestep Slope nên có độ dốc thật |
| `lan.tscn` → `MatTuongTrai/Phai` | 🟡 `BoxMesh` 0,6 × 3 × 400 m | Vách đá/lan can — `kenney_nature-kit` (329 model, **không** bị loại khỏi build) |
| `lan.tscn` → `Vach` | 🟡 `BoxMesh` đỏ, ẩn sẵn, chỉ Slippery bật | Cổng đích có cờ |
| `xe_doc.tscn` → `Toa` (Sidestep, xe lao xuống dốc) | 🟡 toa goòng `train-carriage-container-red.glb` (train-kit) ×1,8 + 2 đèn pha phát sáng | **Model ô tô/xe tải thật** — repo chưa có bộ xe nào; vài màu xe khác nhau; tiếng động cơ |
| `xe_doc.tscn` → `Hinh` | ✅ `BoxShape3D` 1,8 × 2,45 × 4,86 m đúng bằng toa | — |
| Cảnh hai bên làn | 🔴 trống trơn | Cây/đá `kenney_nature-kit` — làn 400 m không có gì thì không cảm được tốc độ |
| UI cho cả 3 trò | 🔴 chưa có | Cùng món nợ `CanvasLayer` với T1–T3 |

### Vật thể sinh bằng code ở T4 — và lý do

| Sinh bằng code | Vì sao không đặt sẵn trong `.tscn` |
|---|---|
| `xe_doc.tscn` (Sidestep) | Lịch xe sinh từ hạt giống, số xe trên đường đổi theo giây — `XeDoc.lich` |

### Lệch guide ở T4 — có lý do

- **Đá không phải `RigidBody3D`.** Cùng lý do với khối chữ của Word Wars: vật lý không tất định
  giữa hai máy, mà ở đây nó quyết định ai chết. Đá lăn thẳng đều theo hàm của `(hạt giống,
  gio())` → mọi máy chiếu đúng một cuốn phim, 0 gói tin.
- **Đá sinh theo ĐỒNG HỒ, không theo vị trí người chơi.** Vị trí người chơi trên máy người khác
  luôn trễ vài chục ms; sinh theo nó thì hai máy đặt cùng một tảng đá ở hai chỗ. Điểm sinh bám
  `TOC_CHAY_MAU` nên đá vẫn luôn ló ra trong tầm nhìn.
- **Mọi làn bày đúng MỘT bố cục** (Nhặt quà) và **một đợt đá rải cho mọi làn cùng lúc**
  (Sidestep). Khác bố cục thì người thắng chỉ là người bốc được làn dễ.

## minigame/quan_tro_minigame.tscn — màn hướng dẫn

| Node | Hiện tại | Cần |
|---|---|---|
| `Lop/HuongDan` | 🔴 `ColorRect` nền phẳng + ba `Label` (tên, luật, số đếm) | Nền/khung hướng dẫn thật; mỗi trò một hình minh hoạ phím + cách chơi |


## Ô điểm chung minigame — `minigame/chung/o_diem.tscn`

| Node | Hiện tại | Cần |
|---|---|---|
| `ODiem` (một ô mỗi người, dải `QuanTroMiniGame/Lop/BangDiem` ở đáy màn hình) | 🟡 `PanelContainer` + 2 `Label`, viền dưới màu nhân vật | Avatar nhỏ của nhân vật (xem mục "12 avatar 2D") |
