# Plan: Đổi toàn bộ HUD/Menu sang Flashy Cartoon

Mục tiêu: bỏ style "neon kính tối" hiện tại (viền 1px xanh ngọc, nền đen trong suốt, chữ mảnh) → style **cartoon sặc sỡ, khối to, viền đậm, bóng đổ cứng, nảy tưng**, giống ảnh tham chiếu (thẻ Coins/Gems, hàng nút icon Shop/Inventory/…, bảng Active Boosts). Bố cục **thẻ to dễ bấm** thay cho danh sách nút dọc. Hỗ trợ đầy đủ **chuột + bàn phím** (và tay cầm nếu có).

---

## 1. Hiện trạng (chụp bằng godot-ai MCP, build 0.0.6, 1280×720)

### Map / bối cảnh
| Map | Nhận xét màu sắc |
|---|---|
| **Rumble Reef** (menu nền + board `board/ban_party.tscn`) | Đảo tròn giữa biển teal, cỏ xanh lá, cát cam, hải đăng kem mái đỏ hồng, lều tím. Đường ván gỗ nâu đỏ, ô bát giác kem/cam viền đen dày — **đã là cartoon**. |
| **Lobby** (`lobby/lobby.tscn`) | Nhà kính tròn, sàn trắng mặt đồng hồ số La Mã vàng, tàu lượn xanh rêu, sofa olive, bàn cờ/bóng rổ/phi tiêu/poker. Sáng, trắng → HUD chữ trắng không nền **bị chìm**. |
| **Minigame** (tank, breaking_blocks, laser_leap, spotlights, magma, explosive, crown, temporal_trails, word_wars, dem_thu, lo_da) | Sân tròn/vuông màu phẳng (trắng, nâu đỏ). HUD điểm là hộp đen nhỏ ở đáy. |

### Nhân vật
KayKit chibi đầu to: **Vệ Binh (Knight), Pháp Sư (Mage), Xạ Thủ (Ranger), Kẻ Lừa Đảo (Rogue Hooded), Chiến Binh Xương (Skeleton)**. 10 màu chính + 10 màu điểm nhấn, phụ kiện đặc trưng, 4 kiểu bong bóng chat (Vuông/Tròn/Đám mây/Gai). Tỉ lệ chibi + màu bão hoà → hợp HUD cartoon.

### Màn UI đã chụp & vấn đề
| Màn | File | Vấn đề |
|---|---|---|
| Main menu | `ui/main_menu.tscn` | Panel kính tối 1/3 trái, 4 nút viền 1px chữ mảnh, che mất đảo. Không có icon. |
| Cài đặt | `main_menu.tscn` (SettingsScreen) | Toggle bé xíu, slider mảnh, dropdown chất lượng nhỏ. Không có trang phím bấm. |
| Cách chơi | `ui/how_to_guide.gd` + `ui/huong_dan/*.tres` | Danh sách 19 dòng chữ nhỏ, khối text dài, không hình. |
| Tạo nhân vật | `ui/character_creator.tscn` | Ổn về bố cục nhưng nút dạng list "01 VỆ BINH", không có ảnh chân dung. |
| Chơi online | `main_menu.tscn` (OnlineScreen) | Input/nút cùng cỡ, danh sách phòng là hộp rỗng. |
| Cài đặt màn chơi | `main_menu.tscn` (RoomSetup) | SpinBox chật, bị cắt ("Giá mở rương" lẹm đáy), tỉ lệ 4 loại ô chỉ là số. |
| Lobby HUD | `ui/hud.tscn` | 5 dòng chữ trắng không nền, chồng lên cảnh sáng, lẫn info debug (ping/FPS). |
| ESC / Tạm dừng | `ui/pause_menu.tscn` | Hộp nhỏ giữa màn, **thiếu Cài đặt/Cách chơi**, Rời phòng/Thoát không xác nhận. |
| Chọn nhân vật (M) | `ui/character_picker.tscn` | Style khác hẳn creator (2 UI cho 1 việc), ô nhân vật trống không ảnh. |
| Board HUD | `ui/trang_thai_ca_nhan.tscn`, `ui/bang_ban.tscn` | Panel trái ổn nhưng chữ nhỏ; panel phải chữ trắng không nền, wrap xấu; "ĐANG TUNG…" chữ trôi giữa màn. |
| Chọn hướng / thuế | `ui/hud.gd` `cap_nhat_chon_huong`, `ui/bang_chon.tscn` | Gợi ý "[A/D] đổi [SPACE/E] đi" chỉ là text; popup thuế 4 nút nhỏ, **không dùng màu ô** của board. |
| Kết quả minigame | `minigame/quan_tro_minigame.tscn`, `minigame/chung/o_diem.tscn` | Chữ đen trên nền trắng sân; hộp điểm bé. **Bug:** text lobby ("đứng lên ô giữa sàn…", "Lượt: … Space tung xúc xắc") vẫn hiện trong minigame. |
| Thắng | `ui/bang_thang.tscn` | (chưa chụp được — cần ván đủ vòng) |

Theme hiện tại: `ui/main_menu_theme.tres` (StyleBoxFlat viền 1px, alpha thấp). Còn nhiều `theme_override_*` rải rác trong ~20 `.tscn`.

---

## 2. Ngôn ngữ thiết kế mới

### Bảng màu (lấy từ map Rumble Reef)
| Token | Hex | Dùng cho |
|---|---|---|
| `muc` (ink) | `#2B1B3D` | Viền 4–5px, chữ chính, bóng cứng |
| `kem` | `#FFF6DC` | Nền panel/thẻ |
| `troi` | `#4FC3F7` | Nền màn hình, nút phụ |
| `cam` | `#F58A2C` | Khung ngoài, CTA phụ |
| `hong` | `#F78FA7` | Thẻ tiền/coin, highlight |
| `vang` | `#FFD54F` | Số tiền, sao, nút CHÍNH |
| `tim` | `#8E5CF7` | Trang bị / gem |
| `la` | `#6CC04A` | Xác nhận, sẵn sàng |
| `do` | `#EF4B4B` | Máu, nguy hiểm, Thoát |

**Màu theo loại ô board (giữ đồng bộ HUD ↔ map):** Đất = kem/cam, Máu = đỏ-hồng, Tiền = vàng, Trang bị = tím. Mỗi loại kèm icon riêng (không chỉ dựa màu — an toàn mù màu).

### Font
- Tiêu đề / số: **Baloo 2 ExtraBold** (tròn, dày, có tiếng Việt, OFL).
- Thân: **Nunito Bold/Black** (có tiếng Việt, OFL).
- Chữ tiêu đề có `outline_size` 8–10 màu `muc` + shadow offset (0,4) → hiệu ứng "sticker" như chữ COINS/GEMS.
- Cỡ tối thiểu: thân 20px, nút 28px, số lớn 48–64px.

### Khối giao diện (StyleBoxFlat)
- `corner_radius` 22–28, `border_width` 4–5 màu `muc`, `anti_aliasing` bật.
- Bóng **cứng** lệch xuống: `shadow_size 0` + panel phụ phía sau lệch (0,8) màu đậm hơn 30% → giả khối 3D (như nút trong ảnh tham chiếu). Cách rẻ: StyleBoxFlat `expand_margin_bottom` + `border_width_bottom` 10 màu tối.
- Trạng thái nút: normal (đáy dày 10) → hover (nhấc lên: scale 1.06, xoay ±2°, đáy dày 12, sparkle) → pressed (lún: scale 0.94, đáy 2) → focus (viền vàng nhấp nháy 6px + mũi tên con trỏ cam như ảnh) → disabled (xám nhạt, không bóng).
- Nền màn hình menu: gradient trời + mây cartoon trôi + sọc chéo nhẹ (shader canvas_item rẻ, tắt được).

### Chuyển động ("juice")
- Mở màn: thẻ bay vào lệch nhịp 40ms, `TRANS_BACK EASE_OUT`.
- Số tiền/máu/cúp đổi: số đếm lên + "pop" scale 1.3 → 1, hạt sao nhỏ.
- Banner sự kiện ("LƯỢT CỦA BẠN!", "ĐANG TUNG…", "GO!"): ribbon đập xuống (scale 2 → 1, rung camera UI 4px).
- Tuỳ chọn **Giảm chuyển động** trong Cài đặt: tắt tilt/rung/hạt, giữ fade.

---

## 3. Kiến trúc

```
ui/
  theme/cartoon_theme.tres        # theme toàn cục (project setting gui/theme/custom)
  theme/fonts/ (Baloo2, Nunito)
  theme/nen_menu.gdshader         # nền mây/sọc
  kit/
    the_lon.tscn/.gd              # Thẻ nút to: icon + nhãn + badge phím tắt + tween hover/press
    nut_khoi.tscn/.gd             # Nút ngang to (CTA)
    bang_dan.tscn/.gd             # Panel "sticker": ribbon tiêu đề màu + nút đóng X
    vien_so.tscn/.gd              # Pill số (coin/máu/cúp/gem) có đếm + pop
    goi_y_phim.tscn/.gd           # Chip phím: [Esc] [Space] [1]… tự đổi glyph tay cầm
    bieu_ngu.tscn/.gd             # Banner đập giữa màn
    hop_xac_nhan.tscn/.gd         # Dialog Có/Không to
    buoc_so.tscn/.gd              # Stepper [-] 10 [+] thay SpinBox
    cong_tac.tscn/.gd             # Toggle to 96×48
    thanh_truot.tscn/.gd          # Slider dày, núm tròn to
    the_chan_dung.tscn/.gd        # Ảnh nhân vật (SubViewport snapshot) + tên
autoload/
  ui_dieu_huong.gd (UINav)        # stack màn, Esc = back, focus memory, thiết bị nhập, âm thanh
```

### Hệ điều hướng chung (UINav)
- `day_man(man)` / `bat_man()` — stack; **Esc / chuột phải / nút B** luôn = quay lại 1 cấp; ở gốc in-game = mở ESC menu.
- Ghi nhớ control đang focus mỗi màn, trả lại khi quay về.
- **Hover chuột ⇒ grab_focus** để chỉ có 1 highlight; di chuột lại thì focus theo chuột, bấm phím mũi tên thì hiện viền focus.
- Phím tắt số: thẻ trong lưới có badge `1..9`, bấm số = chọn ngay.
- `Enter`/`Space`/nút A = xác nhận; `Tab`/`Q`/`E` (LB/RB) = đổi tab; cuộn chuột/PageUp/Down = cuộn danh sách.
- Lưới thẻ: tự set `focus_neighbor_*` theo vị trí (hàm `UINav.noi_luoi(container, so_cot)`).
- Phát hiện thiết bị nhập cuối cùng → `goi_y_phim` đổi glyph (bàn phím ↔ tay cầm), ẩn con trỏ khi dùng tay cầm.
- Âm thanh: hover tick, click pop, back whoosh (dùng `kenney_interface-sounds` đã có).
- Chặn input game khi có màn UI mở (đã có cờ riêng ở pause/picker — gom về UINav).

---

## 4. Thiết kế từng màn

### 4.1 Main menu
- Logo **PARTYBASH** to, chữ sticker vàng viền mực, nảy nhẹ, góc trên trái; đảo Rumble Reef để lộ **toàn bộ** phía phải.
- Hàng dưới: **thẻ CHƠI ONLINE cực lớn** (2×, vàng, icon tay cầm) + lưới thẻ icon 1 hàng: Nhân vật · Cách chơi · Cài đặt · Thoát (giống hàng Shop/Inventory/… ảnh mẫu). Badge 1–5.
- Pill trạng thái máy chủ (chấm xanh/đỏ + chữ) góc dưới trái; build version góc dưới phải.
- Phím: ←→ di chuyển, Enter chọn, 1–5 tắt, Esc = hỏi thoát.

### 4.2 Chơi online
- 2 thẻ lớn cạnh nhau: **TẠO PHÒNG** (xanh lá) | **VÀO BẰNG MÃ** (ô nhập mã chữ to monospace + nút VÀO).
- Bảng tên người chơi dạng "bảng tên" phía trên kèm chân dung nhân vật hiện tại (bấm = mở creator).
- Danh sách phòng: thẻ ngang (tên phòng, chủ phòng, chip `3/8` người, nút VÀO); trống → minh hoạ đám mây + "Chưa có phòng — tạo phòng đầu tiên!". Nút làm mới icon xoay (`F5`).

### 4.3 Cài đặt màn chơi (chủ phòng)
- **Thanh tỉ lệ 4 màu** (Đất/Máu/Tiền/Trang bị) kéo vạch chia bằng chuột hoặc chọn đoạn + ←→; luôn tổng 100%.
- Preset chip: **Nhanh / Chuẩn / Dài / Hỗn loạn**.
- Các số còn lại dùng `buoc_so` to, chia 2 cột, không scroll ở 720p.
- Nút **RỜI PHÒNG** (đỏ, có xác nhận) | **VÀO SẢNH** (vàng to).

### 4.4 Cài đặt (dùng chung main menu + ESC in-game)
- Tab icon: 🔊 Âm thanh · 🖥 Hình ảnh · 🎮 Điều khiển · ♿ Hỗ trợ.
- Âm thanh: slider dày Tổng / Nhạc / Hiệu ứng.
- Hình ảnh: Toàn màn hình (toggle to), Chất lượng = 3 thẻ (Mượt / Cân bằng / Đẹp) thay dropdown, Camera nền chuyển động.
- Điều khiển: bảng phím (đọc từ InputMap) — xem trước, giai đoạn sau cho rebind.
- Hỗ trợ: Cỡ UI 80–130%, Giảm chuyển động, Hiện ping/FPS (thay vì luôn hiện ở lobby HUD).
- Áp dụng ngay, có nút **MẶC ĐỊNH**.

### 4.5 Cách chơi
- Trang đầu: lưới thẻ nhóm — **Luật cơ bản** · **Các ô** · **Vật phẩm** · **Minigame** · **Phím bấm**.
- Trong nhóm: thẻ có icon (ô màu tương ứng, icon minigame), chọn → trang chi tiết: tiêu đề sticker, đoạn ngắn + gạch đầu dòng, hình minh hoạ, mũi tên ← → to ở 2 mép (phím ←→/A D, chuột cuộn).
- Giữ dữ liệu `ui/huong_dan/*.tres`, thêm field `nhom`, `icon`.

### 4.6 Nhân vật (gộp `character_creator` + `character_picker` thành 1 màn)
- Trái: preview 3D to trên bệ tròn có spotlight, chuột kéo xoay, nút động tác dạng chip icon (Đứng/Đi/Nhảy/Ngồi).
- Phải: **băng chuyền 5 thẻ chân dung** (snapshot từ SubViewport — `_dung_anh` đã có trong picker), ←→/Q E đổi.
- Màu: chấm tròn to 56px, 2 hàng (Chính / Điểm nhấn), focus phóng to.
- Bong bóng chat: 4 thẻ có hình bong bóng thật.
- Toggle phụ kiện to. Nút XONG / QUAY LẠI.
- Mở từ main menu (trước khi vào online) và bằng phím **M** ở lobby → cùng 1 scene, khác chế độ.

### 4.7 ESC / Tạm dừng
- Mờ + tối cảnh 50%, panel sticker giữa màn, lưới thẻ 2×3:
  **TIẾP TỤC** (to, vàng) · Nhân vật · Cài đặt · Cách chơi · Rời phòng (cam) · Thoát game (đỏ).
- Rời phòng / Thoát → `hop_xac_nhan`. Esc lần nữa = Tiếp tục.
- Trong board: hiển thị thêm mã phòng + nút copy.

### 4.8 Lobby HUD
- Góc trên trái: pill **Mã phòng** (bấm/`C` copy) + chip vai trò "CHỦ PHÒNG".
- Giữa trên: thanh **Sẵn sàng 0/1** kiểu progress tròn, đếm ngược "BẮT ĐẦU SAU 3" thành banner lớn.
- Dưới giữa: hàng chip phím: `[M] Nhân vật` `[Enter] Chat` `[Esc] Menu`, nền kem viền mực (đọc được trên sàn trắng).
- Ping/FPS chỉ hiện khi bật trong Cài đặt (hoặc `F3`).

### 4.9 Board HUD (giống ảnh mẫu nhất)
- **Trên trái — thẻ người chơi:** chân dung + tên, thanh máu dày có icon tim, 2 pill số **Vàng** (hồng/vàng như thẻ COINS) và **Cúp** (cam như thẻ GEMS), số to 40px, pop khi đổi. Dòng "VÒNG 1/17 · Rương 100" thành ribbon nhỏ phía trên.
- **Trên phải — thứ tự lượt:** cột avatar tròn, người đang lượt to hơn + viền vàng nảy; kèm mini máu/vàng/cúp.
- **Dưới — thanh hành động** (như "Active Boosts"): ô trang bị dạng thẻ có icon + số lượt còn, phím `1–4`; nút to **TUNG XÚC XẮC `Space`**, **DÙNG ĐỒ `E`**. Chuột bấm được hết.
- **Chọn hướng:** 2 nút mũi tên to trên màn (bám vị trí ngã rẽ hoặc 2 bên đáy) `A`/`D`, nút giữa **ĐI `Space`**; chuột hover mũi tên 3D trên board cũng chọn.
- **Chọn mục tiêu (A/D):** thẻ chân dung mục tiêu ở giữa đáy với ◀ ▶.
- **Popup chọn thuế (`bang_chon`):** 4 thẻ lớn đúng màu + icon loại ô, badge `1–4`, Esc huỷ.
- **Banner sự kiện:** "LƯỢT CỦA BẠN!", "cac ĐANG TUNG…", "+15 VÀNG" → `bieu_ngu`; log sự kiện thành toast trượt vào góc phải, tự tắt 4s.
- Tên trên đầu nhân vật: nameplate có nền, không đè chữ ô.

### 4.10 Minigame
- **Thẻ giới thiệu** trước khi chơi: tên minigame + icon + 2–3 chip phím điều khiển + "Sẵn sàng `Space`".
- Đếm ngược **3-2-1-GO!** banner.
- Điểm: hàng pill avatar + số ở trên đỉnh màn (không đè sân).
- Kết quả: **bục 1-2-3** với chân dung, sao bay vào; nút/phím Tiếp tục.
- **Sửa bug:** ẩn lobby info + BangBan khi đang ở minigame (`ui/hud.gd` cần trạng thái `che_do`: menu / lobby / board / minigame).

### 4.11 Thắng (`bang_thang`)
- Confetti (GPUParticles2D), bục vinh quang, cúp xoay, bảng xếp hạng thẻ; nút Về sảnh / Chơi lại.

### 4.12 Chat
- Bong bóng tin nhắn có màu theo người chơi, ô nhập to bo tròn, `Enter` mở/gửi, `Esc` đóng, tự mờ sau 6s.

---

## 5. Lộ trình

| Giai đoạn | Việc | File chính | Xong khi |
|---|---|---|---|
| **P0 Nền** | Font, `cartoon_theme.tres`, đặt `gui/theme/custom`, xoá override thừa trong `.tscn`, UINav autoload | `ui/theme/*`, `project.godot`, `autoload/ui_dieu_huong.gd` | Mọi màn đổi sang viền đậm/font mới mà không vỡ layout |
| **P1 Kit** | 11 component `ui/kit/*` + scene demo `ui/kit/_trien_lam.tscn` để soi | `ui/kit/*` | Demo chạy được chuột + phím + tay cầm, hover/press/focus đúng |
| **P2 Menu** | Main menu, Online, Room setup, Cài đặt, Cách chơi | `ui/main_menu.*`, `ui/how_to_guide.gd`, `ui/huong_dan/*` | Đi hết luồng menu chỉ bằng bàn phím và chỉ bằng chuột |
| **P3 Nhân vật** | Gộp creator + picker | `ui/character_creator.*`, `ui/character_picker.*` | 1 scene, mở được từ menu và phím M |
| **P4 In-game** | ESC, Lobby HUD, Board HUD, bang_chon, banner, toast, chat | `ui/pause_menu.*`, `ui/hud.*`, `ui/trang_thai_ca_nhan.*`, `ui/bang_ban.*`, `ui/bang_chon.*`, `ui/chat.gd` | Một lượt board chơi được hoàn toàn bằng chuột |
| **P5 Minigame** | Intro, countdown, điểm, kết quả, bang_thang, sửa bug HUD rò | `minigame/quan_tro_minigame.*`, `minigame/chung/o_diem.*`, `ui/bang_thang.*` | Không còn text lobby/board trong minigame |
| **P6 Polish** | Âm thanh UI, giảm chuyển động, cỡ UI, kiểm FPS | — | 60 FPS giữ ở "Tự động"; UI scale 80–130% không vỡ |

Gợi ý thứ tự: P0 → P1 → P4 (lợi ích lớn nhất khi chơi) → P2 → P3 → P5 → P6.

---

## 6. Kiểm tra (dùng godot-ai MCP)
1. `project_run` → `editor_screenshot(source="game")` từng màn, so với trước (bộ ảnh ở mục 1).
2. `game_manage get_ui_elements`: mọi Button/thẻ có `size >= 64×64` (thẻ lưới ≥ 140×140), chữ ≥ 20px.
3. Chạy luồng chỉ bàn phím: `input_key` Tab/mũi tên/Enter/Esc/số qua Menu → Online → Tạo phòng → Lobby → Board → chọn thuế → Minigame → ESC → Rời phòng.
4. Chạy luồng chỉ chuột: `input_mouse` cùng luồng.
5. Kiểm 1600×900, 1920×1080 và 1280×720, UI scale 80/130%.
6. `test_run` cho `tests/test_gameplay_rules.gd` vẫn xanh (UI không đụng luật).

## 7. Trạng thái (2026-10-12)
Đã chốt: tải font + Kenney Game Icons; **không hỗ trợ tay cầm**.
Đã làm P0–P5 + phần lớn P6: theme toàn cục, UINav, kit, menu chính/online/luật phòng, Cài đặt (tab), Cách chơi, Nhân vật (gộp creator+picker, chân dung), ESC (lưới thẻ + xác nhận), HUD sảnh, HUD bàn (thẻ lượt, chọn hướng, thuế, túi đồ), bảng chọn mục tiêu, minigame (intro, điểm, kết quả), màn thắng, Light/Music picker. Sửa bug HUD sảnh rò sang minigame.
Còn lại: right-click = quay lại (bỏ qua), rebind phím, test 1080p/UI scale nhiều người chơi thật.

## 8. Cần quyết định / tải về (đã chốt)
- Tải font **Baloo 2** + **Nunito** (Google Fonts, OFL) vào `ui/theme/fonts/`, ghi `CREDITS.md`.
- Bộ icon: vẽ SVG tự làm (đã có `ui/icons/coin|cup|heart.svg`) hoặc tải **Kenney Game Icons** (CC0) → cần đồng ý tải.
- Có giữ hỗ trợ tay cầm ngay P1 hay để P6?
