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
| `bom_axit.tscn` → `Qua` | 🟡 `SphereMesh` cam | Quả bom thật + `GPUParticles3D` đuôi khói |
| `bom_axit.tscn` → `Dau` (vòng đánh dấu) | 🟡 `TorusMesh` đỏ, bán kính đúng bằng vùng nổ | Cố ý — nhưng nên nhấp nháy nhanh dần khi sắp chạm |
| `bom_axit.tscn` → `Quang` + `No` | ✅ quầng nổ và vùng sát thương cùng 3,6 m (có assert) | Thay quầng cầu bằng `GPUParticles3D` |
| `san_axit.tscn` → `BienAxit` | 🟡 `PlaneMesh` 90 m, vật liệu `mat_axit.tres` **mới thêm**, chỉ để nhìn | Shader gợn sóng + bọt |
| `bom_chuyen.tscn` → `Mat` | 🟡 `SphereMesh` cam | Quả bom có ngòi cháy |
| `bom_chuyen.tscn` → `Dem` | ✅ `Label3D` đếm ngược trên đầu người ôm | — |
| `vuong_mien.tscn` → `Mat` | 🔴 `TorusMesh` đồng — trông như cái vòng, không ra vương miện | Model vương miện thật. Quaternius/KayKit có |
| Hoạt ảnh "đang ôm bom" / "đang đội miện" | 🔴 chưa có | Model KayKit có sẵn tư thế; cần nối `AnimationPlayer` |
| UI cho cả 5 trò T1 | 🔴 chưa có | Cùng món nợ `CanvasLayer (UI)` với T2 |

> **Sàn trơn nằm trong `Player`, không nằm trong sân.** `Player.truot` —
> số giây để tăng tốc lên `speed` và cũng là số giây để dừng. `0` = như cũ. Trò nào cần thì
> bật, và `dung_som()` PHẢI tắt lại, không thì người chơi trượt băng giữa phòng chờ.

> **Chỉ hai trò T1 cần trọng tài** — Explosive Exchange (`_ai_om`) và Crown Capture (`_ai_giu`).
> Ba trò kia 0 gói tin ngoài "tôi chết": cầu lửa gửi đúng một gói lúc bắn rồi tự bay, thanh
> xoay và lịch bom đều là hàm thuần của hạt giống + thời gian.

## Minigame pha 3 — khuôn T3 (Bounding Blocks · Temporal Trails · Word Wars)

> **Lưới 13×13 giờ dùng chung.** `san_breaking.tscn` (520 dòng, 169 ô) đã chuyển thành
> `minigame/chung/san_luoi.tscn` và bỏ bản riêng của Breaking Blocks. Hai trò cùng cần đúng
> cái sân đó; giữ hai bản là hai chỗ phải sửa mỗi lần đổi bước lưới.

> **`OSan.son()` là hàm mới, tách khỏi `dat()`.** Breaking Blocks hỏi "ô còn hay tan",
> Bounding Blocks hỏi "ô của ai" — hai câu khác hẳn nhau, nhét chung một hàm thì mỗi bên phải
> truyền một tham số mình không quan tâm.

| Node | Hiện tại | Cần |
|---|---|---|
| `materials/o_nguoi/mat_o_nguoi_0..9.tres` | ✅ **10 file mới**, màu khớp đúng `NetManager.PLAYER_COLORS` | — (sinh sẵn thành file, KHÔNG tạo vật liệu lúc chạy) |
| `san_luoi.tscn` → ô | 🟡 `BoxMesh` 1,6 m | Texture gạch, và hiệu ứng lúc ô đổi chủ |
| `vet.tscn` → `Mat` | 🟡 `BoxMesh` 0,35 × 1,4 m, sơn theo màu chủ | Tường phát sáng kiểu đua xe ánh sáng + mờ dần khi sắp tan |
| `vet.tscn` → `Hinh` | ✅ `BoxShape3D` đúng bằng mesh, cùng vị trí (có assert) | — |
| `khoi_chu.tscn` → `Mat` + `Chu` | 🟡 `BoxMesh` 1,1 m + `Label3D` | Khối gỗ có vân, chữ khắc chìm |
| `khoi_chu.tscn` → `Vung` | ✅ `Area3D` + `BoxShape3D` đúng bằng khối (có assert) | — |
| `san_chu.tscn` → `Bang` | 🟡 `Label3D` treo lơ lửng ở độ cao 7 m | Bảng gỗ/đá thật để chữ có chỗ bám |
| Hoạt ảnh đấm | 🔴 chưa có | KayKit có `Attack`; cần nối `AnimationPlayer` vào `_dam()` |
| Âm thanh (chiếm ô, chạm tường, đấm trúng/trượt) | 🔴 chưa có | `asset/kenney_impact-sounds/` |
| UI cho cả 3 trò | 🔴 chưa có | Word Wars đang mượn `Bang` trong sân thay `CanvasLayer` |

### Vật thể sinh bằng code ở T3 — và lý do

| Sinh bằng code | Vì sao không đặt sẵn trong `.tscn` |
|---|---|
| `vet.tscn` (Temporal Trails) | Số lượng không biết trước và thay đổi từng giây: 4 người × 12 giây tường sống ≈ 250 đoạn cùng lúc, lúc nhiều lúc ít. Hình tường, hộp va chạm, vật liệu đều nằm trong `.tscn`; code chỉ đặt vị trí và kéo dài |
| `khoi_chu.tscn` (Word Wars) | Như trên — mưa chữ 0,45 giây một khối, cả ván ~130 khối |

### Lệch guide ở T3 — có lý do

- **Word Wars không dùng `RigidBody3D`.** Vật lý Godot không hứa hẹn cho cùng kết quả trên hai
  máy khác cấu hình. Đây là trò ĐUA ghép cùng một từ: người thấy chữ "H" ngay chân mà người kia
  thấy nó văng ra mép sân là thua vì máy chứ không phải vì tay. Khối rơi thẳng tới chỗ tính sẵn
  từ hạt giống → mọi máy bày ra đúng một bàn cờ, 0 gói tin.
- **Word Wars gửi 1 gói/TỪ ghép xong, không phải 1 gói/cú đấm.** Đấm là chuyện riêng của từng
  máy (khối không bị tiêu thụ, ai đấm cũng được), nên không có gì để kể cho người khác nghe cho
  tới lúc có điểm.
- **Bounding Blocks quét cả 169 ô mỗi khung hình** thay vì `RayCast3D` bắn xuống. Bố cục lưới
  nằm trong `.tscn`; tính chỉ số ô từ toạ độ là chép cùng một con số ở hai nơi — đúng thứ đã đẻ
  ra lỗi hộp va chạm lệch mesh ở Laser Leap. ~1000 phép so sánh mỗi khung hình là rẻ.
- **Temporal Trails hỏi `intersect_shape()` một lần** thay vì gọi `overlaps_body()` lên từng
  đoạn vệt. Cuối ván có ~250 đoạn; để engine lo phần chia lưới là việc của engine.

## Minigame pha 3 — khuôn T4 (Sidestep Slope · Nhặt quà né rác · Slippery Sprint)

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
| `da_lan.tscn` → `Mat` | 🟡 `SphereMesh` 1,3 m | Tảng đá thật — `kenney_nature-kit` có `rock_*` |
| `da_lan.tscn` → `Hinh` | ✅ `SphereShape3D` đúng bán kính mesh (có assert) | — |
| `vat_pham.tscn` → `QuaNho` / `QuaTo` / `Rac` | 🟡 hai khối hộp + một hình cầu, ba màu | Hộp quà thật + thùng rác — `kenney_furniture-kit`, `polypizza` |
| Cảnh hai bên làn | 🔴 trống trơn | Cây/đá `kenney_nature-kit` — làn 400 m không có gì thì không cảm được tốc độ |
| UI cho cả 3 trò | 🔴 chưa có | Cùng món nợ `CanvasLayer` với T1–T3 |

### Vật thể sinh bằng code ở T4 — và lý do

| Sinh bằng code | Vì sao không đặt sẵn trong `.tscn` |
|---|---|
| `da_lan.tscn` (Sidestep) | Số lượng không biết trước: một đợt mỗi 1,5 → 0,45 giây, nhân số làn đang có người. Hình và hộp va chạm đều trong `.tscn` |
| `vat_pham.tscn` (Nhặt quà) | 64 món × **số làn đang có người**. Bày sẵn đủ 8 làn là 512 `Area3D` cho một ván 4 người |

### Lệch guide ở T4 — có lý do

- **Đá không phải `RigidBody3D`.** Cùng lý do với khối chữ của Word Wars: vật lý không tất định
  giữa hai máy, mà ở đây nó quyết định ai chết. Đá lăn thẳng đều theo hàm của `(hạt giống,
  gio())` → mọi máy chiếu đúng một cuốn phim, 0 gói tin.
- **Đá sinh theo ĐỒNG HỒ, không theo vị trí người chơi.** Vị trí người chơi trên máy người khác
  luôn trễ vài chục ms; sinh theo nó thì hai máy đặt cùng một tảng đá ở hai chỗ. Điểm sinh bám
  `TOC_CHAY_MAU` nên đá vẫn luôn ló ra trong tầm nhìn.
- **Mọi làn bày đúng MỘT bố cục** (Nhặt quà) và **một đợt đá rải cho mọi làn cùng lúc**
  (Sidestep). Khác bố cục thì người thắng chỉ là người bốc được làn dễ.
