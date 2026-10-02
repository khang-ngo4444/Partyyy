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

# 3. Minigame pha 3 — hiện có 15 TRÒ

> **Đã xoá (2026-10-02): Acidic Atoll (chìm đảo), Nhặt quà né rác và Bounding Blocks** — gỡ khỏi `QuanTroMiniGame.DANH_SACH`, xoá thư mục `minigame/acidic_atoll/`, `minigame/nhat_qua/`, `minigame/bounding_blocks/`, `materials/mat_axit.tres` và `minigame/chung/san_luoi.tscn` (lưới 13×13 chỉ Bounding Blocks dùng). Các đoạn bên dưới còn nhắc tới hai trò này là lịch sử.

```
extends MiniGame   →  17 script, nhưng 2 trong đó là KHUÔN chứ không phải trò
DANH_SACH          →  15 mục                           ← danh sách thật
main.gd            →  xin_chay(DANH_SACH.keys().pick_random())
```

Hai khuôn chung, trò nào cũng đi qua một trong hai:

| Khuôn | File | Làm gì cho lớp con |
|---|---|---|
| `MiniGame3D` | `minigame/chung/mini_game_3d.gd` | Dựng sân, đọc giờ, đếm người còn sống, **chốt và phát `xong`** (`_chot_ket_qua` → `_net_xep_hang`) |
| `MiniGameLan` | `minigame/chung/mini_game_lan.gd` | Kế thừa `MiniGame3D`, 8 làn riêng SÁT NHAU + camera chung bám tốp |
| `ThanhMau` | `minigame/chung/thanh_mau.gd` + `.tscn` | Máu + thanh máu. Không phải khuôn — kéo vào `.tscn` của trò nào cần |
| `CauLua` | `minigame/chung/cau_lua.gd` + `.tscn` | Quả cầu lửa bay thẳng, 1 gói tin cả đời. Magma & Crown dùng chung |

Nên **lớp con không tự phát `xong`** — đừng đi tìm `xong.emit` trong `laser_leap.gd` rồi kết
luận trò đó chưa xong. Nó nằm ở `mini_game_3d.gd`, một chỗ cho cả 15 trò.

## Chạy lúc nào

```
pha 2: mọi người đổ xúc xắc xong một lượt
  → pha_ban_co.gd:_ket_luot    — `luot` vòng về 0, phát `het_vong`
  → main.gd:_khi_het_vong      — master bốc ngẫu nhiên 1 trong 15
  → pha 3 chạy, `xong(xep_hang)`
  → main.gd:_khi_xong_minigame — xếp hạng thành THỨ TỰ LƯỢT vòng sau
```

Ngẫu nhiên bốc **ở master**, không cần thêm đồng bộ: `xin_chay(ma)` phát chính `ma` đó qua RPC
cho cả phòng, mọi máy nạp cùng một scene.

`/mg <mã>` trong chat **chỉ để test tay từng trò**, không phải đường chạy thật. `/mg` trơ trọi
thì liệt kê mã.

> ⚠️ Rút ngẫu nhiên trần, có thể lặp lại trò vừa chơi. Thêm bộ đếm "không lặp N trò gần nhất"
> khi người chơi bắt đầu thấy nhàm.

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
| **30–90 giây** | Nó chen giữa hai lượt bàn. Dài hơn là người chơi quên mình đang ở ô nào. T4 chạy 30 s vì làn chỉ 150 m |
| **Luật hiểu trong 3 giây** | Đếm ngược chỉ có 3 giây và một dòng chữ. Trò cần giải thích là trò sai |
| **2–8 người, không chia phe** | Số người là số người đang trong phòng, không đoán trước được |
| **Xếp hạng GIỐNG NHAU trên mọi máy** | Nó quyết định lượt. Lệch một chỗ là hai người thấy hai bàn khác nhau |
| **Hết ván là phải kết thúc** | Không có đường thoát nào khác. Bàn party đang đứng chờ `xong()` |

> ⚠️ **Tank đang vi phạm điều thứ tư.** Lần chạy thử 6 người: master ra `[2,6,3,1,5,4]`, máy
> khác ra `[1,2,3,4,5,6]`. Hiện chưa gây hại vì chỉ gói của master được phát đi, nhưng
> `mini_game.gd` ghi rõ `xong()` phải phát **cùng một bảng trên mọi máy**. Cần truy lại.

---

# 3b. Hai trò đã làm lại lõi — và vì sao

Hai trò này từng "chạy xanh" nhưng lõi sai. Ghi lại để không ai vô tình làm lại bản cũ.

## Breaking Blocks — hư theo NGƯỜI ĐỨNG, không theo đồng hồ

| | Bản cũ | Bản mới |
|---|---|---|
| Ô tan vì | `trang_thai_o(pha, gio(), chu_ky)` — đồng hồ | `_hu[i]` cộng khi CÓ người đứng trên |
| Người chơi gây ra gì | Không gì. Đứng yên hay chạy loạn đều như nhau | Ô dưới chân mình nứt dần, rời đi thì vết nứt ở lại |
| Lưới | 13×13 ô 1,6 m (gần như sàn liền) | 8×8 ô 2,8 m, khe 1,2 m — phải nhảy thật |
| Gói tin | 0 | Chỉ khi có ô ĐỔI trạng thái, do master phán |

Vỡ do master phán rồi phát đi, vì vỡ là thứ giết người — hai máy lệch vài khung hình mà một bên
ô đã mất thì có người chết oan. Vết nứt thì mỗi máy tự tính, 0 gói tin.

## Laser Leap — phá NHỊP, không phải cho tia nhanh hơn

Bản cũ cho 3 tia quay cùng tốc, pha cách đều, quanh đúng tâm sàn. Không có góc an toàn — nhưng
**nhịp cố định**: đo được, hai khoảng tia đi qua liền nhau chỉ lệch **1,6%**. Người chơi tìm ra
một nhịp nhảy rồi lặp lại là sống hết ván mà không cần nhìn gì. Trò phản xạ thành trò bấm nhịp.

Bản mới thêm **lịch đợt** suy từ hạt giống: mỗi đợt đổi hướng quay, hệ số tốc riêng từng tia, pha
đầu, và **điểm quay lệch khỏi tâm sàn**. Lệch tâm là thứ phá nhịp mạnh nhất — khoảng giữa hai lần
tia đi qua một chỗ không còn đều. Đo lại: **62%**.

Lệch tâm đòi thanh tia dài 30 m: tia lệch `d` quét một đĩa bán kính `nửa thanh` quanh điểm lệch,
muốn phủ kín sàn bán kính 11,5 thì cần `nửa thanh ≥ 11,5 + d`. Thanh ngắn hơn là sinh ra một vành
sàn tia không bao giờ với tới — đúng cái "chỗ đứng an toàn vĩnh viễn" phải tránh.

## Cả hai đều có bộ kiểm chạy được

```
godot --headless --path minigame/breaking_blocks --script kiem_luat.gd
godot --headless --path minigame/laser_leap      --script kiem_luat.gd
godot --headless --path minigame/spotlights      --script kiem_luat.gd
godot --headless --path minigame/magma           --script kiem_luat.gd
godot --headless --path minigame/acidic_atoll    --script kiem_luat.gd
godot --headless --path minigame/explosive       --script kiem_luat.gd
godot --headless --path minigame/crown           --script kiem_luat.gd
```

Chúng chặn được những thứ KHÔNG thấy bằng mắt trong một ván chơi thử:

- `GIAY_HOI = 9` ở Breaking Blocks → 4 người biết chạy thì 60 giây không một ô nào vỡ, ván nào
  cũng hết giờ với bốn người sống, xếp hạng thành ngẫu nhiên.
- 3 người chung một ô cuối ván → cửa sổ cảnh báo co còn 0,27 giây, vỡ gần như cùng lúc đổi màu.
- Nhịp tia khoá ở Laser Leap — và lần đầu tôi đo bằng độ lệch chuẩn cả ván thì bản cũ ra 34%,
  **lọt qua**; phải đo hai khoảng liền nhau mới lộ ra 1,6%.
- `TAM_QUET = 7,8` ở Spotlights → đèn rọi ra ngoài sàn và đèn chạy nhanh hơn người. Chơi thử 3
  đèn thấy thoải mái; tới chu kỳ 6 mới hết chỗ đi, mà lúc đó không ai còn đang test.
- Ở Crown Capture, "xếp theo tổng giây giữ" và "xếp theo người đang giữ lúc hết giờ" **thường ra
  cùng kết quả**, nên chơi thử không bắt được nếu một ngày ai sửa sai khoá sắp. Bộ kiểm dựng hẳn
  một dòng thời gian mà hai cách ra kết quả khác nhau.
- Ở Explosive Exchange, mọi người cùng tốc độ nên người ôm bom chỉ còn 1,22 giây biên trên bom
  ngắn nhất. Đông người thì không thấy, vì luôn có ai đó ở gần; chỉ lộ ra ở màn 1v1 cuối ván.
- Ở Acidic Atoll, cửa sổ trượt có thể ăn hết mọi đảo an toàn cùng lúc — lúc đó người chơi đúng
  cũng buộc phải xuống axit. Bộ kiểm quét **200 hạt giống × mọi chặng** và đòi luôn còn ít nhất
  một đảo sống qua được chặng sau.

Hằng số trong bộ kiểm **chép tay** từ file trò. Đổi số bên trò thì phải đổi ở đây — và đó là việc
cố ý: mỗi lần đổi một con số, bộ kiểm buộc phải chạy lại.

> ⚠️ `assert` fail trong `--headless --script` làm Godot **đứng chờ debugger**: 0% CPU, không in
> một chữ nào. Hai bộ kiểm dùng `ck()` tự viết chứ không dùng `assert` vì lý do đó.

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
  tiêu ném bao nhiêu cũng được. Pha 3 phải dừng sau 30–90 giây.
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
| **T1 — sàn đẩy nhau** | Magma & Mages · Acidic Atoll · Explosive Exchange · Crown Capture | cam trên cao · di chuyển theo cam · 1 nút đòn (tầm/hình/lực/hồi chiêu là config) · rơi khỏi sàn tự khai tử · sàn co dần bật-tắt |
| **T2 — né chướng ngại** | Breaking Blocks · Laser Leap · Searing Spotlights · Slippery Sprint | cùng cam + điều khiển T1, bỏ nút đòn · chướng ngại = hàm của hạt giống + thời gian mạng |
| **T3 — lưới ô** | Temporal Trails · Word Wars | sàn chia ô · giẫm lên thì ô đổi chủ · đếm ô |
| **T4 — làn chạy, cam chung** | Sidestep Slope · Nhặt quà né rác · Slippery Sprint | 8 làn kề vai · vật cản sinh theo quãng đường từ hạt giống |
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
| T4 | **A** | Vật cản sinh theo quãng đường từ hạt giống; mỗi người một làn riêng, các làn kề nhau |
| T5 | **C — điểm số** | Đúng cái khung `MiniGameDiem` ở mục 6 |

## Bảng chốt 18 trò

| # | Trò | Khuôn | Camera | Tính điểm | Gói tin |
|---|---|---|---|---|---|
| 1 | Magma & Mages | T1 | trên cao | loại trừ · **100 máu, −22/giây trong nham** | 1/phát cầu lửa |
| 3 | Acidic Atoll | T1 | trên cao | loại trừ · **100 máu, −20/giây trong axit** | ~~1/quả bom~~ → **0**, lịch rơi + thứ tự chìm từ hạt giống |
| 4 | Explosive Exchange | T1 | trên cao | loại trừ theo thứ tự nổ (**không máu** — xem ghi chú) | `ai_om` do master, 1 gói/cú chuyền |
| 5 | Crown Capture | T1 | trên cao | **1 đ/giây giữ**, 60 s · **không ai chết** | `ai_giu` do master, 1 gói/phát cầu lửa |
| 6 | Breaking Blocks | T2 | trên cao | thời gian sống, 60 s | "tôi chết" + **ô vỡ/mọc do master phát** |
| 7 | Laser Leap | T2 | trên cao | thời gian sống, chốt chặn 90 s | chỉ "tôi chết" |
| 8 | Searing Spotlights | T2 | trên cao, **chu kỳ sáng↔tối** | thời gian sống · **100 máu, −40/giây trong đèn** | chỉ "tôi chết" |
| 9 | Slippery Sprint | T2/T4 | **cam chung bám tốp** | thứ hạng về đích; chưa về thì theo quãng đường | chỉ "tôi chết" |
| 10 | Bounding Blocks | T3 | trên cao | số ô lúc hết giờ, 60 s | **0** — suy từ vị trí |
| 11 | Temporal Trails | T3 | trên cao | loại trừ, 60 s | **0** — suy từ vị trí |
| 12 | Word Wars | T3 | trên cao | số từ ghép xong, 60 s · **cả phòng chung một từ** | ~~1/cú đấm~~ → **1/từ ghép xong** |
| 13 | Sidestep Slope | T4 | **cam chung bám tốp** | quãng đường đi được | **0** |
| 14 | Nhặt quà né rác | T4 | **cam chung bám tốp** | quà +1 · quà to +3 · rác −1 (cho âm), 30 s · **làn riêng, kề nhau** | **0** |
| 15 | Fractured Faces | T5 | trên cao, khu riêng | thứ hạng hoàn thành; chưa xong thì số mảnh đúng | **0** + 1 gói cuối |
| 16 | Đếm thú | T5 | trên cao, **không render người chơi** | 5 vòng, đếm 1 loại giữa 3 loại · đúng +1 sai 0 | **0** + 1 gói/vòng |
| 17 | Rockin Rhythm | T5 | **overlay 2D, hàng ngang** | Perfect 3 · Good 1 · Miss 0 · combo ×1.5 sau 10 nốt | 1 gói/giây/người |
| 18 | Bóng chày | T5 | **overlay 2D, hàng ngang** | tâm ±40 ms **3đ** · ±100 ms **2đ** · ±180 ms **1đ** · trật 0 · 15 quả | 1 gói cuối |

## Ghi chú riêng vài trò

**Crown Capture — cướp miện phải qua ĐÒN, và miện RƠI chứ không sang tay.**

Bản cũ đúng phần khó: điểm tích luỹ theo giây giữ, master trọng tài, `_chot_ket_qua()` ghi đè để
xếp theo giây giữ chứ không theo thời gian sống. Giữ nguyên trọn phần đó.

Nhưng `Area3D` cướp nằm ngay trên quả miện, mà miện thì đội trên đầu người giữ — nên **chạy tới
chạm vào người giữ là miện sang tay mình**. Hai hệ quả, cả hai sai với trò:

- **Không có đòn nào trong một trò PvP.** Người không giữ miện chẳng có việc gì ngoài chạy tới
  đụng. Không có chặn đường, không có tranh giành.
- **Miện sang tay TỨC THÌ.** Không có khoảnh khắc miện nằm đất để mà giành; ai đến trước ăn tất.

Giờ: bắn cầu lửa trúng người đang giữ thì **miện rơi xuống đúng chỗ họ đứng**, không bay sang ai.
Ai chạy tới trước thì nhặt. Bắn vào người không giữ miện thì chỉ hất — vẫn có ích, đó là cách hẩy
đối thủ ra khỏi quả miện đang nằm đất.

Tính được từ `Player`: xung 9,0 với `DAY_TAT_DAN = 9,0` hất xa **4,5 m** trong 1,0 giây, tầm nhặt
1,9 m (tâm đến tâm), nên người bị hất cần **1,43 giây** mới về được trong khi miện mở nhặt từ
**1,10 giây** — có đúng một cửa hẹp cho người khác, và cú đòn không vô nghĩa.

**Không ai chết.** Vị trí bị kẹp trong lòng sàn: thắng thua chỉ do tổng giây đội miện, nên hất
nhau xuống vực sẽ biến nó thành nửa deathmatch. `_toi_thua()` luôn trả `false`.

**Thêm bảng điểm cả phòng.** Trước chỉ hiện điểm của người đang giữ, nên không ai biết mình thứ
mấy — và cả phần "cuối ván ai cũng xông vào người dẫn điểm" không xảy ra được.

`cau_lua` chuyển từ `minigame/magma/` sang `minigame/chung/`: giờ hai trò dùng, mà để nó nằm trong
thư mục của một trò là đúng cái bẫy vừa gặp khi xoá Snowy Spin — phải đi dò xem còn ai dùng file
của trò bị xoá.

**Explosive Exchange — người ôm bom chạy NHANH HƠN, và đó là cả trò.**

Bản cũ đã đúng kiến trúc (master giữ `_ai_om`, nạn nhân tự khai tử, đồng hồ ngắn dần 16 → 7 giây)
nhưng có một lỗ hổng không thấy được khi chơi thử đông người: **mọi người cùng `Player.speed`**.

`kiem_luat.gd` mô phỏng đuổi bắt 1v1 trên sàn tròn và đo: không boost thì bắt từ đầu này sàn sang
đầu kia mất **4,88 giây**, trong khi bom ngắn nhất 7 giây và còn mất 0,9 giây nghỉ chuyền — còn
**1,22 giây** để làm mọi việc. `TOC_OM_THEM = 1,6` hạ xuống 2,83 giây, còn **3,27 giây**.

> Lần đầu tôi viết lý lẽ là "bằng tốc thì KHÔNG BAO GIỜ bắt được". Chính mô phỏng bác lại: kẻ chạy
> trốn men theo bờ vẫn bị cắt góc. Lý lẽ đúng là **biên quá sát**, không phải bất khả. Và kẻ chạy
> trốn trong mô phỏng còn ngây thơ, nên 4,88 giây là biên DƯỚI của cái khó.

Phải trả tốc độ lại khi hết ôm và trong `dung_som()` — đúng cái bẫy `Player.truot` của Slippery
Sprint đã dính một lần.

**Ba chỗ khác đã sửa:**

| | Cũ | Mới |
|---|---|---|
| Chuyền | tự chuyền cho người gần nhất khi hết nghỉ | bấm **E**. Chạy ngang qua ai đó không còn làm mất bom |
| Tầm chuyền | `Area3D` bán kính 1,5 **trên đầu**, không ứng với gì nhìn thấy (comment bảo bằng "quầng sáng" nhưng quầng sáng là `OmniLight` tầm 6,0) | hạ xuống chân người ôm, bán kính 1,8, và vẽ `VongTam` đúng bán kính đó |
| Lúc sắp nổ | chỉ một con số đang tụt | bom phồng + nhịp nhanh dần (2 → 9 nhịp/giây), đèn 3 → 9, chữ vàng → đỏ |

**Không thêm máu.** Hai trò T1 kia dùng `ThanhMau` vì ở đó bị hất vào nham/axit xảy ra liên tục;
ở đây "ôm bom lúc nổ" là sự kiện dứt khoát và người chơi đã có cả 16 giây để tránh. Spec cũng nói
rõ: nếu demo đang loại thẳng thì giữ nguyên.

**Không cần tránh trao lại cho người vừa ôm** (§7): `_trao_cho_ai_do()` chỉ chạy khi người ôm cũ
đã CHẾT, nên `con_song` đã loại họ. Lặp lại người ôm là chuyện không xảy ra được.

**Acidic Atoll — SÁU đảo rời, tập đảo an toàn đổi mỗi chặng.**

Bản cũ là **một đảo tròn duy nhất** + mưa bom; axit chỉ là mặt phẳng trang trí ở `y = -5` và chết
là do rơi. Tức nó đang là trò né chướng ngại, không phải trò đảo — và ra khỏi đảo là chết ngay.

Giờ: bồn axit **đứng được** (có va chạm, thấp hơn mặt đảo 0,8 m) + 6 đảo đặt lên trên (1 giữa,
5 trên vành bán kính 7,5). Rơi xuống là lội trong axit, −20 máu/giây, nhảy lên đảo lại được —
0,8 m < `jump_height` 1,2 m, đây là ràng buộc cứng chứ không phải con số cho đẹp.

**Khác Magma & Mages ở đâu** (§9 của spec đòi phải khác): Magma là MỘT sân, nham ăn vào từ ngoài,
ai cũng dồn về cùng một tâm — "trụ ở giữa thế nào". Ở đây là sáu đảo rời và tập đảo an toàn **đổi
mỗi chặng** — "nhảy sang đảo nào, lúc nào". Không có chỗ nào càng-vào-giữa-càng-an-toàn.

**Cửa sổ TRƯỢT, không phải chìm dần rồi hết.** Mỗi chặng cửa sổ đảo-chìm trượt một bước trên một
thứ tự gieo từ hạt giống: một đảo nổi lên, đảo kế tiếp chìm xuống. Nên phải di chuyển LẶP LẠI
suốt ván (đo được: tập đảo an toàn đổi 7/7 chặng), chứ không dồn một lần về đảo cuối rồi đứng đó.
Số đảo chìm cùng lúc tăng dần 0 → 4, nên chỗ an toàn ít đi: `6 → 5 → 4 → 3 → 2` đảo.

Bom giữ nguyên (vòng đánh dấu + quầng nổ đúng bằng vùng sát thương) nhưng giờ **nhắm vào một đảo
còn nổi** chứ không rơi bừa khắp bồn — bom rơi xuống axit là bom vô nghĩa. Nhịp bom cuối ván nới
từ 0,5 lên 1,0 giây: áp lực chính giờ là đảo chìm, hai nguồn chồng lên nhau thì thành rối.

**Fisher-Yates với `RandomNumberGenerator`, KHÔNG dùng `Array.shuffle()`** — `shuffle()` lấy RNG
toàn cục nên mỗi máy một trạng thái và mỗi người sẽ thấy một đảo khác chìm. Cả trò dựa vào chỗ
này để khỏi gửi gói tin nào.

**Máu tách ra dùng chung.** Đây là trò thứ ba cần máu, đúng lúc comment `ponytail:` trong
`magma.gd` hẹn sẽ tách. `minigame/chung/thanh_mau.tscn` giờ giữ máu + thanh, ba trò (Spotlights,
Magma, Acidic Atoll) đều dùng; bỏ được 5 biến lặp trong mỗi script và một khối `CanvasLayer`
lặp trong mỗi `.tscn`.

**Magma & Mages — vùng an toàn co theo CHẶNG, sàn không biến mất.**

Bản cũ cho cả `SanTron` co lại: ngoài sàn là hư không, bước ra là rơi và chết ngay. Hai chỗ sai:

- **Dung nham không "ăn" sàn gì cả.** Nó là một mặt phẳng trang trí ở `y = -6`, chỉ để rơi xuống;
  sàn thì tự biến mất. Không có chặng nào để mà cảnh báo.
- **Chạm nhẹ là chết ngay.** Lùi quá đà một bước = rơi = hết. Không có chỗ cho "bị hất vào nham,
  cháy một tí, bò ra" — tức không có chỗ cho chính cái combat của trò này.

Giờ sàn giữ nguyên cỡ và **chính nó là dung nham**; hai đĩa mỏng chồng lên đánh dấu ba vùng:

| Vùng | Node | Nghĩa |
|---|---|---|
| Trong `VungAnToan` | đĩa nhạt | an toàn, và còn an toàn qua lần co tới |
| Vành giữa hai đĩa | đĩa đỏ hở ra | **CẢNH BÁO** — còn an toàn, sắp thành nham |
| Ngoài `VungBao` | mặt sàn cam | **NHAM** — đứng là mất máu |

Mốc sát thương là `ti_le_san(t) * bán_kính`, đúng bằng mép đĩa `VungBao` nhìn thấy — một công
thức cho cả hình và sát thương nên chúng không thể lệch nhau.

**Vì sao co theo chặng chứ không co đều.** Co đều từ 1,0 xuống 0,45 trong 43 giây là 0,147 m/s;
báo trước 4 giây thì vành cảnh báo rộng **0,59 m** — nhìn từ camera trên cao gần như không thấy,
và nó đọc như một vạch trôi chứ không như "khoanh này sắp mất". Co theo chặng cho vành **1,38 m**,
hở ra dứt khoát rồi biến thành nham.

Năm lần co: 11,50 → 10,12 → 8,74 → 7,36 → 5,98 → 4,60 m, xong ở giây 54, còn 21 giây đánh nhau
trong vòng nhỏ nhất. Cuối ván 8 người chia 66 m² = 8,3 m² mỗi người.

**Đòn giữ nguyên hoàn toàn** (E bắn cầu lửa, 1 gói tin một quả, mỗi máy tự áp lực đẩy lên mình).
Chỉ đổi hệ quả: trước hất xuống vực là chết luôn, giờ hất vào nham — người bị hất có 4,5 giây để
bò ra, và bò ra xa nhất mất 1,15 giây.

 Vòng lặp:

```
SÁNG HẲN 4 s  →  tối dần 1,6 s  →  TỐI HẲN 6,5 s  →  sáng dần 1,4 s  →  chu kỳ sau, +1 đèn
 (ghi nhớ         (thấy rõ          (đi theo ký ức      (nhận ra mình
 chỗ mình)       đang tắt)          + vệt đèn)           đang ở đâu)
```

Đèn chạy Lissajous nên đường đi không khép thành vòng đoán trước được — **nhớ đường đèn là vô
ích, và đó là cố ý**. Thứ phải nhớ là chỗ của chính mình; vệt đèn chỉ là mốc để định hướng.

Ba thứ bắt buộc, thiếu thì trò thành ngẫu nhiên chứ không thành khó:

- **Phải có chặng SÁNG.** Bản cũ tối từ giây 0 tới hết ván, nên không có lúc nào để mà nhớ —
  người chơi bị thả vào bóng tối và đi loạn. Cả vòng lặp trên không tồn tại.
- **Thanh máu luôn hiện trên HUD** — trong tối, đó là tín hiệu duy nhất báo "đang bị nướng".
- **Viền sàn phát sáng yếu** (`VienSan`). Là NÚM CHỈNH: càng mờ càng căng. Nó cũng là chỗ bức
  tường vô hình (`BAN_KINH_GIU`) nằm, nên tường đó không bí ẩn.

**Không chết vì rơi.** Lớp cha giết người rơi khỏi sàn, nhưng đây là trò đi trong tối không thấy
bờ — chết vì chạy quá đà là chết vì không có thông tin. `_toi_thua()` không gọi `super()`, và vị
trí bị kẹp trong bán kính 11,0.

**Hai con số bản cũ đặt sai, `kiem_luat.gd` mới bắt được:**

| | Cũ | Vì sao sai | Mới |
|---|---|---|---|
| `TAM_QUET` | 7,8 | Lissajous hai trục nên tâm đèn ra `7,8·√2` = 11,03 m, cộng vệt là 13,69 m trên sàn 11,5 — đèn rọi ra ngoài sàn. Và tốc đỉnh 6,88 m/s > `Player.speed` 6,0, đèn đuổi được người | **6,2** |
| `spot_angle` | 18° | Vệt bán kính 3,9 m; 8 đèn là ~92% sàn, hết chỗ đi | **12,5°** (vệt 2,66 m, 8 đèn = 43%) |

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
2. T1   Magma&Mages · Acidic Atoll · Explosive · Crown              (4 tro)   ✅ DA DUNG
        -> Snowy Spin DA XOA khoi tro (thu muc + muc DANH_SACH), `Player.truot` giu lai
        -> them 1 nut don, bang config 5 dong
        -> con no: chay thu NHIEU MAY. Moi kiem bang assert + nap scene, chua qua Photon that
3. T3   Bounding Blocks · Temporal Trails · Word Wars          (3 tro)   ✅ DA DUNG
        -> luoi 13x13 `chung/san_luoi.tscn` gio CHI Bounding Blocks dung
        -> Breaking Blocks co luoi 8x8 rieng (`o_vo.tscn`, o 2.8 m, dung bang code)
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
| Fractured Faces | thời điểm gắn mảnh đúng cuối cùng |
| Crown Capture · Sidestep Slope · Slippery Sprint | không cần — điểm là số thực |

## Còn để mở

- **Word Wars ghép chữ tiếng Anh.** Người giỏi tiếng Anh thắng chứ không phải người chơi giỏi.
  Đã hỏi và bạn chọn giữ nguyên — ghi lại để sau không ai tưởng là bỏ sót.
- **Slippery Sprint** chạy đường thẳng nên nó vừa thuộc T2 vừa dùng khuôn làn của T4.
- 18 trò là **kế hoạch**; 15 trò đã dựng và đã đăng ký trong `DANH_SACH`.
