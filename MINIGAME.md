# Pha 3 — Minigame

```
phòng chờ  →  PHA 2: bàn party (tung xúc xắc)  →  PHA 3: MINIGAME  →  quay lại pha 2
```

Tài liệu này nói về **pha 3**. Nhưng trong repo có **hai loại trò hoàn toàn khác nhau** và
chúng rất dễ bị nhầm là một, nên phải tách bạch ngay từ đầu.

---

# 1. HAI LOẠI TRÒ — đừng bao giờ gộp chung

| | **Trò phòng chờ** | **Minigame pha 3** |
|---|---|---|
| Sống ở đâu | `lobby/objects/` — đặt sẵn trong `lobby.tscn` | `minigame/` — scene nạp vào khi cần |
| Là gì về mặt mạng | **Scene object**, có sẵn từ lúc vào phòng | Scene phủ lên, dựng rồi xoá mỗi ván |
| Ai chơi | Ai đi tới thì chơi. Thường **một người, cả phòng đứng xem** | **Cả phòng cùng lúc**, danh sách do bàn đưa vào |
| Bắt đầu thế nào | Người chơi tự bấm | `bat_dau(nguoi_choi, hat_giong)` |
| Kết thúc thế nào | **Không kết thúc.** Chơi chán thì đi chỗ khác | Hết giờ hoặc còn một người → **bắt buộc** kết thúc |
| Sinh ra cái gì | Không gì. Vui là chính | **Bảng xếp hạng** — quyết định thứ tự lượt vòng sau |
| Class | Không có class chung | `extends MiniGame` |
| Đăng ký ở đâu | Không đăng ký. Kéo vào `lobby.tscn` là xong | `QuanTroMiniGame.DANH_SACH` |

**Câu phân biệt gọn nhất:** trò phòng chờ *không có người thắng*, minigame pha 3 *bắt buộc
phải đẻ ra một thứ hạng cho mọi người*.

---

# 2. Trò phòng chờ — ĐÃ CÓ, không thuộc pha 3

Đây là những trò đã chạy xanh trong `lobby/objects/`. **Không cái nào là minigame pha 3**, và
không cái nào đăng ký được vào `DANH_SACH` (lý do ở mục 4).

| Trò | File | Cách chơi |
|---|---|---|
| Tháp Hà Nội | `hanoi_tower.gd` | 3 cọc, 6–8 đĩa. Master giữ luật, phát nguyên trạng thái JSON |
| Liar Bar | `liar_bar.gd` | 2–4 người, bộ 20 lá, nói dối và bắt nói dối |
| Đập chuột chũi | `whack_a_mole.gd` | Chuột nhô lên từ 5 lỗ trên mặt máy arcade |
| Penguin Cross | `penguin_cross.gd` | Tham-hay-dừng. **Một người bước, cả phòng đứng xem** |
| Đua gà | `chicken_race.gd` | Đặt cược rồi xem. Một hạt giống, mọi máy ra cùng kết quả |
| Phi tiêu | `dartboard.gd` · `dart.gd` | Ném phi tiêu vật lý thật, bia tính điểm như bia thật |
| Bóng rổ | `basketball_court.gd` · `basketball_hoop.gd` | Nửa sân 3×2 m, ném bóng vật lý thật |
| Poker · Xì dách | `card_table.gd` · `card_seat.gd` | Ngồi ghế, có luật đầy đủ, hệ thống làm nhà cái |
| Cờ vua · Cờ tướng · Caro | `chess_board.gd` · `chess_piece.gd` | Bày quân tự do, không ép luật |
| Xúc xắc | `dice_table.gd` · `die.gd` | Cầm lên ném, đọc mặt từ hình học model |

(`community_board.gd` không phải một trò — nó là tấm dựng bài chung của bàn poker.)

**Thêm một trò phòng chờ:** dựng scene, thả `FusionSharedReplicator` nếu cần đồng bộ, kéo vào
`lobby.tscn`. Không đụng gì tới bàn party.

---

# 3. Minigame pha 3 — hiện có ĐÚNG MỘT

```
extends MiniGame   →  minigame/tank/tank_battle.gd     ← duy nhất
DANH_SACH          →  { "tank": ... }                  ← một mục
main.gd:161        →  quan_tro.xin_chay("tank")        ← tên CỨNG trong code
```

> ⚠️ **`main.gd` đang ghi cứng `"tank"`.** Kể cả `DANH_SACH` có 5 trò thì nó vẫn chạy Tank mãi.
> Phải đổi thành bốc ngẫu nhiên. Rẻ: `xin_chay(ma)` đã phát `ma` qua RPC cho cả phòng, nên
> master `randi()` chọn một khoá là đủ — không cần thêm cơ chế đồng bộ nào.

## Hợp đồng

```gdscript
extends MiniGame

func bat_dau(nguoi_choi: Array, hat_giong: int) -> void   # danh sách player_id vào
signal xong(xep_hang: Array)                              # player_id, giỏi nhất đầu, ra
```

Đăng ký là một dòng trong `QuanTroMiniGame.DANH_SACH`.

Minigame **không biết** gì về chìa khoá, cốc, bàn cờ. Bàn cờ **không biết** luật minigame nào.
Nhờ vậy thêm một trò không phải sửa dòng nào bên bàn.

## Năm ràng buộc, trò pha 3 nào cũng phải qua

| | Vì sao |
|---|---|
| **45–90 giây** | Nó chen giữa hai lượt bàn. Dài hơn là người chơi quên mình đang ở ô nào |
| **Luật hiểu trong 3 giây** | Đếm ngược chỉ có 3 giây và một dòng chữ. Trò cần giải thích là trò sai |
| **2–8 người, không chia phe** | Số người là số người đang trong phòng, không đoán trước được |
| **Xếp hạng GIỐNG NHAU trên mọi máy** | Nó quyết định lượt. Lệch một chỗ là hai người thấy hai bàn khác nhau |
| **Hết ván là phải kết thúc** | Không có đường thoát nào khác. Bàn party đang đứng chờ `xong()` |

> ⚠️ **Tank đang vi phạm điều thứ tư.** Lần chạy thử 6 người: master ra `[2,6,3,1,5,4]`, máy
> khác ra `[1,2,3,4,5,6]`. Hiện chưa gây hại vì chỉ gói của master được phát đi, nhưng
> `mini_game.gd` ghi rõ `xong()` phải phát **cùng một bảng trên mọi máy**. Cần truy lại.

---

# 4. Vì sao KHÔNG đăng ký thẳng trò phòng chờ vào `DANH_SACH`

Đây là chỗ hay nhầm nhất, nên nói thẳng bằng code.

Trò phòng chờ **không có** hai thứ mà hợp đồng đòi:

```gdscript
func bat_dau(nguoi_choi: Array, hat_giong: int)   # không cái nào nhận danh sách người chơi
signal xong(xep_hang: Array)                      # không cái nào sinh ra thứ hạng
```

Và ba thứ nữa lệch về bản chất:

- **Không có giờ.** Tháp Hà Nội chơi tới khi xong, Liar Bar chơi tới khi còn một người, phi
  tiêu ném bao nhiêu cũng được. Pha 3 phải dừng sau 45–90 giây.
- **Không phải ai cũng chơi.** Penguin Cross là *một người bước, cả phòng đứng xem*. Tháp Hà
  Nội là một cái tháp dùng chung. Pha 3 cần cả 8 người cùng chơi cùng lúc.
- **Một bản dùng chung, không phải mỗi người một sân.** Để 8 người cùng đập chuột thì phải có
  8 cái máy, không phải một.

→ Muốn có "Tháp Hà Nội pha 3" thì phải **viết một scene mới** `extends MiniGame`: dựng một
tháp riêng cho từng người, đặt giới hạn giờ, xếp hạng theo số bước. Phần *logic tháp* lấy lại
được từ `hanoi_tower.gd`; phần *"ván có kết thúc và có thứ hạng"* là viết mới.

**Bản phòng chờ vẫn giữ nguyên.** Hai bản sống song song, dùng chung phần logic, khác nhau ở
lớp vỏ. Đừng sửa bản phòng chờ thành bản pha 3 — mất một trò để được một trò.

---

# 5. Ba kiểu đồng bộ cho minigame pha 3

Chọn đúng kiểu là xong 80% việc.

### Kiểu A — HẠT GIỐNG · 0 gói tin

Master gieo một số, mọi máy tính ra cùng kết quả. Người chơi **không điều khiển gì**, chỉ chọn
trước rồi xem. Rẻ nhất, nhưng chỉ hợp trò may rủi.

### Kiểu B — SỰ KIỆN · vài chục gói mỗi ván

Chỉ gửi khi trạng thái **thật sự đổi**. Giữa hai lần đổi, mọi máy tự tính ra cùng vị trí.

> Đã dùng: `tank_battle.gd` — xe chạy tốc độ đều theo 4 hướng nên đoán trước được; chỉ gửi lúc
> đổi hướng, bắn, trúng, phá gạch.

Hợp trò đối kháng thời gian thực. **Đắt nhất về công sức.**

### Kiểu C — ĐIỂM SỐ · 1 gói mỗi người mỗi ván ⭐

Mỗi người chơi **phần sân riêng của mình**, hoàn toàn cục bộ. Hết giờ mới gửi **một con số**.
Không có va chạm giữa người chơi nên không có gì để đồng bộ.

Rẻ nhất mà vẫn có người chơi điều khiển. **Phần lớn trò nên đi đường này.**

> **Cấm gửi vị trí mỗi khung hình.** 8 người × 15 Hz = 120 gói/giây — một phần tư ngân sách
> 500 gói/giây của cả phòng, cho một trò (`tank_battle.gd` đã tính). Ba kiểu trên tránh được hết.

> ❌ **Bỏ con số "RPC tối đa 512 byte".** `GUIDE.md` mục 7 nói rõ: đó là số của Fusion 2 bản
> **Unity**, không áp dụng ở đây. Đã đo thật trên hai máy — `String` **3000 byte tới đủ**.
> Bàn party đang phát gói ~800 byte mỗi lượt và chạy bình thường.

---

# 6. Khung cho trò kiểu C — viết một lần, dùng lại cho mọi trò sau

Trò kiểu C khác nhau đúng phần *"tính điểm thế nào"*. Phần còn lại giống hệt: chia sân, đếm
giờ, thu điểm, xếp hạng.

```gdscript
class_name MiniGameDiem extends MiniGame

## Lớp con cài đúng hai hàm này.
func _dung_san(_cho: Node3D, _id: int) -> void: pass
func _diem_cua_toi() -> int: return 0
```

Lớp cha lo: đặt sân của mỗi người cách nhau (không ai thấy ai), chạy đồng hồ, hết giờ thì
`Fusion.rpc(_net_diem, id, _diem_cua_toi())`, gom đủ điểm rồi `xong.emit()`.

**Xếp hạng khi bằng điểm:** lấy `player_id` nhỏ hơn đứng trên. Phải có luật rõ ràng — mọi máy
phải ra cùng một thứ tự, `sort_custom` của Godot không ổn định nên không được để nó tự quyết.

---

# 7. Lỗ hổng phải bịt trước khi thêm trò

**Xếp hạng hiện chỉ đổi thứ tự lượt, KHÔNG thưởng chìa khoá.**

`main.gd::_khi_xong_minigame()` chỉ gọi `ban_co.xin_thu_tu_moi(xep_hang)`. Theo thiết kế Pummel
Party thì hạng cao phải được chìa khoá — đó mới là lý do người chơi cố thắng. Thiếu nó thì
minigame chỉ là quãng nghỉ giữa hai lượt.

Cần một bảng thưởng trong `LuatBan`, ví dụ `hạng 1: +5 chìa · 2: +3 · 3: +2 · 4+: +1`.

Đặt trong `LuatBan` chứ **không** đặt trong minigame — minigame không được biết chìa khoá là gì.

---

# 8. Asset

Trò kiểu C dựng bằng khối cơ bản thì gần như không cần asset mới; thứ thiếu là **âm thanh**,
và `asset/kenney_impact-sounds/` với `kenney_interface-sounds/` đã có sẵn trong repo.

Node nào còn đang là hình tạm: xem `ASSET-CAN-THEM.md`.

---

# 9. Roadmap nội dung — 18 trò gom về 5 KHUÔN

Mục 1–8 nói **cách làm** một minigame pha 3. Mục này nói **làm những trò nào**.

Nguồn: một buổi bàn ý tưởng, tham khảo Pummel Party (~48 trò). Lunars không liệt kê được —
Steam, trang chủ, bài preview và wiki đều chỉ nói "30+ minigame", không nơi nào có danh sách.

## Điều đắt nhất là số KHUÔN, không phải số TRÒ

| Khuôn | Trò | Xây một lần |
|---|---|---|
| **T1 — sàn đẩy nhau** | Magma & Mages · Snowy Spin · Acidic Atoll · Explosive Exchange · Crown Capture | cam trên cao · di chuyển theo cam · 1 nút đòn (tầm/hình/lực/hồi chiêu là config) · rơi khỏi sàn tự khai tử · sàn co dần bật-tắt |
| **T2 — né chướng ngại** | Breaking Blocks · Laser Leap · Searing Spotlights · Slippery Sprint | cùng cam + điều khiển T1, bỏ nút đòn · chướng ngại = hàm của hạt giống + thời gian mạng |
| **T3 — lưới ô** | Bounding Blocks · Temporal Trails · Word Wars | sàn chia ô · giẫm lên thì ô đổi chủ · đếm ô |
| **T4 — làn chạy, cam sau lưng** | Sidestep Slope · Nhặt quà né rác · Slippery Sprint | đường cuộn · vật cản sinh theo quãng đường từ hạt giống |
| **T5 — mỗi người một bàn riêng** | Fractured Faces · Đếm thú · Rockin Rhythm · Bóng chày | chia khu riêng · cùng chuỗi đề từ hạt giống · cuối ván gửi đúng một con số |

**13/18 trò dùng chung đúng một camera.** 3 trò cam sau lưng dùng lại `CameraRig` của phòng
chờ. 2 trò là overlay 2D dùng chung một bố cục hàng ngang. Tổng cộng phải viết **3 kiểu
camera**, không phải 18.

**8 trò gửi 0 gói tin** trong lúc chơi.

## Khuôn nào đi đường đồng bộ nào

Nối với ba kiểu ở mục 5:

| Khuôn | Kiểu | Vì sao |
|---|---|---|
| T1 | **B — sự kiện** | Có va chạm người-người. Chỉ phát lúc đánh, lúc chết |
| T2 | **A + "tôi chết"** | Chướng ngại tất định từ hạt giống; người bị nạn tự khai tử |
| T3 | **B, gần 0 gói** | Ô chiếm suy ra từ vị trí người chơi — replicator đã gửi sẵn |
| T4 | **A** | Vật cản sinh theo quãng đường từ hạt giống; mỗi người một băng riêng |
| T5 | **C — điểm số** | Đúng cái khung `MiniGameDiem` ở mục 6 |

## Bảng chốt 18 trò

| # | Trò | Khuôn | Camera | Tính điểm | Gói tin |
|---|---|---|---|---|---|
| 1 | Magma & Mages | T1 | trên cao | loại trừ: chết thứ *i* → `n−i` | 1/phát cầu lửa |
| 2 | Snowy Spin | T1 | trên cao | ~~`n−i` mỗi vòng, 3 vòng × 20 s~~ → **một ván 60 s, thời gian sống** | **0** |
| 3 | Acidic Atoll | T1 | trên cao | loại trừ | ~~1/quả bom~~ → **0**, lịch rơi từ hạt giống |
| 4 | Explosive Exchange | T1 | trên cao | loại trừ theo thứ tự nổ | `ai_om` do master |
| 5 | Crown Capture | T1 | trên cao | **1 đ/giây giữ**, 60 s | `ai_giu` do master |
| 6 | Breaking Blocks | T2 | trên cao | thời gian sống, 60 s | chỉ "tôi chết" |
| 7 | Laser Leap | T2 | trên cao | thời gian sống, **không giới hạn giờ** | chỉ "tôi chết" |
| 8 | Searing Spotlights | T2 | trên cao, **tối hoàn toàn** | thời gian sống · **100 máu, −40/giây trong đèn** | chỉ "tôi chết" |
| 9 | Slippery Sprint | T2/T4 | **sau lưng riêng** | thứ hạng về đích; chưa về thì theo quãng đường | chỉ "tôi chết" |
| 10 | Bounding Blocks | T3 | trên cao | số ô lúc hết giờ, 60 s | **0** — suy từ vị trí |
| 11 | Temporal Trails | T3 | trên cao | loại trừ, 60 s | **0** — suy từ vị trí |
| 12 | Word Wars | T3 | trên cao | số từ ghép xong, 60 s · **cả phòng chung một từ** | ~~1/cú đấm~~ → **1/từ ghép xong** |
| 13 | Sidestep Slope | T4 | **sau lưng riêng** | quãng đường đi được | **0** |
| 14 | Nhặt quà né rác | T4 | **sau lưng riêng** | quà +1 · quà to +3 · rác −1 (cho âm), 60 s · **băng riêng mỗi người** | **0** |
| 15 | Fractured Faces | T5 | trên cao, khu riêng | thứ hạng hoàn thành; chưa xong thì số mảnh đúng | **0** + 1 gói cuối |
| 16 | Đếm thú | T5 | trên cao, **không render người chơi** | 5 vòng, đếm 1 loại giữa 3 loại · đúng +1 sai 0 | **0** + 1 gói/vòng |
| 17 | Rockin Rhythm | T5 | **overlay 2D, hàng ngang** | Perfect 3 · Good 1 · Miss 0 · combo ×1.5 sau 10 nốt | 1 gói/giây/người |
| 18 | Bóng chày | T5 | **overlay 2D, hàng ngang** | tâm ±40 ms **3đ** · ±100 ms **2đ** · ±180 ms **1đ** · trật 0 · 15 quả | 1 gói cuối |

## Ghi chú riêng vài trò

**Searing Spotlights — tối là tối HẲN.** Không thấy nhân vật nào, kể cả của mình. Đèn quét là
nguồn sáng duy nhất: ai lọt vào thì vừa bị lộ, vừa mất máu. Hai thứ bắt buộc, thiếu thì trò
thành ngẫu nhiên chứ không thành khó:

- **Thanh máu luôn hiện trên HUD** — tín hiệu duy nhất báo "đang bị nướng, chạy đi".
- **Sàn có mốc định hướng mờ** (viền phát sáng yếu, vài vạch chìm). Là NÚM CHỈNH: càng mờ càng
  căng. Không có gì để bám thì đi trong tối là tung xúc xắc.

**Rockin Rhythm là 2D, không phải 3D.** Mỗi người một hàng ngang, avatar 2D của nhân vật bên
trái (chụp sẵn 12 ảnh PNG bằng `SubViewport`, lấy theo `model_index` đã replicate — **không
render lúc chạy**), nốt chạy từ phải sang vạch phán định.

Xếp hàng ngang mới là thứ làm trò này hay: liếc sang thấy hàng người khác đang ăn combo.

> **Hàng của mình phải khác hẳn** — cao hơn, sáng hơn, có khung. Tám hàng giống nhau là người
> chơi bấm theo nhầm hàng, rồi nghĩ game hỏng chứ không nghĩ mình nhìn nhầm.

> **Đừng gửi từng nốt.** 4 nốt/giây × 8 người = 32 gói/giây, một mình trò này ăn gần hết ngân
> sách. Gửi `(id, điểm, combo)` mỗi giây một lần — người xem cần thấy ĐIỂM LEO, không cần thấy
> từng cú bấm.

> **Đổi sang 2D sửa phần CODE, không sửa phần NỘI DUNG.** Vẫn cần một bài nhạc dùng được và
> một bản đồ nốt khớp nhạc làm tay. Chỉ làm **một bài**.

**Explosive Exchange phải có hồi chiêu chuyền ~1 s.** Không có thì hai người dính nhau là quả
bom nảy qua lại mỗi khung hình → bão RPC → lỗi 1035.

**Temporal Trails: lệch vài cm là chấp nhận được.** Vệt vẽ từ vị trí nội suy nên có thể có
khung hình mà máy A thấy mình chạm, máy B thấy không. Vì NGƯỜI BỊ NẠN TỰ NHẬN nên không bao
giờ mâu thuẫn — chỉ là "thoát chết trong mắt người khác" đúng một khung.

**Đếm thú không render người chơi.** Cả phòng nhìn đúng một khung hình, gần như xem chung một
đoạn phim: đàn thú sinh từ hạt giống, 0 gói tin, không va chạm, không trọng tài. Rẻ nhất cả 18
trò. Nhưng **phải hiện số đang đếm lên màn hình** — phím có thể dính đúp, không thấy số thì
người chơi đổ lỗi cho game chứ không cho ngón tay.

## Thứ tự làm

```
1. T2   Breaking Blocks · Laser Leap · Searing Spotlights      (3 tro)   ✅ XONG
        -> dung khuon: san + cam tren cao + dieu khien theo cam + tu khai tu
2. T1   Magma&Mages · Snowy Spin · Acidic Atoll · Explosive · Crown   (5 tro)   ✅ DA DUNG
        -> them 1 nut don, bang config 5 dong
        -> con no: chay thu NHIEU MAY. Moi kiem bang assert + nap scene, chua qua Photon that
3. T3   Bounding Blocks · Temporal Trails · Word Wars          (3 tro)   ✅ DA DUNG
        -> luoi 13x13 tach ra `chung/san_luoi.tscn`, Breaking Blocks dung chung
4. T4   Sidestep Slope · Nhat qua · Slippery Sprint            (3 tro)   ✅ DA DUNG
        -> khung rieng `chung/mini_game_lan.gd`: lan rieng, cam sau lung cua chinh minh
5. T5   Bong chay · Rockin Rhythm · Dem thu · Fractured Faces   (4 tro)
```

Hết bước 2 là **8 trò chạy được**, đủ quay demo. Cắt thì cắt ngược từ T5 — mỗi trò T5 là một
game nhỏ tự thân, **đắt nhất về công sức dù rẻ nhất về mạng**.

## ⚠️ Một luật còn mâu thuẫn — phải chốt trước khi code

Mục 6 ghi: hoà điểm thì `player_id` nhỏ hơn đứng trên.
`ROADMAP.md` §1bu ghi ngược lại: **hoà thì hoà thật**, cùng nhận thưởng hạng đó, hạng sau nhảy
cóc (5đ, 5đ, 3đ → hạng 1, 1, 3), vì người chơi thấy "1. A, 2. B" trong khi cùng điểm là họ
nghĩ game thiên vị.

Hai cái không thể cùng đúng. Cần một câu trả lời trước khi viết trò thứ hai.

Nếu chọn "hoà thật" thì mỗi trò vẫn phải có **tiebreak CÓ NGHĨA** trước đã. Quy tắc: điểm là
số nguyên nhỏ thì chắc chắn sẽ hoà → phải có tiebreak; điểm là thời gian hoặc quãng đường →
bỏ qua.

| Trò | Tiebreak |
|---|---|
| Loại trừ, thời gian sống | **Thứ tự master nhận gói "tôi chết"** — miễn phí, master vốn nhận tuần tự |
| Đếm thú | **Tổng thời gian chốt đáp án.** Bắt buộc — 8 người cùng đúng 5/5 là chuyện thường |
| Bóng chày | số cú trúng tâm |
| Rockin Rhythm | combo dài nhất |
| Bounding Blocks | ai chiếm ô cuối muộn hơn |
| Word Wars | tổng số nút giẫm đúng |
| Nhặt quà né rác | số quà to |
| Snowy Spin | hạng ở vòng cuối |
| Fractured Faces | thời điểm gắn mảnh đúng cuối cùng |
| Crown Capture · Sidestep Slope · Slippery Sprint | không cần — điểm là số thực |

## Còn để mở

- **Word Wars ghép chữ tiếng Anh.** Người giỏi tiếng Anh thắng chứ không phải người chơi giỏi.
  Đã hỏi và bạn chọn giữ nguyên — ghi lại để sau không ai tưởng là bỏ sót.
- **Slippery Sprint** chạy đường thẳng, cam sau lưng từng người — nên nó vừa thuộc T2 vừa dùng
  khuôn cam của T4.
- 18 trò là **kế hoạch**, chưa viết dòng nào. Trò pha 3 duy nhất đang chạy vẫn là Tank.
