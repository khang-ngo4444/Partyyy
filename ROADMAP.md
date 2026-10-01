# PartyBash — Roadmap

Party game 3D multiplayer online, Godot 4.7.1 + Photon Fusion (Shared Authority).
Đồ án 3D Programming — *Your First Multiplayer Game*.

---

> ⚠️ **TRẠNG THÁI: đang thiết kế lại.** Mục 1 dưới đây là định hướng ĐÃ CHỐT.
> Các mục 5 (roadmap phase), 6, 7 viết theo phương án cũ (marathon minigame, không bàn cờ)
> nên **chưa khớp** — sẽ viết lại sau khi layout tổng thể xong. Đừng bám theo chúng.

## 0. VIỆC CỦA BẠN

Cập nhật khi có thay đổi. Cái nào Claude làm được thì ghi rõ.

### A. Chặn tiến độ — làm sớm nhất có thể

- [x] ~~**Đăng ký Photon App ID**~~ — XONG. App tạo với SDK Fusion / Fusion 3 Core (Unreal/Godot),
      App ID đã nằm trong `project.godot`, region `asia`. `dashboard.photonengine.com` → tạo app loại
      **Fusion** → copy App ID → dán vào Project Settings > Fusion > Connection > App Id.
      Claude không tạo tài khoản hộ được.

      **PHASE 0 ĐÃ XANH** — xem mục 1f. Rủi ro lớn nhất của dự án đã bị loại.

### B. Ý tưởng cần bạn quyết

- [ ] **Q1 — bàn cờ thắng bằng cái gì?** *(câu quan trọng nhất còn lại trong cả dự án)*
      Kéo theo: độ dài ván, số ô, loại xúc xắc, minigame thưởng cái gì. Xem 3 phương án ở mục 1c.
- [ ] **Q2** — các loại ô sự kiện trên bàn cờ
- [ ] **Q3** — một ván dài bao nhiêu vòng / bao nhiêu phút
- [ ] **Q4** — danh sách minigame
- [ ] **Q5** — tên dự án (thư mục đang là `PartyBash`, chỉ là tên tạm)
- [ ] Quân caro lấy từ đâu — đề xuất: bát quân đen + bát quân trắng, bốc ra đặt

### C. Tra doc Photon Fusion

**Q6, Q7, Q8, Q9 đã có đáp án** — xem mục 1e và 1f.
**Q7, Q10, Q11, Q16 và toàn bộ phần ownership/RPC/master-migration đã có đáp án** —
xem mục 1e, 1g, 1h, 1i.

**CÒN THIẾU ĐÚNG MỘT TRANG: `Manual > Replication`** — kiểu dữ liệu nào replicate được
(đặc biệt `Dictionary`), mảng có nới sức chứa được không, và **"word count" là gì / có trần
cho mỗi object không**. Đây là trang duy nhất còn lại có thể buộc ta sửa kiến trúc
(nếu có trần cứng thì `MatchState` phải tách ra nhiều object).

Không gấp: **Q15** (rejoin theo `player_ttl_ms`), **Q17** (`AllowConfigOverride`).

### D. Asset

- [ ] **Chuyển nhạc FLAC → OGG hoặc WAV.** Godot không đọc FLAC (đã kiểm trên 4.7.1).
      WAV là lossless, không mất gì, chỉ nặng. OGG `-q:a 10` thì gần như trong suốt.
- [x] ~~Tải pack Kenney~~ — XONG, 5 pack đã nằm trong `asset/` (61 MB), ghi vào `CREDITS.md`.
- [ ] Duyệt danh sách model bên dưới, chọn nguồn cho phần "cần tìm".

**ĐÃ KIỂM MODEL NHÂN VẬT — Kenney Mini Characters, dump xương bằng Godot:**

```
7 xương: root, leg-left, leg-right, torso, arm-left, arm-right, head
```

**KHÔNG có xương bàn tay** — cánh tay là một xương duy nhất. Nhưng vẫn dùng được:
`BoneAttachment3D` vào `arm-right` + offset cố định tới đầu mút cánh tay.
**Không cần model tay riêng, không cần IK.**

32 animation có sẵn, phủ gần hết nhu cầu phòng chờ:
`holding-left/right/both` · `pick-up` · `interact-left/right` · `sit` · `crouch` ·
`idle` · `walk` · `sprint` · `jump` · `fall` · `die` · `emote-yes/no` · `attack-melee-*`

**12 nhân vật khác nhau** (male a–f, female a–f) → tối đa 10 người thì **mỗi người một model riêng**.
Gỡ được lo ngại "4 màu không đủ cho 10 người": phân biệt bằng model **cộng** màu.

Model cao **0.671 đơn vị → nhân 2.68 để ra 1.8 m**. Chỉ 2 surface nên đổi màu dễ.

**Blocky Characters đã loại và xoá** — không có skeleton nào, animation là dịch chuyển từng khối
mesh rời, `BoneAttachment3D` không dùng được.

**Còn thiếu, chưa tìm được nguồn CC0:** quân cờ vua · quân cờ tướng · con vịt · chim cánh cụt ·
robot nhỏ · rổ bóng rổ · skybox vũ trụ. Chưa cần cho lát cắt đầu tiên.

**Phần lớn danh sách này KHÔNG cần đi tìm model** — chúng là khối cơ bản cộng texture.
Chỉ khoảng 5 thứ thật sự cần model có sẵn.

| Cần tìm model | Ghi chú |
|---|---|
| Nhân vật | Kenney Mini Characters — **đã chọn** |
| Con vịt | Kenney / Quaternius có animal pack |
| Chim cánh cụt | Nếu không có, dùng con vật khác cũng được |
| Robot nhỏ | Quaternius có Animated Robot Pack |
| Bàn, ghế | Kenney Furniture Kit |

| Tự dựng bằng khối cơ bản | Cách làm |
|---|---|
| Quân caro, xu | Trụ tròn + màu |
| Ô sẵn sàng | Bệ trụ tròn dẹt + phát sáng |
| Xúc xắc 2d6 | Khối lập phương + texture chấm |
| Lá bài | Mặt phẳng + texture bộ bài (texture CC0 có nhiều) |
| Bảng phi tiêu | Trụ dẹt + texture vòng điểm; phi tiêu = hình nón nhỏ |
| Bóng rổ, rổ | Cầu + texture; rổ = vành tròn + lưới |
| Xích đu | Dây + ván |
| Cầu tuột | Ống hoặc máng |
| Bảng hướng dẫn | Mặt phẳng + chữ |
| Vòm kính | Bán cầu trong suốt |
| Đường ray cánh cụt | Thanh dài + vạch chia |
| Hành tinh | Quả cầu + texture |
| Skybox vũ trụ | Nguồn CC0 có nhiều |

**Quân cờ tướng là món khó nhất** — quân dẹt có chữ Hán, gần như không có bộ CC0.
Cách rẻ: trụ dẹt + texture chữ tự làm. Cờ vua thì ngược lại, có rất nhiều bộ CC0.

### E. Quyết vặt

- [ ] Dọn `addons/fusion/` từ 97 MB xuống ~7 MB (xoá binary macOS/Linux/Android/iOS/web)?
      *Claude làm được.*
- [ ] Tạo repo git private chưa? *Claude làm được.*
- [ ] Có duyệt việc bỏ **bảng vẽ chung** và hoãn **máy bán mũ** không (xem mục 1d)?

---

## 1. Định hướng — ĐÃ CHỐT

**Party game dạng bàn cờ.** Người chơi di chuyển trên bàn cờ như một quân cờ, tham khảo
Pummel Party. Phòng chờ tương tác được nhiều thứ, theo hướng Lunars / PEAK — không phải
một màn hình menu.

### Nguyên tắc xuyên suốt: một nhân vật, ba nơi

Model nhân vật của **bàn cờ, phòng chờ và minigame là MỘT**. Chỉ đổi kiểu camera và góc nhìn.

- Một `player.tscn`, một bộ animation, một cấu hình đồng bộ, dùng ở cả ba nơi.
- **Không scale lại nhân vật.** Giữ đúng 1.8 m ở mọi nơi. Muốn quân cờ trông nhỏ thì
  kéo camera ra xa và hạ góc — Mario Party làm vậy. Đổi scale model sẽ kéo theo tốc độ,
  độ cao nhảy, sải chân animation và chiều cao collision lệch nhau.
- **Kích thước ô cờ chiều theo nhân vật, không phải ngược lại.**

### Hai chế độ điều khiển, không phải ba

```
Di chuyển tự do   ->  phòng chờ  +  minigame     (khác nhau chỉ ở LUẬT)
Chế độ quân cờ    ->  bàn cờ                      (theo lượt, đi trên ray)
```

Phòng chờ chính là minigame với bộ luật rỗng. Làm xong phòng chờ là xong phần lớn
hạ tầng của minigame.

### Bàn cờ rẻ về mạng, đắt về nội dung

Bàn cờ theo lượt nên **không cần đồng bộ vị trí liên tục** — chỉ một RPC
`"người chơi 3 tung 5, đi từ ô 12 tới ô 17"`, mọi máy tự chạy animation. Không thể desync.

Phần đắt là nội dung: vẽ ô, xúc xắc, các loại ô sự kiện, UI lượt chơi.

### Thứ tự làm

```
phòng chờ  ->  minigame (1 cái)  ->  bàn cờ  ->  thêm minigame
```

Phòng chờ trước vì nó là nơi rẻ nhất để bắt mọi lỗi mạng — không đồng hồ, không thắng thua.
Bàn cờ sau minigame vì bàn cờ *dẫn tới* minigame; chưa có gì để dẫn tới thì chưa test đủ.

### Còn để mở

- Mục đích của bàn cờ: đi để làm gì, thắng bằng gì
- Các loại ô sự kiện
- Số vòng / độ dài một ván
- Danh sách minigame

---

## 1e. Đáp án từ quickstart chính thức

Nguồn: trang *Getting Started* của Photon Fusion Godot v3 Shared Authority.

**Q7 — tham số phòng.** Gọi trống được, không cần `FusionRoomOptions`:
```gdscript
Fusion.connect_to_photon(user_id)
Fusion.join_or_create_room()
```

**Q8 — ai spawn? MỖI CLIENT TỰ SPAWN NHÂN VẬT CỦA MÌNH.**
Bắt signal `room_joined` rồi gọi `spawner.spawn()` — chạy trên mọi client, mỗi máy tự spawn
người của mình. `FusionSpawner` gán ID mạng, gửi lệnh spawn lên cloud, cloud phát cho các
client khác tự tạo bản sao. **Người vào muộn được xử lý tự động** — server cache cả lệnh
spawn/destroy lẫn trạng thái hiện tại của mọi object mạng.
```gdscript
func _on_room_joined():
    var player = spawner.spawn()
    player.position = pos
```
Đặt vị trí **sau** khi spawn, không cần `pre_spawn_function`.

**Q9 — định dạng NodePath của replication config: `<TênNode>:<property>`.**
Ví dụ `Player:player_name`, `Asteroid:asteroid_size`. Thêm qua bảng dưới cùng của
`FusionSharedReplicator` trong editor.

**Setter của GDScript chạy cả trên máy chủ sở hữu lẫn máy remote** — dùng để phản ứng khi giá
trị được đồng bộ về:
```gdscript
var player_name: String = "":
    set(value):
        player_name = value
        $Label.text = value
```

**Root Replication Mode = `Auto`** tự đồng bộ position + rotation, **và cả velocity nếu node gốc
là RigidBody hoặc CharacterBody**. Nghĩa là `CharacterBody3D` của ta được velocity miễn phí.

**Snap Distance** = khoảng cách tối đa được nội suy, vượt thì teleport. Đơn vị: **pixel cho 2D,
unit cho 3D**. Mặc định 5.0 — quickstart bảo nâng lên 50 nhưng **đó là lời khuyên cho 2D**.
Với 3D và nhân vật cao 1.8 m thì 5 unit đã hợp lý, **đừng chép 50 vào 3D**.

**RPC** dùng lại annotation của Godot, gửi qua `Fusion.rpc()`:
```gdscript
@rpc("any_peer", "call_local")
func show_message(text: String):
    $MessageLabel.text = text

Fusion.rpc(show_message, "Hello!")
```

**Doc xác nhận đúng cảnh báo ở mục 1d:** *"RPCs fire once, and while they are reliably delivered,
they are not stored in server state buffer, so late joiners won't receive them."*
→ Trạng thái phải là property được replicate; RPC chỉ dành cho sự kiện tức thời.

**`Fusion` truy cập thẳng trong GDScript** — `Fusion.room_joined.connect(...)`,
`Fusion.get_local_player_id()`. Không cần `Engine.get_singleton()`.

**Có chế độ Local Server** (`Project Settings > Fusion > Connection > Mode`, mặc định `Cloud`,
kèm `Local Server Address`). Chưa cần, nhưng ghi lại — có thể hữu ích khi test offline.

---

## 1f. Phase 0 — ĐÃ XANH

Chạy hai tiến trình Godot headless kết nối Photon thật. Kết quả:

```
Instance A: id=1, master=true    Instance B: id=2, master=false
Cả hai vào cùng phòng "PHASE0", mỗi bên tự spawn player của mình.
Allocated Object First Seen From Remote: [2:1]   <- A thấy player của B
Allocated Object First Seen From Remote: [1:1]   <- B thấy player của A
Suốt 20 giây: mỗi máy thấy đúng 2 player — 1 của mình, 1 của người khác.
B thoát -> A nhận player_left(id=2, inactive=false) đúng ngay.
```

**Chứng minh xong cùng lúc:** SDK preview chạy trên Godot 4.7.1 · kết nối Photon Cloud ·
tạo/vào phòng · mỗi client tự spawn · quyền sở hữu phân đúng · người vào muộn nhận được object
đã spawn từ trước · thoát phòng báo đúng.

→ **Không phải rơi về ENet. Giữ nguyên Photon Fusion Shared Authority.**

**Q6 — region `asia` HỢP LỆ**, kết nối thành công với giá trị đó.

### Thông số Fusion tự báo lúc chạy

```json
{"SimulationMode":"Shared", "RoomSendRate":30, "OwnershipRequestCooldown":0.1,
 "InterestUpdateTime":0.25, "InterestSlackTime":2.0, "DefaultPriority":2,
 "AllowConfigOverride":true, "ConfigWasOverridden":true, "AllowSimulationModeOverride":true}
```

- `SimulationMode: Shared` — đúng chế độ ta chọn, không phải tự đặt thêm gì
- `RoomSendRate: 30` — 30 Hz, khỏi phải chỉnh `update_interval` vội
- **`AllowConfigOverride: true`** — Fusion CÓ SẴN cơ chế ghi đè cấu hình lúc chạy.
  Đáng tra thêm khi làm file config ngoài (mục 1d) — có thể dùng luôn thay vì tự viết.

### PHÁT HIỆN QUAN TRỌNG — sửa một quyết định cũ

`player_joined(player_id, user_id)` **chỉ điền `user_id` cho chính mình**. Nhìn từ máy khác thì
`user_id` về **rỗng**:

```
Log A:  >>> người chơi VÀO: id=1 user_id=user_1708083771   <- join của chính A
        >>> người chơi VÀO: id=2 user_id=                  <- B nhìn từ A, RỖNG
Log B:  >>> người chơi VÀO: id=2 user_id=user_779453097    <- join của chính B
        (B KHÔNG nhận player_joined của A vì A đã ở trong phòng từ trước)
```

**→ KHÔNG dùng `user_id` để mang tên người chơi.** Mục 1d trước đây ghi "tên nhập ở menu chính,
đi kèm lúc kết nối" — sai, phải sửa: **tên là một property được replicate trên chính object
player** (`Player:player_name`, đúng như Step 10 của quickstart). Vẫn nhập tên ở menu chính,
nhưng gán vào player lúc spawn chứ không gửi qua `user_id`.

**Hệ quả thứ hai:** người vào phòng **không** nhận `player_joined` cho những ai đã ở sẵn trong
phòng. Muốn biết ai đang có mặt thì đọc `Fusion.get_room()`, hoặc đơn giản là dựa vào các object
player đã được spawn (server tự phát cho người vào muộn — đã kiểm chứng ở trên).

---

## 1g. Scene object và chuyển scene

Nguồn: trang *Large Scenes* của doc Fusion Godot.

### Q10 — chuyển scene: dùng chế độ Auto

**Master client** gọi `Fusion.load_scene(scene)`, mọi client tự load. Chế độ Auto thì Fusion lo
hết — load, gắn vào cây, đăng ký scene object. Không phải xử lý `scene_load_requested`.

```gdscript
func _ready():
    Fusion.set_scene_load_mode(Fusion.SCENE_LOAD_AUTO)
    Fusion.set_scene_parent(self)
    Fusion.scene_ready.connect(func(idx): ...)

func start_game():
    Fusion.load_scene(ArenaScene)   # CHỈ master client
```

Chế độ Custom (`SCENE_LOAD_CUSTOM`) dùng khi cần màn hình loading: bắt `scene_load_requested`,
tự `instantiate()` + `add_child()`, rồi gọi `notify_scene_ready(instance, index)`. Chưa cần.

**Nhiều scene load cùng lúc được.** `load_scene()` trả về chỉ số slot; `unload_scene(index)` gỡ
đúng slot đó. → Lúc chuyển phòng chờ sang bàn cờ có thể giữ hoặc gỡ phòng chờ, tuỳ chọn sau.

### SCENE OBJECT — thay đổi cách làm toàn bộ phòng chờ

> *Any `FusionSharedReplicator` not bound by a FusionSpawner is treated as a scene object when
> `notify_scene_ready()` scans the tree.*

Vật thể **đặt sẵn trong scene** (cửa, công tắc, thang máy, đồ nhặt) **KHÔNG cần FusionSpawner**.
Chúng suy ra danh tính mạng **từ hash tên node**, nên mọi máy nhận ra nhau mà không cần lệnh spawn.

Doc nói rõ nó thiết kế cho **"dozens, hundreds, or even thousands"** node như vậy.

**Đây đúng là toàn bộ phòng chờ của ta.** Ready pad, máy đổi nhạc, công tắc, bàn cờ, cabin đua
vịt, đường ray cánh cụt, bảng phi tiêu — không cái nào sinh ra lúc chạy.

→ **Cái "khuôn chung cho vật tương tác được" ở mục 1d KHÔNG CẦN VIẾT.** Nó là: thả một
`FusionSharedReplicator` vào node, khai property cần đồng bộ ở bảng dưới cùng, đặt vào scene.
Framework lo phần còn lại. Và không phải tiết kiệm số lượng công tắc.

### ⚠️ BẪY: tên node phải duy nhất

> *Node names must be unique within the scene. Deterministic IDs are derived from node name
> hashes — duplicates cause collisions.*

Danh tính mạng đến **từ tên node**. Hai node trùng tên = hai máy hiểu nhầm nhau về cùng một vật.
Godot tự đánh số khi nhân bản (`Switch`, `Switch2`) nên bình thường ổn, nhưng **đổi tên tay hoặc
copy-paste ẩu là dính**. Cần quy ước đặt tên ngay từ đầu, ví dụ `Chess_Pawn_W1`, `Switch_Music`.

### Có thể làm đơn giản hẳn phần bàn cờ — CHƯA QUYẾT

Mục 1d chốt bàn cờ là **một mảng trạng thái ô**, vì lúc đó cho rằng mỗi quân cờ là một object
mạng riêng sẽ đắt. Với scene object thì lập luận đó yếu đi:

| | Mảng trạng thái ô (đang chốt) | Mỗi quân là một scene object |
|---|---|---|
| Code | Quản mảng + spawn/despawn quân đang cầm | Nhặt = `want_authority()`, di chuyển, nhả. Hết |
| Object mạng | 1 replicator + tối đa 4 quân đang cầm | 32 replicator đặt sẵn |
| Rủi ro | Nhiều code tự viết hơn | Phụ thuộc chi phí của replicator đứng yên |

**Q16 chặn quyết định này: một replicator đang đứng yên có tốn băng thông không?**
Nếu chỉ gửi khi có thay đổi thì cách scene object thắng rõ ràng — ít code hơn hẳn.
Tra doc, hoặc đo thẳng: đặt 50 object rồi xem chỉ số mạng.

---

## 1h. Đáp án đợt 2 — từ trang Intro, Prediction, và diễn đàn

### Q7 — tuỳ chọn phòng nhận DICTIONARY, không cần `FusionRoomOptions`

```gdscript
Fusion.connect_to_photon("player_42", "us")          # region là tham số thứ 2
Fusion.join_or_create_room("arena", {"max_players": 8})
```

→ Ta cần `{"max_players": 10}`.
→ **`region` truyền được lúc chạy**, không bị khoá trong Project Settings. Hữu ích cho file
config ngoài (mục 1d) — chỉ cần đọc config rồi truyền vào, không phụ thuộc Q17.

### Q16 — ĐÃ CÓ ĐÁP ÁN: replicator đứng yên gần như KHÔNG tốn gì

> *"Replication works at the **property level - only changed values are distributed**,
> keeping bandwidth low."*

Chỉ giá trị **thay đổi** mới được gửi đi. Object đứng yên không phát gì.
Cộng với việc doc Large Scenes nói thiết kế cho "hundreds, thousands" scene object.

**→ Khuyến nghị đổi cách làm bàn cờ** (mục 1d hiện đang chốt "một mảng trạng thái ô"):
mỗi quân cờ là một **scene object** đặt sẵn, có replicator riêng. Nhặt lên =
`want_authority()` xin quyền sở hữu con đó, di chuyển, nhả ra. Không quản mảng, không
spawn/despawn quân đang cầm. **Ít code hơn hẳn.**
*Chưa sửa mục 1d — chờ xác nhận.*

### Q11 — `PLAYER_PREDICTED` không liên quan tới ta

Nó thuộc **Client-Server**: bật luồng prediction, dùng với `set_input_authority()`,
`queue_input()`, `process_input_queue()`. Ta dùng Shared-Authority → **bỏ qua hoàn toàn**.

Còn `PLAYER_ATTACHED` chính là hành vi **"Destroy when state authority leaves"** mà diễn đàn
Fusion nhắc tới. Nếu KHÔNG bật, object của người thoát sẽ **ở lại phòng vĩnh viễn**.

**Đã quan sát được điều này trong test Phase 0:** owner_mode để mặc định (`Transaction`),
B thoát rồi mà A vẫn đếm đủ 2 player. Object của B không tự biến mất.

**Diễn đàn còn cảnh báo một lỗi cụ thể** (*"Despawn orphan players in Fusion shared mode"*):
người rớt mạng rồi vào lại sẽ có **hai instance** — một cái vừa spawn, một cái cũ với state
authority = None. Cách chữa đúng là bật "destroy when state authority leaves".

### ⚠️ HỆ QUẢ KIẾN TRÚC — điểm số KHÔNG được lưu trên object player

Nếu object player bị huỷ khi chủ rời phòng (mà ta cần vậy để tránh lỗi orphan), thì **mọi thứ
phải sống sót qua việc người chơi thoát đều không được nằm trên object đó**: điểm, slot, trạng
thái "đã thoát", màu, tên.

→ Chúng nằm trong **`MatchState` do master client sở hữu**, đánh chỉ số theo player id.
Object player chỉ giữ thứ chết cùng nó: vị trí, hướng, animation.

Điều này **xác nhận kiến trúc ở mục 2 là bắt buộc**, không phải một lựa chọn.
Và nó khớp với thiết kế "chừa chỗ trống khi có người thoát" ở mục 1d — chỗ trống đó là một ô
trong `MatchState`, không phải một object player còn sót lại.

### `pre_spawn_function` dùng để làm gì

> *"Pass a `pre_spawn_function` callback to `spawner.spawn()` to assign authority **before the
> spawned scene's `_ready()` runs**, so the assignment is observable in `_ready()`."*

→ Dùng để đặt **tên và màu** người chơi, để `_ready()` của player đọc được ngay.
Khác với quickstart (đặt `position` **sau** khi spawn) — position không cần có mặt lúc `_ready()`.

### Công cụ: Network Inspector

**Debugger > Fusion Network** — xem **băng thông từng object, RTT, quyền sở hữu, word count**
theo thời gian thực. Dùng cái này để đo thay vì đoán.

### Forecast physics — dành cho quả bóng rổ

RigidBody 2D/3D có **forecast prediction**: ngoại suy vị trí từ vận tốc + trọng lực đã biết, rồi
chỉnh dần khi gói tin mới tới. Stiffness, damping, ngưỡng teleport đều chỉnh được trong inspector.
→ Đúng thứ quả bóng rổ (món vật lý duy nhất của phòng chờ) cần.

### RPC — ba kiểu đích, hai kiểu định tuyến

- Đích: **tất cả** · **vai trò trên object đó** (master client hoặc owner) · **một player id**
- Định tuyến: **object-targeted** (đi qua replicator của một object cụ thể) ·
  **broadcast** (tới mọi node đã `register_broadcast_receiver`)

Khớp với enum đọc được từ binary: `All=0, Master=-1, Plugin=-2, Owner=-3`.

### Xác nhận lại Q8

> *"Any client can spawn a NetworkObject. Spawning a NetworkObject automatically assigns
> StateAuthority over it to the client."*
> *"Scene objects do not need to be spawned, they are automatically spawned when the scene is loaded."*

---

## 1i. Ownership, RPC, master migration

### `owner_mode` — bảng phân quyền cho toàn bộ dự án

| Giá trị | Nghĩa | Dùng cho |
|---|---|---|
| `DYNAMIC` | **Ai nhanh tay người đó được.** Photon cấp quyền ngay nếu vật đang trống, theo thứ tự đến trước, không hỏi ai | Quân cờ · lá bài · xúc xắc · phi tiêu · bóng rổ |
| `TRANSACTION` | **Cần phê duyệt.** Kích hoạt `authority_requested` trên máy đang giữ quyền; phải `return true` mới chuyển | **Ta KHÔNG dùng** — nó để kiểm tra "có đúng lượt không", mà ta cố ý không làm luật cờ |
| `MASTER_CLIENT` | **Độc quyền master.** Client khác gọi `want_authority()` là bị từ chối tự động | MatchState · ô sẵn sàng · máy nhạc · công tắc · bảng điểm |
| `PLAYER_ATTACHED` | Chết theo chủ khi chủ rời phòng | Nhân vật người chơi |
| `PLAYER_PREDICTED` | Chỉ dành cho Client-Server | Không liên quan |

**Scene object khi chưa ai đụng vào thì Master Client sở hữu** (mặc định lúc scene được load).

### Master client đổi giữa chừng — MatchState AN TOÀN

Object có `owner_mode = MASTER_CLIENT` **KHÔNG chết theo master cũ**. Photon bầu master mới và
quyền sở hữu **tự động chuyển sang** người kế nhiệm, giữ nguyên trạng thái.

→ Đây là câu quan trọng nhất trong đợt hỏi này. `MatchState` sống sót qua việc master thoát.

### `want_authority()` BẤT ĐỒNG BỘ — phải chờ

**Không được "xin xong dùng luôn".** Di chuyển vật ngay khi vừa gọi `want_authority()` thì toạ độ
local sẽ bị ghi đè và **giật ngược về chỗ cũ**, vì Photon chưa xác nhận. Chỉ được động vào sau
khi nhận `authority_response(true)`.

Độ trễ ≈ nửa RTT (~30–60 ms với region asia) — không ai nhận ra khi nhặt quân cờ.

**Cần một trạng thái "đang xin" ở phía local** để bấm hai lần không gửi hai yêu cầu.
Khớp với `OwnershipRequestCooldown: 0.1` mà Fusion tự in ra lúc chạy — không spam nhanh hơn
10 lần/giây được.

### `register_broadcast_receiver()` dùng khi nào

Khi muốn nghe gói tin broadcast ở **tầng phòng**, không đi qua một networked object nào cả.
Ví dụ: **chat tổng** trong phòng chờ, hoặc tín hiệu heartbeat/ping giữa người chơi.

### ⚠️ HAI CHỖ CHƯA XÁC MINH — đừng chép nguyên

**1. Cơ chế `authority_requested`.** Có nguồn nói phải override hàm ảo vì signal Godot không trả
về giá trị được. Nhưng binary cho thấy `authority_requested` **là một signal thật**, và wrapper C#
của SDK ghi:

> *"Fires on the owner when another client requests authority. The handler decides whether to
> grant it: return true to accept. (Native walks the connections and grants if any returns true.)"*

→ Nhiều khả năng: vẫn là signal, nhưng native **duyệt danh sách callable đã connect, gọi từng cái
và đọc giá trị trả về** thay vì `emit_signal`. Không ảnh hưởng tới ta vì ta không dùng
`TRANSACTION`. Nếu cần thì thử: connect một callable trả về bool rồi xem có được tôn trọng không.

**2. Cú pháp RPC gửi cho owner.** Có nguồn viết
`Fusion.rpc_to(owner_id, "apply_knockback", [force_vector])`. Binary báo khác:

```
rpc_to(target: int, callable: Callable, ...args)
```

Nhận **Callable** chứ không phải chuỗi tên hàm, tham số **rải ra** chứ không gói trong Array.
Và enum đích có sẵn hằng số **`OWNER = -3`** → không cần lấy `owner_id` rồi truyền vào,
truyền thẳng `-3`. **Tự thử được lúc làm knockback, không cần tra doc.**

---

## 1j. Luật mạng — đọc lại trước khi viết bất kỳ object mới nào

### Điều lớn nhất: cùng một script chạy trên MỌI máy

`player.gd` không chạy trên "máy của player" — nó chạy trên tất cả các máy, cùng lúc, cho mọi
người chơi. Máy bạn đang chạy 10 bản `player.gd`: một cho bạn, chín cho người khác.

Mỗi hàm phải trả lời được: **máy nào đang chạy dòng này?**

| Vai | Kiểm tra | Được làm gì |
|---|---|---|
| Chủ sở hữu | `replicator.has_authority()` | Ghi trạng thái object đó |
| Master client | `Fusion.is_master_client()` | Ghi trạng thái thế giới chung |
| Bản sao | không phải hai cái trên | Chỉ đọc, chỉ hiển thị |

> *"remote clients should not write to objects they do not own, as this would not be propagated
> anyway"* — quickstart Step 8

Ghi nhầm vai thì **không lỗi, không cảnh báo** — giá trị bị ghi đè âm thầm ở lần đồng bộ sau.
Loại bug tốn thời gian nhất.

### Năm câu phải trả lời trước khi viết object mới

1. **Ai sở hữu?** Chọn `owner_mode` trước khi viết dòng đầu tiên (bảng ở mục 1i).
2. **Trạng thái hay sự kiện?** Property replicate (người vào muộn nhận được) vs RPC
   (bắn một lần, người vào muộn **mất vĩnh viễn**).
3. **Người vào muộn thấy gì?** Server cache spawn/despawn + trạng thái hiện tại của mọi object
   mạng. Đã kiểm chứng ở Phase 0.
4. **Object chết khi nào?** `PLAYER_ATTACHED` chết theo chủ → **không để thứ cần sống lâu hơn
   người chơi nằm trên object của họ**.
5. **Ai được phép gọi hàm này?** Mở đầu bằng cổng chặn, hoặc chấp nhận nó chạy vô nghĩa trên
   chín máy khác.

### Bốn cái bẫy đã xác nhận

- **Ngẫu nhiên không tự chia sẻ.** Một máy quyết, gửi con số, máy khác KHÔNG tính lại.
- **`want_authority()` bất đồng bộ.** Động vào vật trước khi nhận `authority_response(true)` thì
  toạ độ local bị ghi đè và giật ngược. Cần cờ "đang xin"; `OwnershipRequestCooldown: 0.1`.
- **Biến local không sống sót qua việc mất quyền.** Chỉ property replicate mới được khôi phục.
  → Đồng hồ đếm ngược phải là **property**, không phải `var timer` trong script của master.
  Master cũ thoát thì master mới không có biến local đó.
- **Tên node là danh tính mạng** của scene object. Trùng tên = hai máy hiểu nhầm về cùng một vật.

### Ngân sách

| | |
|---|---|
| Nhịp gửi | 30 Hz (`RoomSendRate: 30`) |
| Gửi cái gì | **Chỉ giá trị thay đổi**, ở mức từng property. Object đứng yên không phát gì |
| Số người tối đa | `{"max_players": 10}` lúc tạo phòng |
| Trần mỗi object | **CHƯA BIẾT** — cột "word count". Câu hỏi cuối cùng còn treo |

### Quy trình

- **Mọi thứ phải test bằng 2 instance.** Một instance không bao giờ lộ lỗi phân quyền — nó luôn
  là chủ của mọi thứ nó tạo ra.
- **Không có server để tin.** Shared authority = client nào cũng nói dối được. Chơi với bạn bè
  thì không sao, nhưng là lựa chọn có ý thức → viết vào báo cáo mục 13A.

---

## 1k. Bẫy gặp khi code — ghi lại để khỏi dính lần hai

### `create_room()` / `join_room()` KHÔNG nhận Dictionary

Doc trang Intro viết `Fusion.join_or_create_room("arena", {"max_players": 8})`.
Nhưng `create_room()` và `join_room()` thì **đòi đúng kiểu `FusionRoomOptions`**:

```
Parse Error: argument 2 should be "FusionRoomOptions" but is "Dictionary"
```

Cách đúng:
```gdscript
var opts := FusionRoomOptions.new()
opts.set_max_players(10)
opts.set_is_open(true)
opts.set_is_visible(true)
Fusion.create_room(ten_phong, opts)

Fusion.join_room(ten_phong, null)   # null chấp nhận được
```

Setter có: `set_max_players` · `set_is_open` · `set_is_visible` · `set_player_ttl_ms` ·
`set_empty_room_ttl_ms` · `set_custom_properties` · `set_lobby_name` · `set_lobby_properties` ·
`set_plugins`.

### ⚠️ KHÔNG gọi `connect_to_photon()` trong `_ready()`

Triệu chứng: không kết nối, **không báo lỗi gì**, signal `connected_to_photon` không bao giờ bắn.
Dấu vết duy nhất là một dòng tưởng như vô hại:

```
ERROR: Parent node is busy setting up children, `add_child()` failed.
```

Fusion tự `add_child` một node dịch vụ khi bắt đầu kết nối. Gọi trong `_ready()` thì cây scene
đang dựng dở → `add_child` thất bại → Fusion không có vòng lặp xử lý → im lặng chết.

Đã sửa **bên trong `NetManager.connect_to_photon()`** (hoãn một frame bằng
`await get_tree().process_frame`) để không caller nào dính lại.

*Phase 0 chạy được là do may: lúc đó có `await` một timer trước khi kết nối.*

### `FusionRoom.get_players()` — cách biết ai đã ở sẵn trong phòng

`player_joined` chỉ bắn cho người vào **sau** mình. Muốn biết ai đang có mặt thì đọc
`Fusion.get_room().get_players()` → Array các id. Đã kiểm chứng chạy đúng.

`FusionRoomListing` có: `get_name()` · `get_player_count()` · `get_max_players()` ·
`get_is_open()` · `get_custom_properties()`.

---

## 1m. Tien do code

### Lat cat 1 — ket noi + menu  DA TEST XANH

`autoload/net_manager.gd` · `main.tscn/.gd` · `ui/main_menu.tscn/.gd` · `ui/hud.tscn/.gd`

Test 2 tien trinh headless voi Photon that: host tao phong -> join thay phong trong danh sach
(`AutoHOST 1/10`) -> bam vao -> ca hai deu thay 2 nguoi suot 24 giay.
`max_players = 10` an dung, `peers_in_room()` doc duoc ca nguoi vao truoc.

### Lat cat 2 — player + camera + san  DA TEST XANH (phan tu dong)

`player/player.tscn/.gd` · `player/camera_rig.tscn/.gd` · `lobby/lobby.tscn/.gd`

```
HOST  player=2 (cua toi=1)  camera_active=1  TOI(0.0,9.0), khac(5.3,7.3)
JOIN  player=2 (cua toi=1)  camera_active=1  TOI(5.3,7.3), khac(0.0,9.0)
```

Moi may thay dung 2 player, dung 1 cai la cua minh, dung 1 camera active
(camera cua player remote da bi `queue_free()`).
**Vi tri spawn replicate dung** — may nay thay may kia o dung diem spawn cua no.
Xac nhan cach cua quickstart: dat `global_transform` SAU khi `spawn()` van replicate binh thuong.

Chua test duoc bang headless: **di chuyen that, xoay chuot, cam giac dieu khien** — can chay GUI.

### Chua lam: dong bo TEN va MAU nguoi choi

Bi chan boi trang doc `Manual > Replication` (custom property). Chua ro:
`Dictionary` co replicate duoc khong, mang co noi suc chua duoc khong, va **"word count" co tran
cho moi object khong**. Xem muc 1c.

Ky thuat: `FusionReplicationConfig.add_property(NodePath)` voi dinh dang `Player:player_name`,
nhung chua ro cach gan config nay tu code hay tu .tscn cho dung thoi diem.

---

## 1n. CUSTOM PROPERTY — hai loi chong nhau, ca hai hong IM LANG

Da giai xong bang thuc nghiem. Ghi that ky vi ca hai deu khong bao loi gi khi chay game.

### Loi 1 — duong dan tinh TUONG DOI voi `root_path`

```gdscript
root_path = NodePath("..")          # tro thang vao node Player

":player_name"          DUNG   <- property nam ngay tren root_path
"Player:player_name"    SAI    <- Fusion di tim NODE CON ten "Player"
```

O Path trong panel goi y dung dinh dang: `:property`.

Anh `Asteroid:asteroid_size` trong doc la truong hop khac — o do `root_path` tro vao node
**cha**, con `Asteroid` la node con.

Panel co bao loi: dong chu **do cam kem dau cham than**. Nhung **chay game thi khong bao gi**.

### Loi 2 — property BAT BUOC phai co `@export`

```gdscript
@export var player_name: String = "":     # DUNG
var player_name: String = "":             # SAI - Fusion khong thay
```

Bien script thuan thi Fusion khong nhin thay -> **`Words: 0`** trong panel, khong cap o nao
trong state buffer, khong loi, khong canh bao. Gia tri chi nam trong bien local roi mat.

**Quickstart Step 10 viet vi du bang `var` thuan, khong co `@export`** — doc thieu cho nay.

### Cach kiem nhanh: cot `Words` trong panel

`Words: 0` = **KHONG CO GI duoc dong bo**. Do la den bao. Them property xong ma Words van 0
thi chua chay, du dong chu khong con do.

### `element_type` chi co nghia voi MANG

Sau khi sua xong, file `.tres` van co `element_type = 0` (TYPE_NIL) ma van replicate binh thuong.
Editor cung tu ghi de ve 0 khi luu. -> Voi property thuong khong can dat;
`set_property_element_type()` chi dung cho `add_array_property()`.

### SUA LAI: ket luan "config khong dung duoc luc chay" CHUA CHAC DUNG

Luc thu cach `_enter_tree()` thi van con dinh CA HAI loi tren (sai duong dan + thieu `@export`),
nen khong the ket luan rieng ve thoi diem. Doc Fusion noi `_enter_tree()` la thoi diem hop le
va kip truoc khi replicator dang ky.

**Chua kiem lai** vi cach `.tres` trong scene dang chay tot va khai bao trong scene thi doc ro
hon. Neu sau nay can dung config bang code (vi du sinh hang loat object giong nhau) thi thu lai
— rat co the chay duoc.

### `set_property_interpolate()` — lam muot custom property tren may remote

| Gia tri | Dung cho |
|---|---|
| `None` (0) | Diem, pha, id, co san sang — thu khong chuyen dong lien tuc. **Dang dung cai nay** |
| `Lerp` (1) | Gia tri bien thien lien tuc: thanh mau, thanh nang luong |
| `Angle` (2) | **BAT BUOC** cho goc quay. `Lerp` se lam vat quay nguoc ca vong khi di tu 355 sang 5 do |

Hien chua can doi gi: ta khong replicate goc quay dang custom property (root Auto lo phan do).

### Bon huong da thu va THAT BAI (truoc khi tim ra hai loi tren)

| Cach | Ket qua |
|---|---|
| Dung config bang code trong `_enter_tree()` roi gan vao `replication_config` | Khong replicate |
| Luu config thanh `.tres`, cam vao scene bang `ExtResource` | Khong replicate |
| Ghi gia tri sau signal `spawned` thay vi trong `_ready()` | Khong replicate |
| Dat `element_type` tuong minh (TYPE_STRING / TYPE_INT) | Khong replicate |

Bon cai deu that bai vi hai loi that nam cho khac. **Config dung duoc ca hai cach** —
dung code roi `ResourceSaver.save()` ra `.tres`, hoac them qua panel — mien la path va
`@export` dung.

### Dinh dang `.tres` (viet tay duoc)

```
[gd_resource type="FusionReplicationConfig" format=3]

[resource]
property_count = 2
properties/0/path = NodePath(":player_name")
properties/0/max_array_capacity = 0
properties/0/interface_tag = ""
properties/0/interpolate = 0
properties/0/element_type = 0
properties/0/element_class_name = ""
```

---

## 1o. Hai bay nua khi lap model

### Fusion ghi gia tri replicate NGUOC VE ca cho chu so huu

Setter cua property replicate **ban lai sau `_ready()`**, ke ca tren may dat gia tri do.
Neu setter dung lai thu gi (o day: nap lai model) thi no chay HAI LAN.

Trieu chung gap phai: `_apply_model()` chay 2 lan -> `AnimationPlayer` moi -> nhung bien
`_playing` con giu ten animation cu -> `_process` tuong dang phat dung roi -> **khong bao gio
goi `play()` tren AnimationPlayer moi** -> animation dung im.

Ve sau se bieu hien thanh *"animation thinh thoang dung im"* va rat kho lan.

**Cach chua — hai phan, thieu phan nao cung sai:**
```gdscript
func _apply_model() -> void:
    if _loaded_model == model_index and _anim != null:
        return          # 1. khong dung lai neu khong doi
    _loaded_model = model_index
    _playing = ""       # 2. reset trang thai dan xuat khi CO dung lai
```

### glTF import vao Godot mac dinh KHONG lap animation

`idle` chay dung mot luot roi dung, `current_animation` ve rong. Khong loi, khong canh bao.

```gdscript
for a in ["idle", "walk", "sprint", "fall", "crouch", "sit"]:
    if _anim.has_animation(a):
        _anim.get_animation(a).loop_mode = Animation.LOOP_LINEAR
```

`jump` va `pick-up` de nguyen khong lap — chung la animation mot phat.

**Da dinh bay nay HAI LAN** (lan hai voi `holding-right`). Quy tac: **bat ky animation nao dung
lam TRANG THAI — thu se giu nguyen cho toi khi doi trang thai khac — deu phai cho vao danh sach
lap.** Chi animation mot phat moi de nguyen.

### Animation KHONG can dong bo

Moi may tu suy ra tu `velocity`, ma `velocity` thi Auto replication da gui san cho
`CharacterBody`. Bot mot property phai truyen qua mang.

```gdscript
func _pick_anim() -> String:
    if absf(velocity.y) > 1.0 and not is_on_floor():
        return "jump" if velocity.y > 0.0 else "fall"
    return "sprint" if Vector2(velocity.x, velocity.z).length() > 0.3 else "idle"
```

### Editor va Claude ghi de len nhau

Khi mo project trong Godot editor thi:
- Editor ghi lai `.tscn` (them `uid`, `unique_id`, `process_priority`, bo thuoc tinh mac dinh)
  -> cac phep thay the chuoi cua Claude co the truot mot nua va lam **hong file**
- Editor ghi de `element_type` trong `.tres` ve 0
- Chay headless cung luc bi loi `Failed to open '~libfusion...dll'` (DLL dang bi editor giu)

-> **Dong editor khi Claude dang sua scene, va nguoc lai.**

---

## 1p. Lat cat 3 — o san sang + MatchState  DA TEST XANH

`lobby/objects/ready_pad.tscn/.gd` · `net/match_state.tscn/.gd`

```
pha=0 (cho)  ->  pha=1 dem=2.7 -> 0.2  ->  pha=2 vong=1
Ca hai may doc ra CUNG mot pha, cung mot so dem, cung mot vong
```

### Cach chia trach nhiem da chay dung

- **O san sang chi la CONG TAC VAT LY.** No khong luu trang thai, khong quyet dinh khi nao
  bat dau. O ton tai tren moi may (nam trong `lobby.tscn` ma may nao cung tu nap), va moi may
  **chi phan ung voi player cua chinh no**.
- **Nguoi choi TU bat `is_ready` cua minh** — ho so huu object do nen khong co tranh chap quyen.
- **`MatchState` (master, `owner_mode = 3`) dem so nguoi san sang va chay dong ho.**
  Dem bang cach quet `get_nodes_in_group("players")` — khong can dong bo danh sach nao.

### Dong ho dem nguoc PHAI la property replicate

Khong duoc la `var timer` trong script cua master. Master doi giua chung thi object
`MASTER_CLIENT` tu chuyen chu — **nhung bien local khong sang theo**. La property thi master moi
doc tiep dung cho cu.

### Diem SONG vs diem LUU TRU

`score` nam tren player (ho tu ghi). Nhung object player la `PLAYER_ATTACHED` -> **chet theo chu**.
Nen khi ai do thoat, master phai **chep diem sang `MatchState`**. Diem song thi phan tan,
diem luu tru thi tap trung.

### Bay: danh sach phong khong tu lam moi

Photon chi day `room_list_updated` khi no muon. Nguoi mo menu TRUOC luc ai do tao phong co the
ngoi nhin danh sach rong mai. Da bat gap dung tinh huong nay trong test.

-> `NetManager` co `Timer` doc lai ban cache moi **1.5 giay** roi phat lai signal.

### ⚠️ Loi tu gay hai lan: quen `script = ExtResource(...)` tren node goc cua .tscn

Khai `[ext_resource type="Script" ...]` roi ma khong gan vao node goc thi scene chay **khong
loi gi ca** — chi la khong co hanh vi nao. Lan dau o `player.tscn`, lan hai o `ready_pad.tscn`.

**Khi viet tay `.tscn`, kiem lai dong `script = ExtResource(...)` ngay duoi `[node name=... ]`
cua node goc.**

---

## 1q. BON LOI IM LANG da gap — checklist bat buoc

Bon lan lien tiep gap loi **khong bao gi ca, chi la khong co hanh vi nao**. Doc lai muc nay
truoc khi ngoi debug "sao no khong chay".

### 1. Quen `script = ExtResource(...)` tren node goc cua .tscn

Khai `[ext_resource type="Script" ...]` roi ma khong gan vao node goc -> scene chay khong loi,
chi la khong lam gi. Da tu gay 2 lan (`player.tscn`, `ready_pad.tscn`).

### 2. `@export var x: Node3D` viet tay vao .tscn thi VE NULL

```gdscript
@export var body: Node3D          # SAI khi viet tay .tscn
```
```
body = NodePath("..")             # Godot KHONG phan giai thanh Node3D
```

Kieu Node export chi phan giai khi gan bang **node-picker trong editor**. Viet tay thi no null.

**Trieu chung that gap:** camera cui/nguoc duoc (pitch ap len chinh no) nhung **khong xoay ngang
duoc** (yaw ap len `body` dang null), va code co `if body != null:` nen bo qua im lang.

**Cach dung:**
```gdscript
@export var body_path: NodePath = ^".."
var _body: Node3D

func _ready() -> void:
    _body = get_node_or_null(body_path) as Node3D
    if _body == null:
        push_error("...")          # KEU LEN, dung bo qua
```

### 3. Property replicate thieu `@export` -> `Words: 0`

Xem muc 1n.

### 4. Duong dan property sai (`Node:prop` thay vi `:prop`)

Xem muc 1n. Panel co bao do, nhung chay game thi khong.

---

### Quy tac rut ra

> **Dung viet `if x != null: ...` cho thu le ra phai luon ton tai.**
> Kiem o `_ready()` va `push_error()` neu thieu. Bo qua im lang bien mot loi 1 phut
> thanh mot buoi debug.

---

## 1r. PHONG CU CON SOT — thu phai kiem DAU TIEN khi replication co van de

### Trieu chung

4 object `Pickable` do master spawn **khong bao gio sang may kia**. Host van thay du 4,
joiner thay 0. Khong loi, khong canh bao.

Ba gia thuyet deu SAI (mat 3 lan chay de loai):

| Da thu | Ket qua |
|---|---|
| `owner_mode` 2 (DYNAMIC) -> 0 (TRANSACTION) | Van hong |
| Gian 4 lan spawn ra moi frame mot cai | Van hong |
| Bo `root_replication_mode = 1` khoi Node3D tran | Van hong |

### Nguyen nhan that: HAI MAY O HAI PHONG KHAC NHAU

**Photon giu phong RONG song tiep** sau khi moi nguoi thoat (`EmptyRoomTtl`). Cac phong tu
nhung lan test truoc van nam trong danh sach, va joiner chon `rooms[0]` bua nen vao nham
mot phong cu — trong do con **cache object cua lan chay truoc** (dung 2 cai, giong het so
luong "dung" nen rat de tuong la binh thuong).

**Dau vet le ra phai de y som:**
```
[Fusion Godot] OnPlayerJoined: player=4      <- phong nay da co 3 nguoi truoc do
HOST nhan object remote: 0                   <- host khong nhan duoc GI CA, ke ca player kia
```

Host nhan 0 la manh moi quyet dinh: neu chi rieng `Pickable` hong thi host van phai thay
player cua joiner.

### Cach chua — trong game

```gdscript
opts.set_empty_room_ttl_ms(0)     # phong bien mat ngay khi nguoi cuoi cung roi di
```

Khong tat thi danh sach phong day cac phong ma cua nhung lan choi truoc, va nguoi choi that
cung se bam vao mot phong rong.

### Quy tac debug rut ra

> **Replication co van de kho hieu -> viec DAU TIEN la xac minh hai may co thuc su o cung mot
> phong khong.** Dem so object remote moi may nhan duoc. Neu mot ben nhan 0 thi dung dao
> `owner_mode` hay config lam gi.

---

## 1s. Co che nhat do — DA TEST XANH

`lobby/objects/pickable.tscn/.gd` — khuon chung cho quan co, la bai, xuc xac, phi tieu.

```
HOST  cam vat o (0.0, 1.4, 9.9)   = dung diem cam tren tay
JOIN  thay vat o (0.0, 1.3, 9.8)  = cung cho, lech chut do noi suy
holder_id sang duoc ca hai may, ca 4 vat deu replicate
```

### `want_authority()` KHONG phan hoi neu da so huu san

Vat do chinh minh spawn ra thi minh da co quyen -> `want_authority(true)` khong co gi de cap,
`authority_response` **khong bao gio ban**, va code cho mai.

```gdscript
if sync.has_authority():
    holder_id = NetManager.local_id()    # cap luon
    return
_pending = true
sync.want_authority(true)                 # chi xin khi that su chua co
```

### Khong luu bien `_carried` tren player

Suy ra tu `holder_id` da replicate. Mot nguon su that duy nhat, va khong the lech voi thu ma
may khac dang thay.

### Chi may dang cam moi ghi vi tri

```gdscript
func _process(_delta):
    if holder_id == 0 or not sync.has_authority():
        return
    global_transform = _find_hold_point(holder_id).global_transform
```
May khac nhan vi tri qua replication nhu moi vat the khac.

### `get_room_list()` bao loi khi dang o trong phong

`Must be connected to a master server to get the room list.` — timer lam moi danh sach phai
bo qua khi `Fusion.is_in_room()`.

---

## 1t. Canh tay goc nhin thu nhat

Vat dang cam ma khong co tay thi no lo lung. Them mot khoi hop don gian lam canh tay.

### Diem cam phai gan vao CAMERA, khong gan vao than

Ban dau `HoldPoint` la con cua `Player` -> nhin len nhin xuong thi vat dung yen o tam nguc.
Chuyen no vao `CameraRig` thi vat bam theo huong nhin — do moi ra cam giac dang cam.

**He qua ky thuat:** `CameraRig` bi `queue_free()` tren may khac, nen `player.hold_point` la
`null` o do. Khong sao — **chi may dang cam moi ghi vi tri vat**, va tren may do thi rig ton tai.
May khac nhan vi tri qua replication.

### Tay chi hien khi dang cam

Mot canh tay lo lung suot ngay thi ky hon la khong co. `rig.set_holding(carried() != null)`.

Tay duoc to mau nguoi choi — gan nhu mien phi, va giup nhan ra mau cua minh trong goc nhin thu nhat.

### Nguoi khac thay gi

Nhan vat chay animation `holding-right` cua Kenney. Vat nam o vi tri do camera nguoi cam quyet
dinh (co ca goc cui/nguoc), con tay nhan vat thi khong bam theo goc do — hoi lech nhung doc duoc,
va du cho mot party game.

*Muon khop chinh xac thi phai lam viewmodel rieng: vat mang la mot ban sao local truoc camera,
con vat mang thi gan vao xuong tay bang `BoneAttachment3D`. Dat hon nhieu, chua can.*

---

## 1u. Nem do — DA TEST XANH

### Don gian hoa so voi thiet ke ban dau

Muc 1d chot "tinh san cung bay roi gui MOT RPC" de **ne viec truyen vi tri lien tuc**.
Nhin lai thi lap luan do **sai**: vat dang cam **von da** truyen vi tri 30 lan/giay qua root Auto.

-> Nguoi nem cu tu chay cung bay, moi may nhan qua replication nhu moi vat khac.
**Khong can RPC nao.** It code hon han, va cung bay chi keo dai 0.75 giay.

```
host  dang cam (-0.3, 1.4, 9.8)  ->  nem  ->  dap (-0.3, 0.6, 3.0)
join  t+1: (-0.3, 0.9, 3.7)      <- bat duoc vat DANG GIUA CUNG BAY
      t+2: (-0.3, 0.6, 3.0)      <- roi dung dung cung mot cho
```

### Van KHONG dung vat ly

Cung bay la mot duong cong tinh san (`lerp` + `sin(t*PI)` lam do cao). Dap xuong la **nam im**,
khong lan, khong troi, khong rung. Dung nhu da chot cho quan co.

### "Tha" va "nem" la CUNG MOT hanh dong

Diem dap = `vi_tri_cam + huong_nhin * throw_power`. **Nhin xuong dat thi vat roi ngay chan** —
tu nhien thanh dong tac tha, khong can day nguoi choi hai phim.

### Kep vao trong san, roi do mat dat bang raycast

```gdscript
# 1. kep ban kinh -> khong bao gio bay ra ngoai vu tru
# 2. raycast tu tren xuong -> dap dung len mat san HOAC mat be
```
Da kiem chung: nem vao vung be san sang thi vat nam **tren mat be** (y = 0.4 + 0.16),
khong xuyen qua.

### Tha quyen so huu ngay khi dap

`sync.want_authority(false)` -> nguoi khac nhat duoc ngay.

### ⚠️ `authority_response` KHONG DANG TIN — phai theo doi `has_authority()`

Trieu chung: nem xong roi **khong nhat lai duoc nua**, vinh vien.

```
[sau khi nem]   holder=0  has_authority=FALSE  _pending=false
[nhat LAN HAI]  holder=0  has_authority=TRUE   _pending=TRUE   <- ket
```

Quyen **DA duoc cap** (`has_authority` chuyen sang true) nhung signal `authority_response`
**khong he ban**. `_pending` ket o `true` vinh vien -> `holder_id` khong bao gio duoc gan ->
vat thanh bat kha nhat.

**Cach dung:** coi signal la duong nhanh, con duong chac chan la nhin thang vao `has_authority()`
moi frame, kem timeout.

```gdscript
func _process(delta):
    if _pending:
        if sync.has_authority():
            _pending = false
            holder_id = NetManager.local_id()
        else:
            _wait += delta
            if _wait >= REQUEST_TIMEOUT:      # xin khong duoc thi thoi
                _pending = false
                sync.want_authority(false)
        return
    ...
```

Cong voi phat hien truoc do (**`want_authority()` khong phan hoi neu da so huu san**), quy tac
chung la: **dung dieu khien luong bang signal cua Fusion. Hoi trang thai.**

### Chuyen quyen giua hai may — DA TEST XANH

```
host cam:   holder=1   host auth=true    join auth=false
da nem:     holder=0   ca hai auth=false
join nhat:  holder=2   host auth=false   join auth=TRUE
```

### Tam voi phai do tu CAMERA, khong do tu diem cam

Diem cam dong dua theo goc nhin -> do tu no thi chi can nguoc len mot chut la vat duoi chan
bong "ngoai tam". Do tu camera, va trong tam voi thi chon vat **nam giua tam nhin nhat**
(`look.dot(huong_toi_vat)` lon nhat) — de giua dong quan co con lay dung con dang nhin.

---

## 1v. Cache class toan cuc bi cu khi them `class_name` tu ngoai editor

### Trieu chung

```
Parser Error: Could not find type "MatchState" in the current scope.
res://ui/hud.gd:25
Failed to load script "res://ui/hud.gd" with error "Parse error".
```

Nhung mo `net/match_state.gd` ra thi dong dau tien DUNG la `class_name MatchState`.

### Nguyen nhan

Godot giu danh sach class toan cuc trong `.godot/global_script_class_cache.cfg`.
Sua file **tu ben ngoai editor** de them `class_name` thi cache khong duoc cap nhat, va moi
script khac van khong nhin thay kieu do.

```bash
grep '"class"' .godot/global_script_class_cache.cfg
# CameraRig, Pickable, Player   <- THIEU MatchState du file da co class_name
```

### Cach chua

```bash
rm .godot/global_script_class_cache.cfg
```
Roi chay lai `--editor --quit`. Trong editor thi **Project > Reload Current Project**.

### Ghi nho

Claude sua file ngoai editor -> **them `class_name` xong phai kiem cache**, dung tin vao viec
import chay sach. Kiem bang mot lenh:
```bash
grep '"class"' .godot/global_script_class_cache.cfg
```

---

## 1w. Loc loi khi kiem — DUNG loc hep

Grep chi `SCRIPT ERROR|Parse Error` da **bo sot hai loi that** trong mot luot:

| Loi | Godot bao duoi dang khac |
|---|---|
| `var ms := ... as MatchState` | `Cannot infer the type of "ms" variable because the value doesn't have a set type` |
| `var ready := ready_count()` | `SHADOWED_VARIABLE_BASE_CLASS: local variable "ready" is shadowing an already-declared signal in base class "Node"` |

Cai thu hai nguy hiem hon: **code van chay**, chi la `ready` trong pham vi do khong con la thu
minh tuong.

**Loc dung:**
```bash
... 2>&1 | grep -iE "error|shadow|cannot|unsafe|warning"         | grep -viE "audio|wasapi|dummy driver|Capture not registered|CSV file|Ambient light"
```

### Nhieu da biet — bo qua duoc

**`WASAPI: Initialize failed` -> `falling back to the dummy driver`**
May khong mo duoc thiet bi phat am thanh. Khong lien quan toi code, xay ra o moc 0.8 giay
truoc khi script nao chay. Nhung **luc lam may phat nhac va SFX thi se im lang hoan toan** va
rat de tuong code sai -> kiem Windows Sound co thiet bi phat dang bat khong.

**`Unable to start the timer because it's not inside the scene tree`**
**KHONG PHAI cua ta.** Da xoa sach: khong con `Timer` nao trong toan bo code du an
(`grep -rn "Timer.new" --include="*.gd" .` -> rong) ma no van hien. Va no **chi hien luc editor
quet**; chay game that thi sach hoan toan. Nhieu kha nang tu chinh GDExtension cua Fusion
(log cua no co dong *"processor node created and added to tree"*).

> Nhieu che mat tin hieu. Do la ly do that khien hai loi tren bi bo sot — bang Errors ngap
> nhung dong khong lien quan.

---

## 1x. Ban co — mat ban va ket dinh vao o  DA TEST XANH

`lobby/objects/chess_board.tscn/.gd`

```
tam o (4,4) = (-6.35, 0.78, -3.35)
quan dap o  = (-6.35, 0.89, -3.35)      <- tha lech 7cm/9cm
lech ngang  = 0.0000 m
```

### Ban co de DUNG LEN, khong phai ban co de ban

```
Ban:  8 o x 0.8 m = 6.4 m ngang
Tot:  cao 0.49 m, rong 0.32 m   (quan chiem 40% be rong o)
Vua:  cao 0.85 m                (nhan vat cao 1.80 -> ngang hong)
```

Ban dau lam ban co dat tren mot cai ban cao 0.78 m, o 0.3 m. **Sai huong** — nguoi choi phai
DUNG LEN ban co va di lai tren do, nhu anh tham khao.

**Ban nam PHANG tren san, khong co bac.** Quan trong: co bac thi `CharacterBody3D` khong tu treo
len duoc va nguoi choi vap o ria ban. Bo han cai ban di, chi con 64 o day 0.04 m nam tren san.

**Vi tri:** `(-7, 0, 0)`. Mep gan nhat cach be san sang 0.3 m; goc xa nhat cach tam san 10.7 m
nen van nam gon trong san ban kinh 12.

Quan phong to bang `piece_scale` tren node `Visual` — mat cat giu nguyen don vi cu, chi nhan
he so. Doi kich thuoc ban sau nay chi phai sua mot so.

### 64 o dung bang CODE, khong dung texture

`_build_cells()` sinh 64 `MeshInstance3D` xen ke hai mau. Khong can file anh, va doi so o hay
kich thuoc o thi tu dung lai.

### Ket dinh: mat ban dang ky vao nhom `snap_surface`

`Pickable._landing_point()` sau khi raycast tim mat dat thi hoi tung mat ban:
```gdscript
for b: ChessBoard in get_tree().get_nodes_in_group("snap_surface"):
    if b.contains(landed):
        return b.snap(landed) + Vector3(0, ground_offset, 0)
return landed          # nem ra san thi cu nam cho no roi
```

**Mat ban khong biet gi ve co.** Khong biet quan nao la quan gi, khong quan tam luot di.
No chi lam hai viec: cho biet mot diem co nam tren ban khong, va tam o gan nhat o dau.
Dung nhu da chot — ban co cua ta la ban co ngoai doi, ai cung tho tay vao duoc.

### Chua lam

- Bo quan tien bang `CSGPolygon3D` che do Spin (hien van la khoi hop)
- Quan ma = `TextMesh` "HORSE" xep doc
- Nut LAT MAT sang co tuong
- **Nut RESET** — can giai bai toan *ai so huu quan nao luc bam*. Master muon dat lai vi tri thi
  phai co quyen tren tung quan, ma quyen dang nam o nguoi cham cuoi cung. Dang mot buoc rieng.

---

## 1y. Bo quan co — DA TEST XANH

`lobby/objects/chess_piece.tscn/.gd` — ke thua `Pickable`, chi them phan hinh dang.

```
HOST  quan=32  {tot:16, xe:4, ma:4, tuong:4, hau:2, vua:2}  ma co 6 node con
JOIN  quan=32  {tot:16, xe:4, ma:4, tuong:4, hau:2, vua:2}  ma co 6 node con
```

32 object mang cung luc, khong van de gi.

### May tien viet bang code, khong dung CSG

Quan co ngoai doi duoc TIEN — mot mat cat xoay quanh truc. Nen 5 trong 6 quan chi la mot danh
sach diem 2D.

Doc goi y `CSGPolygon3D` che do Spin, nhung CSG **tinh lai luc chay**. Thay bang `SurfaceTool`
xoay mat cat thanh `ArrayMesh` tinh — mot ham `_lathe(profile, segments)` khoang 20 dong.

**Mesh duoc cache theo loai quan**: 32 quan nhung chi 5 lan tien.

```gdscript
static var _mesh_cache: Dictionary = {}
```

**`cull_mode = CULL_DISABLED`** lam bao hiem: luoi tu sinh ma sai chieu mat thi van nhin thay,
khong bi mat hinh. Mot dong, bo di ca mot loai bug "sao no tang hinh".

### Quan ma = chu HORSE

`TextMesh` (chu 3D co do day that), 5 chu xep doc, **H tren cung**, dung tren **de tien giong
moi quan khac**. Cai de moi la cho buon cuoi — bo de di thi no chi la chu noi lan loc.

### `kind` va `side` deu phai replicate

Neu khong thi may khac dung ra mot ban co toan tot. Setter dung lai mesh khi gia tri ve —
da kiem chung chay dung tren may remote.

### Chua lam

- Nut LAT MAT sang co tuong
- **Nut RESET** — van cho giai bai toan *ai so huu quan nao luc bam*

---

## 1z. Nhat do KHONG chuyen quyen so huu — DA TEST XANH

### Thiet ke: master so huu vinh vien, nguoi choi gui RPC

Ban dau moi lan nhat la mot lan `want_authority()`. Bo han cach do.

```
Nguoi choi bam E -> Fusion.rpc(_net_pick, id cua minh)
Master nhan -> gan holder_id = id do
Master di chuyen vat theo tay nguoi cam moi frame
Vi tri replicate ve moi may nhu moi vat the khac
```

**Lam duoc vi vi tri nguoi choi VON DA replicate toi moi may** — master biet tay ai o dau
ma khong cần ai gui gi them.

**Gia phai tra:** dong tac nhat tre mot nhip RTT (~30 ms voi region asia). Khong ai nhan ra.

**Doi lai:**
- Khong con tranh chap quyen so huu
- **Nut reset thanh chuyen vat**: master so huu tat -> tu despawn tu spawn. Khong con man
  "moi may tu despawn phan cua minh"
- Bam reset tu may KHONG phai master van chay dung (da test)

### `owner_mode` dang dung: 0 (mac dinh)

KHONG dung `MASTER_CLIENT` (3). Master **von da** so huu moi thu no spawn ra, nen khong can
che do do. Va khong ai xin quyen nen phan "cho phe duyet" cua TRANSACTION vo hai.

*Co quan sat thay bat thuong voi mode 2 va 3 (so object hai may lech nhau, has_authority bao
la), nhung do bang mot kich ban test CO LOI (xem duoi) nen KHONG ghi nhan la ket luan.
Mode 0 chay dung va do la thu can biet.*

### Da xac minh rieng: replication vi tri chay hoan hao

Host dat mot quan ve `(9, 3, 9)` -> may join thay dung mot quan o `x = 9.00`.
Lam test toi thieu nay som hon thi da tiet kiem duoc nhieu vong debug.

---

## 1aa. Ba loi INSTRUMENTATION lam mat nhieu vong debug

Ba vong debug lien tiep duoi mot bug KHONG CO THAT. Loi nam o kich ban test, khong nam o game.

### 1. Ten node KHONG on dinh giua cac may

```
host: ChessPiece, @Node3D@231, @Node3D@232 ...
join: ChessPiece, @Node3D@234, @Node3D@245 ...
```

Godot tu dat ten cho node sinh ra luc chay, va **thu tu khac nhau tren tung may**. So sanh
"cung mot vat" theo ten la so hai vat khac nhau.

**Cach dung:** so sanh theo mot dac diem xac dinh duoc tu du lieu — vi du *quan co x nho nhat*.
Ca hai may deu chon dung mot vat vi vi tri da replicate.

### 2. `%.1f` giau mat gia tri

`0.04` in ra thanh `0.0`, lam tuong vi tri spawn bi ghi de ve 0. Mat mot vong debug de dung lai
dung cho cu.

### 3. Vi tu do bien gioi + noi suy = ket qua nhay

Dem "bao nhieu quan nam ngoai ban" bang `contains()`. Quan o RIA ban nam dung tren bien, ma vi
tri o may remote di qua noi suy nen lech vai phan nghin -> hai may dem ra hai so khac nhau.

**Cach dung:** trong test, dung nguong cach xa bien (`x > 5.0` khi ban ket thuc o `x = -3.8`),
dung dung `contains()` o sat bien.

> **Bai hoc:** khi hai may bao hai ket qua khac nhau, nghi kich ban test TRUOC khi nghi netcode.
> Va viet mot test toi thieu cho DUNG co che dang nghi ngo, thay vi doc so lieu tu mot kich ban
> phuc tap.

---

## 1ab. Ban co tuong va nut LAT MAT — DA TEST XANH

```
truoc:   luoi 8x8   32 quan co vua
sau lat: luoi 9x10  32 quan co tuong   board_mode=1
Khop tren CA HAI may. Nguoi bam la may KHONG phai master.

Do:  俥x2 傌x2 相x2 仕x2 帥x1 炮x2 兵x5 = 16
Den: 車x2 馬x2 象x2 士x2 將x1 砲x2 卒x5 = 16
```

### Lat mat KHONG phai doi texture — no doi ca LUOI

| | Co vua | Co tuong |
|---|---|---|
| Luoi | 8x8 **O** | 9x10 **GIAO DIEM** |
| Quan dung | GIUA o | TREN giao diem |
| Rieng | — | Song o giua, cung 3x3 hai dau |

`ChessBoard` co `_axis()` va `_index()` re nhanh theo `mode`: co vua lech nua o, co tuong thi
khong. `snap()` va `point()` dung chung hai ham do nen ca hai che do dung cung mot duong ma.

### Font mac dinh cua Godot VE DUOC chu Han

Da do truoc khi viet: `TextMesh` voi `將` cho ra 7662 dinh (khong rong). **Khong can tai font
Noto hay bat ky font CJK nao.** Quan co tuong = tru det + chu Han noi nam ngua tren mat.

### Trinh tu lat

1. **Day nguoi dung tren ban** — moi may tu ap van toc len NGUOI CHOI CUA NO
   (dung nguyen tac "thu gi day nguoi choi deu re, mien la ho tu ap len minh")
2. **Xoay toi canh** (nua vong dau) — luc nay khong nhin thay mat ban
3. **Dung lai luoi moi** o dung diem khuat do
4. **Xoay not**, roi dat `rotation.x = 0` — ban phang nen khong ai thay

Master lam phan 3 va 4 cua du lieu: despawn bo cu, spawn bo moi sau 0.7 giay.

**Lat va reset la CUNG MOT co che** — xoa sach quan roi spawn bo moi. Lat chi them phan day
nguoi va xoay.

### `board_mode` nam trong MatchState, khong nam trong ChessBoard

Ban co nam trong lobby duoc nap **cuc bo** nen no khong phai object mang — khong replicate duoc
gi. Mat ban hien tai luu trong `MatchState` (master so huu, da replicate) de **nguoi vao muon
dung dung mat ban**.

### ⚠️ Fusion gui property VE RIENG LE, KHONG dam bao thu tu

Loi that gap phai:
```
SCRIPT ERROR: Out of bounds get index '6' (on base: 'Dictionary')
```

`kind = 6` (tuong, co tuong) ve TRUOC `game = XIANGQI`. Setter dung lai ngay -> luc do object
tuong minh la quan co vua so 6, ma bo co vua chi co 0..5 -> no di tien mot quan khong ton tai.

**Cach chua: hoan viec dung lai toi cuoi frame.**
```gdscript
func _queue_build() -> void:
    if _build_queued or not is_node_ready():
        return
    _build_queued = true
    _deferred_build.call_deferred()
```
Toi cuoi frame ca ba gia tri da ve du. **Tien the bot duoc hai lan dung lai thua.**

> **Quy tac:** setter cua property replicate KHONG duoc lam viec nang ngay lap tuc neu ket qua
> phu thuoc vao NHIEU property. Gom lai va hoan toi cuoi frame.

---

## 1ac. Ban caro 28x28 + hop cap quan — DA TEST XANH

```
[1] so ban co trong phong = 2
    mode=0 luoi=8x8   o=1.05m rong=8.4m  tam_x=-8.0
    mode=2 luoi=28x28 o=0.50m rong=13.5m tam_x=11.0
[2] sau khi bam hop: quan_caro=6 (dang_cam=6)  quan_co_vua=32
[3] sau DON BAN CARO: quan_caro=0  quan_co_vua=32
```

### Vi sao 28x28 chu khong phai 64x64

Kich thuoc ban = (so duong - 1) x khoang cach. Khong co cach nao thoat khoi phep nhan nay.

Khoang cach co **san duoi ~0.5 m**: nguoi choi DUNG TREN ban, mat o 1.65 m. Gan hon 0.5 m thi
hai giao diem canh nhau chi cach nhau vai do trong tam nhin -> nham lien tuc khi dat quan.

| Luoi | @0.5 m | Vua san ban kinh 20 m? |
|---|---|---|
| 13x13 | 6.0 m | thua, nhung nguoi dung ke thay it o |
| **28x28** | **13.5 m** | **vua — chon cai nay** |
| 64x64 | 31.5 m | khong: gan het ca phong |

### Ban caro la INSTANCE KHAC, khong phai mat thu ba cua ban co vua

`ChessBoard.mode` la `@export` dat tu scene. Ban co vua/tuong o x=-8 lat qua lai giua mode 0 va
1; ban caro o x=11 co mode=2 co dinh. Cung mot script, hai object.

Caro dung chung duong ma giao diem voi co tuong (`_axis`/`_index` nhanh "khong lech nua o"), chi
khac o `_build_caro()`: mat tron + luoi ke deu, khong song khong cung.

### Hop cap quan — quan spawn THANG VAO TAY nguoi bam

Nut `CaroWhite`/`CaroBlack` -> `main.request_stone(side)` -> RPC toi master:

```gdscript
@rpc("any_peer", "call_local")
func _net_give_stone(side: int, player_id: int) -> void:
    if not master: return
    # dem quan caro, tu choi neu >= MAX_CARO_STONES
    var s := spawner.spawn(CHESS_PIECE_SCENE)
    s.game = CARO; s.side = side; s.holder_id = player_id
```

`holder_id` dat ngay luc spawn — khong can buoc "nhat". Lam duoc vi **master von so huu moi
pickable va tu di chuyen no theo tay nguoi cam** (muc 1z). Do luon: 6 lan bam -> 6 quan, ca 6
deu `holder_id != 0`.

Gioi han `MAX_CARO_STONES = 200`. Bam qua thi master lang le bo qua — khong bao loi, vi day la
do choi chu khong phai chuc nang.

### Don ban phai CO PHAM VI

`_clear_pieces(caro: bool)` loc theo `game` truoc khi despawn. Nut reset ban caro khong duoc
dung toi 32 quan co vua ben kia phong. Do o buoc [3]: caro ve 0, co vua **van du 32**.

Cung ly do, `_board()` va `_caro_board()` loc nhom `snap_surface` theo `mode` — gio trong phong
co HAI ban, `get_nodes_in_group("snap_surface")[0]` khong con dung nua.

> **Quy tac:** khi mot loai object co nhieu hon mot the hien trong phong, moi ham "tim cai do"
> phai loc, khong duoc lay phan tu dau tien.

### Kich thuoc sàn phai lon theo

San ban kinh 17 -> **20** (40 m), vom 21, `Pickable.ROOM_RADIUS` 16.5 -> **19.5**. Ban caro
13.5 m dat o x=11 nen mep ngoai cham x=17.75 — sat vach cu.

---

## 1ad. Xuat ban gui nguoi khac — 0.0.1  DA CHAY THU XANH

```
build/PartyBash-0.0.1/
  PartyBash.exe                                        104 MB
  PartyBash.pck                                         25 MB
  libfusion.windows.template_release.x86_64.release.dll  2 MB
  DOC-TRUOC-KHI-CHAY.txt
-> PartyBash-0.0.1.zip  55 MB
```

Chay thu ban da xuat (`--headless`): nap DLL, doc app_id, chon region asia,
`Connect complete -> Connected`, nhan duoc danh sach phong. **Khong can may kia cai Godot.**

### Ba file phai di CUNG NHAU

GDExtension khong nam trong `.pck` — no la DLL rieng nam canh `.exe`. Copy moi `.exe` ra la
game khong chay. Da viet canh bao nay vao `DOC-TRUOC-KHI-CHAY.txt` cho nguoi nhan.

### `export_presets.cfg` — thu can loai bo

```
exclude_filter="*.md, addons/fusion/cs/*, check_fusion.gd"
```

`addons/fusion/cs/` la ban boc C# cua Fusion — **du an nay khong dung**, chi dung GDExtension.
Khong co `.csproj` nen no khong duoc bien dich, mang theo chi to file.

Rac `~libfusion...dll~RF*.TMP` trong `bin/` (do editor giu DLL luc build lai) phai xoa tay
truoc khi xuat.

**Va rac do CON XUAT HIEN O THU MUC BUILD.** Xuat de len mot ban cu thi Windows giu lai ban
sao du phong `PartyBash.exe~RF795bb0.TMP` va `libfusion...dll~RF799cb0.TMP` — **111 MB** lot
thang vao zip, phong len 46 -> 85 MB. Truoc moi lan nen:

```bash
rm -f build/<ban>/*~RF*.TMP
```

> **Dau hieu:** file zip to len bat thuong. Luon nhin ky dung luong zip truoc khi giao —
> no la thu duy nhat noi cho biet co gi do lot vao ma minh khong biet.

### ⚠️ APP ID NAM TRONG BAN BUILD, DOC RA DUOC

`grep` thay chuoi app_id nguyen ven trong `PartyBash.pck`. Ai co ban build deu doc duoc va
dung duoc quota Photon mien phi (20 CCU) cua minh. Ban thu trong nhom ban be thi khong sao;
**dung dua ban build len cho cong khai** (itch.io, drive cong khai) khi chua tinh den chuyen do.

Cung ly do: repo phai de **private** neu day len GitHub.

### Da doi cho hai nut ban co vua

Truoc: `z = 5.0` (dau ban). Lat qua co tuong thi ban dai them theo truc z — nua chieu sau
tu 4.2 len **4.725** — nut gan nhu dinh vao mep ban.

Sau: `x = -13.6` (**hong ban**). Nua chieu rong giu nguyen 4.2 o CA HAI mat, nen hong ban la
cho duy nhat khong xe dich khi lat.

> **Quy tac:** dat do trang tri canh mot vat thay doi hinh dang thi bam vao chieu KHONG doi.

---

## 1ae. Dung phong cho bang code + lat ban NGANG — DA TEST XANH

```
[1] prop = 35 / 35
[2] ngoai tuong = 0 | dam vao ban co / o san sang = 0
[3] diem spawn bi prop chan = 0
[4] prop cao nhat = 2.28 m (nguoi choi 1.8 m)
[HOST] nguoi=2 luoi=9x10 rot=(0,0,0) quan=32 lech_o_max=0.02 m
[JOIN] bam lat...   <- may KHONG phai master
```

### ⚠️ GLB CUA KENNEY KHONG NAM O GOC TOA DO

Do duoc:

| kit | tam mesh lech |
|---|---|
| space kit | **(2.00, 1.50)** — gan nhu moi model |
| furniture kit | moi model mot kieu (`loungeSofa` lech (0.49, −0.21)) |
| mini-arcade | (0, 0) — kit duy nhat dat dung goc |

Dat thang model space kit vao (0,0,0) thi no hien ra cach do **2.5 m**, va **khong co loi nao
bao**. Phai do AABB luc nap roi nan ve: tam x/z ve 0, DAY ve y = 0.

### Ti le: do bang chinh nguoi cua kit do, khong doan

| kit | nguoi mau | cao (don vi) | he so | ra |
|---|---|---|---|---|
| space | `astronautA` | 0.79 | ×2.2 | 1.74 m |
| arcade | `character-employee` | 0.72 | ×2.4 | 1.73 m |
| furniture | `chair` | 0.47 | ×2.0 | 0.94 m |

Ca ba deu gom trong `lobby/prop.gd`. Model Kenney cung **khong co collision** — `Prop.place()`
boc them mot hop theo AABB (toi thieu 10 cm moi chieu, hop mong dinh lam CharacterBody3D ket).

### Dat do theo TOA DO CUC, khong theo x/z

Lan dau viet bang x/z va dat nham 5 mon **ra ngoai tuong** — `(-22, -19)` cach tam 29.1 m
trong khi tuong o 28 m. Khong loi, khong thay, do choi bay ngoai vu tru.

Doi sang `[kit, model, ban_kinh, goc, xoay_them, chan_duong]`:
- ban kinh co dinh -> ca cum tu om theo vach
- xoay mac dinh = goc -> mon do **tu quay mat vao giua phong**
- muon kiem "co mon nao ngoai tuong khong" chi can nhin mot cot so

### Tuong vo hinh, KHONG co mesh

San la mot cai dia — truoc day nguoi choi di ra mep la roi mai. Vom trong suot da lo phan
NHIN roi nen tuong chi can chan CHAN.

`CylinderShape3D` khong dung duoc: no DAC, day nguoi choi ra ngoai chu khong giu lai. Phai
ghep 48 hop phang theo vong tron, moi hop rong hon 15% de hai tam chong mep.

### Lat ban: doi truc X -> truc Z

Truc X = lat DOC, mep truoc hat len — nhin nhu ban do vao mat nguoi dung xem.
Truc Z = lat NGANG, mep trai hat len mep phai chui xuong.

### Trinh tu moi: don TRUOC, spawn SAU KHI HET animation

```gdscript
if NetManager.is_master():
    _clear_pieces(false)      # quan cu bien mat het TRUOC khi ban bat dau xoay
await board.flip_to(next_mode)  # 1.13 s — flip_to gio await duoc (await t.finished)
if not NetManager.is_master(): return
board_state_mode(next_mode)
_spawn_set(next_mode)         # rotation.z da ve 0, luoi moi da dung xong
```

Truoc day spawn o giay 0.7 trong khi animation dai 1.2 s — quan hien ra luc ban dang nghieng.
Gio doi het han. **Do: lech o toi da 0.02 m = dung bang `surface_y`, tuc sai so ngang = 0.**

### Kho asset dang co

| pack | so model | dung vao |
|---|---|---|
| `kenney_space-kit` | 153 | vo tau, may moc, phi thuyen, da |
| `kenney_furniture-kit` | 140 | goc nghi: ghe sofa, ban, tham, den |
| `kenney_mini-arcade` | 20 | **air-hockey, basketball-game, claw-machine, dance-machine, pinball, prize-wheel, vending-machine, ticket-machine** |
| `kenney_mini-characters` | 26 | nhan vat |
| `kenney_playing-cards` | (2D) | ban bai |
| `kenney_prototype-textures` | (texture) | |

Con thieu, phai tai TAY (CC-BY, phai ghi nguon): chim canh cut (poly.pizza/m/fBXvsC6pe_V),
vit (poly.pizza/m/6HpauUCfIAb), robot Quaternius.

---

## 1af. Model quay lung ve huong nhin — loi MOT MINH KHONG THAY DUOC

Nguoi choi bao: "A quay lung ve phia B thi A lai NHIN THAY B."

Camera dung, di chuyen dung (`W` di ve `-basis.z`, chinh la huong nhin). Chi co **model bi ve
nguoc 180°**. Vi minh da an mesh cua chinh minh o goc nhin thu nhat nen **mot may chay thu
khong bao gio phat hien ra** — phai hai nguoi dung nhin nhau moi lo.

### Do bang XUONG, khong doan

```
arm-left   rest=(+0.100, 0.288, -0.017)
arm-right  rest=(-0.100, 0.288, -0.017)
```

He toa do Godot la tay phai, Y len. Nhan vat quay mat ve `-Z` thi tay PHAI cua ho nam o `+X`:

```
right = forward x up = (-Z) x (+Y) = +X
```

O day `arm-right` nam o `-X` -> nhan vat quay mat ve **+Z**, nguoc voi huong truoc cua Godot.

**Sua: `model_yaw_deg = 180.0`.** Kiem lai sau khi sua: tay phai ra `x = +0.268`.

> **Quy tac:** import model nguoi tu bat ky kit nao, viec DAU TIEN la doc rest cua
> `arm-left`/`arm-right` de biet no quay mat ve dau. Nhanh hon nhieu so voi cho hai nguoi
> vao phong roi doan.

---

## 1ag. Don kho asset, phong to may choi duoc, dua ga — DA TEST XANH

```
[KQ] prop=35  dam nhau=0  ngoai tuong=0
[HOST] ket qua dua: GA LUC THANG!
[JOIN] bam nut DUA GA (may nay KHONG phai master)
[JOIN] ket qua dua: GA LUC THANG!      <- KHOP
```

### Kho asset: 80 MB -> 19 MB

Thu an cho **khong phai model**. Moi pack Kenney dong goi CUNG MOT BO MODEL o 5 dinh dang:

```
Models/FBX format   5.7M
Models/DAE format   5.8M
Models/OBJ format   2.9M
Models/STL format   1.7M
Models/GLTF format  0.9M   <- Godot chi doc cai nay
Isometric/          6.8M   <- anh preview 2D cua pack
Side/               1.3M
```

Xoa 4 dinh dang thua + anh preview = **49 MB**, khong mat model nao. Cong voi 142 model
space-kit, 131 furniture, 14 phu kien nhan vat khong duoc code nao goi toi.

**Cach chon an toan:** grep bang bo tri trong `lobby.gd` + `MODEL_FILES` trong `player.gd` ra
danh sach trang, roi xoa moi thu ngoai danh sach. Khong xoa theo cam tinh.

> Ban build KHONG can viec nay: `export_filter = "all_resources"` doi thanh `"resources"` la
> Godot chi dong goi thu duoc scene tham chieu. Don kho la de gon ổ dia va git.

### May choi duoc phai TO HON do trang tri

| may | phong to | cao that |
|---|---|---|
| basketball-game | ×1.7 | 3.3 m |
| claw-machine | ×1.6 | 3.6 m |
| prize-wheel | ×1.8 | 3.7 m |
| dance-machine | ×1.6 | 3.6 m |
| pinball | ×1.5 | 2.7 m |
| air-hockey | ×1.6 | 1.9 m (ban dai 4.7 m) |

Nguoi choi cao 1.8 m. May cao ngang dau tro len moi ra dang may game thung that.

**Bay:** phong to xong thi **goc dat phai tinh lai**. Lan dau giu nguyen goc cu -> 9 cap prop
dam vao nhau. Goc = (be ngang may A + be ngang may B)/2 + 1.6 m loi di, chia cho do dai cung
mot do (`2πr/360`, o r=23.5 la 0.41 m/do).

Do bang **AABB the gioi** chu khong phai kich thuoc model: prop xoay 145° thi hinh chieu
phinh ra ~25%. Dung kich thuoc model thi test bao sach ma trong game van dam nhau.

### Dua ga: gui MOT HAT GIONG, khong dong bo vi tri

```gdscript
func request_chicken_race() -> void:
    Fusion.rpc(_net_chicken_race, randi())     # dung MOT so
```

Moi may seed `RandomNumberGenerator` bang so do roi chay cung mot phep tinh -> **cung mot cuoc
dua**. Thay cho 4 con × 60 frame × 9 giay vi tri.

Do: hai may nhan cung `GA LUC THANG!`, lenh bam tu may KHONG phai master.

**Gia phai tra:** ai vao phong GIUA cuoc dua thi khong thay gi. Chap nhan duoc — day la do
choi, khong phai trang thai van dau. Trang thai van dau van nam trong `MatchState`.

### Model poly.pizza: KHONG co animation, don vi lung tung

```
chicken  size=(167.32, 189.02, 103.44)  anim=KHONG
penguin  size=( 70.70, 175.89,  98.47)  anim=KHONG
```

Cao 189 don vi cho mot con ga. Moi model mot ti le khac nhau nen **khong dat duoc mot he so
chung cho ca kit** — de he so kit = 1.0, ghi ti le that vao cot "phong to" cua tung mon.

Khong co animation thi cho **nhun nguoi + nghieng minh** bang code:
```gdscript
c.position.y = absf(sin(_t * 9.0 + _phase[i])) * 0.14
c.rotation.z = sin(_t * 9.0 + _phase[i]) * 0.15
```
Nhin xa thi doc ra "dang chay" — du cho mot tro xem cho vui.

### ⚠️ CC-BY: ghi cong la BAT BUOC THEO GIAY PHEP

Ga va chim canh cut khong phai CC0. Dong ghi cong nguyen van da chep vao `CREDITS.md`, phai
xuat hien trong game hoac tai lieu nop kem. Xem muc 18 cua de.

---

## 1ah. DA XOA het do trang tri — quy tac moi cho phong cho

Nguoi choi hoi: "may game trong kit co that su choi duoc khong?" **Khong.**

```
air-hockey        animation=KHONG  so_mesh=4
basketball-game   animation=KHONG  so_mesh=2
claw-machine      animation=CO     so_mesh=3
dance-machine     animation=KHONG  so_mesh=2
pinball           animation=KHONG  so_mesh=2
prize-wheel       animation=CO     so_mesh=2
gambling-machine  animation=KHONG  so_mesh=1
arcade-machine    animation=KHONG  so_mesh=1
grep toan project: KHONG script nao tham chieu toi chung
```

Kit chi co MODEL. **Khong kit nao chua logic game** — phan choi phai tu viet. Hai may co
clip animation cung khong doi duoc gi: van khong co ai goi `play()`.

### Loi cua minh: dat ten bang la "MAY CHOI DUOC"

Y la "co the lam thanh minigame", nhung doc len thanh "da choi duoc". Roi con phong to chung
len ×1.5–1.8 tren co so do. Nguoi choi di toi, bam E, khong co gi xay ra.

### Quy tac tu day

> **Mon nao vao phong thi mon do phai LAM DUOC VIEC GI DO.**
> Phong trong con hon phong day do khong bam duoc. Khi nao co logic thi hay dat model vao.

Da xoa: 35 prop trong `lobby.gd`, ca ham `_build_props()`, ca file `lobby/prop.gd`, va ba kit
`kenney_space-kit` / `kenney_furniture-kit` / `kenney_mini-arcade`. **80 MB -> 16 MB.**

`prop.gd` xoa duoc vi moi con so do duoc deu con nguyen trong muc **1ae** va **1ag**:
do lech goc toa do cua tung kit, he so ti le do bang nguoi mau cua kit, cach boc collision.
Dung lai la viec 10 phut, khong phai do lai.

### Con lai trong phong — moi thu deu bam duoc

```
ReadyPad     o san sang
ChessBoard   + ResetButton + FlipButton
CaroBoard    + CaroWhite + CaroBlack + CaroReset
ChickenRace  + RaceButton
Walls        48 tam tuong vo hinh
6 nut bam | 2 ban co | 1 duong dua | 10 diem spawn
```

---

## 1ai. Man hinh Esc, dua ga v2 (dat niem tin) — DA TEST XANH

```
[1] 8 lan | rong 4.8 m | dai 8.0 m       (truoc: 4 lan, 6.4 x 14 m)
[2] ga cao 0.45 m | dai theo Z 0.40 | rong theo X 0.25  => QUAY DUNG HUONG CHAY
[JOIN] truoc khi dua, con 3 co 2 nguoi tin (ca HOST va JOIN)
[JOIN] bam DUA (may nay KHONG phai master)
[HOST] bang: GA 4 THANG!   khong ai tin no
[JOIN] bang: GA 4 THANG!   khong ai tin no
```

### Xac dinh huong mat cua model KHONG co xuong

Ga poly.pizza: 1 mesh, khong xuong, khong mau dinh. Nhung mesh co **5 surface, moi surface
mot vat lieu mot mau** — do vi tri tung mau la ra huong:

```
surface 3  #f53f30 (DO  = mao/yem)  X: -84.0 .. -37.5   Y: 122.8 .. 190.3
surface 2  #191919 (DEN = mat)      X: -65.1 .. -59.1   Y: 150.3 .. 156.4
```

Mao do va mat den deu o phia **-X** va tren cao -> ga quay mat ve -X. Xoay **+90 do** de mat
ve +Z (huong chay). Truoc de 180 do -> bien -X thanh +X -> ga chay ngang.

> **Quy tac:** model khong co xuong thi doc AABB CUA TUNG SURFACE theo mau vat lieu. Mat, mao,
> mo — thu nao chi co o dau thi no chi cho biet dau o phia nao. Nhanh hon mo Blender.

### Dat niem tin: la SU KIEN, khong phai state

`_bets` la `Dictionary` lan -> mang id nguoi choi. Mot nguoi dat duoc NHIEU con, nhieu nguoi
dat chung mot con — nen phai la MANG chu khong phai mot gia tri.

Gui thang RPC, khong replicate: danh sach chi co y nghia cho toi luc cuoc dua ket thuc.
Do: hai may deu doc ra 2 nguoi tin con 3.

**Nut dat niem tin gian 1.3 m, rong hon lan dua 0.6 m.** `_nearest_pressable()` chon theo
huong nhin; hai nut cach nhau 0.6 m o tam 2 m chi lech vai do -> bam nham lien tuc.

### Man hinh Esc: MOT NOI duy nhat duoc doi `Input.mouse_mode`

Truoc day `CameraRig` tu bat Esc de nha/khoa chuot. Them menu vao thi hai ben tranh nhau mot
bien toan cuc: mo menu ra la camera khoa chuot lai ngay, khong bam duoc nut nao.

Da **go het phan doi mouse_mode khoi CameraRig** (ca Esc lan bam-chuot-de-khoa-lai).
`ui/pause_menu.gd` giu quyen do. CameraRig chi con viec xoay khi chuot dang bi khoa.

Menu co: TIEP TUC / ROI PHONG / THOAT GAME. Nut ROI PHONG tat khi chua vao phong.

### ⚠️ Ghi de nho: minigame khu SILVER FLAG phai NHO va DE DI CHUYEN

Nguoi choi dan: **khong lam to nhu hai ban co**. Ban co vua 8.4 m va ban caro 13.5 m an het
mot goc phong, khong the doi cho. Minigame cua khu silver flag phai gon, nhac di duoc.

**Khu silver flag** = cum co bac o Goc 2: craps 2d6 - dua ga - Penguin Cross - ban bai.
Da co trong muc 1d tu dau, minh grep hut.

Uu tien hien tai: **dung HET minigame truoc, phan khu va tai cau truc sau.**

---

## 1aj. Xuc xac CAM DUOC, nem la lan — DA TEST XANH

```
[HOST] phong 'HostA-WFJH' | 2 nguoi
[HOST sau] xuc xac: ["red=4", "yellow=1"]
[JOIN sau] xuc xac: ["red=4", "yellow=1"]      <- khop
nem thu 30 lan mot may: sai 0 | cac mat da ra: [1,2,3,4,5,6]
```

### DOC DUOC mat nao mang so may tu chinh hinh hoc cua model

Ban dau dinh tu dung mot khoi lap phuong vi "khong biet mat nao la so may". Sai — do duoc,
bang chinh model KayKit:

```
D6_A:  +X=2  -X=5  +Y=6  -Y=1  +Z=3  -Z=4     tong = 21
```

**Cach do:** cham la HINH HOC (lom sau 0.27..0.375 tren khoi canh 0.375). Voi moi huong mat,
lay cac dinh nam gan mat do nhung LOM vao trong, chieu xuong mat phang 2D, roi gom **cum lien
thong** (BFS, ban kinh noi 0.09). So cum = so cham.

**Ba phep kiem tu xac nhan lan nhau:** tong 21 dung nhu xuc xac that; ba cap mat doi nhau deu
cong bang 7. Ca 5 bien the mau giong het nhau. `D6_B` ra tong 25 (kieu cham khac) va `D6_C`
cham nam trong texture — dung `D6_A`.

> **Bay minh da suot:** lan do dau tien loc `surface > 0` trong khi file chi co surface 0 —
> vong dem **khong he chay**, in ra bang rong, va minh ket luan "khong doc duoc". Bang rong
> khong phai bang chung.

### Bo nut GIEO. Xuc xac la VAT CAM DUOC.

`Die extends Pickable` — thua nguyen nhat / nem / ket dinh / master so huu. Chi them hai thu,
va them bang **hai moc nho tren lop cha**:

```gdscript
func _khi_nem() -> void      # goi luc roi tay: quyet mat, chon truc lon nhao
func _khi_bay(p: float)      # goi moi frame khi bay: lon nhao roi xoay dan ve dung mat
```

Ca hai moc deu nam sau cong `has_authority()` cua Pickable nen **chi master chay** — dung
cai minh can. Huong vien xuc xac tu toi cac may khac vi `root_replication_mode` da dong bo
ca vi tri lan goc xoay; khong phai gui them gi.

Tha tay (`Q`) cung la mot cu gieo, vi `drop()` di qua dung duong `_net_throw`.

### KHONG dung vat ly that

Vat ly moi may chay lech nhau mot chut la ra hai ket qua khac nhau. Ket qua **quyet truoc**,
hoat hinh chieu theo: lon nhao tu do toi 55% quang duong, roi `Quaternion.slerp` ve dung
huong dich. O `p = 1` trong so slerp = 1 nen **khong co sai so dong lai**.

```gdscript
const FACE_UP := {1: Vector3(180,0,0), 2: Vector3(0,0,90), 3: Vector3(-90,0,0),
                  4: Vector3(90,0,0),  5: Vector3(0,0,-90), 6: Vector3(0,0,0)}
```
Xoay them quanh Y **giu nguyen mat tren** — moi lan gieo mot dang khac ma van dung so.

### ⚠️ Xuc xac luon dung o mat 6 — va TEST DA BO SOT

Trieu chung: nem kieu gi vien nao cung nam ngua mat 6.

```gdscript
if _t >= 1.0:
    global_position = _to
    _t = -1.0                        # <- gan -1 TRUOC
else: ...
_khi_bay(clampf(_t, 0.0, 1.0))       # <- clampf(-1) = 0.0, khong phai 1.0
```

Frame cuoi cung goi `_khi_bay(0.0)` -> trong so slerp = 0 -> goc xoay ve **identity**.
Ma `FACE_UP[6] = Vector3(0,0,0)`, tuc identity **chinh la mat 6**. Nen vien nao cung dung o 6.

Chua: chot tien do vao mot bien TRUOC khi dung toi `_t`.
```gdscript
var tien_do: float = clampf(_t, 0.0, 1.0)
if _t >= 1.0: ... _t = -1.0
_khi_bay(tien_do)
```

> **Test cu KHONG bat duoc vi no goi tay `_khi_bay(1.0)`** thay vi de vien xuc xac bay that
> qua `_process`. No kiem dung phep tinh goc, nhung **bo qua chinh cai dong da lam hong**.
>
> **Quy tac:** test phai di qua DUONG THAT ma nguoi choi kich hoat. Goi thang ham noi bo la
> dang test mot chuong trinh khac. Test moi: `_net_throw()` roi cho `_t` tu ve -1, do lai
> 20 lan -> sai 0, ca 6 mat deu ra (1:3, 2:2, 3:5, 4:2, 5:3, 6:5).

### Ban gieo chi con la cai ban + bang cong

Doc theo VI TRI giong `CardSpot`: vien nao dang NAM trong ban kinh mat ban thi cong vao.
Vien dang cam khong tinh. Khong ton them byte mang nao.

---

## 1ak. Penguin Cross + ban bai — DA TEST XANH. Khu silver flag DU 4 TRO

```
[HOST] ket qua canh cut: ["nguoi 2 NGA o 2.0x", "nguoi 2 NGA o 2.0x", "nguoi 2 dung o 3.0x"]
[JOIN] ket qua canh cut: ["nguoi 2 NGA o 2.0x", "nguoi 2 NGA o 2.0x", "nguoi 2 dung o 3.0x"]
[HOST] bai=["hearts_09(tay=2)", "spades_08(tay=2)", "spades_J(tay=2)"]
[JOIN] bai=["hearts_09(tay=2)", "spades_08(tay=2)", "spades_J(tay=2)"]
[7] bo bai dung duoc 52 ten khac nhau (can 52)
```

Khu silver flag: ✅ craps 2d6 · ✅ dua ga · ✅ Penguin Cross · ✅ ban bai

### Huong mat cua model KHONG co xuong, KHONG co vat lieu tach mau

Ga doc duoc bang mau vat lieu (muc 1ai). Canh cut chi co **1 surface trang + texture** nen
cach do bang mau khong dung duoc. Doi sang do **PHAN BO DINH o hai dau truc**:

```
dau +Z: 108 dinh | Y trung binh +69.1 | be ngang X   9.8   <- MO (hep, tren cao)
dau -Z:  53 dinh | Y trung binh -59.1 | be ngang X  45.4   <- duoi/chan (rong, duoi thap)
```

Mo thi hep va o tren cao; duoi/chan thi rong va o duoi thap. -> quay mat ve **+Z**, dung
huong ray, khoi xoay.

> **Ba cach do huong mat, thu tu nen thu:**
> 1. Xuong `arm-left`/`arm-right` (muc 1af) — chac nhat, dung khi co Skeleton3D
> 2. AABB tung surface theo mau vat lieu (muc 1ai) — dung khi model tach nhieu vat lieu
> 3. Phan bo dinh o hai dau truc dai nhat — luon dung duoc, doc yeu hon nhung du ro

### Penguin Cross: cuoc bang KHAN GIA, khong cuoc bang xu

Xu la dao cu, refill thoai mai, nen mat xu chang dau -> tro se vo nghia. Con canh cut **di
that tren ray giua phong**, he so hien to tren dau, ca phong dung xem ban tham toi 8x roi
nga. Cai mat la thua truoc mat ca phong — khong refill duoc, va **mien phi ve mat code**.

```
he so:  1.0  1.2  1.5  2.0  3.0  4.0  6.0  8.0  12.0
song:   95%  90%  82%  72%  60%  48%  35%  22%
```

Ray CAO hon san 0.6 m — ray sat dat thi cu nga khong doc ra duoc.
Di het ray thi TU DUNG, khong con buoc nao de tham them.

### Ban bai: KHONG CO LUAT, giong het ban co

Cung ly do da chot cho ban co: khong luat thi choi duoc xi dach, tien len, phom, hay bat cu
tro gi nhom ban tu nghi ra. Co luat thi chi choi duoc mot tro, ma lai phai cai nhau luat nao
dung.

`Card extends Pickable` — thua nguyen co che nhat/nem/tha. Chi them mat bai.
Anh Kenney la **sprite pixel-art 64x64 VUONG** (vien la bai ve san ben trong), nen mat dan
cung phai vuong; keo thanh chu nhat la meo. `TEXTURE_FILTER_NEAREST` — loc min lam nhoe het.

**Master giu danh sach la DA RUT.** Do la trang thai cua the gioi chu khong phai cua rieng ai,
va nguoi vao muon phai thay dung bo bai con lai. Nut XAO LAI BO BAI despawn het bai + xoa
danh sach.

### ⚠️ Them mot loai Pickable moi LAM VO vong lap cu

```gdscript
for p: ChessPiece in get_tree().get_nodes_in_group("pickable"):   # vo khi co la bai
    if (p.game == ChessPiece.Game.CARO) == caro:
```
La bai cung o nhom "pickable" nhung khong co thuoc tinh `game`. Sua tan goc mot cho:
```gdscript
for p in get_tree().get_nodes_in_group("pickable"):
    if p is ChessPiece and (p.game == ChessPiece.Game.CARO) == caro:
```
> **Quy tac:** vong lap tren mot nhom dung chung thi lap KHONG kieu roi loc bang `is`.
> Kieu o dau vong lap la mot loi hua rang nhom chi co mot loai — loi hua do se vo.

**Da vo LAN THU HAI, dung y het:**
```
_net_give_stone: Trying to assign value of type 'die.gd' to a variable of type 'chess_piece.gd'
```
Lan truoc them `Card` -> vo `_clear_pieces()`. Lan nay them `Die` -> vo `_net_give_stone()`.

Loi that su la o lan truoc minh **chi va cho goi ma bao loi**, khong quet het. Lan nay quet
ca project:
```
grep -rn 'for [a-z_]*: (ChessPiece|Card|Die|Pickable|...) in get_nodes_in_group'
```
16 cho. Chi mot cho that su nguy hiem (`main.gd:362`) vi cac nhom khac deu thuan mot loai,
va `player.gd` von da lap bang **kieu cha `Pickable`** nen xuc xac lot qua duoc.

> **Bo sung quy tac:** lap bang KIEU CHA (`Pickable`) cung an toan va van giu duoc kieu.
> Chi dung `is` khi can loc theo loai con cu the.
>
> **Va: sua loi kieu nay thi phai grep ca project ngay lan dau.** Va mot cho la hen den lan
> them loai tiep theo.

### Canh bao "Integer division" (3 cai)

`card_index / 13` va `rows() / 2` — chia so nguyen CO CHU DINH. Them
`@warning_ignore("integer_division")` ngay tren dong do de noi ro y voi trinh bien dich,
thay vi de canh bao lan trong log lam che loi that.

### ⚠️ Hai bay khi VIET TEST (lai la test sai, khong phai code sai)

1. **`Fusion.rpc()` da la `call_local`.** Test goi ca `m._net_penguin_step(true)` truc tiep
   LAN `Fusion.rpc(m._net_penguin_step, true)` -> may gui buoc HAI lan, may kia mot lan ->
   1.2x vs 1.5x. Nhin nhu loi dong bo, thuc ra la test tu ban vao chan minh.
2. **Chup trang thai qua muon.** Canh cut nga thi 1.6 giay sau tu reset ve man hinh cho.
   Test doc bang o giay thu 23 -> thay "BAM BAT DAU", tuong nhu chua chay gi.
   Sua: bat thang **signal `ended`** o ca hai may va so danh sach — khong phu thuoc thoi diem.

*(Cung nhu vay: `tay=0` ben HOST o lan test truoc KHONG phai loi — JOIN da thoat phong, va
`Pickable._process` co chu dinh tra do ve the gioi khi nguoi cam roi di.)*

---

## 1al. Ban xi dach + ban poker — DA TEST XANH

```
[JOIN truoc xao] xi dach(bo 0)=3 ["hearts_05","hearts_09","spades_03"]
[JOIN truoc xao] poker(bo 1)=4  ["diamonds_09","hearts_09","hearts_A","spades_K"]
[JOIN] XAO LAI rieng bo 0
[JOIN sau xao]   xi dach(bo 0)=0 []
[JOIN sau xao]   poker(bo 1)=4  ["diamonds_09","hearts_09","hearts_A","spades_K"]
[HOST]           poker(bo 1)=4  ["diamonds_09","hearts_09","hearts_A","spades_K"]
```

`hearts_09` co o CA HAI ban — dung, hai bo 52 la rieng biet.

### Van KHONG ep luat, nhung LAM HO PHAN SO HOC

Giu nguyen nguyen tac cua ban co: khong chia bai, khong bat luot, khong tuyen bo ai thang.
Nhung co hai thu may nen lam ho vi nguoi that hay cai nhau ve chung:

**Cong 21 (at 1 hay 11).** Cong at = 11 truoc, qua 21 thi ha dan tung con xuong 1.
```
["A","K"]        -> XI DACH! 21
["A","A","10"]   -> 12        <- ha CA HAI at
["A","09","09"]  -> 19        <- ha mot at
["10","J","Q"]   -> 30 - QUA 21
```

**Xep hang bai poker.** Da test du **9 hang** + hai ca am tinh:
```
A-2-3-4-5 dong chat  -> Thung pha sanh    (sanh nho, at tinh la 1)
10-J-Q-K-A dong chat -> Thung pha sanh
5-6-7-8-9 khac chat  -> Sanh
10-J-Q-K-A khac chat -> Sanh              (at tinh la 14)
A-2-3-4-6            -> Mau thau          <- KHONG phai sanh
duoi 5 la            -> "3 la"
```

> **Bay cua at:** trong mang `RANKS` at o **chi so 0**, nen neu tinh thang thi 10-J-Q-K-A ra
> khoang cach 12 chu khong phai 4 -> mat sanh cao. Phai quy at ve **14** de bat sanh cao, roi
> kiem rieng day `[2,3,4,5,14]` de bat sanh nho.

### Doc theo VI TRI, khong giu danh sach rieng

`CardSpot` quet nhung la dang NAM (`holder_id == 0`) trong ban kinh cua no. Vi tri la bai da
replicate san nen may nao cung tu tinh ra cung mot con so — **khong ton them mot byte mang
nao**, va khong the lech giua hai may.

La dang CAM khong tinh: khong loc thi di ngang qua ban la diem cua nguoi khac nhay loan.
Quet 4 lan/giay chu khong moi frame — day la bang so cho nguoi doc, khong phai vat ly.

### Hai ban HAI BO BAI rieng

Them mot property replicate `deck_id` vao `Card`, va `_da_rut` trong main.gd doi tu
`Array[int]` thanh `Dictionary` so_bo -> mang la da rut. Khong tach thi rut o ban poker lam
het bai ban xi dach.

Nut RUT BAI / XAO LAI do **chinh ban tu dung**, so bo nam trong ten nut (`Draw0`, `Shuffle1`)
— cung cach voi nut dat niem tin cua duong dua. Ban va bo bai cua no di lien mot khoi.

### Mot scene cho ca hai ban

`CardTable` co `@export var poker`. Khac nhau dung hai thu: **bo tri cho ngoi** (xi dach trai
tren 160 do chua cho nha cai; poker chia deu ca vong + o BAI CHUNG o giua) va **cach doc so**.
Mat ban bau duc = tru dep keo gian truc X 1.45 lan — re hon dung luoi bau duc that, ma trong
game khong phan biet duoc.

---

## 1am. Man hinh Esc tu hien o menu chinh — LAN THU BA dinh dung mot loi

```
[1] khoi dong: PauseMenu.visible=true | LeaveButton.disabled=false
```

`disabled=false` la bang chung: **`_ready()` chua tung chay**. Ma `_ready()` khong chay thi
chi co mot nguyen nhan — script khong duoc gan.

`ui/pause_menu.tscn` co khai bao `[ext_resource type="Script" ...]` nhung node goc **thieu
dong `script = ExtResource("1_pause")`**. Scene chay voi zero hanh vi, **khong mot loi nao**.
Da dinh o `player.tscn`, `ready_pad.tscn`, gio la `pause_menu.tscn`.

### Chua tan goc: quet ca project

```
18 file .tscn co khai bao Script  ->  18 file root deu da gan  ->  So file hong: 0
```

Doan script kiem: tim moi `.tscn` co `[ext_resource type="Script"]`, lay node **dau tien
khong co `parent=`** (tuc node goc), kiem trong than no co dong `script = ExtResource(...)`.
Chay lai bat cu luc nao nghi mot scene "chay ma khong lam gi".

### Trang thai BAN DAU thuoc ve .tscn, khong thuoc ve `_ready()`

Truoc: `visible = false` nam trong `_ready()`. Script roi ra -> menu sinh ra **hien** va che
ca man hinh. Sau: `visible = false` nam trong `.tscn`. Script co roi ra lan nua thi menu van
sinh ra o trang thai an — hong im lang, khong hong tren mat nguoi choi.

> **Quy tac:** gia tri mo ta *object sinh ra trong hinh dang nao* thi de trong `.tscn`.
> `_ready()` chi lam nhung viec can chay (noi signal, dung node con).

### Sua kem: dong menu khi CHUA vao phong

`_dong()` truoc day luon khoa chuot vao game. Gio:
```gdscript
Input.mouse_mode = (Input.MOUSE_MODE_VISIBLE if leave_button.disabled
        else Input.MOUSE_MODE_CAPTURED)
```

**`Input.mouse_mode` KHONG kiem duoc bang headless** — khong co display server nen gan gi no
cung ve 0. Phan nay phai nhin bang mat trong GUI.

---

## 1an. Xi dach + poker CO LUAT, he thong lam nha cai — DA TEST XANH

```
[HOST] nguoi trong phong = 2
[HOST] ket qua xi dach: NHA CAI: 20 | H69639: 13 - thua | JOIN: 14 - thua
[JOIN] ket qua xi dach: NHA CAI: 20 | H69639: 13 - thua | JOIN: 14 - thua
[JOIN] ket qua poker:   NHA CAI: Mau thau | JOIN: Cu lu - THANG
[HOST] ban xi dach:     Van moi, chia sau 6 giay.
```

### DOI HUONG: hai ban bai GIO CO LUAT

Truoc day chot "khong luat" giong ban co. Nguoi choi doi y: he thong lam nha cai, chia bai,
va nguoi choi bam rut/dung (xi dach) hoac theo/bo (poker). Ban co van giu nguyen khong luat.

**"He thong" = may MASTER.** No chia, no lat, no tuyen ket qua. Nguoi choi chi gui hai lua
chon. Khong co gi de gian vi nha cai khong co quyet dinh nao tuy y — xi dach rut toi 17 la
luat cung.

### NHIEU NGUOI cung choi: moi nguoi quyet DOC LAP

Thu tu luot la thu dat nhat trong game bai nhieu nguoi. Ne han:

> Moi nguoi bam rut/dung khi nao ho muon. Khi TAT CA da xong thi nha cai moi danh MOT lan,
> roi so voi tung nguoi.

Sòng bai that cung xu ly dung nhu vay (nha cai danh mot lan cho ca ban), nen day khong phai
cat goc — no vua dung luat vua bo duoc toan bo phan dong bo luot.

6 ghe moi ban (`@export`, keo len 10 duoc). Hai ghe gan nhau nhat cach 2.74 m.

### Vong doi mot van

```
CHO --(ai do ngoi)--> GOI (doi 6s cho nguoi khac vao) --> CHOI --> XONG (7s xem ket qua)
                                                                     |
                        con nguoi ngoi -> quay lai GOI, van moi <-----+
                        ban trong      -> ve CHO
```

Ngoi giua chung van dang choi thi duoc bao "cho van sau" — khong chen vao van dang danh.

### Phep tinh diem dung CHUNG mot doan ma

`CardSpot.blackjack_total()` va `CardSpot.poker_rank()` la ham **static**. O hien thi tren
ban dung no, va nha cai tren may master cung dung no. Hai ban sao cua luat cong 21 la hai
co hoi lech nhau.

### La UP phai replicate

Them `face_down` vao `Card` va vao file replication. La tay cua nha cai up cho toi luc lat —
khong replicate thi moi may thay mot kieu.

`CardSpot.cards()` bo qua la up: khong bo thi bang cua nha cai lo luon la tay.

### ⚠️ LAI dinh bay PHONG MA (muc 1r) — lan nay o TEST

```
[HOST] nguoi trong phong = 1
[JOIN] nguoi trong phong = 2      <- hai may o HAI phong khac nhau
```

Test cu cho JOIN vao `rooms[0]`. Lan chay truoc bi `timeout` giet nen phong cu con song voi
mot object nguoi choi cached -> JOIN vao phong ma, thay "2 nguoi" (no + con ma), con HOST
ngoi mot minh o phong moi.

**Chua:** HOST dat ten phong DUY NHAT moi lan chay (`H<timestamp>`), JOIN chi vao phong co
ten do.

> **Dau hieu nhan ra:** hai may bao SO NGUOI KHAC NHAU. Neu chi la loi replicate thi so
> nguoi van phai bang nhau. So lech nhau = hai may khong o cung mot phong.

---

## 1ao. Khung day bao quanh vat dang ngam

> **DA BO** — xem muc 1ay. Khung day nhin nhu cong cu go loi, khong hop game.

```
xuc xac     vat 0.143x0.142x0.143 | 12 thanh, day 0.020 m
quan vua    vat 0.290x0.610x0.290 | 12 thanh, day 0.031 m
la bai      vat 0.260x0.014x0.260 | 12 thanh, day 0.020 m
nut san     vat 0.640x1.080x0.640 | 12 thanh, day 0.045 m
ghe         vat 0.640x0.720x0.680 | 12 thanh, day 0.036 m
```

### Vi sao BO cach "vo ngoai lon mat"

Ban dau dung inverted hull: nhan ban chinh cai luoi roi phong ra theo phap tuyen. Dep tren
vat KHOI KIN — nhung phan lon do trong phong khong kin:

- quan co tien **ho day**
- la bai la **hai tam phang**
- nhan chu la **mat phang mot chieu**

Vo lon mat tren may thu do chi hien duoc vai canh, nhin goc khac la mat. Dung y nhu nguoi
choi bao: "chi hien 1 canh hoac 1 mat, goc nhin bi khuat".

### Khung day khong phu thuoc hinh dang vat

Muoi hai canh cua mot cai hop, dung tu **AABB gop** cua moi luoi trong vat. Luon thay du tu
moi phia. Khung la CON cua vat nen tu bam theo moi phep bien doi, ke ca luc vat dang bay.

```
AABB vat      : 0.1425     (xuc xac)
sau khi noi   : 0.1625     (+7% moi ben)
khung dung ra : 0.1825     (noi + be day thanh)
```

**Be day thanh tinh theo co vat**, kep trong 0.020–0.045 m: vat be nhu vien xuc xac ma thanh
day 4 cm thi khung nuot mat vat; ghe to ma thanh 1 cm thi khong thay.

**`no_depth_test = true`**: khung xuyen qua moi thu, nen canh sau khong bi chinh vat che.

**Mau vang neon `#ffff00`** — khong vat nao trong phong co mau nay nen no khong lan vao nen.

### Hai bay da dinh khi lam

**1. `Array[MeshInstance3D]` khong nhan `Node3D`.**
```
Attempted to push_back an object of type 'Node3D' into a TypedArray,
which does not inherit from 'MeshInstance3D'
```
Danh sach khung con khai bao tu hoi dung vo vien (moi vo la mot MeshInstance3D). Gio moi
khung la MOT node cha om 12 thanh -> phai doi kieu.

**2. `_bao_quanh()` dem ca chinh cai khung.** Khung la CON cua vat, nen goi `_bao_quanh()`
sau khi da to thi AABB gom ca thanh khung — to lai lan nua la khung phinh them mot nac.
Chua: danh dau nhom `"vien_ngam"` va bo qua.

> Test dau tien cua minh bao "noi +0%" cung vi ly do do — **no do vat SAU khi da gan khung**.
> Khong phai code sai, la phep do sai. Do lai dung thu tu thi ra +7%.

### Tat khi quay di qua 60 do

`NGAM_TOI_THIEU = 0.5` (= cos 60°) cho ca nut lan vat. Truoc day vat nhat duoc chi can
`dot > 0` tuc toi 90° — nhin gan nhu vuong goc van tо sang.

---

## 1ap. Don rac tren man hinh o hai ban bai — DA TEST XANH

```
[1] tong nut trong phong = 20  (truoc 22)
    nut o hai ban bai: [Start0, Start1]      <- truoc: 4 nut Yes/No
[2] o dat bai: chu nhat 1.80 x 0.62 m | chu khi trong: ''
[3] la bai o nhom 'pickable'? false | o nhom 'card'? true
[4] so la bai ma vong ngam co the cham toi = 0
[HOST] ban_dang_ngoi() = 0 | bang: 2 nguoi da ngoi. Bam CHIA BAI de bat dau.
[HOST] ket qua: NHA CAI: 18 | H70921: 18 - HOA | JOIN: 16 - thua
[JOIN] ket qua: NHA CAI: 18 | H70921: 18 - HOA | JOIN: 16 - thua
```

### Van de: 3D KHONG PHAI cho de treo chu

Anh chup cho thay man hinh kin chu noi — 6 chu "GHE n", 6 chu "NGOI VAO DAY", 4 nut
Yes/No, ten ban, bang thong bao. `Label3D` + `billboard` khong bao gio bi khuat nen tat ca
chong len nhau, va chu o xa 20 m van to bang chu o ngay truoc mat.

**Bon cach chua, theo thu tu hieu qua:**

| | truoc | sau |
|---|---|---|
| Nut o ban bai | 4 (`Yes0/No0/Yes1/No1`) | **1** (`Start<n>` = CHIA BAI) |
| Chu tren o dat bai | "GHE 1".."GHE 6" luon hien | **rong** khi trong |
| Rut/dung | nut noi giua phong | **phim 1 / 2 + note tren HUD** |
| Chu ghe | "NGOI VAO DAY" 40pt | "NGOI" 28pt, **tat khi da ngoi** |

> **Quy tac:** thu chi lien quan toi MOT nguoi thi de tren HUD cua nguoi do, dung treo vao
> khong gian chung. Sau ghe x hai lua chon = 12 mau chu ai cung phai nhin, trong khi moi
> nguoi chi can doc hai dong cua rieng minh.

### O dat bai: hinh chu nhat, khong phai hinh tron

Vong tron ban kinh 0.75 m to hon bo bai rat nhieu nen sau o chong lan kin mat ban. Doi sang
**khung chu nhat dung bang hang bai** (1.8 x 0.62 m) va **xoay theo huong ghe**, nen hang bai
nam ngang truoc mat nguoi ngoi. Khung ghep tu bon thanh mong chu khong phai mat phang dac —
dac thi che mat ni.

### La bai KHONG cam len duoc nua

```gdscript
func _ready() -> void:
    super()
    add_to_group("card")
    remove_from_group("pickable")   # chan o GOC
```
Rut khoi nhom "pickable" thi `_nearest_pickable()` khong con thay no — vong ngam khong bat
vao la bai, va khong can them mot cai `if` nao o cho bam.

Doi lai: moi cho quet bai phai dung nhom **"card"**, khong dung "pickable" nua. `_xoa_bai()`
da doi theo.

### Bo dem nguoc 6 giay, thay bang nut CHIA BAI

Truoc: ngoi vao la chay dong ho, het gio tu chia. Nguoi vao sau bi hut. Gio: ngoi bao nhieu
nguoi cung duoc, ai bam CHIA BAI thi moi bat dau. Xong van thi bai bien mat nhung nguoi van
ngoi nguyen — bam lan nua la van moi.

### `pha_ban` — ban sao cua pha tren MOI may

`_pha` chi master biet. HUD tren may nguoi choi can biet "co dang toi luot chon khong" de
quyet dinh hien nhac phim. Nen `_bao()` gui kem mot RPC `_net_pha`.

Nguoc lai, **"toi co dang ngoi khong" thi KHONG can replicate**: `CardSeat` la Area3D bat
chinh than nguoi choi cua may nay, nen `toi_dang_ngoi` luon dung va khong ton byte nao.

---

## 1aq. Bo HAN nut o ban bai — DA TEST XANH

```
[1] tong nut trong phong = 18 | nut o hai ban bai = 0
[HOST] di vao ghe (KHONG bam nut nao)
[HOST] 1 nguoi da ngoi. Chia bai sau 6 giay.
[JOIN] ngoi vao GIUA luc dem nguoc
[HOST] ket qua: NHA CAI: 21 | H71447: 15 - thua | JOIN: 12 - thua
[JOIN] ket qua: NHA CAI: 21 | H71447: 15 - thua | JOIN: 12 - thua
[..]   van moi tu mo: 2 nguoi da ngoi. Chia bai sau 6 giay.
```

Ban bai gio **khong con mot cai nut nao**. Ngoi vao ghe la mo dem nguoc 8 giay; ai ngoi kip
trong luc do thi vao chung van. Xong van, con nguoi ngoi thi tu mo van moi — dung day la nghi.

Ba lua chon con lai deu la PHIM: `1` / `2`, nhac hien tren HUD cua rieng nguoi ngoi.

### ⚠️ O DAT BAI CHONG NHAU — va mot phep thay SILENT FAIL

Do lan dau: o rong **1.48 m** ma hai o ke nhau chi cach **1.46 m**.

Hai so quyet dinh:
```
khoang cach hai o ke nhau = 2 * ban_kinh_dat_o * sin(goc_giua_hai_o / 2)
```
- gian goc: 200 do -> **240 do** (6 ghe, moi khoang 48 do)
- day o ra xa tam: `radius * 0.6` -> **`radius * 0.82`**
- thu o lai: khoang cach bai 0.26 -> 0.22 m, la bai 0.34 -> 0.28 m

Ket qua: ho **0.52 m** (xi dach) va **0.74 m** (poker), o xa nhat 2.71 m van nam gon tren
mat ban ban kinh 3.0.

> **Bay:** lan sua dau tien, phep thay chuoi cho `radius * 0.6` **khong khop** (sai so tab)
> va minh khong dat `assert` o dong do -> no hong IM LANG, chi doi duoc goc 240 do con ban
> kinh giu nguyen. Test bat duoc vi no in ra CA BA so (rong / khoang cach / ho) chu khong
> chi in "OK".
>
> **Quy tac:** moi phep thay chuoi phai co `assert`. Va test phai in SO DO DUOC, khong in
> ket luan — "OK" thi khong bao gio phat hien duoc no dang OK vi ly do sai.

### Slogan dua ga

`"DAT NIEM TIN ROI BAM DUA"` -> **`"TRAO NIEM TIN - NHAN TAI LOC"`**

---

## 1ar. "Chu phong khong thay nhan vat nguoi khac" — CHUA TAI HIEN DUOC

Nguoi choi bao: may chu phong khong thay nhan vat cua nguoi tham gia, nhung nguoi kia van
thay nhan vat cua chu phong.

### Da thu tai hien, KHONG ra

Ep hai may vao CUNG MOT phong chac chan (ten phong duy nhat), chay lai nhieu lan:
```
[HOST] PHONG HostA-5BFT · ban la #1 · CHU PHONG | 2 nguoi trong phong
[JOIN] PHONG HostA-5BFT · ban la #2            | 2 nguoi trong phong
```
Chu phong luon thay du. **Khong ket luan duoc la code sai.**

### Nhung tim ra mot thu that: DANH SACH PHONG CO NHIEU PHONG

Luc chay thu, danh sach phong that su co:
```
["KKKK(2/10)", "HostA-5BFT(1/10)"]
```
`KKKK` la phien choi khac. Test cua minh chon `rooms[0]` -> vao KKKK, thay 3 nhan vat la;
con HOST ngoi mot minh o phong cua no.

**Trieu chung cua "ngoi nham phong" giong het lỗi dong bo:**

| | Ngoi nham phong | Loi dong bo that |
|---|---|---|
| Chu phong thay | 1 nguoi | 2 nguoi, 1 nhan vat |
| Nguoi kia thay | co nhan vat (cua phien cu) | 2 nguoi, 2 nhan vat |

Truoc day tren man hinh **khong co gi phan biet duoc hai truong hop nay** — do la van de
that, du nguyen nhan goc la gi.

### Ba thu da lam

**1. Ten phong DUY NHAT moi lan tao.** Truoc: ten phong = ten nguoi choi, choi hai phien lien
tiep la hai phong trung ten. Sau: `HostA-5BFT` (them 4 ky tu ngau nhien). Hai phong khong the
trung ten nua.

**2. `set_player_ttl_ms(0)` khi tao phong.** Nguoi mat ket noi bi bo suat ngay. Do lai thi
mac dinh cua SDK **von da la 0** roi (`player_ttl_ms=0 empty_room_ttl_ms=0`) nen dong nay chi
la viet ro y dinh, khong sua duoc gi — ghi lai de sau khoi do lai.

**3. HUD hien TEN PHONG va bao khi hai con so lech nhau.**
```
PHONG HostA-5BFT · ban la #1 · CHU PHONG
2 nguoi trong phong — moi thay 1 nhan vat
```
- `peer` = Photon bao co bao nhieu may trong phong
- `nhan vat` = bao nhieu object Player that su co mat tren may nay

Hai so bang nhau = binh thuong. **Lech nhau = loi dong bo THAT.** Con neu chu phong thay
"1 nguoi" trong khi ban minh thay "2 nguoi" thi hai may **khong o cung phong**.

> `Fusion.get_room().get_name()` tra ve **chuoi rong** — khong dung duoc. Phai tu giu ten
> phong trong `NetManager.room_name` luc tao/vao phong.

### Lan sau bao loi thi doc hai dong nay

Chup man hinh CA HAI may, doc dong dau (ten phong) va dong hai (so nguoi / so nhan vat).
Hai dong do phan biet duoc ngay hai nguyen nhan hoan toan khac nhau.

---

## 1as. Canh cut lun vao ray, va ha ti le song

```
[1] canh cut: day o y=0.600, ray cao 0.60 -> lun 0.000 m   (truoc: lun nua nguoi)
[2] ti le di tron 8 buoc = 0.16%  (truoc 3.0%)
```

### Model poly.pizza lay TAM lam goc toa do

Penguin co Y tu **-87.9 toi +87.9** — goc toa do nam giua bung. Dat thang vao mat ray thi
nua duoi lun vao trong.

Khong viet so cung `0.30` (doi `MODEL_SCALE` la sai ngay). Do AABB luc nap roi keo len:
```gdscript
inst.position.y = -box.position.y * MODEL_SCALE
```
Cung mot thu doan da dung cho prop Kenney o muc 1ae — **model tai ve gan nhu khong bao gio
lay day lam goc**, phai luon nan lai.

### Ti le song moi

```
truoc:  95 90 82 72 60 48 35 22   (%)
sau:    90 80 70 58 46 34 24 15
```
Di toi 3.0x: 29% · 4.0x: 13% · 12.0x: 0.16%. Truoc do toi 4x qua de nen chang ai phai can
nhac, ma **can nhac moi la toan bo cai hay** cua tro nay.

---

## 1at. Thu gon khu board game, bang luat, tu dua ga — DA TEST XANH

```
co vua       8.40 -> 4.40 m      (52%)
caro        13.50 -> 6.75 m      (50%)
ban bai      3.00 -> 1.60 m ban kinh (53%)
dua ga    4.8 x 8.0 tren SAN -> 2.08 x 2.20 m TREN TU cao 0.95 m
san         28   -> 18 m ban kinh   (vat xa tam nhat 14.3 m)
```

### ⚠️ LA BAI TRAN KHOI O — offset dat NHAM HE TOA DO

```gdscript
# sai
return spots[seat].global_position + Vector3(_offset(i), 0.02, 0.0)
```
O dat bai da duoc XOAY theo huong ghe, nhung offset lai cong theo truc X cua **THE GIOI**.
Bai trai ngang trong khi khung nam cheo -> tran het ra ngoai.

```gdscript
# dung: offset trong he toa do CUA O, va tra ve ca GOC XOAY
func _cho(o: CardSpot, i: int) -> Transform3D:
    return Transform3D(o.global_transform.basis, o.to_global(Vector3(_offset(i), 0.02, 0.0)))
```
Do lai: lech khoi truc o **0.000 m**, la xa nhat cach tam o 0.280 m (nua khung 0.42).

> **Quy tac:** he node da xoay thi moi offset phai di qua `to_global()`. Cong thang vao
> `global_position` la lang le bo qua phep xoay.

### Khung o chong nhau — cong thuc quyet dinh

```
khoang cach hai o ke nhau = 2 * ban_kinh_dat_o * sin(goc_giua_hai_o / 2)
```
Thu nho ban tu 3.0 xuong 1.5 lam khoang cach tut con 1.00 m trong khi khung dai 1.19 m.
Chua bang ba so: ban kinh 1.5 -> **1.6**, khoang cach bai 0.17 -> **0.14**, va **so la toi da
6 -> 5** (rut toi la thu sau ma chua qua 21 gan nhu khong xay ra, ma chua cho cho no thi khung
dai them 14 cm). Ket qua: khung 0.84 m, khoang cach 1.07 m, **ho 0.23 m**.

### Tu dua ga: bo duong dua tren san

Dang lay theo may Duck Race: than tu, long mang **DOC LEN** ve phia dich, vom bien hieu, o
caro vach dich, nut dat cuoc nho gan thang mat truoc duoi tung lan, nut DUA to ben hong.

Mang doc vi neu phang thi lan gan che het lan xa. May thung ngoai doi doc dung vi ly do do.

**Hai lan phai sua nhan:**
1. Tam nhan noi "XANH DUONG" canh nhau 26 cm -> de len nhau kin mit.
2. Doi sang dat ten len NUT -> van de vi nut cung cach nhau 26 cm.
3. Cuoi cung: **nut chi hien SO NGUOI DA TIN**. Ban than nut da mang dung mau cua lan ngay
   phia tren no, viet them ten mau la thua. Mot dong "BAM MAU DE TIN" cho ca hang thay cho
   tam cai nhan.

### `Pressable` them kieu GAN MAT PHANG

`@export var compact` bo cot va thu nho, de gan len mat tu / mat ban. Nut co cot chi hop khi
no moc tu san. Them `set_label()` de doi chu luc dang chay (dem so nguoi tin).

### Bang luat dat trong THE GIOI, khong phai HUD

Dung luat loc cua ca du an: thu gi nguoi khac khong thay duoc thi khong dang ton tai. Nguoi
moi di ngang doc duoc ma khong phai mo menu nao.

**KHONG billboard.** Bang luat la tam bien that dung mot cho, co mat truoc mat sau. Xoay theo
mat nguoi xem thi no troi lo lung va chu de len moi thu phia sau.

> **Bay:** dat bien o phia sau ban thi mat chu phai quay ve phia ban (−Z), khong phai +Z.
> Lan dau chup ra mot tam mau xanh tron — dang nhin vao lung tam bien.

### Poker viet lai thanh TEXAS HOLD'EM THAT

Bang luat ghi Hold'em ma game lai la "5 la doi dau nha cai". Bang mo ta mot tro khac voi tro
dang chay thi te hon la khong co bang. Da **doi GAME cho khop BANG**, khong phai nguoc lai.

```
[HOST] chia xong:        TRUOC FLOP - con 1 nguoi - THEO hay BO? | bai chung ngua = 0
[HOST] sau THEO lan 1:   SAU FLOP                                | bai chung ngua = 3
[HOST] sau THEO lan 2:   SAU TURN                                | bai chung ngua = 4
[HOST] sau THEO lan 3:   SAU RIVER                               | bai chung ngua = 5
[HOST] sau THEO lan 4:   H42740: Mot doi | => H42740 THANG voi Mot doi
```

**Chia:** moi ghe 2 la RIENG (ngua), 5 la CHUNG dat san giua ban nhung UP het.
**Bon vong:** truoc flop -> sau flop (lat 3) -> sau turn (lat 4) -> sau river (lat 5) -> ha bai.
Moi vong ai cung phai quyet lai (`_xong` xoa sach), ai bo bai thi bai rieng up lai va khong
phai quyet nua.

### Xep hang bo 5 la MANH NHAT tu 7 la

Hold'em cho 7 la, phai thu het **C(7,5) = 21 to hop**. Duyet thang nam vong lap long nhau —
21 lan cham diem moi phan tu giay la khong dang ke, khong can thuat toan khon hon.

Da kiem 6 ca co dap an ro rang:
```
A-K bich rieng + Q-J-10 bich chung  -> Thung pha sanh
doi 8 rieng + 8 chung               -> Xam
5-6-7 chung + 4-8 rieng             -> Sanh
tu quy K trong 7 la                 -> Tu quy
3 con J + doi 4                     -> Cu lu
khong ghep duoc gi                  -> Mau thau
```

### O cua ghe phai NHIN DUOC bai chung

`CardSpot.chung` tro toi o giua ban. O cua tung ghe cong 5 la chung vao 2 la rieng roi cham
`best_rank()`, nen **bang diem tren tung ghe hien luon bo manh nhat hien tai** — dung cai
nguyen tac "may lam ho phan so hoc" da theo tu dau.

O ghe poker chi con 2 la nen khung thu xuong **0.42 m** (xi dach van 0.84 m cho 5 la).

### Highlight: doi mau va them ghe

Vien den -> **vang nhat `#fff3c4`**: noi tren san xam, ni xanh, go nau. Vien den chim han vao
nhung vat von da sam mau. Them ghe vao danh sach ngam duoc (chu "DI VAO DE NGOI" — ghe khong
bam duoc, di vao la ngoi).

---

## 1au. Cot doc bai chung — bai nam phang thi khong doc duoc

Nguoi choi bao: tu cho ngoi khong nhin ra nam la bai chung o giua ban la la gi. Dung — mat
ban cao 0.75 m, mat nguoi 1.65 m, la bai canh 0.34 m nam PHANG cach 1.5 m: goc nhin qua doc,
hinh bi bep gan het.

**Chua: mot TANG TRONG bon mat nang cao giua ban.** Bai dan len mat ngoai tang, dung thang,
nen doc duoc tu cho ngoi. Bon mat quay ra bon huong — khong billboard, khong xoay theo camera,
ai ngoi dau cung co mot mat quay ve phia minh.

### HOAN TOAN CUC BO, khong ton mot byte mang nao

Tang trong chi **doc lai** nam la bai chung dang nam tren ban — ma chung von la object mang
da replicate ca `card_index` lan `face_down` lan vi tri. May nao cung tu dung ra dung cung
mot cot.

> Them mot object mang nua chi de hien thi la tao ra **nguon su that thu hai** co the lech voi
> ban. Doc lai tu thu da co thi khong the lech.

### Hai phep tinh hinh hoc bat buoc

**1. Tang trong phai NAM SAU bai, khong che bai.**
Lan dau dat loi tru o giua roi day bai LUI ra sau -> tru nam TRUOC la giua, che mat no.
Dung: bai dan o `drum_r + 0.012`, tuc ngay ngoai mat tru.

**2. Ban kinh tang KHONG duoc nho hon nua be rong mot hang bai.**
```
be rong hang bai   = 5 x 0.145 = 0.72 m
cung mot mat o r   = 2*pi*r/4
r = 0.40 -> cung 0.64 m  ->  TRAN, hai mat ke nhau cat qua nhau
r = 0.52 -> cung 0.84 m  ->  ho 0.11 m, vua
```
Bon tam phang quanh mot cai tru manh la **khong xep duoc** — day la rang buoc hinh hoc, khong
phai chuyen tinh chinh.

**3. Tang trong NANG CAO 0.30 m khoi mat ni.** Dat sat ban thi no de len chinh nam la bai
phang o giua. Nang len thi bai phang van nhin tu tren xuong duoc, con tang trong doc duoc tu
cho ngoi.

### `card_size` phai REPLICATE

Bai chung to hon bai rieng (0.34 vs 0.26) va master dat co do. Khong replicate thi **chi may
master thay la to**, moi nguoi khac van thay co mac dinh — dung loai loi im lang da dinh
nhieu lan voi property khong `@export`.

---

## 1av. Cuoc poker day du — DA TEST XANH

```
[1] blind xong: pot=30                       (SB 10 ghe 1, BB 20 ghe 2)
    g0 theo  -> pot=50  muc=20
    g1 TO    -> pot=170 muc=130
    g2 theo  -> pot=280
    g0 theo  -> VONG 1: muc ve 0, ai cung phai hanh dong lai
    ... check het 3 vong ...
[2] Mot doi | Cu lu | Hai doi | => THANG voi Cu lu (+60 chip)
[3] tong chip 3 ghe = 3000     (khong sinh, khong mat)
```

### ⚠️ Fusion KHONG serialize duoc `PackedInt32Array` — va `call_local` GIAU mat loi do

Goi trang thai cuoc (pot, muc, luot, dealer, chip tung ghe) vao mot `PackedInt32Array` roi
`Fusion.rpc(...)`:

```
WARNING: FusionRpcSerializer: Unsupported type 30 in RPC argument - will deserialize as NIL
```

Type 30 = `PACKED_INT32_ARRAY`. May kia nhan duoc **NIL**.

**Phep thu cua minh bao "OK" — va no sai.** Vi `@rpc("call_local")` chay ham NGAY TAI CHO
truoc, khong di qua bo serialize. Nhin man hinh thay in ra dung, trong khi duong mang da hong.

> **Quy tac:** thu kieu tham so RPC thi phai doc **canh bao cua serializer**, dung tin vao
> ket qua `call_local` in ra. Hoac thu bang HAI may.

Chua: goi ca cum vao **mot chuoi** `"pot,muc,luot,dealer,han,ghe,chip,cuoc,co,..."`. Chuoi la
kieu da chung minh chay qua mang that (bang thong bao cua ban dung no tu dau).

### Mot RPC cho ca cum, khong phai moi con so mot RPC

Gui rieng tung cai thi co luc may khac thay **pot moi voi luot cu**. Goi chung: hoac thay het
trang thai moi, hoac thay het trang thai cu.

### ⚠️ Chi so HANG bai la khong du — phai co la cao va kicker

Van test dau tien: ba nguoi cung "Mot doi" -> **hoa ca ba, chia deu pot**. Sai: doi K phai an
doi 5.

`poker_rank()` chi tra ve hang (0..8). Them `poker_score()` goi ca hang lan thu tu quan trong
cua tung la vao MOT so nguyen, co so 15 (at = 14 nen can 15 gia tri):

```
diem = hang·15⁵ + v1·15⁴ + v2·15³ + v3·15² + v4·15 + v5
```

`v1..v5` xep theo **so la trung giam dan, roi gia tri giam dan** — dung thu tu quan trong cho
moi hang con lai (tu quy, cu lu, xam, hai doi, mot doi, thung, mau thau dung chung mot phep).
Sanh xu ly rieng vi chi can mot con so: la dinh, va sanh nho A-2-3-4-5 co dinh la **5** chu
khong phai at.

Da kiem 9 cap co dap an ro rang, sai 0:
```
doi K + kicker  >  doi 5 + kicker
doi 9 kicker A  >  doi 9 kicker K
hai doi K-2     >  hai doi Q-J
sanh den A      >  sanh den K
sanh nho A-5    <  sanh 2-6          <- at tinh la 1
tu quy A > tu quy K | cu lu A-2 > cu lu K-Q | thung A > thung K | mau thau A > mau thau K
hai bo giong het nhau  ->  HOA
```

### Vong cuoc ket thuc khi nao

Khi moi nguoi CON CHOI (chua bo, chua all-in) da hanh dong ke tu lan to gan nhat VA da dat du
muc cao nhat. `_ghe_ke()` quet vong tron tim nguoi dau tien chua thoa; het thi tra -1 = xong
vong.

**To la dat lai ca vong:** ai da hanh dong roi cung phai tra loi lan nua.

### Bai rieng: lan dau du an co thu HAI MAY HIEN THI KHAC NHAU

Trang thai MANG cua bai rieng la "up" voi tat ca. May cua chinh chu bai tu lat hinh len cho
ho xem (`Card.lo_cuc_bo`). Khong ai ghi gi len mang.

O dat bai cham diem theo `hien_voi_toi()` nen **o cua ban hien bo bai cua ban, o nguoi khac im
lang** — dung cai can.

> Noi that: `card_index` van replicate toi moi may, nen ai sua client van doc duoc bai nguoi
> khac. Giau that phai de master khong gui `card_index` cho nguoi ngoai, ma Fusion khong co
> kieu gui-rieng-tung-nguoi. Choi voi ban be thi khong dang ban tam.

### Con thieu / da rut gon co chu dinh

- **Khong co side pot.** Nguoi all-in it hon thi phan chip vuot qua duoc tra lai nguoi dat
  nhieu hon, roi con lai chia cho nguoi thang. Du dung cho van thuong; nhieu muc all-in long
  nhau thi chia khong hoan toan chuan.
- Het gio 20 giay thi **bo bai**, khong tu check.

---

## 1aw. Bam nut la nut PHINH TO va o luon nhu the

Trieu chung: tam nut dat cuoc tren tu dua ga bam vai cai la dinh thanh mot mang lien.

```gdscript
func _flash() -> void:
    tween.tween_property(m, "scale", Vector3.ONE * 0.85, 0.06)
    tween.tween_property(m, "scale", Vector3.ONE, 0.12)   # <- xoa luon co da thu nho
```

Nut phang duoc thu nho luc dung (`scale = 0.231`). Hieu ung bam tween ve **`Vector3.ONE`**
— tuc co cua nut SAN. Bam mot cai la nut nhay len gap bon lan va **o luon nhu the**, vi
tween da ghi de gia tri cu.

**Chua: nho `_co_goc` luc dung, tween ve dung no.**

> **Quy tac:** hieu ung tren mot thuoc tinh phai quay ve GIA TRI CUA CHINH OBJECT DO, khong
> phai ve hang so mac dinh. Vector3.ONE dung duoc chi vi truoc day moi nut deu co scale 1.

Do lai: bam ba lan lien, scale giu nguyen 0.231; duong kinh 0.129 m trong khi lan cach nhau
0.26 m. Nhan doi so nguoi dat cuoc van hien binh thuong.

---

## 1ax. Bon loi tim ra tu mot lan choi thu

### ⚠️ 1. O dat bai dem SAI so la — so toa do sai he quy chieu

Ghe co 2 la ma bang chi hien diem cua 1 la. Do duoc: ghe o goc -120 do dem duoc **1/5** la.

```gdscript
var d := card.global_position - global_position          # sai: truc THE GIOI
if absf(d.x) <= size.x * 0.5 and absf(d.z) <= size.y * 0.5:
```
O da duoc XOAY theo huong ghe. Tru vi tri roi so truc the gioi thi hang bai nam cheo, la
ngoai cung roi ra khoi khung tinh:
```
la ngoai cung o local dx=-0.32, ghe goc -120 do
  toa do THE GIOI: dx=+0.160 dz=-0.277   nua khung z = 0.19  ->  LOT RA NGOAI
  toa do CUA O:    dx=-0.320 dz= 0.000   ->  trong khung
```
Chua: `to_local()`. Do lai ca 6 ghe: **5/5 la, sai 0**.

> Dung mot loi voi cho DAT bai da sua o muc 1at. Lan do minh sua cho GHI ma khong soat cho
> DOC. **He node da xoay thi MOI phep so toa do phai di qua `to_local()`, ca hai chieu.**

### ⚠️ 2. Nut gan mat ban khong bam duoc

`_nearest_pressable()` ngam vao `vi_tri_nut + 1.0 m` — con so viet cho nut moc tu san (dau
nut o do cao 1.0 m). Nut phang tren mat tu thi dau nut chi cao vai xang-ti-met:

```
RaceButton   nut o y=0.90 | ngam CU y=1.90 | ngam MOI y=0.95 | lech 0.95 m
ResetButton  nut o y=0.00 | ngam CU y=1.00 | ngam MOI y=1.00 | lech 0.00 m
```
Phai ngam cao hon nut gan MOT MET moi trung. Chua: `Pressable.diem_ngam()` tu bao cho ngam
cua chinh no.

### 3. Bam nham nut khi dung tren ban co

Truoc: nut duoc kiem TRUOC, thang vo dieu kien. Dung tren ban nhin thang vao quan tot ngay
duoi mui van bam trung cai nut cach 2.5 m o ria.

Chua: cham diem CA HAI (nut va vat) roi chon cai **nam giua tam nhin hon**. Cong them mot
be be-tong that giua nut va ban co, dung nhu nguoi choi de nghi.

### 4. Con tro giua man hinh

Mot cham trang co vien den o chinh giua. Tat khi mo man hinh Esc.

### Nem do: cung bay theo QUANG DUONG, va co cu nay

Truoc: moi cu nem deu bay dung 0.75 giay voi cung vong 1.1 m — tha xuong chan cung bay cham
y nhu quang qua nua phong.

```
nem 0.4 m -> bay 0.16 s | vong 0.23 m
nem 1.5 m -> bay 0.18 s | vong 0.54 m
nem 4.0 m -> bay 0.46 s | vong 1.30 m
nem 9.0 m -> bay 0.99 s | vong 1.30 m
```

**Cu nay:** cung chinh dung o 86% quang duong, phan con lai la hai cu nay nho dan (16% roi
5% do vong) tren DUNG diem dap da tinh. Nen vat van ket dinh dung o ban co — no nay vao cho
thay vi dan phich xuong.

Do duoc do cao tren diem dap: `0.16 0.26 0.28 0.23 0.11 0.02 | 0.07 0.10 0.10 0.07 0.02`
— hai cai bum ro rang.

---

## 1ay. Highlight: bo khung day, chuyen sang VO PHAT SANG

Khung day 12 thanh (muc 1ao) bi bo. Ly do nguoi dung neu: "trong nhu debug tool", khung
qua to, thanh qua day, che vat va xau. Do la mot cai HOP bao quanh — no khong bao gio om
theo hinh dang vat, quan vua tron van bi nhot trong hop vuong.

### Cach lam bay gio

Nhan ban CHINH cai luoi cua vat, phong to 6%, to cyan trong suot co phat sang.

```gdscript
const VIEN_MAU := Color("00ffff")
const VIEN_NOI := 1.06        # to hon vat 6%
const VIEN_ALPHA := 0.5
const VIEN_SANG := 2.5
```

Vat lieu: `TRANSPARENCY_ALPHA`, `SHADING_MODE_UNSHADED`, `emission_enabled`,
`emission_energy_multiplier = 2.5`, `CULL_DISABLED`, `render_priority = 1`, tat do bong.

### Ba cho de sai, deu da vap

**1. Phong to quanh TAM CUA LUOI, khong quanh goc toa do node.**

Goc toa do cua luoi thuong khong nam giua no — quan vua lay chan de lam goc. Nhan thang
`scale` thi vo TRUOT LECH di chu khong no deu: day phinh ra, dinh hut vao.

```gdscript
var tam: Vector3 = m.mesh.get_aabb().get_center()
vo.scale = Vector3.ONE * VIEN_NOI
vo.position = tam * (1.0 - VIEN_NOI)
```

**2. Vo la con cua luoi goc, nen phai LOC no ra khi quet luoi lan sau.**

Khong loc thi lan ngam thu hai boc luon vo cua lan thu nhat — moi lan ngam vo phinh them
6%. `_luoi_cua()` bo qua moi node trong nhom `"vien_ngam"`.

**3. `CULL_DISABLED` la bat buoc.**

Luoi HO (quan vua tien hoc day, la bai la hai tam phang, nhan chu la mat mot chieu) ma chi
ve mot mat thi nhin tu phia kia la mat vo. Day cung chinh la ly do bo cach "vo lon mat"
(inverted hull) truoc do — nhung o day ta ve CA HAI mat nen luoi ho van duoc boc.

### So do

```
xuc xac   vat 0.143/0.142/0.143 -> vo 0.151/0.151/0.151   ti le 1.060/1.060/1.060  lech tam 0.0000 m
la bai    vat 0.260/0.014/0.260 -> vo 0.276/0.014/0.276   ti le 1.060/1.000/1.060  lech tam 0.0000 m
nut bam   vat 0.640/1.080/0.640 -> vo 0.678/1.112/0.678   ti le 1.060/1.030/1.060  lech tam 0.0114 m
```

La bai va nut bam khong dat 1.060 theo truc dung vi chung gom NHIEU luoi, moi luoi phong
quanh tam CUA NO — khoang cach giua cac luoi khong doi. La bai day 0 mm thi nhan 6% van la
0 mm. Chap nhan duoc: cai mat la duong vien nhin thay, va duong vien deu no du 6%.

### Da kiem

- To lai lan hai cho ra dung so cu (`GIONG HET`) — khong phinh don.
- `_tat_vien()` xong con lai 0 vo tren ca ba vat — khong ro ri node.
- Vat lieu doc lai tu vo: `albedo=00ffff alpha=0.50 emission=00ffff energy=2.5`.
- Anh chup: xuc xac con doc duoc so cham, quan vua con thay hinh, vo om theo duong net.

Giu nguyen tu muc 1ao: nguong 60 do (`NGAM_TOI_THIEU`), chi dung lai vo khi doi muc tieu
(`_dang_ngam`), va cach cham diem chon muc tieu. Ham `_bao_quanh()` (AABB gop) da XOA —
khong con ai goi, vi vo bay gio bam theo luoi chu khong theo hop.


## 1az. Bam E trung nut XEP LAI CO khi dang ngam quan co

### Nguyen nhan goc: HAI luat chon muc tieu lech nhau

- `_cap_nhat_goi_y()` (phan to sang + chu "E — ..."): cai nao NAM GIUA TAM NHIN hon thi thang.
- `_unhandled_input()` (phim E): nut LUON thang, mien nut trong tam 3 m va lech duoi ~56 do
  (`dot > 0.55`).

Anh chup: quan xe goc ban sang len, chu ghi "E — NHAT", bam E lai trung nut sau be. Man hinh
noi mot dang, phim lam mot neo.

Sua: phim E lam DUNG tren `_dang_ngam` — cai dang duoc to sang. Chi con mot cho quyet dinh
muc tieu. Sua o day la sua cho MOI nut trong phong (caro, dua ga, canh cut, ban bai), khong
chi ban co.

### Doi nut sang be ben hong (theo anh tham chieu nut PLAY gan tren tru)

Be dai 5.2 m sat mep ban (x = -9.55) thay bang MOT cai be 0.5 x 1.0 x 1.6 m o x = -10.8,
cach mep ban 1.1 m. Hai nut thanh nut phang (`compact`) nam tren mat be, cao 1.05 m.
Ten node giu nguyen nen `main.gd` khong phai sua.

So do (cung cong thuc cham diem voi Player; quan tren hai cot phia tay, luoi cho dung 0.5 m):

```
                          tinh huong ngam quan | nut trong tam 3 m | goc nho nhat quan->nut
CU  (cot san x=-9.9)                      1146 |               880 |  21.8 do
MOI (tren be x=-10.8)                     1146 |               442 |  37.6 do
```

Luat E cu bat nut o bat ky goc nao duoi ~56 do, ma goc nho nhat chi 21.8 do — nen bam nham la
chuyen chac chan xay ra, khong phai xui. Gio nut o xa hon (37.6 do) VA phim E theo to sang.

Chua lam: nut caro (`CaroWhite/Black/Reset`) van nam truoc be caro nhu cu. Sua phim E da che
luon cho do; neu choi thu van thay vuong thi doi len be giong ban co.

Chua kiem duoc bang anh chup: luc sua, editor dang mo nen DLL Fusion bi khoa, khong chay duoc
scene co script mang. Da kiem: `lobby.tscn` doc lai dung vi tri + `compact` + `label_size`.

## 1ba. Chat chu va voice — CHUA LAM, can doc

Tai lieu nguoi dung gui la **Photon Chat (C#/C++)** va **Photon Voice 2 (Unity)**. Ca hai
KHONG dung duoc truc tiep o day:

- Voice 2 ghi ro la SDK cho Unity (Unity 2019.4+, IL2CPP). Du an la Godot + GDScript.
- Addon `addons/fusion` (Fusion Godot) khong co lop chat hay voice nao — da quet chuoi trong
  DLL, chi co RPC serializer.

Nhung gi Godot 4.7.1 CO (kiem bang ClassDB):
`AudioStreamMicrophone`, `AudioEffectCapture` (thu mic), `AudioStreamGenerator` (phat).
KHONG co bo nen Opus. `audio/driver/enable_input` dang `false`.

**Chat chu**: khong can Photon Chat — gui qua `Fusion.rpc` nhu moi su kien khac. La su kien nen
nguoi vao sau khong thay tin cu.

**Voice**: tu lam duoc ve ly thuyet (mic -> cat khuc -> RPC -> AudioStreamGenerator) nhung khong
nen, am thanh tho rat nang: 16 kHz mono 16 bit = 256 kbps MOT nguoi noi. Can doc truoc khi lam:

1. Fusion Godot: RPC toi da bao nhieu byte mot lan; co gui kieu unreliable khong (am thanh mat
   goi thi bo, khong gui lai).
2. Photon Cloud goi Free: gioi han tin/giay va bang thong moi phong — day voice qua phong game
   co bi ngat khong.
3. Photon Voice co ban nao dung ngoai Unity (native/C++) goi duoc tu GDExtension khong.


## 1bb. Chat chu + bong bong tren dau — DA TEST XANH (2 may, Photon that)

- `ui/chat.gd` (node `Chat` trong `hud.tscn`): Enter mo o go, Enter gui, Esc huy. Giu 8 dong,
  8 giay khong co tin moi thi mo. Toi da 120 ky tu — may NHAN tu kep lai, khong tin may gui.
- `player/speech_bubble.gd`: nen trang + chu toi, co theo do dai tin, neo MEP DUOI tren bang
  ten. Hien 6 giay roi mo. Tao luc nguoi do noi lan dau — khong sua `player.tscn`.
- Gui SO nguoi choi chu khong gui ten: ten da replicate tren nhan vat roi.
- Bong bong cua chinh minh khong hien (goc nhin thu nhat, giong bang ten).

Hai cho de sai, da chan:
1. `Input.get_vector` doc thang ban phim, KHONG quan tam o chu dang giu focus. Khong chan thi
   go "wow" la nhan vat chay. `player.gd` dung yen khi focus la `LineEdit`.
2. PauseMenu dung SAU HUD trong cay nen nhan Esc truoc. Khong nhuong thi Esc mo menu con o chat
   van giu phim. `pause_menu.gd` bo qua Esc khi o chu dang giu focus.

So do (host gui, may join nhan):

```
join 5.5s  bong bong tren Player986: visible=true, 34 ky tu ("Ai choi poker khong? thieu 1 nguoi")
join 6.6s  tin 300 ky tu -> bong bong 120 ky tu (kep dung)
join 12.9s bong bong visible=false (tin cuoi luc 6.6s + 6s + 0.5s mo)
LOG ca hai may: "...: Ai chơi poker không? thiếu 1 người | ...: xxx(120) | ...: gg"  -> tieng Viet nguyen dau
nhan vat cua chinh minh: co bong bong = false (ca hai may)
```

Chua test bang tay: Enter/Esc that va dung yen khi go (test headless goi thang `_gui`).

### Do duoc ve RPC cua Fusion Godot (SDK 3.0.0.2787) — de danh cho voice

```
chuoi 100 / 400 / 510 / 600 / 1000 / 3000 byte  -> nhan du ca 6, dung do dai
PackedByteArray [1,2,3,250]                      -> nhan kieu 29, dung gia tri
@rpc("any_peer", "call_local", "unreliable")     -> nhan duoc
```

- Gioi han "512 byte" trong tai lieu la cua Fusion 2 **Unity**, khong dung o day: 3000 byte van toi.
- Khac voi `PackedInt32Array` (muc truoc: bi bien thanh NIL), `PackedByteArray` gui duoc.
- Tu khoa `"unreliable"` duoc chap nhan, nhung CHUA chung minh no thuc su gui khong tin cay —
  mang tot thi khong mat goi nao, hai che do trong giong het nhau.

### Loi tim ra luc test, KHONG thuoc phan chat

- `chess_piece.gd:117-118`: `var color := CHESS_SIDE_NAMES[side % 2]` — hang mang khong khai
  kieu phan tu, lay ra la Variant, `:=` khong suy duoc -> CA SCRIPT loi phan tich, 32 quan co
  sinh ra tran ("Trying to assign value of type 'Node3D' to a variable of type 'chess_piece.gd'").
  Da sua bang kieu tuong minh `: String`. Lan chay lai: 0 loi phan tich.
- `die.gd` duoc NGUOI DUNG doi asset luc 10:49 (dang lam song song, co chu y) (model JDSherbert FBX, `DIE_SCALE 0.07`, ghi chu
  "CHUA DO LAI"). Lan chay dau bao `String formatting error` x4 trong `Die._build`; lan hai het.
  Khong dung vao file nay.
- Lan chay thu hai: may join bi Photon ngat khi dang ket noi (`OnDisconnected cause=5`), con
  phong test lai co MOT NGUOI LA vao luc 54.6s va gui 4 RPC ma ban build nay khong biet
  (`Received broadcast RPC with unknown ID`). Phong test hien cong khai trong danh sach phong —
  mot ban build khac (editor dang mo, hoac ban 0.0.2) da bam vao.


## 1bc. Dong ho dem nguoc tren ban bai — DA TEST XANH (2 may, Photon that)

### Ba loi cung mot goc: dong ho

1. **Dem 8 → 6 → 4 → 2.** `_dem_nguoc` gui chu roi `await create_timer(2.0)` — nhay cung 2 giay,
   moi lan mot RPC.
2. **Dong ho poker o may khach sai.** Master gui `_han` la moc `Time.get_ticks_msec()` CUA
   RIENG NO (dem tu luc master mo game). May khach tru bang dong ho cua chinh no -> ra so vo nghia.
3. **Xi dach khong co han.** Mot nguoi treo may la ca ban dung mai.

### Sua

- MOT dong ho cho ca ba viec: `_han[deck]` (moc cuc bo cua master). `_process` het gio thi goi
  `_het_gio`: dang cho nguoi -> chia bai; xi dach -> ai chua chot tu DUNG; poker -> nguoi toi luot
  tu BO. Bo han vong lap `await`.
- Gui **so mili-giay CON LAI** trong `_day_trang_thai`, khong gui moc. May nhan doi ra moc cua
  chinh no, tru nua RTT. Moi luot mot RPC luc bat dau — khong gui moi giay.
- Dong ho la `Label3D` noi tren ban (`CardTable._dong_ho`), cap nhat moi frame, lam tron LEN,
  do khi con <= 3 giay. Bo so giay khoi HUD: nguoi dung xem cung phai thay.
- "Het gio! X tu dong DUNG / BO BAI" giu trong `_ghi_chu`, in kem bang ket qua o `_ket_thuc`.

### So do (host va join, cung dong ho he thong)

```
host 136.168  xidach 0:07     join 136.242  xidach 0:07     -> lech 0.07 s
host 140.170  0:03 DO         join 140.244  0:03 DO
host 143.340  chia bai, 0:20  join 143.421  0:20
host 163.202  "Het gio! Player713, Player71 tu dong DUNG"   join 163.254  giong
host 163.202  poker "Het gio! Player71 tu dong BO BAI"       join 163.254  giong
host 170.191  van moi 0:08    join 170.254  0:08
```

Moi so tu 8 ve 1 va tu 20 ve 1 deu hien, khong so nao bi bo.

Chua lam trong dot nay: am thanh tick-tock (spec ghi tuy chon).

## 1bd. Quan co vua khong lo

Bo chess_set moi (vua 4.49, hau 5.58 don vi goc) o `CHESS_MODEL_SCALE = 0.2` ra vua 0.90 m,
hau 1.12 m. Ha con 0.1: vua 0.45 m, hau 0.56 m, ma rong 0.35 m trong o `cell_size = 0.85`.
Ghi chu cu trong `chess_piece.gd` gop lai thanh mot.

## 1be. Highlight: so sanh hai kieu — CHO NGUOI DUNG CHON

Render cung mot canh: vua trang, ma den (bi tot trang KHONG to che mot phan), xuc xac bi vach che,
la bai.

- **A — shader fresnel** (mep sang, giua trong, `depth_draw_never`, KHONG xuyen vat): ma den van
  thay mau goc qua lop xanh, xuc xac bi vach che dung.
- **B — material trong spec** (alpha 0.4, `BLEND_MODE_ADD`, `no_depth_test`): ma den thanh khoi
  cyan dac, mat hinh; xuc xac hien XUYEN qua vach. Vat trang gan nhu khong doi mau (cong cyan vao
  trang van ra trang).


## 1bf. Bai chung poker: bo tru den, bai phang lech ve phia nha cai + bang go dung — DA TEST

- `_spot_cai` doi tu tam ban ra `z = -0.4·r` (phia nha cai, khong co ghe). Gan hon thi hang bai
  de len o cua hai ghe ngoai cung (±120°); xa hon thi hang rong 1.9 m tran khoi day cung mat ban.
- `CommunityBoard`: bo tru + tang trong 4 mat. Thay bang MOT tam go 0.52 × 0.25 × 0.02 m dung o
  mep ban phia nha cai, co chan de. Bai dan 0.08 × 0.12 m, khe 0.02 m, dan CA HAI MAT (mat sau dao
  thu tu de doc tu phia sau van dung).
- Spec ghi bang rong 0.4 m nhung 5 × 0.08 + 4 × 0.02 = 0.48 m — da noi len 0.52 m.

So do (ban dung doc lap, 6 ghe x 2 la + 5 la chung, 2 la up):

```
la doc duoc moi o ghe: 2, 2, 2, 2, 2, 2        (khong o nao an nham bai chung)
la ngua o bai chung:   3                        (2 la up khong tinh)
bang: (0, 0.75, -1.59) rong 0.52 cao 0.25 day 0.020, 10 la dan (5 truoc + 5 sau)
hang bai tren bang 0.48 m, le moi ben 0.020 m
la xa tam ban nhat 1.61 m < ban kinh 1.75 m
tru den con lai: 0
```

Nhan xet tu anh: bai tren bang doc duoc tu ghe giua; tu ghe ngoai cung (±120°) bang bi nghieng
~75° va nho — bai phang tren ban van la cho doc chinh. Muon to hon thi doi `card_w/card_h`.


## 1bg. Ngoi ghe ban bai: dat len ghe, khoa di chuyen, khoa toi het van — DA TEST XANH (2 may)

### Truoc day

Ghe la Area3D: di xuyen vao la ngoi, buoc ra la dung. Nguoi ngoi van di lai tu do, camera goc
dung, va truot chan ra khoi ghe giua van la tu dung day.

### Bay gio

- **Ngoi:** ngam ghe, bam E -> `request_sit`. Master xep cho (tu choi neu dang PHA_CHOI, hoac
  nguoi do dang ngoi ghe khac o BAT KY ban nao) roi phat trang thai.
- **Ai ngoi ghe nao** di kem trong `_day_trang_thai` (moi ghe them id nguoi ngoi). `CardSeat` doc
  lai de hien ten / "NGOI" / "DANG CHOI"; `toi_dang_ngoi` gio suy tu trang thai nay chu khong tu va
  cham nua.
- **Player chi NHIN trang thai roi dat nguoi theo** (`_theo_ghe`): thay ten minh tren ghe -> len
  ghe, quay mat vao tam ban, `set_ngoi(true)`; mat ten -> dat ra ngoai ghe 0.9 m. Master tu cho roi
  ghe (roi phong, don ban) cung di dung duong nay.
- **Khoa:** dang ngoi thi `_physics_process` dung han (khong move_and_slide — ghe sat ban, de chay
  la bi day bat ra), E khong nhat do, Q la xin dung day; master tu choi dung day khi PHA_CHOI.
- **Camera ngoi:** mat 1.65 -> 1.2 m, cui -15°, FOV 80 -> 68 (tween 0.35 s). Do cao/FOV dung doc tu
  scene, khong chep cung.
- **Hoat hinh "sit"** moi may tu suy ra tu trang thai ghe — khong replicate them.
- **Roi phong giua van:** master `_roi_ban` — poker bo bai (dung luot thi `_lam FOLD` de chuyen luot),
  xoa khoi ghe, con 1 nguoi thi ket van som.
- **Nguoi vao sau:** master gui lai pha + trang thai moi ban 1.5 s sau `peer_joined` (RPC la su
  kien, nguoi vao sau khong nhan duoc cai cu).
- Ghe dich sat ban: tam ghe cach mep 0.45 m (truoc 0.85 m).

### So do

```
1. ngam ghe: goi y 'E — NGOI'
   bam E  -> ngoi=true, cach tam ghe 0.000 m, huong vao ban 1.000, mat 1.20, fov 68, cui -15, anim sit
   HUD: 'Dang ngoi tai ban XI DACH — [Q] dung day · [ESC] menu'
2. giu W 0.8 s khi ngoi -> di chuyen 0.000 m
3. bam Q giua van      -> van ngoi; HUD: '... cho het van moi dung day duoc'
4. bam Q sau van       -> dung, cach tam ghe 0.90 m, mat 1.65, fov 80; giu W 0.5 s -> di 0.95 m
A. may Join thay: ten tren ghe = ten Host, Host cach tam ghe 0.002 m, anim Host = sit
B. Join ngam ghe trong giua van: goi y 'DANG CO VAN — CHO VAN SAU', tag 'DANG CHOI';
   gui thang request_sit -> ghe van trong (master tu choi)
5. Join roi phong giua van poker -> ghe trong, bang: 'Player684 roi phong — tu dong BO BAI |
   Player412 THANG (moi nguoi khac da bo bai)'; Host van ngoi nguyen cho
```

### Loi cu tim ra luc test

`_ket_van_som` in "+%d chip" SAU `_chia_pot` — ma `_chia_pot` dua pot ve 0, nen luon ghi "+0 chip".
Doc pot truoc khi chia. (`_ha_bai` da lam dung — co `pot_truoc`.)

Chua lam: may MASTER roi phong thi trang thai ban mat het (da ghi `ponytail:` o `_roi_ban`).


## 1bh. Nem tich luc + bong ro, phi tieu bang vat ly that — DA TEST (1 may)

### Nem tich luc (moi vat cam duoc)

- Giu E khi dang cam = nap; tha E = nem. Toc do 3 -> 15 m/s theo thoi gian giu (day sau 1.2 s).
- Huong = huong camera (ca goc ngang lan goc cui/ngua).
- Vat bay theo cung tinh san (xuc xac, quan co) doi toc do ra quang duong x0.7 (2.1 -> 10.5 m).
- HUD: thanh luc duoi tam ngam, xanh -> vang -> do. Vat bay vat ly: ve parabol du doan.
- Thu tu phim: su kien THA E bat truoc moi thu. Nhat do bang E thi luc bam chua cam gi nen
  khong nap — tha E sau khi nhat khong nem nham.

### Vat ly that chi cho bong ro va phi tieu (`PhysicsPickable`)

- Chi MASTER co RigidBody3D (con `top_level`, dung luc nem lan dau); goc duoc replicate bam
  theo no. May khac khong mo phong gi — mot may quyet dinh duong bay.
- Dang cam: than vat ly freeze VA tat lop va cham — khong thi mot khoi va cham vo hinh nam o
  cho cu giua san.
- Xuc xac, quan co, bai GIU cung tinh san: xuc xac phai ra cung mat tren moi may, bai do nha
  cai dat vao o.

### Loi tim ra: ham gio mac dinh lam hut ro

`RigidBody3D.linear_damp_mode` mac dinh COMBINE — cong them ham 0.1 cua Project Settings. Bong mat
toc do giua khong trung, roi hut so voi parabol du doan: 4/4 cu nem hut, phi tieu cam thap
1.3–1.7 cm. Doi sang REPLACE, tren khong ham = 0, gan mat dat (y < 0.5) moi ham 0.8.

Kem theo: vat dung yen tren cao > 1.5 m qua 2 giay (ket tren noc bang ro) thi ve cho de san.

### Bong ro: nua san 3 × 2 m, ro 2.5 m

- San dung bang khoi co ban (model san cu la san DAY DU 10 m). Mat san nho 1 cm, co va cham.
- Ro: tru, bang 1.2 × 0.8, o do, vanh + luoi lay tu model goc. Va cham vanh = 16 cau nho xep
  vong (luoi tam giac manh thi bong nhanh xuyen qua).
- Loi cu cua model: `Sphere`/`ring` nam duoi `RootNode`, code go nham cha -> "already has a parent"
  -> khong co bong, khong co ro. Go khoi `get_parent()` that.
- Ghi diem: vung Area3D duoi vanh, chi master bat, bong phai dang ROI XUONG. 2 diem, 3 diem neu
  cho dung luc nem cach tam vanh > 1.45 m (vach 3 diem ve dung ban kinh do). MOT RPC kem ca bang
  tong. Hieu ung: chu "+2 TEN!" bay len + no hat cam.

```
tu 1.22 m: cat do cao vanh cach tam 0.001 m -> +2 (tong 2)
tu 1.79 m: cach tam 0.008 m                  -> +3 (tong 5)
tu 1.36 m: cach tam 0.010 m                  -> +2 (tong 7)
cu doan ngam mep vanh: cach tam 0.372 m      -> nay ra, khong tinh
bay tu do (khong va cham): lech cong thuc 0.026 m sau 0.36 s, 0.132 m sau 1.09 s
```

Test dau tien 3 cu gan (0.72 m, 0.87 m) hut la LOI TEST: tay cam o truoc nguoi 0.72 m, dung sat
the thi bong xuat phat ngay duoi vanh, bay thang len dap vanh.

### Phi tieu

- Model "Darts by Jarlan Perez" la CA BO nhieu cay nam cheo (do: dai 0.69, rong 0.57) — moi vat
  nhat len la mot chum. Dung lai bang khoi co ban: 16 cm, mui chia −Z.
- Nhe, trong luc 0.5, mui luon chui theo huong bay.
- Bia nam o LOP VA CHAM 3 rieng. Than phi tieu khong va lop do (bay xuyen), tia quet moi nhip bat
  diem cham roi CAM lai (sau 2 cm). Va cham that thi phi tieu nay khoi bia truoc khi kip cam.
- Trung thu khac: roi xuong san, nhat lai duoc; rut duoc phi tieu dang cam tren bia.
- Bia tren gia dung, tam cao 1.5 m, vach nem 2.37 m, bang diem noi tren bia.
- Tinh diem theo kich thuoc bia that (vong 34 cm, T 99–107 mm, D 162–170 mm, 20 o dung thu tu).

```
nem vao tam: cam, lech tam 13 mm -> "25"      (tinh tay tam dung: 50)
nem vao T20: cam, thap 15 mm     -> "20"      (tinh tay T20 dung: 60)
nem truot: khong cam, nam tren san
rut phi tieu tren bia: nhat duoc, lop va cham = 0
```

### Hai may (Photon that)

```
Host nem tu ngoai vach:  dinh cung tren host y=3.18 luc .11 | tren join y=3.08 luc .41  -> join tre ~0.25 s
bang ro ca hai may:      "Player884  3"
Join tu nhat bong, nem (master mo phong): ca hai may "Player884 3 | Player475 2"
Join nem phi tieu:       cam o local (0.03, 1.52, 0.08) tren CA HAI may, bang "Player475: 18"
```

May khac thay bong tre ~0.25 s va muot hon mot chut — do noi suy replication cua Fusion, khong phai
do mo phong. Chap nhan duoc cho nem bong; neu can tre it hon thi phai chinh cau hinh noi suy.


## 1bi. Gom cum phong cho — DA KIEM (khong chong lan, spawn khong ket)

```
            BAC (tro may)
       dua ga (0,-10.5)   penguin cross (4,-10)
TAY (board game)                      DONG (the thao, sat tuong)
  co vua/tuong (-8.9,-3)  [be nut -13.97]   phi tieu (14.4,-6.5) quay mat vao tam
  caro (-8.9, 5)          [be nut -5.13]    san bong ro (14.2, 6.5) quay mat vao tam
  xuc xac (-10.5, 9.8)
            NAM (ban bai)
       xi dach (-3.25, 10.5)   poker (3.25, 10.5)   -> mep ban cach nhau 3.0 m
```

- Xi dach + poker: mep ban cach nhau 3.0 m (spec 2–3 m); vong ghe hai ban cach nhau 1.46 m di lot.
- Phi tieu cach tu dua ga > 10 m (spec >= 2 m). San bong ro va bia quay mat vao tam phong.
- Be nut co vua va be nut caro cach mep ban 1.0 m. O co vua that la 0.85 m nen ban co tuong
  rong 7.65 m — be nut cu (x = -10.8) da nam LOT vao trong mep ban, phai doi theo.
- Nut caro chuyen len be (nut phang) giong be co vua, thay cho hang cot nut + be dai 6 m.

Kiem bang script do AABB tung khu (ban co o che do co tuong — to hon co vua):

```
so cap chong lan: 0
goc xa tam nhat: 16.66 m (san ban kinh 18)
be nut <-> mep ban: 1.00 m ; nut <-> mep ban: 1.07 m
spawn: P3 cach mep san bong 0.27 m, P8 cach mep ban co 0.19 m (deu la san di duoc, khong ket)
xoay san bong / bia: basis.z = (-1, 0, 0) — dung chieu trai ve phia tam phong
```

Lan dau: P8 nam ngay mep ban co tuong, P10 dinh ban xuc xac -> doi ban co sang dong 0.6 m, dich
ban xuc xac.


## 1bj. Vat dang cam bam theo CAMERA nguoi cam — DA TEST XANH (2 may)

### Truoc day

Vat cam gan vao `HoldPoint` tren THAN nguoi choi: theo huong xoay ngang, KHONG theo goc cui/ngua.
Ly do cu: master khong co CameraRig cua nguoi khac. Ghi chu cu da noi "muon bam ca goc cui thi phai
replicate them mot float" — gio lam dung nhu vay.

### Bay gio

- `Player.nhin_doc`: goc cui/ngua camera, may so huu ghi moi frame, replicate (`player_replication.tres`).
- `Player.diem_cam(offset)`: cho cam = camera + offset (he camera). May so huu dung camera THAT; may
  khac dung lai tu vi tri + goc xoay than + `nhin_doc` + `MAT_CAO = 1.65`. Cung mot cong thuc.
- Master dat vat theo cong thuc do -> moi may thay cung cho.
- May cua NGUOI DANG CAM tu dat vat theo camera cua chinh ho moi frame (khong doi mang). Pickable
  chay `process_priority = 1` de chay SAU replicator.
- Moi vat cau hinh rieng: `cam_offset`, `do_tre_xoay`.
  - Bong ro: (0.22, -0.2, -0.43) — tay phai duoi man hinh, cach camera 0.52 m; xoay duoi theo camera.
  - Phi tieu: (0, -0.04, -0.3) — giua man hinh, 0.30 m; mui khop dung huong nhin.
  - Vat khac: (0.27, -0.24, -0.6), xoay khop camera.
- Dang cam: than vat ly freeze + tat lop va cham (da co tu 1bh) — khong bi trong luc keo.
- Bo `HoldPoint` o player.tscn va camera_rig.tscn, bo `Player.hold_anchor()`, `Pickable._find_hold_point()`.

### Loi tim ra luc test

Xoay duoi theo camera doc lai goc tu `global_transform`. O may nguoi cam (khong phai master),
replicator ghi de goc xoay bang gia tri master gui ve — cu mot nhip mang — nen quay ngoat 90° xong
0.4 s qua bong van lech 38°. Giu goc dang duoi RIENG o may nay (`_xoay_tay`): con 3.6°.

### So do

```
A. host cam bong da tung nem: than freeze=true, layer=0, mask=0; bong o do cao tay 1.45 m sau 1 s
B. host (master) cam phi tieu: trong he camera (0.000, -0.040, -0.300), cach 0.303 m
   xoay camera 2 s: lech vi tri max 0.0029 m, huong min 1.000
   tren may join: lech khoi cho cam tinh tu than + nhin_doc toi da 0.018 m
   dung yen: host (11.714, 1.51, -6.118) | join (11.71, 1.51, -6.12); nhin_doc -0.350 ca hai may
C. join (KHONG phai master) cam bong: trong he camera (0.22, -0.20, -0.43), cach 0.523 m
   xoay camera 2 s tren may join: lech vi tri max 0.0415 m (1–2 frame khi quay nhanh)
   tren may host: lech khoi cho cam 0.000 m
   quay ngoat 90°: lech huong 103.7° ngay sau -> 3.6° sau 0.4 s (truoc khi sua: 38.2°)
   dung yen: host (12.219, 1.596, 6.464) | join (12.221, 1.596, 6.463); nhin_doc 0.300 ca hai may
```

Anh: bong o 0.5 m voi FOV 80 nam sat mep man hinh nen hoi meo phoi canh (tron thanh bau).


## 1bk. Don code dot 1 (khong doi hanh vi) — DA TEST (2 may)

Project KHONG co file quy tac clean code rieng (khong CLAUDE.md, khong .editorconfig). Quy tac dang
dung: quy tac lam viec cua nguoi dung (scene module, khong Main.gd khong lo, moi script mot viec,
signal giua he thong, @export thay so cung, khong over-engineer) + cac "Quy tac" rai trong file nay
+ nguyen tac clean code chung.

### Da don

- Code chet: `main.request_penguin_start()`, `main._caro_board()`, `Card.value_bj()` — khong ai goi.
  `pickable.tscn` (vat nhat duoc chung, hinh hop) chi duoc dang ky spawn ma khong bao gio spawn -> xoa
  file + dong dang ky.
- Hai khoi `if true:` con sot trong `CardDealer._luot_nha_cai` -> bo, lui le noi dung.
- Bon ban sao "tim ten nguoi choi theo id" (`CardDealer._ten_nguoi`, `PenguinCross._ten`,
  `CardSeat._ten`, vong lap trong `ChickenRace._ai_dung`) -> dung chung `Player.ten_theo_id`.
- `CardDealer.ban_dang_ngoi/ghe_cua_toi` tach so ban/so ghe tu TEN NODE ("Seat0_2") -> doc thang
  truong `CardSeat.deck/index`.
- `CardSeat extends Area3D` -> `Node3D`: ghe khong con dung va cham tu dot ngoi ghe moi.
- Ghi chu cu con ta khung day "12 thanh", "Area3D bat than nguoi choi" -> sua theo code hien tai.
  `Player._vien` doi kieu `Array[MeshInstance3D]`, `_nearest_seat()` tra `CardSeat`.

### Kiem

```
host: ban_dang_ngoi=0 ghe_cua_toi=1 | join: ban_dang_ngoi=0 ghe_cua_toi=3
tag ghe 1/3 tren CA HAI may: 'Player497' / 'Player763'
penguin cross ca hai may: 'Player497 - 1.0x - buoc sau song 90%'
xi dach het gio ca hai may: 'Het gio! Player763, Player497 tu dong DUNG | NHA CAI: 26 - QUA 21 | ...'
dua ga ca hai may: thang lan 4 (ca hai dat lan 2 -> "khong ai tin no", dung)
0 loi script
```

Chua chay qua: nhanh co TEN trong `ChickenRace._ai_dung` (khong ai dat trung con thang lan test).

Test lan dau hong vi LOI TEST: may join doc file ten phong luc no con rong -> `join_room("")` ->
vao nham mot phong la. Da sua test doi tới khi file co noi dung.

### De xuat — CHUA LAM, can nguoi dung quyet

1. `net/card_dealer.gd` 1117 dong / 72 ham gom ca xi dach, poker, trang thai ghe, dong ho -> tach.
2. `main.gd` 427 dong con giu RPC cua co vua, caro, penguin cross, dua ga -> dua ve tung minigame.
3. `player/player.gd` 673 dong: di chuyen + highlight + ngoi ghe + nem tich luc + cam do -> tach thanh
   node thanh phan.
4. Ten dat lan tieng Anh/tieng Viet (`request_sit` / `_net_hanh_dong`, `cam_offset` / `do_tre_xoay`), ghi
   chu co dau / khong dau -> chon mot quy uoc. Doi ten ham RPC doi luon ID mang — moi may phai cung ban.


## 1bl. Vat ly that cho moi Pickable + dong bo Fusion — DA TEST 2 MAY, CON 1 QUYET DINH

### Da lam

- Bo han duong ngam du doan (aim line) khoi `player.gd`.
- `Pickable extends RigidBody3D` (goc scene cua quan co, bai, xuc xac, bong, phi tieu). Gop
  `PhysicsPickable` vao, xoa file. Bo het "vat ly gia": cung bay tinh san, nay tu viet, xuc xac chon
  mat truoc, ket dinh o ban co, `ground_offset`.
- Trang thai than vat ly SUY RA moi nhip tu `holder_id` + `dinh_co_dinh`: dang cam = freeze + tat va
  cham; roi tay = dong. Chi master dat van toc luc tha.
- Hinh va cham: quan co vua = hinh loi tu luoi (nho lai theo loai); co tuong/caro = tru; xuc xac, la
  bai, phi tieu = hop; bong = cau. Ban co them mat va cham.
- Xuc xac: mat ngua do vat ly, master doc truc chi len troi luc vien nam yen 0.3 s. `value = 0` = dang lan.
- La bai: co than vat ly nhung LUON khoa — bai do nha cai dat, khong ai cam len.
- Nguoi choi nam lop va cham rieng (`Player.LOP_NGUOI`), vat nhat duoc lop `Pickable.LOP_VAT`: di qua
  ban co khong xo do quan (do: quan dich 0.0000 m khi nguoi dung de len 1 s).
- `dinh_co_dinh` replicate (phi tieu cam tren bia khoa ca may khac).

### Doi chieu tai lieu nguoi dung tim voi SDK that (Fusion Godot 3.0.0.2787)

- KHONG co `NetworkRigidBody3D`, `SetKinematicMode`, `ApplyCentralImpulse` kieu Unity.
- KHONG co `request_state_authority()` — ham that la `FusionSharedReplicator.want_authority()` +
  signal `authority_requested` / `authority_response`.
- KHONG co che do `RIGID_BODY_3D` — `root_replication_mode` chi co None / Auto.
- `root_interpolation_mode` mac dinh la Exponential (DLL co chuoi goi y "None:0,Forecast:2" rieng cho
  than vat ly). Co day du: `root_correction_mode`, lo xo, nguong teleport, `sync_sleeping`,
  `root_forecast_gravity`, `root_max_forecast_time`, `teleport_3d()`.
- Auto CO gui van toc: may khac thay Linear (4.98, 3.52, 0) dung luc nem, goc 13.6 = may chu 13.6.
- Trang doc doc.photonengine.com bi chan boi trang kiem tra trinh duyet — khong doc truc tiep duoc.

### Hai loi tim ra luc test (deu da sua)

1. **Dung hinh loi quan co lam dung game 6.9 s.** `Mesh.create_convex_shape()` ton 64–119 ms MOI
   model (5–14 nghin dinh). 32 quan cung sinh -> khung hinh dai nhat 6874 ms -> Photon khong duoc phuc
   vu: canh bao 1035 (hang doi goi den day), may vao sau bi ngat 1040. Sua: lay thua toi da 256 dinh,
   de may vat ly tu bao loi, nho lai theo loai -> khung dai nhat 76 ms, het canh bao.
2. **Vat nam yen tren may khac lun 0.32 m.** `root_forecast_gravity` mac dinh `true` +
   `root_max_forecast_time = 0.25` -> du doan roi tu do 0.25 s ca voi vat dang nam: 1/2 * 9.8 * 0.25^2
   = 0.31 m. Do: phi tieu -0.324, quan co -0.322, xuc xac -0.321; van toc "ma" 2.45 = 9.8 * 0.25. Quan co
   va xuc xac xuyen xuong duoi san. Sua: `root_forecast_gravity = false` trong .tscn 5 vat.

### So sanh hai cach cho may khac (tat trong luc du doan ca hai)

```
                                     BAN SAO KHOA (freeze)        BAN SAO CHAY VAT LY (docs)
may khac tre sau may chu             ~120 ms                      30–50 ms
lech cung thoi diem bong/xx/co       0.25 / 0.14 / 0.07 m         0.20 / 0.10 / 0.08 m
hinh duong bay sau khi bu tre        5.6 / 1.7 / 2.1 cm           14 / 8.8 / 6.9 cm
diem nam yen cuoi cung lech          <= 6 cm bong, <= 1 cm con lai   <= 3 cm
buoc nhay > 15 cm (bong/xx/co/tieu)  0 / 0 / 0 / 0                3 / 0 / 0 / 16
```

Ca hai: tranh nhat mot vien -> ca hai may cung thay mot nguoi; roi phong khi dang cam -> vat roi
(0.8 s sau holder = 0); 32 quan cung bay: vat ly <= 6.7 ms/nhip.

**CHUA QUYET:** khoa = muot, dung hinh, tre ~120 ms. Chay vat ly = it tre (dat ±50 ms) nhung giat
(phi tieu 16 buoc nhay). Code dang de CHAY VAT LY + Forecast theo tai lieu.

Chua test: nguoi KHONG phai chu nem nhanh — may cua ho thay vat tu tay minh nhay ve vi tri master
(tre) ngay luc tha. Test 10 nguoi that — mot may chi chay duoc 2 ban.


## 1bm. Nhay doi + bo dong chu "E — ..." — DA TEST

- **Nhay doi:** `Player.so_lan_nhay = 2`. Cham dat thi dem lai; buoc hut khoi mep ma khong nhay thi coi
  nhu da dung lan dau (tren khong chi con mot lan). Lan hai DAT thang van toc len, khong cong them.
  Hoat hinh moi may tu suy tu van toc — khong can dong bo gi them.
- **Bo chu goi y "E — NHAT / E — LAT MAT BAN":** no chong len chu cua chinh cai nut (anh nguoi dung:
  "LAT MAT BAN" hai lan de nhau). Giu vo sang highlight. `_cap_nhat_goi_y` doi ten `_cap_nhat_muc_tieu`.

```
nhay 1 lan:                      cao 1.26 m
nhay 2 lan (lan 2 sau 0.25 s):   cao 2.47 m
bam 3 lan:                       cao 2.47 m   (lan thu ba khong co tac dung)
dang ngam vat: vo sang bat, so Label3D bat dau bang "E ": 0
```


## 1bn. Thap Ha Noi — DA TEST 2 MAY

Bo Cornhole (nguoi dung quyet). Khong tim duoc asset thap Ha Noi dung duoc (chi co ban in 3D STL va mot
model CC-BY chua ro so dia) nen dung bang khoi: dia la TorusMesh ep det (co lo giua, mep tron).

- **Mot file** `lobby/objects/hanoi_tower.gd`, dat trong `lobby.tscn` o (8, 0, 0), mat quay ve giua phong.
  Ban 1.8 m, bang luat ben trai, bang nut (BAT DAU / SO DIA 6-7-8 / LAM LAI) ben phai cach coc C ~1 m.
- **Khong vat ly, khong replicator.** Dia chi la hinh ve suy ra tu `_coc`. Master giu luat, phat
  NGUYEN trang thai bang JSON sau moi lenh. Moi may giu du trang thai -> doi master van choi tiep.
- **Coc la Pressable** (tao bang code, con "Mesh" + "Label"): co san vo sang va phim E, khong sua Player.
  E vao coc: nhac dia tren cung (bay theo `Player.diem_cam` cua nguoi choi, may nao cung thay).
  E vao coc khac: dat. Sai luat: dia chua roi mang coc cu nen tu ve cho. Dang cam dia thi chu coc
  to vang (coc nhac), xanh (dat duoc), do (sai luat).
- Mot thap cho ca phong: ai bam BAT DAU la chu van; nguoi khac bam coc bi bo qua. Nguoi choi 30 giay
  khong bam coc (`giay_bo_di`) thi ai cung LAM LAI / BAT DAU duoc. Nguoi choi roi phong -> ve cho.
- Dem nguoc 3 giay, dong ho va so buoc 3D, ky luc theo so dia (it buoc, roi it giay), chu "XONG!" +
  phao giay khi thang. Gio gui bang SO MILI-GIAY (khong gui moc gio), tru nua RTT nhu ban bai.
- Nguoi vao muon: lobby dung sau khi master da phat, nen tower tu xin trang thai trong `_ready`.
- Am thanh Kenney CC0 (Impact Sounds + Interface Sounds): go nhe khi nhac, go vua khi dat, error khi
  sai, tick moi giay dem nguoc, bong khi bat dau, confirmation khi thang.

```
test 2 may (host headless + khach co cua so, phong an):
A->B, roi A->B sai luat            buoc 1, dia ve A          dung
khach vao giua dem nguoc           nhan du trang thai        coc/buoc/nguoi/cam giong host
khach bam COC/LAM_LAI/BAT_DAU/SO_DIA khi host dang choi       bi bo qua, host khong doi
mau chu coc tren may khach khi host cam dia 1: A vang, B xanh, C do     dung
dia dang cam tren may khach cach diem cam cua host        0.012 m
giai 6 dia (63 buoc + 4 buoc thu)  buoc 67, XONG, ky luc 67 buoc 20.218 s — hai may giong nhau
host thoat                         khach thanh master, van giu XONG + ky luc
loi moi: 0 (con "Capture not registered: 'fusion'" luc thoat va loi get_room_list luc tao phong — co tu truoc)
```

Chua test: 10 nguoi, va nguoi choi di xa khoi thap khi dang cam dia (dia bay theo ho — chua gioi han).


## 1bo. Dap chuot chui + Bowling + Mini golf — DA TEST 2 MAY

Nguoi dung: "trien khai cac mini game con lai, khong can bang huong dan" -> bo luon bang luat cua
Thap Ha Noi. Liar Bar cho luat moi. Cornhole da bo.

**Chung cho ca ba:** mot file mot game trong `lobby/objects/`, dat trong `lobby.tscn`, master cam
luat va phat NGUYEN trang thai JSON; vat the vat ly (bong, ky, bua, gay) la Pickable nen vi tri
da co replicator lo, JSON chi mang DIEM.

**Dap chuot chui** (`whack_a_mole.gd`, `hammer.gd`) — o (-6, 0, -8)
- Ban TU DUNG: CSG khoet 6 lo that, thung rong toi thui ben duoi. KHONG dung mat may "Whack em
  All": mat may la mat bac thang, cac hom lom nam rai o nhieu bac khac nhau (do bang tia quet
  trong Godot: chi tim duoc 4 hom o hai do cao khac nhau) — chuot nho len se dam xuyen mat may.
  Model may dat canh ban lam tu arcade trang tri.
- Chuot: model CC-BY co xuong, chi co MOT animation 9.42 s gom tat ca; cat doan bang
  `play_section` (0.9-3.4 dung yen, 8.3-8.8 bi dap). Quy ti le theo CHIEU CAO model chu khong
  theo canh lon nhat — canh lon nhat la sai tay, lay nham thi chuot be mot nua.
- Bua: `throw()` bi ghi de -> tha E la VUNG BUA chu khong nem di, khong phai them phim moi vao
  Player. Trung/truot tinh o may nguoi cam bang TIA NHIN (khong phai khoang cach dau bua: tay
  chi voi ~0.6 m ma sau lo cach nhau 0.42 m, ban kinh du lon se dap trung ca lo ben canh).
- Hiep 45 giay, dem nguoc 3 giay, ai cung dap cung luc, bang diem 3D theo tung nguoi.

**Bowling** (`bowling_lane.gd`, `bowling_pin.gd`, `bowling_ball.gd`) — o (7, 0, 5), dai 8 m
- 10 cay ky lay tu model CC-BY "Bowling pins by Poly by Google" (file goc la ca bo 10 cay dinh
  lien, don vi hang tram nghin — tach mot cay, keo ve goc, quy ve 0.38 m). Hinh va cham la bao
  loi tu luoi, co cache san trong Pickable.
- Ky nang 0.6 kg (khong phai 1.5 kg nhu that): bong trong game chi 3 kg, ky nang bang that thi
  mot cu nem thang chi do 2 cay.
- Dem ky SAU khi bong dung 1.6 giay — dem ngay thi cu do 5 cay chi tinh duoc 2.
- Tinh diem bowling that (strike +2 bong sau, spare +1 bong sau), 10 khung. Luot thuoc ve nguoi
  nem dau tien, nguoi khac nem xen thi khong tinh; bo di 30 giay thi nhuong luot.
- Don gian hoa: khung 10 khong co hai bong thuong.

**Mini golf** (`mini_golf.gd`, `putter.gd`, `golf_ball.gd`) — o (-2.5, 0, -6), 2.6 x 5 m, par 3
- San tu dung (CSG khoet lo that), lay cua Kenney Minigolf Kit ba mon ro rang: bong, gay, co.
- Gay: `throw()` ghi de -> tha E la VUT, luc lay tu chinh thanh nap luc (3-15 m/s -> 1-5 m/s).
- Cu vut do theo CHO DUNG CUA NGUOI, khong theo tia nhin: bong nam thap hon mat 1.6 m nen do
  theo tia thi cu vut nao cung bi tu choi (da dinh dung loi nay).
- Vat can phai dat BEN CANH duong bong: bong ban kinh 3 cm khong treo noi buc cao 10 cm, dat
  chan giua san la khong the vao lo.

```
test 2 may (host headless + khach co cua so, phong an):
dap chuot: host dap 10 con        -> hai may deu 10, bang diem giong nhau
bowling:   nem mot cu do 5 ky     -> hai may deu nga=[5], ky con dung=3
mini golf: vut mot cu vao lo      -> hai may deu "VAO LO - 1 GAY (HOLE IN ONE)"
loi moi: 0
```

Da sua trong luc test: ten nguoi thang gio gui bang ID roi MAY NHAN doi ra ten (truoc do master
gui san cau, may khac in ra "#1"); `BowlingPin.dung()` o may khong phai master chi xet do nghieng
vi cho dung chi master biet.

Chua test: 10 nguoi; hai nguoi nem bowling xen nhau; nguoi cam dia/bong di xa khoi khu vuc.


## 1bp. Liar Bar — DA TEST 2 MAY

Luat theo ban nguoi dung gui lai (khac han ban dau: khong con dat cuoc chip, thay bang o quay).

**Luat da lam:** 2-4 nguoi, bo 20 la (6 K, 6 Q, 6 A, 2 Joker — Joker thay duoc chat ban). Moi
nguoi 5 la, moi vong bat mot CHAT BAN (K/Q/A). Den luot: chon 1-3 la roi bam DANH, bai up mat
xuong giua ban. Nguoi ke tiep (nguoc chieu kim dong ho) hoac danh tiep — coi nhu tin — hoac bam
LIAR. Bat duoc noi doi thi ke noi doi ban mot phat; to nham thi nguoi to ban. O quay 6 vien, 1
vien that, ban lan luot; trung vien that la bi loai. Con mot nguoi song thi thang.

**File:** `lobby/objects/liar_bar.gd`, dat trong `lobby.tscn` o (-13, 0, 3). Mot file, khong dung
lai `CardDealer` (nha cai cu la luat xi dach/poker, khong dinh gi toi day).

- **Bai tren tay la NUT bam duoc** (`Pressable` dung bang code, con "Mesh" la than la bai): ngam
  vao la cua chinh minh, bam E de chon/bo chon (la duoc nhac len). Chon xong bam DANH o bang
  dieu khien. Viec chon CHI o may minh — khong RPC, nguoi khac khong thay minh dang can nhac.
- **Bai up/bai ngua:** chu bai thay mat bai o may CUA MINH, may khac thay lung bai — dung dung
  cach cua bai up poker. Bai vua danh nam giua ban up mat, chi lat len khi co nguoi to LIAR.
- **O quay chi master biet** (gui di la lo ai sap chet). May khac chi thay DA BAN MAY PHAT — sau
  vien tron truoc cho ngoi, do dan = da ban.
- Het gio 25 giay thi tu danh mot la bat ky. Het bai tren tay thi chia vong moi, doi chat ban.
- Bang dieu khien lech mot ben (VAO BAN / BAT DAU / DANH / LIAR! / LAM LAI) de bam nut khong
  cham nham vao bai.

```
test 2 may (host headless + khach co cua so, phong an):
hai nguoi vao ban                -> ghe=[1,2,0,0] tren ca hai may
chia bai                         -> moi nguoi 5 la, chat ban K
host danh bai DOI, khach to LIAR -> "NOI DOI THAT", host ban 1 phat, song, chia vong moi
host danh bai THAT, khach to LIAR-> "BAI THAT — TO NHAM", khach ban 1 phat, song
moi so lieu (ghe/song/da_ban/tay/chat ban) giong nhau tren ca hai may
loi moi: 0
```

**Da biet va chap nhan:** bai tren tay nam trong JSON phat cho ca phong, nen may bi sua doc trom
duoc — y het bai up cua poker, vi Fusion Godot khong gui rieng cho mot nguoi (muc 1ba). Va yeu
cau chung "moi thu public" thi mau thuan voi bai rieng, nen chon cach nay.

Chua test: 3-4 nguoi that; nguoi dang choi roi phong giua van (ghe van giu cho ho).


## 1bq. Chu 3D chong nhau + dap chuot chuyen sang choi TREN MAY

**Chu 3D:** dung giua phong thi bang diem cua ca chuc khu de chong len nhau. Dung
`visibility_range_end` co san cua GeometryInstance3D (Label3D thua ke) — KHONG dung `visible`,
vi game con tu bat/tat `visible` cua dong ho dem nguoc, hai ben se danh nhau. `lobby.gd` quet
moi Label3D trong phong dat tam 6 m + fade; cho nao da tu dat tam rieng thi bo qua (bang diem
bowling dat 14 m vi nguoi nem dung cach no gan 9 m). Sau khi sua: dung giua phong khong con
mot dong chu nao.

**Dap chuot:** bo ban tu dung, choi thang tren model may "Whack em All" theo yeu cau. Do lo
bang tia quet trong Godot (ban tia tu tren xuong khap mat may, gom diem lom 2-20 cm, gom cum):
mat may la mat BAC THANG, **nam lo** — hai lo o bac thap, ba lo o bac cao. Toa do do o may cao
1.6 m, luu trong `LO_MAY`, doi model la phai do lai.

- May quy ve 2.0 m, xoay -90 do cho mat choi ve +Z, keo ve giua node, va cham theo trimesh.
- Chuot cao bang 3.6 lan ban kinh mieng lo; luc len nho hon mat may 0.6 lan chieu cao chuot —
  toa do do duoc la DAY hom lom chu khong phai mat may, de ngang do thi chuot thut trong hom.
- **Loi da dinh:** do AABB con chuot bang ham do trong toa do NODE NAY, nen so do mang theo ca
  cho dat cua `moc`/`than` va chuot bi day chim vao may. Phai do trong toa do CUA CHINH MODEL
  (`_bao_trong`, dung `global_transform.affine_inverse()`).
- **De hon:** chuot nam tren 1.8-3.2 giay (truoc 1.0-2.0), nghi 0.7-1.8 giay (truoc 1.0-3.0),
  ban kinh ngam 0.3 (truoc 0.2), tam voi 3.0 m. Test: vung 20 lan trung 18-20.

**Su co:** mot script python sua file bi loi da GHI DE `whack_a_mole.gd` thanh file rong (mo
file bang mode "w" roi moi vo o dong sau). Repo khong co git nen khong roll back duoc — da viet
lai ca file. Tu gio sua file bang script thi ghi ra file tam roi doi ten, dung mo "w" trong cung
mot buoc voi phan tinh toan.


## 1br. Bo Bowling + cam SIEU LINH theo tai lieu — DA TEST 2 MAY

**Bowling:** xoa `bowling_lane.gd`, `bowling_pin.gd/.tscn`, `bowling_ball.gd/.tscn`, phan spawn
trong `main.gd`, node trong `lobby.tscn`. Giu file model "Bowling pins" trong `asset/` (nguoi
dung tai ve), CREDITS ghi "khong con dung".

**Sieu linh:** truoc do chua co dong code sieu linh nao trong du an (chi la goi y trong chat), nen
khong co gi de go. Lam theo tai lieu, KHONG theo cac doan code AI goi y:
- "Soft Constraints: Reinventing the Spring" (Erin Catto, GDC 2011) va mouse joint cua Box2D: tay
  la LO XO MEM CO GIOI HAN LUC, do cung cho bang tan so (Hz) + ti le tat dan, luc toi da la boi so
  trong luong.
- Godot "Using RigidBody": khong ghi thang trang thai moi nhip — dung luc / `_integrate_forces`.

Cai dat trong `Pickable` (khong file moi), CHI master mo phong:

    w = 2 pi f          F = m (w^2 * lech  -  2 * zeta * w * v)      cat o  n * m * g

- `sieu_linh_hz = 5`, `sieu_linh_tat_dan = 1` (tat dan toi han), `sieu_linh_luc = 4` lan trong
  luong, lo lung cach mat 1.3 m. Vat VAN LA VAT LY DONG va van va cham trong luc lo lung.
- Dung cu can nam dung cho van cam TRONG TAY nhu cu: bua, gay golf, phi tieu (`sieu_linh = false`).
- Buong tay (Q) giu nguyen da dang co thay vi dung khung — vat dang bay thi bay tiep.
- Loi trong goi y cu da tranh: gan `linear_velocity = K*lech - C*v` doi dau van toc moi nhip khi
  C >= 1; ban cai dat dung LUC (`apply_central_force`).

```
test 2 may (host headless master + khach co cua so, phong an):
bong ro, dung yen                cach diem giu 0.010 m   (= g / w^2 o 5 Hz: dung ly thuyet)
quay nguoi 90 do                 0.15 s: tre 1.45 m  ->  1.0 s: 0.010 m, khong vuot qua dich
ep diem giu vao long ban         bong dung o mat HONG ban (x 7.53 + r 0.12 = 7.65 = mep ban), khong chui vao
khach cam xuc xac (master mo phong)  o may khach cach diem giu 0.038 m
buong tay                        roi xuong (1.15 -> 0.81 m trong 1.2 s)
nem bang co che cu               10.03 m/s
bua (dung cu)                    van trong tay, lech 0.000 m
loi script moi: 0
```

Sai lam trong luc test (ghi lai de khoi lap lai): lan dau dich chuyen nguoi choi xa qua bong 14 m
— bong bi keo lech mat dat vao thanh chan san bong ro va ket, vi luc tay co gioi han (dung thiet
ke). Tam nhat do la 3.2 m, test phai dung trong tam do.

Chua lam (ghi o comment `ponytail:`): chua cong van toc cua diem giu vao so hang giam chan — chay
6 m/s thi vat tre sau ~0.38 m. May nguoi cam khong phai master thay vat qua mang (tre theo RTT),
khong con tu dat vat truoc mat nhu kieu cam trong tay.


## 1bs. Liar Bar de len ban caro — doi cho

Anh nguoi dung: ban Liar Bar va bang nut nam chong len mep ban caro. Quet ca phong bang script
tam (hop bao XZ cua moi node con cua lobby, in moi cap giao nhau > 5 cm) thay:

```
CaroBoard <-> LiarBar : giao 0.79 x 2.89 m     <- loi that
+ Liar Bar o (-13, 3) nam de len diem spawn P9 (-13.3, 4.3): nguoi choi co the sinh ra trong ban
ReadyPad <-> MiniGolf : 2.40 x 0.10 m          <- bao dong gia: o san sang la HINH TRON, hop bao
                                                  vuong; khoang ho that ~8 cm
ResetButton/FlipButton <-> BeCoVua, CaroWhite/Black/Reset <-> BeCaro   <- co y: nut dat tren be
```

Doi Liar Bar sang (8.5, 0, 5.5) — cho duong bowling vua bo trong. Cach Thap Ha Noi 1.37 m, ban
poker 0.7 m, san bong ro 1.33 m, xa moi diem spawn. Quet lai: Liar Bar khong con giao voi gi.


## 1bt. Xuat ban 0.0.3

```
build/PartyBash-0.0.3/
  PartyBash.exe                                        104 MB
  PartyBash.pck                                         78 MB   (lan dau 107 MB)
  libfusion.windows.template_release.x86_64.release.dll  2 MB
  DOC-TRUOC-KHI-CHAY.txt
-> build/PartyBash-0.0.3.zip
```

- Truoc khi xuat: kiem loi script (`--headless --import`, 0 loi); xoa 6 file rac
  `~libfusion...dll~RF*.TMP` trong `addons/fusion/bin/` (muc 1ad).
- `.pck` lan dau 111.8 MB — 14 lan ban 0.0.2 (7.8 MB). `export_filter = all_resources` dong goi
  MOI tai nguyen da import, ke ca kit khong ai dung. KHONG doi sang "scenes": game nap rat nhieu
  thu bang `load("res://...")` chuoi luc chay (am thanh, mat bai, model nhan vat) — che do do se
  bo sot va ban build hong.
- Thay vao do: quet `.gd/.tscn/.tres`, thu nao **khong duoc tham chieu** thi them vao
  `exclude_filter` (KHONG xoa file — kit do nguoi dung tai, co the sap dung): city-kit-commercial,
  graveyard-kit, castle-kit, mini-arcade, pa_grapes_wooden_mallet, chess all_pieces_board, san bong
  ro Poly, Bowling pins. Giu furniture-kit, train-kit, nature-kit (lobby.tscn dang dung).
  **Them model/kit moi vao scene thi kiem lai `exclude_filter`** — thu bi loai tru se thieu trong
  build ma editor van chay binh thuong.
- Phan con lai la tai nguyen DANG DUNG: KayKit Adventurers/Skeletons (ca bo vu khi di kem), bo co,
  anh Sketchfab.
- Chay thu ban xuat `--headless`: nap DLL, ket noi Photon.
- **Mini Golf khong co trong ban nay:** `lobby.tscn` hien khong con node MiniGolf (nguoi dung dang
  chuyen do sang scene). File `mini_golf.tscn` van nam trong `lobby/objects/`.


## 1bu. Minigame — 18 trò gom về 5 KHUÔN. KẾ HOẠCH, chưa code

> 📄 **Bản chính giờ nằm ở `MINIGAME.md` mục 9.** Ở đó nó đứng cạnh phần kiến trúc pha 3 (hợp
> đồng, ba kiểu đồng bộ, khung `MiniGameDiem`). Mục này giữ lại để không mất bối cảnh lịch sử;
> **sửa thì sửa bên `MINIGAME.md`**, đừng sửa hai chỗ rồi để chúng trôi khác nhau.

Chốt sau một buổi bàn. Tham khảo Pummel Party (~48 trò) và Lunars. Phần lớn ý tưởng lấy từ
Pummel Party; **Lunars không liệt kê được** — Steam, trang chủ, bài preview và wiki đều chỉ nói
"30+ minigame", không nơi nào có danh sách tên. Cần người dùng tự kể lại.

### Điều đắt nhất là số KHUÔN, không phải số TRÒ

| Khuôn | Trò | Xây một lần |
|---|---|---|
| **T1 — sàn đẩy nhau** | Magma & Mages · ~~Snowy Spin~~ · Acidic Atoll · Explosive Exchange · Crown Capture | cam trên cao · di chuyển theo cam · 1 nút đòn (tầm/hình/lực/hồi chiêu là config) · rơi khỏi sàn tự khai tử · sàn co dần bật-tắt |
| **T2 — né chướng ngại** | Breaking Blocks · Laser Leap · Searing Spotlights · Slippery Sprint | cùng cam + điều khiển T1, bỏ nút đòn · chướng ngại = hàm của hạt giống + thời gian mạng |
| **T3 — lưới ô** | Bounding Blocks · Temporal Trails · Word Wars | sàn chia ô · giẫm lên thì ô đổi chủ · đếm ô |
| **T4 — làn chạy, cam sau lưng** | Sidestep Slope · Nhặt quà né rác · Slippery Sprint | đường cuộn · vật cản sinh theo quãng đường từ hạt giống |
| **T5 — mỗi người một bàn riêng** | Fractured Faces · Rockin Rhythm · Đếm thú · Bóng chày | chia khu riêng · cùng chuỗi đề từ hạt giống · cuối ván gửi đúng một con số |

**13/18 trò dùng chung đúng một camera.** 3 trò cam sau lưng dùng lại `CameraRig` của phòng chờ.
2 trò là overlay 2D dùng chung một bố cục hàng ngang. Tổng cộng phải viết **3 kiểu camera**.

**8 trò gửi 0 gói tin** trong lúc chơi.

### Bảng chốt

| # | Trò | Khuôn | Camera | Tính điểm | Gói tin |
|---|---|---|---|---|---|
| 1 | Magma & Mages | T1 | trên cao | loại trừ: chết thứ *i* → `n−i` | 1/phát cầu lửa |
| 2 | ~~Snowy Spin~~ **ĐÃ XOÁ** | T1 | — | — | — |
| 3 | Acidic Atoll | T1 | trên cao | loại trừ | 1/quả bom |
| 4 | Explosive Exchange | T1 | trên cao | loại trừ theo thứ tự nổ | `ai_om` do master |
| 5 | Crown Capture | T1 | trên cao | **1 đ/giây giữ**, 60 s | `ai_giu` do master |
| 6 | Breaking Blocks | T2 | trên cao | thời gian sống, 60 s | chỉ "tôi chết" |
| 7 | Laser Leap | T2 | trên cao | thời gian sống, **không giới hạn giờ** | chỉ "tôi chết" |
| 8 | Searing Spotlights | T2 | trên cao, **tối hoàn toàn** | thời gian sống · **100 máu, −40/giây trong đèn** | chỉ "tôi chết" |
| 9 | Slippery Sprint | T2/T4 | **sau lưng riêng** | thứ hạng về đích; chưa về thì theo quãng đường | chỉ "tôi chết" |
| 10 | Bounding Blocks | T3 | trên cao | số ô lúc hết giờ, 60 s | **0** — suy từ vị trí |
| 11 | Temporal Trails | T3 | trên cao | loại trừ | **0** — suy từ vị trí |
| 12 | Word Wars | T3 | trên cao | số từ ghép xong, 60 s | 1/cú đấm |
| 13 | Sidestep Slope | T4 | **sau lưng riêng** | quãng đường đi được | **0** |
| 14 | Nhặt quà né rác | T4 | **sau lưng riêng** | quà +1 · quà to +3 · rác −1 (cho âm) · **băng riêng mỗi người** | **0** |
| 15 | Fractured Faces | T5 | trên cao, khu riêng | thứ hạng hoàn thành; chưa xong thì số mảnh đúng | **0** + 1 gói cuối |
| 16 | Đếm thú | T5 | trên cao, **không render người chơi** | 5 vòng, đếm 1 loại giữa 3 loại · đúng +1 sai 0 | **0** + 1 gói/vòng |
| 17 | Rockin Rhythm | T5 | **overlay 2D, hàng ngang** | Perfect 3 · Good 1 · Miss 0 · combo ×1.5 sau 10 nốt | 1 gói/giây/người |
| 18 | Bóng chày | T5 | **overlay 2D, hàng ngang** | tâm ±40 ms **3đ** · ±100 ms **2đ** · ±180 ms **1đ** · trật 0 · 15 quả | 1 gói cuối |

### Searing Spotlights — tối là tối HẲN

Không thấy nhân vật nào, kể cả của mình. Đèn quét là nguồn sáng duy nhất: ai lọt vào thì vừa bị
lộ cho cả phòng thấy, vừa mất máu. Hai thứ bắt buộc, thiếu thì trò thành ngẫu nhiên chứ không
thành khó:

- **Thanh máu luôn hiện trên HUD** — tín hiệu duy nhất báo "đang bị nướng, chạy đi".
- **Sàn có mốc định hướng mờ** (viền phát sáng yếu, vài vạch chìm). Là NÚM CHỈNH: càng mờ càng
  căng. Không có gì để bám thì đi trong tối là tung xúc xắc.

### Rockin Rhythm là 2D, không phải 3D

Mỗi người một hàng ngang, avatar 2D của nhân vật bên trái (chụp sẵn 12 ảnh bằng `SubViewport`,
lấy theo `model_index` đã replicate — không render lúc chạy), nốt chạy từ phải sang vạch phán định.

Xếp hàng ngang mới là thứ làm trò này hay: liếc sang thấy hàng người khác đang ăn combo. Bản 3D
mỗi người một khu thì mất sạch cái đó.

**Hàng của mình phải khác hẳn** — cao hơn, sáng hơn, có khung. Tám hàng giống nhau là người chơi
bấm theo nhầm hàng, rồi nghĩ game hỏng chứ không nghĩ mình nhìn nhầm.

**Đừng gửi từng nốt.** 4 nốt/giây × 8 người = 32 gói/giây, một mình trò này ăn gần hết ngân sách.
Gửi `(id, điểm, combo)` mỗi giây một lần. Nốt trên hàng người khác tất định từ hạt giống; người
xem cần thấy ĐIỂM LEO, không cần thấy từng cú bấm.

**Cảnh báo còn nguyên:** đổi sang 2D sửa phần CODE, không sửa phần NỘI DUNG. Vẫn cần một bài nhạc
dùng được và một bản đồ nốt khớp nhạc làm tay. Chỉ làm **một bài**.

### Explosive Exchange phải có hồi chiêu chuyền ~1 s

Không có thì hai người dính nhau là quả bom nảy qua lại mỗi khung hình → bão RPC → lỗi 1035.

### Temporal Trails: lệch vài cm là chấp nhận được

Vệt vẽ từ vị trí nội suy nên có thể có khung hình mà máy A thấy mình chạm, máy B thấy không. Vì
NGƯỜI BỊ NẠN TỰ NHẬN nên không bao giờ mâu thuẫn — chỉ là "thoát chết trong mắt người khác" đúng
một khung.

### Đồng hạng: hoà thì hoà THẬT

**Đừng sắp thứ tự giả bằng `player_id`.** Người chơi thấy "1. A, 2. B" trong khi cả hai cùng 5
điểm là họ nghĩ game thiên vị — và họ đúng. `player_id` chỉ dùng để mảng sort ổn định.

Hoà thì cùng nhận thưởng hạng đó, hạng sau nhảy cóc (5đ, 5đ, 3đ → hạng 1, 1, 3). Lạm phát thưởng
là giá phải trả, chấp nhận — chia đôi rồi làm tròn thì đẻ ra một mớ luật vặt để tiết kiệm một cái
chìa khoá.

Nhưng trước khi cho hoà, mỗi trò phải hết tiebreak CÓ NGHĨA. Quy tắc: **điểm là số nguyên nhỏ thì
chắc chắn sẽ hoà** → phải có tiebreak; **điểm là thời gian/quãng đường** → bỏ qua.

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

Trên bàn cờ, nếu hạng minigame quyết thứ tự đi lượt sau: hai người đồng hạng thì **giữ nguyên thứ
tự tương đối của lượt trước** — một phép sort ổn định, không phải luật mới.

### Kiến trúc: RIÊNG scene, nhưng CHUNG code

Pummel Party làm mỗi minigame một map độc lập, ẩn board rồi load map minigame qua màn hình chờ.
Fusion làm được y hệt — `Fusion.load_scene()` / `unload_scene(index)`, và `SCENE_LOAD_CUSTOM` sinh
ra đúng để có màn hình loading (xem mục 1g). Cái `CanvasLayer` mà `QuanTroMiniGame` đang dùng
KHÔNG phải giới hạn của Fusion; nó là lựa chọn hợp lý cho Tank — một trò 2D không có nhân vật.

- **Riêng:** file `.tscn`, camera, luật, cách tính điểm
- **Chung:** script điều khiển nhân vật chế độ trên-cao, cách teleport vào, hợp đồng `MiniGame`,
  hàm sort bảng điểm

Hợp đồng `MiniGame.xong(xep_hang)` **giữ nguyên, không sửa dòng nào** — mỗi trò tính điểm kiểu gì
tuỳ nó, chỉ phải trả ra cùng một mảng ở mọi máy.

### ⚠️ CHƯA XÁC MINH — hỏi trước khi cam kết

**Người chơi do `FusionSpawner` spawn có sống sót khi `unload_scene()` gỡ scene phòng chờ không?**
Họ gắn vào `scene_parent` chứ không gắn vào slot scene, nên *có lẽ* sống — nhưng chưa ai kiểm.
Trang *Large Scenes* của doc Fusion Godot có thể trả lời.

**Không cần đợi đáp án:** v1 giữ phòng chờ **load nhưng ẩn**, chỉ `load_scene` thêm scene minigame.
Doc nói rõ nhiều scene cùng lúc là chuyện bình thường, và replicator đứng yên gần như không tốn
băng thông (mục 1h). Tốn ít RAM, đổi lại không phụ thuộc câu chưa xác minh.

### Thứ tự làm

```
1. T2   Breaking Blocks · Laser Leap · Searing Spotlights      (3 tro)
        -> dung khuon: san + cam tren cao + dieu khien theo cam + tu khai tu
2. T1   Magma&Mages · Acidic Atoll · Explosive · Crown   (4 tro, Snowy Spin da xoa)
        -> them 1 nut don, bang config 5 dong
3. T3   Bounding Blocks · Temporal Trails · Word Wars          (3 tro)
4. T4   Sidestep Slope · Nhat qua · Slippery Sprint            (3 tro)
5. T5   Bong chay · Rockin Rhythm · Dem thu · Fractured Faces   (4 tro)
```

Hết bước 2 là **8 trò chạy được**, đủ quay demo. Cắt thì cắt ngược từ T5 — mỗi trò T5 là một game
nhỏ tự thân, đắt nhất về công sức dù rẻ nhất về mạng.

---

## 1bv. Bàn party — máu, chìa, cốc, vật phẩm. ĐÃ CODE, CHƯA TEST 2 MÁY

Trước đây `BanDuong` khai đủ 8 loại ô nhưng **chưa ô nào có hiệu ứng** — `ban.loai(o)` chỉ dùng để
in chữ lên HUD. Đây là điền vào chỗ đã chừa sẵn.

Giả định: **Q1 = chìa khoá → mở rương → lấy cốc, nhiều cốc nhất thì thắng.** Bàn đã có ô `RUONG`
và `ASSET-CAN-THEM.md` ghi "rương + cốc" nên coi như đã chốt theo hướng đó.

### Máu — chết là MẤT, không phải BỊ LOẠI

| | |
|---|---|
| Máu tối đa | 10, ai cũng bắt đầu đầy |
| Hết máu | về **Nghĩa địa gần nhất**, hồi đầy, **mất toàn bộ chìa chưa tiêu và mọi vật phẩm** |
| Không mất | **CỐC.** Mở rương rồi thì không ai lấy lại được |

Cái trần "mất chìa nhưng không mất cốc" là thứ giữ cho ván không vô nghĩa. Không có nó thì người
dẫn đầu bị cả phòng đập về 0 và hai mươi phút vừa chơi thành công cốc.

**Không bao giờ loại người chơi khỏi bàn.** Ngồi xem 20 phút là hỏng cả buổi.

### Tám ô

| Ô | Hiệu ứng |
|---|---|
| `TRONG` | không gì |
| `CHIA` | +1 chìa |
| `SAT_THUONG` | −2 máu (`@export`) |
| `NGUY_HIEM` | −4 máu (`@export`) |
| `NGHIA_DIA` | hồi đầy máu · là điểm hồi sinh (`gan_nhat_loai()` đã viết sẵn cho việc này) |
| `BI_AN` | master rút 1 trong 4 thẻ: +2 chìa · −1 chìa · +1 Bom · hồi đầy máu |
| `CUA_HANG` | mua vật phẩm **bằng chìa** |
| `RUONG` | tiêu `chia_mo_ruong` chìa → +1 cốc |

**Cửa hàng bán bằng chìa khoá — không có loại tiền thứ hai.** Tiêu thứ dùng để thắng để đổi lấy
sức mạnh là một quyết định khó thật sự, và nó tiết kiệm nguyên một hệ thống xu + ô kiếm xu + UI xu.

### Vật phẩm — bốn món, mỗi món một trục

| Món | Hiệu ứng | Giá (chìa) |
|---|---|---|
| Bom | ô tâm −4, hai ô kề −2 | 1 |
| Khiên | chặn **trọn vẹn** một đòn tiếp theo, kể cả đòn to hơn máu đang có | 2 |
| Bom lớn | tầm 2: tâm −5, kề 1 ô −3, kề 2 ô −1 | 3 |

Xúc xắc đôi (trục di chuyển) chưa làm.

**Tầm vụ nổ trên bàn vòng kín là số Ô, không phải mét.** `ban.tien()` / `posmod` lo phần vòng.
Đổi tầm = sửa đúng mảng `BAC_BOM`, thuật toán không cần biết tầm là bao nhiêu.

> ⚠️ **Hai chiều có thể cham CÙNG một ô.** Trên bàn nhỏ, ô cách tâm k bước sang trái và sang phải
> là cùng một ô. Lấy **MAX** chứ không cộng dồn và không ghi đè — một quả bom không đánh một ô hai
> lần, và bậc xa không được xoá bậc gần. Đã có assert cho đúng ca này.

> **Đừng làm hệ nâng cấp tầm nổ trên bàn cờ.** Bomberman có nó vì bạn nhặt buff trong một ván 60
> giây rồi mất sạch. Trên bàn cờ, "tôi đang có tầm mấy" là trạng thái phải nhớ suốt 20 phút —
> người chơi quên, rồi ngạc nhiên. Hai món riêng biệt rẻ hơn và đọc được ngay.

### Đồng bộ — MỘT gói, không phải mười loại sự kiện

Bản trước phát SỰ KIỆN rồi mỗi máy diễn lại. Thêm máu/vật phẩm vào kiểu đó là mỗi món một loại RPC,
và kết quả phụ thuộc trạng thái nên lệch dần. Đã chuyển sang **mẫu mục 8 của `GUIDE.md`** — mẫu mà
cả sáu minigame hiện có đang dùng.

```
{"luot":2, "thu_tu":[1,3,2],
 "o":{"1":5,...}, "mau":{...}, "chia":{...}, "coc":{...}, "do":{"1":["bom"],...},
 "su_kien":"Khang: MO RUONG +1 coc"}
```

Tám người ra khoảng 800 byte. GUIDE đã đo `String` RPC 3000 byte tới đủ → an toàn, miễn là chỉ
phát KHI CÓ SỰ KIỆN. Đổi sang mẫu này cho không hai thứ: người vào muộn xin đúng một gói, và đổi
master giữa ván không mất gì.

Mọi hành động đi một đường: `xin_*` → master kiểm luật → master phát nguyên gói. `main.gd` bỏ được
hẳn RPC `_net_thu_tu_moi` — thứ tự lượt giờ nằm trong cùng gói đó.

### ⚠️ Khoá của mọi bảng theo người chơi là CHUỖI

`JSON.parse_string()` trả Dictionary khoá CHUỖI. Master ghi `tt["mau"][5]` còn máy nhận đọc
`tt["mau"]["5"]` thì tra không thấy, trả về null — **không lỗi, không cảnh báo**, bảng chỉ hiện ai
cũng 0 máu. Mọi chỗ đụng tới bảng theo người chơi đều đi qua `_k()`.

### Đã đơn giản hoá có chủ đích (`ponytail:` trong code)

- **Cửa hàng tự mua món đắt nhất mua nổi** — bản đủ mở bảng cho người chơi chọn. Thêm khi có UI.
- **Bom tự nhắm vào người kế tiếp trong thứ tự lượt** — bản đủ cho chỉ vào một ô bất kỳ. Luật nổ
  bên dưới không đổi một dòng khi thêm UI.
- **Dùng đồ chỉ trong lượt mình, phím 1..9**, đọc thẳng keycode chứ không thêm action vào
  `project.godot`. Một cửa sổ duy nhất, master duyệt tuần tự → không có tranh chấp nào để giải.

### Đã kiểm (headless, assert)

Tầm nổ · vòng kín · lấy MAX khi hai chiều trùng ô · khiên chặn trọn đòn rồi bị tiêu · máu kẹt ở 0 ·
chết mất chìa và đồ nhưng **giữ cốc** · rương thiếu chìa thì không trừ chìa · cửa hàng mua món đắt
nhất mua nổi · ô sát thương/nguy hiểm/nghĩa địa. Tất cả xanh. File test đã xoá theo quy ước.

> `--script` KHÔNG nạp autoload → `NetManager` không tồn tại → mọi script phụ thuộc nó không biên
> dịch được. Test phải chạy bằng **scene**: `godot --headless --path . res://_test_x.tscn`.

### Tái cấu trúc theo ba yêu cầu — vật thể là NODE, scene tách việc, logic tách riêng

**Trước:** `ban_duong.gd` dựng 24 ô bằng code — mỗi ô 6 node (`Node3D.new()`, `BoxMesh`,
`StandardMaterial3D`, `StaticBody3D`, `CollisionShape3D`, `Label3D`). Vị trí tính từ các node
mốc `Moc*` theo độ dài cung. Muốn đổi một ô là phải đọc code.

**Sau:**

| File | Việc duy nhất |
|---|---|
| `board/o_ban.tscn` + `o_ban.gd` | MỘT ô. Script chỉ gán `material_override` và `Label3D.text` theo `loai` |
| `board/ban_party.tscn` | Bản đồ: 24 instance của `o_ban.tscn`, mỗi ô mang `so` + `loai`, **kéo được trong editor** |
| `board/ban_duong.gd` | Hỏi đáp về bàn. Đọc các node `OBan` con, sắp theo `so`. **Không dựng gì** |
| `board/luat_ban.gd` | Luật chơi — **hàm thuần**, không node, không Fusion, không autoload |
| `board/pha_ban_co.gd` | Mạng + vòng lượt + cây scene |
| `ui/bang_ban.tscn` + `.gd` | Bảng trạng thái góc phải, tách khỏi `hud.tscn` |

Tám màu ô thành tám `materials/mat_o_*.tres` — sửa màu là sửa tài nguyên, không sửa code.

Đổi bản đồ = làm `.tscn` khác rồi trỏ `PhaBanCo.ban_scene` sang. `Moc*` đã bỏ vì hết ai đọc.
`board/demo_map.tscn` còn dùng API cũ và **không ai trỏ tới** — để nguyên, chờ người dùng quyết.

`LuatBan` không đụng autoload nên chạy được `godot --headless --script`. Đây là phép thử thật
cho việc tách: file nào chạm `NetManager` là `--script` không biên dịch nổi.

### Hai lỗi tìm ra khi chạy thử 6 người thật

> ⚠️ **Sáu người chồng lên nhau thành một cục.** Ai cũng xuất phát ở ô 0 và `_dat_len_o` đặt
> tất cả vào đúng tâm ô — nhìn ra một đống thịt không phân biệt được ai. Chữa: rải đều quanh
> tâm ô theo THỨ TỰ LƯỢT (`_cho_dung`). Chỗ đứng ổn định, mọi máy tính ra y hệt, **0 byte mạng**.
>
> Kèm một bẫy nhỏ: `thu_tu` đi qua JSON nên phần tử là **float**, `ds.find(id)` với `id` kiểu
> int không bao giờ khớp. Phải `int(ds[i]) == id`.

> ⚠️ **Bàn party vẫn chạy lượt TRONG LÚC minigame đang mở.** Minigame là một `CanvasLayer` phủ
> lên, không phải scene khác — `PhaBanCo` vẫn sống nguyên vẹn bên dưới và vẫn ăn
> `_unhandled_input`. Bấm Space giữa ván Tank là **vừa bắn tank vừa tung xúc xắc**.
>
> Chữa: `QuanTroMiniGame` thêm tín hiệu `bat_dau`, `main.gd` bật/tắt cờ `PhaBanCo.tam_dung`.
> Bàn không cần biết lớp phủ đó là cái gì — chỉ cần biết mình đang bị che. Cờ chặn cả
> `_unhandled_input` lẫn hai RPC, vì gói `_net_tung` có thể còn đang bay lúc minigame vừa phủ.

### Cách chạy thử nhiều người trên một máy

`_test_flow.tscn` bọc `main.tscn` + một node điều khiển; host tạo phòng rồi ghi tên phòng ra
file, khách đợi file CÓ NỘI DUNG rồi mới vào. Phím bấm đi qua `Input.parse_input_event()` nên
kiểm luôn đường input thật chứ không gọi tắt vào RPC.

> ⚠️ **Đừng khởi động nhiều bản cùng lúc.** Sáu bản Godot bật một lượt thì frame đầu dài tới
> mức Photon không được phục vụ và nó ngắt thật — **lỗi 1040**, đã dính hai lần. Giãn 6–10 giây
> mỗi bản, và **đợi vài giây sau frame đầu rồi mới gọi `connect_to_photon()`**, đừng gọi ngay
> trong `_ready()` của scene test.

### ĐÃ NỐI: điều kiện kết thúc ván

`PhaBanCo.coc_de_thang` (mặc định 3, đặt 0 = chơi vô hạn). Master kiểm mốc trong `_ket_luot`
**ngay sau hiệu ứng ô**, trước khi sang lượt kế — mở rương xong là thắng ngay, không phải chờ
hết vòng. Luật nằm ở `LuatBan.nguoi_thang()` (hàm thuần, kiểm bằng `assert` không cần dựng
phòng); hoà thì người đứng trước trong vòng lượt thắng.

Cờ `thang` đi trong chính gói trạng thái, nên MỌI máy tự biết mà không cần thêm một RPC nào:
`PhaBanCo` phát `van_thang`, `main.gd` hiện `ui/bang_thang.tscn` 6 giây rồi `dong()` bàn, kéo
nhân vật về phòng chờ, master đặt phòng về `PHASE_LOBBY`.

> ⚠️ `dong()` phải xoá **hẳn** `tt`, không chỉ đặt `luot = -1`. `LuatBan.trang_thai_moi()` giữ
> lại giá trị cũ của ai đã có (đúng cho "vòng mới"), nên còn giữ `tt` là ván sau mở ra ai cũng
> sẵn 3 cốc và thắng ngay lập tức.

Bước ra khỏi ô sẵn sàng tự tắt `is_ready`, nên kéo người về phòng chờ cũng là cách huỷ đếm
ngược — không cần đặt lại cờ nào.

### ĐÃ LÀM: camera bàn party là GÓC BA TỪ TRÊN XUỐNG

`CameraRig.set_ban_co()` — lùi 12 m, cúi 35°, FOV 72, tween 0.5 s. `PhaBanCo._che_do_ban_co()`
bật/tắt cùng lúc với khoá WASD, và chỉ đụng tới `is_mine`.

> ⚠️ **Độ cao phải do GÓC CÚI lo, không cộng vào `nang_cao`.** `nang_cao` là offset trong hệ
> của rig, mà rig đã nghiêng theo góc cúi: `nang_cao = 6` + cúi 35° đẩy camera lên 11,5 m
> nhưng vẫn chỉ cúi 35°, nên tia nhìn vượt qua đầu bàn — chụp lại thấy bàn tụt hẳn xuống góc
> dưới màn hình. Để `cao_ban = 0` thì camera nằm đúng trên cung tròn bán kính `lui_ban`.

Đã chụp thử ba bộ số trên `ban_party.tscn`: 9 m/28° quá sát (chỉ thấy nửa vòng), 15 m/42° thấy
cả vòng nhưng quân cờ nhỏ tới mức khó tìm ra mình, **12 m/35°** vừa đủ cả hai.

Chặn gọi lại khi không đổi trạng thái: gói trạng thái tới mỗi lượt vài cái, không chặn thì
tween khởi động lại liên tục và camera giật theo từng nhịp mạng.

### ĐÃ QUYẾT: rương DI CHUYỂN, không phải mở một lần

Bản đồ có đúng MỘT ô Rương. Ba phương án đã cân:

| Phương án | Vì sao không / có |
|---|---|
| Giữ vô hạn, đứng yên | Cả ván là đi vòng vòng về đúng một ô. Ai đang đứng gần nó lúc gom đủ chìa thì thắng — thắng bằng chỗ ngồi |
| Mỗi rương mở một lần | **Bẫy:** bản đồ một rương thì ván kết thúc ở đúng 1 cốc, không ai đủ 3 cốc để thắng được nữa |
| **Rương dời chỗ sau mỗi lần mở** ✅ | Mỗi lần mở là cả bàn phải tính lại đường. Không cần thêm ô rương nào trên bản đồ |

Master chọn một ô Trống bất kỳ, ô mới đi trong `tt["o_ruong"]` nên mọi máy dời y hệt — không
máy nào tự gieo số. `PhaBanCo._ap_ruong()` chạy ở MỌI gói nên người vào giữa ván cũng thấy
đúng chỗ. `BanDuong.dat_loai()` chỉ gán `OBan.loai`, mà setter của nó tự đổi vật liệu và nhãn
— không dựng lại node nào, và file `.tscn` không bị sửa.

`o_ruong` mang qua vòng mới (không thì hết mỗi minigame là rương nhảy về chỗ cũ) nhưng **không**
mang qua ván mới — `dong()` xoá sạch `tt`.

### ĐÃ CHỮA: rời phòng giữa ván làm kẹt vòng lượt

Fusion xoá object player của người rời trên mọi máy, nhưng `thu_tu` thì không tự biết. Tới lượt
một id không còn ai ngồi sau là **cả bàn đứng im vĩnh viễn** — lượt chỉ sang khi có người bấm
phím tung xúc xắc, mà không còn ai để bấm.

`PhaBanCo` nghe `node_removed`, master gỡ id khỏi vòng rồi phát lại. Con trỏ lượt phải chỉnh
theo, `erase` rồi thôi là sai:

- Người rời đứng **trước** người đang tới lượt → mọi người sau tụt một bậc, con trỏ tụt theo,
  không thì nhảy cóc qua một người.
- Người rời **chính là** người đang tới lượt → giữ nguyên chỉ số là trúng người kế tiếp;
  `posmod` lo trường hợp họ đứng cuối vòng.
- Hết sạch người → `dong()`.

Gỡ luôn `_dang_di`: họ có thể rời giữa đoạn đi, còn treo cờ đó là bàn khoá.

### Chưa làm

- Test hai máy qua Photon thật
- Xúc xắc đôi, UI chọn mục tiêu bom, UI cửa hàng


## 1c. Câu hỏi mở — CHƯA QUYẾT

Ghi lại để khỏi lạc. Không quyết cái nào cho tới khi bàn tới.

### Thiết kế

**Q1. Đi trên bàn cờ để làm gì? Thắng bằng cái gì?** *(quan trọng nhất — quyết định phần lớn còn lại)*

- **A. Đua tới đích.** Ô cuối là vạch đích, ai tới trước thắng. Thắng minigame thì được
  thêm bước / tung lại. Ván ngắn, luật hiểu trong 5 giây, không cần hệ thống kinh tế.
  Buộc bàn cờ và minigame dính vào nhau. Ít code nhất.
- **B. Kiểu Mario Party.** Minigame cho coin, coin mua sao, hết N vòng ai nhiều sao nhất thắng.
  Có chiều sâu, chơi lại nhiều lần. Nhưng phải thêm: coin, ô mua sao, sao di chuyển, UI cửa hàng.
  Ván dài, khó quay demo 3–5 phút.
- **C. Điểm thuần.** Bàn cờ chỉ là bề mặt ăn/mất điểm. Ở giữa, nhưng bàn cờ thành vô nghĩa —
  bỏ nó đi game vẫn chạy. *Khuyên tránh: tốn gần bằng B mà không được cái hay của B.*

*Claude nghiêng về A.*

**Q2.** Các loại ô sự kiện trên bàn cờ có những gì?
**Q3.** Một ván dài bao nhiêu vòng / bao nhiêu phút?
**Q4.** Danh sách minigame — làm những cái nào?
**Q5.** Tên dự án. Thư mục đang là `PartyBash`, chỉ là tên tạm.

### Kỹ thuật — cần tra doc Photon Fusion

**Q6.** Region code `"asia"` có hợp lệ với Fusion 3 không? Danh sách region ở đâu?
Đang để `fusion/connection/default_region="asia"`. Sai mã là connect fail.
**Q7.** `join_or_create_room(name, options)` — truyền `null` cho `options` được không,
hay bắt buộc `FusionRoomOptions.new()`?
**Q8.** `FusionSpawner.spawn(scene, pre_spawn_function)` — trong Shared mode, **mỗi client
tự spawn player của mình** hay chỉ master client được spawn? `pre_spawn_function` nhận
tham số gì? *(chặn phần spawn)*
**Q9.** `FusionReplicationConfig.add_property(path: NodePath)` — NodePath tương đối với
`root_path` của replicator? Sync `position` thì viết `.:position` hay `:position`?
*(chặn phần đồng bộ chuyển động)*
**Q10.** Đổi scene — master gọi `Fusion.load_scene()` thì client tự load, hay phải tự xử lý
signal `scene_load_requested`? `serialization/scene_load_mode = 0` (Auto) làm gì chính xác?
**Q11.** `owner_mode` — `PLAYER_ATTACHED` vs `PLAYER_PREDICTED` khác gì? Object có tự despawn
khi owner rời phòng không?
**Q15.** Fusion 3 preview có hỗ trợ **rejoin theo `player_ttl_ms`** không? Đặt TTL > 0 thì
người mất kết nối có giữ được player_id cũ và vào lại đúng slot không? *(cả cơ chế giữ chỗ
khi thoát giữa chừng phụ thuộc câu này — có fallback: coi mọi lần thoát là thoát hẳn)*

### Hành chính

**Q12.** Photon App ID — chưa có. Chặn mọi test kết nối. Đăng ký ở `dashboard.photonengine.com`,
điền vào Project Settings > `fusion/connection/app_id`.
**Q13.** Tải 5 pack asset Kenney về chưa?
**Q14.** Có dọn `addons/fusion/` từ 97 MB xuống ~7 MB (xoá binary macOS/Linux/Android/iOS/web) không?

### Đã chốt

- Bàn cờ: **GIỮ** (không bỏ như phương án cũ)
- Phân phối: **git, repo private**. Không auto-updater, không web export, không Steam
- Networking: **Photon Fusion, Shared Authority**
- Ngôn ngữ: **GDScript** (không dùng C#)
- Model nhân vật: **một cho cả ba nơi**, không scale lại, chỉ đổi camera
- Bối cảnh phòng chờ: **TÀU VŨ TRỤ**
- Bố cục phòng chờ: **MỘT PHÒNG DUY NHẤT** (buồng lái), không hành lang, không phòng phụ.
  Mọi người luôn trong cùng khung hình — thấy nhau, thấy ai đã sẵn sàng, không ai đi lạc,
  không có chuyển cảnh phải đồng bộ, quay demo một khung là đủ. Làm cho nó **dày** thứ để
  đụng vào chứ không phải to. Chật thì mở thêm phòng sau — dễ; gom nhiều phòng về một — khó.

### Vì sao tàu vũ trụ

Chọn theo tiêu chí *bối cảnh nào tự đẻ ra thứ để nghịch*, không phải bối cảnh nào đẹp.

- Sci-fi cho phép mọi thứ phát sáng, kêu bíp, chuyển động **mà không cần giải thích**.
  Nút đỏ trên tàu vũ trụ thì hiển nhiên bấm được; nút đỏ giữa rừng thì phải bịa lý do.
- Nó giải thích luôn cấu trúc game: tàu = hub, bàn cờ = bản đồ ngân hà, minigame = hành tinh.
  Bàn cờ tự có hình dạng, đỡ phải thiết kế từ đầu.
- Asset CC0 nhiều và **modular**: Kenney Modular Space Kit, Quaternius Ultimate Space Kit /
  Modular Sci-Fi Megakit. Ghép mảnh theo ý mình thay vì nhận nguyên phòng của người khác.
- Rẻ: không gian kín, ít thứ phải vẽ, chiếu sáng dùng emissive là gần đủ.

Đã cân nhắc và loại: **rừng trúc + sương mù** (đẹp nhất, sương mù rẻ về kỹ thuật, nhưng
tĩnh lặng — lệch tông với party game hỗn loạn, và nghèo thứ tương tác);
**phòng cao ốc** (nội thất văn phòng là đồ để nhìn, không phải đồ để nghịch —
trừ biến thể *sân thượng*, vẫn để ngỏ nếu sau này cần một sân minigame không đổi cảnh).

### Nguyên tắc phòng chờ: lấy gì / xây gì

> **Lấy sẵn những thứ không biết gì về game của bạn. Tự xây những thứ có biết.**

| Phần | Cách làm |
|---|---|
| Hình khối phòng, prop, trang trí, texture, âm thanh | **Lấy CC0.** Không tự model gì hết |
| Hành vi khi bị tương tác, và việc đồng bộ hành vi đó | **Tự xây.** Không tải về được |

Không tải nguyên một scene phòng chờ có sẵn về sửa: mọi template Godot đều viết trên
multiplayer built-in (ENet, `MultiplayerSynchronizer`, `@rpc`), ta dùng Photon Fusion với mô
hình quyền sở hữu khác hẳn → phải moi ra viết lại đúng phần khó nhất, phần giữ được chỉ là
hình học. Kèm theo là thừa hưởng cấu trúc node, quy ước tên và scale của người khác.

*(Lưu ý: MIT là license cho code. Asset 3D thì tìm **CC0**, không có MIT.)*

---

## 1d. Phòng chờ — ĐÃ CHỐT

> Thay thế mục 6 ở dưới (mục 6 viết cho phương án cũ, chưa có bối cảnh tàu vũ trụ).

### Sẵn sàng: một ô lớn, đứng lên là xong

- **Một ô lớn duy nhất.** Mọi người trong phòng cùng đứng lên → đếm ngược → phóng tàu.
  Bước ra khỏi ô = huỷ sẵn sàng.
- **Đứng là đủ, không cần bấm phím.** Tự giải thích, không cần hiện dòng nhắc, lỡ chân
  cũng không hại vì bước ra là huỷ.
- Cú **phóng tàu chính là chuyển cảnh** sang bàn cờ — không cần màn hình loading giả.

Đã cân nhắc và loại: nút UI trên màn hình (là thứ duy nhất trong phòng *không cần đến căn
phòng*); nút lớn chia phần theo số người (đẹp, gộp được cả bảng danh sách người chơi, nhưng
càng đông càng vụn, và việc chia lại phần khi có người vào/thoát giữa chừng là một ổ bug).

**Hai mép phải bịt:**
- Một người AFK là cả phòng kẹt → **giữ nút ép bắt đầu cho chủ phòng**.
- Người vào phòng giữa lúc đang đếm ngược → **huỷ đếm ngược** (họ chưa kịp đứng lên).

### Luật lọc của phòng chờ

> **Thứ gì trong phòng mà người khác không thấy được thì không đáng tồn tại.**

Mọi thứ A tác động thì B, C, D đều phải thấy. Luật này tự động loại các thứ trang trí giả
tương tác — nút chỉ kêu trong máy mình, cần gạt chỉ mình thấy nhúc nhích.

Áp dụng cho **thay đổi lên thế giới**. Góc camera, HUD, âm lượng vẫn là local — không mâu thuẫn.

**Hai điều để giữ luật này mà không trả giá:**

1. **Viết cơ chế đồng bộ đúng một lần.** Một khuôn chung cho "vật tương tác được"
   (có chủ · có giá trị được đồng bộ · có sự kiện lúc bị chạm), mọi thứ trong phòng đúc từ
   khuôn đó. 20 vật thể tự viết phần mạng riêng = 20 chỗ có thể sai.
2. **Ngân sách nằm ở đồ vật lý, không nằm ở số lượng.** Trăm công tắc vẫn rẻ (mỗi cái một
   số nguyên). Năm quả bóng lăn thì tốn thật. **Đếm bóng, đừng đếm nút.**

Hệ quả phải chấp nhận: ai cũng bấm được mọi thứ, sẽ có người spam. Chơi với bạn bè thì đó là
tính năng.

### Trạng thái và sự kiện — chọn sai là bug kinh điển

| | **Trạng thái** | **Sự kiện** |
|---|---|---|
| Là gì | Đèn *đang* màu gì | Tiếng "cạch", tia sáng loé |
| Người vào sau | **Phải** thấy đúng | Không cần biết |
| Cách làm | Property trong replication config | RPC |

Phần lớn vật tương tác cần **cả hai**.

**Bẫy:** chỉ làm RPC. Lúc bấm ai cũng thấy đổi, nhưng người vào phòng 10 giây sau thấy trạng
thái cũ — RPC đã bay qua và không để lại dấu vết.

**Ai sở hữu:** đồ của thế giới → **master client**. Người bấm gửi RPC xin đổi, master đổi giá
trị, giá trị replicate về mọi máy (kể cả máy người bấm). Trễ khoảng nửa RTT, không nhận ra
được với một cái công tắc. Để người bấm tự đổi thì hai người bấm cùng lúc ra hai kết quả khác
nhau và không ai đúng.

**Mẹo:** đồng bộ **số nguyên chỉ số bảng màu** (`0=đỏ, 1=xanh...`), không đồng bộ `Color`
(4 số thực). Nhẹ hơn, và không bao giờ nhận được giá trị vô nghĩa từ mạng.

### Người thoát giữa chừng

**Nguyên tắc số một: KHÔNG dồn số lại.**

```
1 | 2 | 3 | 4     người 2 thoát
1 |   | 3 | 4     ĐÚNG  — chừa chỗ trống
1 | 2 | 3         SAI   — người 3 thành người 2
```

Màu, điểm, điểm spawn, hàng trong bảng điểm đều gắn theo chỉ số slot. Dồn một cái là bốn thứ
lặng lẽ gán nhầm.

**Dùng `is_inactive` của Photon.** Signal thật: `player_left(player_id: int, is_inactive: bool)`,
kèm `FusionRoomOptions.player_ttl_ms`. Đặt TTL > 0 thì người mất kết nối vẫn được giữ chỗ
trong phòng và quay lại đúng slot cũ:

```
is_inactive = true   ->  "MẤT KẾT NỐI"   ô xám, giữ chỗ, giữ điểm, chờ quay lại
is_inactive = false  ->  "ĐÃ THOÁT"      đẩy sang danh sách phụ
hết player_ttl       ->  chuyển sang ĐÃ THOÁT
```

Rớt mạng 30 giây rồi vào lại mà còn nguyên điểm — thứ khiến người test không bực. Có sẵn
trong Photon, không phải tự viết. *(Xem Q15 — cần verify preview có bật không.)*

**Điểm của người thoát: đóng băng, không xoá.**
Vẫn hiện trên bảng, gạch mờ, và **loại khỏi việc xét người thắng**. Không xoá khỏi bảng ngay
lúc họ thoát — bảng điểm nhảy số giữa trận làm người còn lại tưởng mình bị trừ.

**Ba tình huống hở:**

| Tình huống | Xử lý |
|---|---|
| Thoát giữa minigame kiểu "trụ lại cuối cùng" | Tính lại số người còn sống ngay lúc đó. Còn 1 → cho thắng luôn. Còn 0 → huỷ vòng |
| Tụt xuống dưới 2 người | Kết trận, về phòng chờ |
| Người thoát là master client | Photon bầu master mới; master mới **tiếp quản `MatchState`** |

### Đồ trong phòng: bàn cờ

**Có gì:**
- **Bàn cờ hai mặt** — mặt trước cờ vua, mặt sau cờ tướng. Một **nút LẬT MẶT**.
- **Bàn caro** riêng.
- **Không có logic luật nào hết.** Cố ý.

**Vì sao không làm luật:** bàn cờ không luật thì chơi được mọi thứ — cờ vua, cờ tướng, caro,
cờ đam, xếp tháp tốt. Thêm luật vào là *thu hẹp* nó lại. Chưa kể luật cờ qua mạng (tới lượt ai,
nước hợp lệ không, chiếu chưa) sẽ nhiều code hơn toàn bộ phần còn lại của phòng chờ.

**Nhân vật tự cầm quân, không dùng tay robot.** Tay robot có mùi sci-fi hơn nhưng chỉ một người
dùng được một lúc (ba người kia đứng nhìn — phản party), và thêm hẳn một tầng điều khiển.
Cầm tay còn được miễn phí một thứ: **có người sẽ cầm con hậu chạy mất.**

**"Lật mặt" không phải lật thật.** Bàn hai mặt có quân trên cả hai mặt thì lật là rơi hết.
Thực chất: animation lật đẹp mắt, bên dưới là **đổi bộ quân** — cờ vua biến mất, cờ tướng hiện ra.

### Quân cờ — tự dựng hết, KHÔNG mua asset

**Godot có sẵn máy tiện.** `CSGPolygon3D` chế độ **Spin**: vẽ một mặt cắt 2D, nó xoay quanh
trục thành khối 3D. Quân cờ vua ngoài đời vốn được tiện trên máy tiện, nên **5 trong 6 quân**
— tốt, xe, tượng, hậu, vua — là đúng một mặt cắt xoay tròn. Vẽ ngay trong editor bằng cách kéo
điểm, không cần Blender.

*Dựng xong bấm **Convert to MeshInstance3D** để nướng thành mesh tĩnh — đừng ship CSG sống,
nó tính toán lúc chạy.*

**Quân mã = chữ `HORSE` xếp dọc, dùng `TextMesh`.**

```
    H
    O
    R          H TRÊN CÙNG, đọc xuôi từ trên xuống
    S
    E
  ▔▔▔▔▔   <- VẪN đứng trên đế tiện như mọi quân khác
```

`TextMesh` là chữ 3D có độ dày thật (không phải mặt phẳng dán chữ) — gán vào `MeshInstance3D`,
gõ chữ, xong. Không dựng model nào.

Vì sao xếp dọc: viết ngang thì "HORSE" rộng gấp 5 lần cao, tràn sang ô bên cạnh. Xếp dọc thì
chân đế rộng đúng một ô, cao vống lên — mà quân mã thật cũng cao. Đọc được từ **cả hai phía bàn
cờ**, đúng hai hướng nhìn duy nhất quan trọng.

**Giữ đế tiện giống các quân khác** — đó mới là chỗ buồn cười. Bỏ đế đi thì nó chỉ là chữ nổi
lăn lóc. Và **chỉ quân mã thôi**; cả bộ đều là chữ thì hết vui, thành thiết kế khác.

**Quân cờ tướng = trụ dẹt + `Label3D` gõ chữ Hán.** Không cần vẽ texture. Nhất quán với quân mã:
cả hai đều là "chữ thay cho model", một cái nổi khối, một cái phẳng.

### Nguồn asset miễn phí — đã kiểm

**Quyết định: KHÔNG mua asset.** Mọi món còn thiếu đều tự dựng được hoặc có nguồn CC0.
*(KayKit Board Game Bits có cờ vua + bài nhưng nằm ở bản trả phí $4.99 — bỏ qua.)*

| Món thiếu | Đường miễn phí |
|---|---|
| Quân cờ vua | `CSGPolygon3D` Spin |
| Quân mã | `TextMesh` "HORSE" |
| Quân cờ tướng | Trụ dẹt + `Label3D` |
| **Lá bài** | **Kenney Playing Cards Pack** — CC0, **270 file**, nguyên bộ + mặt lưng. Mesh chỉ là hộp mỏng |
| Xúc xắc 2d6 | Khối lập phương + texture chấm |
| Quân caro | Trụ dẹt đen/trắng |
| Rổ bóng rổ | `TorusMesh` vành + `BoxMesh` bảng, bỏ lưới |
| Robot nhỏ | Quaternius **Animated Robot Pack** — CC0 |
| Vịt / cánh cụt | Quaternius **Ultimate Animated Animal Pack** — CC0, 12 con vật, mỗi con 12+ animation, có glTF. Hoặc **đua meeple** |
| Skybox vũ trụ | **Poly Haven** HDRI CC0, hoặc shader vẽ sao thủ tục (~20 dòng) |

Nguồn đúng loại: **Kenney · Kay Lousberg (KayKit) · Quaternius · Poly Haven · Poly Pizza ·
itch.io mục Game Assets · Sketchfab lọc license.**

### Bộ lọc khi gặp một nguồn asset lạ

| | Dùng được | Bỏ |
|---|---|---|
| Định dạng | `.glb` `.gltf` `.obj` `.fbx` `.blend` | `.stl` `.3mf` `.step` `.vox` |
| Texture / UV | Có, kèm `.png` | Không có gì ngoài hình khối |
| Mật độ lưới | Low-poly, vài trăm–vài nghìn tam giác | Hàng chục nghìn trở lên |
| License | Ghi rõ CC0 / CC-BY | Không ghi, hoặc NC / SA |

**Trang in 3D là SAI LOẠI NGUỒN** — Thingiverse, Printables, MakerWorld. File STL không có UV,
không material, Godot không nhập được; mật độ lưới cao gấp hàng chục lần cần thiết; và license
thường là CC-BY-NC-SA (cấm thương mại + bắt chia sẻ lại).

**Lý do chiến lược để không mua và không cầu kỳ:** đề chấm 15% cho extension và ghi rõ
*"Higher marks are awarded for programming extensions rather than only visual changes."*
→ Một giờ bỏ vào netcode đáng hơn một giờ bỏ vào model. Tự dựng bằng CSG không phải phương án
chắp vá, nó là **phương án đúng** — ít thời gian nhất cho phần được chấm ít điểm nhất, và không
có vấn đề license nào để lo.

### Bàn cờ: kiến trúc — quyết định việc này rẻ hay là ác mộng

**Quân cờ KHÔNG được là `RigidBody3D`.** 32 con vật lý sẽ rung, đẩy nhau, trôi, và master phải
đồng bộ 32 transform liên tục. Bàn sẽ tự long ra sau mười giây.

```
Bàn cờ            =  MỘT mảng trạng thái ô   "E4 = mã trắng"   ← master giữ
Quân đang được cầm =  vật thể mạng thật, tối đa 1 con / người
```

Nhặt lên: xoá khỏi mảng, hiện một con trong tay. Thả: xoá con trong tay, ghi vào mảng.
→ Lúc nào cũng chỉ tối đa 4 quân cờ thật sự tồn tại trên mạng, dù bàn có 32 con.
Ba bàn cùng lúc vẫn rẻ.

**Ném được, vẫn không cần vật lý.** Cung bay **tính sẵn**: người ném tính điểm đáp, gửi một lần,
mọi máy nhận cùng điểm đầu + điểm đáp + thời gian bay nên vẽ ra cùng một đường cong. Không có mô
phỏng nào chạy → không có gì để lệch. Đáp xuống là **nằm im**, không lăn.

Trạng thái một quân chỉ có hai kiểu: `"ở ô E4"` hoặc `"nằm ở (x, z)"`.
Cú ném là **sự kiện** (RPC bay một lần); chỗ nằm là **trạng thái** (người vào sau vẫn thấy con
tốt dưới gầm bàn).

**Một nút, không phải hai.** Đang nhắm vào một ô → **đặt xuống ô đó**. Nhắm đi chỗ khác →
**ném theo hướng nhìn**. Không cần dạy, không cần hiện dòng nhắc.

**Nút RESET là thiết yếu, không phải tiện ích.** Sau mười phút cờ nằm khắp buồng lái, dưới ghế,
sau máy móc. Reset = ghi lại mảng ban đầu + gom hết quân văng về. Không có nó là bàn cờ hỏng
vĩnh viễn.

**Mép phải bịt:** quân đáp vào tường hoặc lọt ra ngoài phòng → **kẹp điểm đáp vào biên căn phòng**.
Không cần va chạm, chỉ cần không cho ra ngoài.

**"Bốp" khi ném trúng người** — cung bay đi ngang gần một nhân vật → phát tiếng + cho họ giật mình.
Chỉ là kiểm tra khoảng cách rồi gửi một sự kiện, không cần va chạm thật. Không ảnh hưởng gì tới
game, nhưng biến việc ném cờ vào mặt nhau thành một trò.

### Đồ trong phòng: chốt danh sách

**Lấy:** ô sẵn sàng · bàn cờ (vua/tướng/caro) · bóng rổ + rổ · ống tụt · phi tiêu ·
xích đu · bàn bài · đua vịt · Penguin Cross · craps (2d6)

**Bỏ hẳn:**

| Món | Vì sao |
|---|---|
| Air hockey | Puck nhanh + hai người cùng đánh = trường hợp xấu nhất cho shared authority. Đổi chủ mỗi lần chạm thì thrash; master giữ thì thấy vợt **xuyên qua puck rồi puck mới nảy lại** sau ~80 ms — ở tốc độ đó nhìn thấy rõ. Muốn cứu phải viết client-side prediction = việc của minigame thật, không phải đồ chơi phòng chờ |
| Ping pong | Tệ hơn nữa — bóng nhỏ hơn, nhanh hơn, ăn nhau hoàn toàn ở thời điểm chạm vợt |
| Bắn bia | Trùng niềm vui với phi tiêu nhưng phải làm súng + raycast + bia bật lên. Phi tiêu dùng lại **y nguyên** cơ chế ném quân cờ |
| Máy gắp thú | Để danh sách làm sau |
| Bảng xếp hạng | Không làm |

**Luật lọc rút ra:** *trò nào mà thắng thua phụ thuộc phản xạ theo mili-giây thì đừng đặt
trong phòng chờ.* Độ trễ sẽ quyết định thay cho kỹ năng — và người chơi không nghĩ "mạng lag",
họ nghĩ "game này hỏng".

**Ống tụt nằm NGOÀI khu trò chơi** — nó không phải trò chơi, nó là cách di chuyển giữa hai
cao độ trong buồng lái.

### Cụm cờ bạc — một cơ chế, bốn trò

**Không có cược thật. Xu là ĐẠO CỤ**, có chỗ cấp, refill thoải mái. Không phải hệ thống kinh
tế → cụm này không phụ thuộc Q1 (bàn cờ thắng bằng gì).

**Nhưng không cược thì Penguin Cross mất ý nghĩa** — toàn bộ trò đó là *một* quyết định
tham-hay-dừng, mà tham chẳng mất gì nếu xu mọc lại.

**Cách sửa bị ép bởi chính luật lọc của phòng chờ:** một trò cờ bạc chơi một mình trên màn
hình riêng là vi phạm *"thứ gì người khác không thấy được thì không đáng tồn tại"*.
→ **Cược bằng khán giả, không cược bằng tiền.**

Con cánh cụt **đi thật trên một đường ray giữa phòng**, hệ số hiện to trên đầu, ba người kia
đứng xem bạn đi tới 4x rồi hét "dừng lại đi". Cái mất không phải xu — là **thua trước mặt ba
người**. Không refill được, và miễn phí về mặt code.

**Craps:** luật street craps chuẩn — come-out 7/11 thắng, 2/3/12 thua, còn lại thành Điểm mục
tiêu; sau đó tung lại trúng Điểm thì thắng, ra 7 trước thì thua. Khoảng 40 dòng.
**Bắt buộc 2d6** — 2d4 chỉ ra tổng 2–8 nên mất hẳn 11, 12, 9, 10, luật sập.

### Ngẫu nhiên trong multiplayer — nguyên tắc cho cả dự án

**Ngẫu nhiên không tự chia sẻ.** Mỗi máy tự gọi random thì mỗi máy ra một số khác nhau —
không phải lỗi mạng, là hệ quả tất yếu.

> **Đúng MỘT máy quyết, rồi gửi con số đó đi. Các máy khác KHÔNG tính lại.**

**Ai gieo?**

| Việc | Ai gieo |
|---|---|
| Lắc xúc xắc, rút bài, bước cánh cụt | **Chính người hành động** — nhanh hơn, không phải chờ vòng đi-về tới master |
| Đua vịt, minigame kế tiếp, tranh chấp ai nhặt được xu | **Master** — vì kết quả không thuộc về riêng ai |

Để người hành động tự gieo thì họ *có thể* sửa client để luôn ra 7. Chơi với bạn bè thì không
đáng bận tâm.

**Gửi kết quả hay gửi hạt giống?**
- Kết quả đơn giản (xúc xắc ra 7, lá bài là át bích) → **gửi thẳng con số**
- Chuỗi phức tạp (đua vịt: 6 con, 20 giây, hàng trăm khoảnh khắc) → **gửi một hạt giống**,
  mọi máy nạp vào bộ sinh ngẫu nhiên rồi chạy cùng thuật toán → ra cùng một cuộc đua

**Diễn hoạt phải chiều theo kết quả đã chốt.** ĐỪNG dùng vật lý thật cho xúc xắc — vật lý
trong Godot không đảm bảo giống nhau giữa các máy, bốn máy sẽ ra bốn mặt. Biết trước là 7 rồi
chạy hoạt cảnh lăn dừng đúng ở 7. Mọi board game điện tử đều làm vậy.

→ **Làm xong trò đầu tiên thì ba trò sau gần như chỉ là thay hình.**

### Xúc xắc

- **Phòng chờ: 2d6.** Chốt. Craps bắt buộc.
- **Bàn cờ: CHƯA CHỐT.** Nó là hệ quả của Q1/Q3: `số ô = số lượt × trung bình mỗi lần tung`.
  d6→~35 ô cho 10 lượt, d10→~55, d12→~65. Xúc xắc càng to thì **bàn cờ càng phải dài**,
  mà mỗi ô là nội dung phải nghĩ ra. Chọn lại d6 là phương án **miễn phí** (dùng lại nguyên
  model + hoạt cảnh của phòng chờ); mỗi loại mặt mới cần model riêng và hoạt cảnh riêng.

### Thứ tự làm phòng chờ

| | |
|---|---|
| **Làm trước** | Ô sẵn sàng · bàn cờ · bóng rổ · ống tụt |
| **Cụm cờ bạc** *(làm 1 là gần như có 4)* | Xúc xắc → cánh cụt → đua vịt → bàn bài |
| **Lẻ, làm sau** | Phi tiêu · xích đu |

Bốn món đầu phủ hết **mọi kiểu đồng bộ** cần dùng: trạng thái · sự kiện · vật lý ·
tự-áp-lên-mình. Xong bốn cái đó thì phần còn lại là điền nội dung vào khuôn có sẵn.

### Nguyên tắc: thứ đẩy người chơi thì rẻ

> **Thứ gì đẩy người chơi đi đều rẻ, miễn là chính người chơi đó tự áp lên mình.**

Vì mỗi người sở hữu thân mình. Nên xích đu, bạt nhún, bệ phóng, băng chuyền, ống tụt —
cùng một khuôn, đều rẻ. (Cùng nguyên tắc với knockback ở mục 2.)

**Xích đu phải là animation, không phải khớp vật lý.** Xích đu vật lý thật thì nhân vật ngồi
lên phải bám theo vật đang chuyển động, mà vị trí nhân vật lại đang đồng bộ theo toạ độ toàn
cục — hai cái đánh nhau. Nếu chỉ là dao động hình sin tính từ thời gian mạng thì mọi máy tự
tính ra cùng một góc, không cần đồng bộ gì. Nhảy ra giữa lúc đu vẫn bay được, vì bạn tự áp
vận tốc lên chính mình.

### Bóng rổ

**Đúng MỘT quả.** Đây là "một món vật lý" duy nhất của phòng — vật lý thật, lăn thật, ai chạm
cuối thì tạm sở hữu. Đắt nhất phòng nhưng đáng: bốn người tranh một quả bóng và ai cũng thấy
giống nhau là **bằng chứng netcode chạy đúng**, quay demo ăn ngay.

Rổ: một vùng cảm biến dưới vành, master đếm điểm.

### Camera — ĐÃ CHỐT

| Nơi | Góc máy |
|---|---|
| **Phòng chờ** | **Góc nhìn thứ nhất** |
| **Bàn cờ (party)** | **Góc thứ ba, từ trên xuống** |
| **Minigame** | **Tuỳ từng minigame** — quyết sau, làm cuối |

**Vì sao phòng chờ dùng góc một:**
1. Phòng toàn đồ nhỏ — nhặt con tốt ở ô E4, đặt lá bài, ném phi tiêu trúng vòng 20.
   Góc một làm mấy việc đó tự nhiên; góc ba thì nhắm qua vai, luôn lệch.
2. **Đây là trường hợp xấu nhất của camera góc ba**: phòng nhỏ, chật, đầy máy móc.
   `SpringArm3D` sẽ đâm vào tường và đồ đạc liên tục, thụt vào bung ra, giật cả buổi.
   Góc một xoá sạch vấn đề — không có cần, không có va chạm, không có gì để giật.

**Ngoại lệ duy nhất: xích đu → góc ba.** Vì đu qua đu lại ở góc một thì **say**.
Tụt ống **vẫn giữ góc một**.

**Chuyển camera phải mượt ~0.3 s, không cắt cụp.** Camera nhảy phắt = cảm giác game lỗi.

### Chọn màu / đổi tên — kiểu R.E.P.O.

**Không đổi camera.** Thay vào đó cho người chơi thấy một **nhân vật giả lập**: `SubViewport`
với camera riêng chĩa vào bản sao model, xuất ra texture, dán lên panel UI (hoặc chiếu lên
máy chiếu trong phòng).

**Bẫy:** SubViewport mặc định vẽ lại **mỗi khung hình** kể cả khi panel đóng. Đặt nó chỉ vẽ
khi hiện, hoặc chỉ vẽ lại lúc có thay đổi.

**Panel trước, máy chiếu sau.** Panel tiện hơn (không phải đi đâu, người vào muộn kịp đổi màu
trước lúc phóng). Máy chiếu hợp luật phòng chờ hơn (cả phòng thấy bạn đang loay hoay chọn màu)
— để sau như món trang trí, không chặn gì.

**Tên nhập ở menu chính, trước khi vào phòng** — nhưng **mang theo bằng property replicate trên
object player** (`Player:player_name`), KHÔNG gửi qua `user_id` của `connect_to_photon()`.
Đã kiểm chứng: `user_id` nhìn từ máy khác về rỗng (xem mục 1f).

### Minigame — ghi để sau

Camera **tuỳ từng minigame**. Ví dụ đã nêu:
- Không có camera 3D: bắn tank 2D
- Rhythm game: các nút qua lại lên xuống
- Sàn đấu nhỏ: camera cứng một góc trên cao, chung cho mọi người
- Mô phỏng bắn súng: góc thứ ba sát nhân vật

**Chi phí — hai loại rất khác nhau:**

| Loại | Giá |
|---|---|
| Sàn đấu góc cao, bắn súng góc ba | Dùng chung nhân vật + điều khiển + đồng bộ, **chỉ đổi camera** → gần như miễn phí |
| Tank 2D, rhythm game | Không có nhân vật, không dùng lại gì → **một game nhỏ riêng nằm trong game** |

Không phải lý do để bỏ, chúng vui thật. Chỉ là **một cái tank 2D tốn bằng ba minigame dùng
chung nhân vật** — biết trước khi chọn danh sách.

*(Lưu ý: nguyên tắc "một nhân vật, ba nơi" ở mục 1 vẫn đúng cho minigame dạng nhân vật.
Minigame trừu tượng bước ra ngoài nguyên tắc đó — và đó chính là chỗ chi phí đội lên.)*

### Tank: bản đồ DỰNG TAY, và mọi thứ là node

Bản đầu vẽ cả đấu trường bằng `draw_rect` trong `tank_battle.gd`, tường rải ngẫu nhiên theo
`rng.randf() < 0.42`. Đã bỏ cả hai:

- **Node, không vẽ bằng code.** 136 ô tường là instance `o_tuong.tscn` nằm trong
  `ban_do_tank.tscn`, xe là `xe_tang.tscn`, đạn là `dan.tscn` — kéo được trong editor, có
  sprite thì thay một chỗ là cả bản đồ đổi theo. `tank_battle.gd` 347 → 222 dòng, chỉ còn đọc
  phím + gói mạng + phán trúng đạn. Đúng mẫu `o_ban.tscn` / `ban_party.tscn` của bàn party.
- **Bản đồ cố định, đối xứng bốn phía.** Nhiễu ngẫu nhiên thì ván nào cũng có góc hở toang và
  góc nhốt người trong hốc. Đối xứng thì không chỗ nào lợi hơn chỗ nào, và chơi vài ván là
  thuộc đường — thuộc đường mới có chỗ cho kỹ năng.
- **10 chỗ sinh đặt tay** bằng `Marker2D`, xếp sao cho hai chỗ liên tiếp luôn ở xa nhau; hai
  chỗ giữa bàn có thép chắn nên không bắn thẳng vào nhau được ở giây đầu.

Hạt giống của master giờ chỉ còn xoay thứ tự chỗ sinh — bản đồ không cần nó nữa.

> Lối chạy quanh rìa phải chặn vài ô, không để thẳng suốt: một hành lang 25 ô thông thẳng là
> một trường bắn tỉa, mà luật ở đây là **một phát chết**.

### Số người chơi — ĐÃ CHỐT

**Tối đa 8–10.** Nguyên tắc: **dựng phòng và ô sẵn sàng đủ chỗ cho 10, cân mọi thứ khác theo 4.**
Phòng không vỡ khi đông, mà không tốn công cho tình huống chưa chắc xảy ra.

Bốn chỗ bị ảnh hưởng, không đều nhau:
- Kích thước phòng + ô sẵn sàng: chỉ là nhân lên, dễ
- **Màu phân biệt**: 4 màu tương phản mạnh thì dễ; từ 6 trở lên phải thêm dấu hiệu khác
  (hoa văn, mũ) vì màu không còn phân biệt được từ xa và khi mù màu
- **Bàn cờ theo lượt là chỗ đau nhất**: 10 người thì 9 người ngồi chờ. Lunars sinh ra hẳn chế
  độ đi lượt đồng thời (Blitz) chỉ để chữa đúng chuyện này → khi thiết kế bàn cờ phải tính
- **Thực tế test**: mọi người bận, sẽ chỉ test được 2–3 người → phần dành cho 10 người gần như
  không bao giờ được chạy thử
- Băng thông: không lo, Photon gánh 10 người dễ

**Nút ép bắt đầu của chủ phòng chuyển từ "nên có" sang BẮT BUỘC** — 10 người mà một người AFK
là cả phòng kẹt.

### Không dựng con tàu — ĐÃ CHỐT

**Chỉ cần một phòng chờ, rồi bọc nó bằng khung cảnh vũ trụ.** Không mô hình vỏ tàu, không hình
dáng phi thuyền, không buồng lái theo nghĩa đen.

Cái này vừa rẻ hơn nhiều vừa **đẹp hơn**: thay vì nhìn vũ trụ qua một ô kính lái, cả sàn nổi
giữa không gian và thấy sao ở mọi hướng. Chi phí = một skybox + một cái vòm + một hành tinh
treo trên trời.

Hệ quả: **"kính lái" biến mất.** Điểm đến giờ là hành tinh nhìn thấy được trên bầu trời —
đúng thứ nó nên là, và dựng sẵn ý tưởng bàn cờ = bản đồ ngân hà.

Hình dạng phòng giờ được tự do theo công năng, không phải theo hình con tàu.

### Vào phòng — không có mã

Bỏ mã phòng. Nhưng **giữ hai nút** — đề bài yêu cầu rõ ở mục 5.2 và 8, tiêu chí A (15%) chấm
đúng chỗ đó. Cái cần bỏ là việc gõ mã, không phải hai cái nút.

```
[ TẠO PHÒNG ]  ->  tạo xong vào luôn
[ VÀO PHÒNG ]  ->  danh sách phòng đang mở, bấm một cái là vào
                     Phòng của Khang   2/10
                     Phòng của Nam     1/10
```

Tên phòng lấy luôn tên người tạo — không đặt tên, không phải nhớ.
Photon có sẵn `get_room_list()` và signal `room_list_updated`.

*(Nếu bỏ hẳn cả danh sách mà chỉ "vào nhanh" thì hai người cùng bấm tạo phòng sẽ nằm ở hai
phòng khác nhau mà không hiểu vì sao.)*

### Bố cục phòng chờ

**Năm khu, ô sẵn sàng ở chính giữa:**

| Khu | Nội dung |
|---|---|
| **Giữa** | Ô sẵn sàng — bệ nâng cao |
| Góc 1 | Bàn cờ (vua/tướng + caro) |
| Góc 2 | **Khu silver flag** — craps · đua vịt · cánh cụt · bàn bài |
| Góc 3 | Xích đu + cầu tuột (bệ cao, làm gọn) |
| Khu rộng | Sân bóng rổ — một rổ |
| Rìa | Phi tiêu · chỗ cấp xu · chọn màu · cửa vào/spawn |

**Ô sẵn sàng ở chính giữa** vì cả luồng chơi phụ thuộc vào chuyện người ta *để ý thấy*
"8/10 người đã đứng lên rồi". Nhét vào góc là sẽ có người bỏ lỡ.

**Phải là bệ NÂNG CAO, không phải ô vẽ trên sàn** — phòng đông, ai đi ngang cũng vô tình bật
sẵn sàng. Bước lên một bậc mới thành hành động có chủ ý.

**Đua vịt là một cabin nhỏ có đường đua riêng**, không phải vịt chạy vòng quanh phòng. Mỗi
người chơi có một nút cược mang tên mình, sáng đèn — "cược bằng khán giả" được làm thành vật
thể, ai đặt con nào cả phòng nhìn thấy.

**Ống tụt/cầu tuột là đường xuống, cầu thang là đường lên.**

### Va chạm, rìa sàn, spawn — ĐÃ CHỐT

- **Không cho đẩy nhau. Không rơi khỏi sàn.**
- **Người chơi KHÔNG va chạm với nhau** trong phòng chờ — đi xuyên qua nhau.
  Giết một loạt vấn đề cùng lúc: không ai chặn lối đi, không ai đứng lì trên bệ sẵn sàng cản
  người khác, không ai kẹt trong chỗ spawn, và 10 người trong phòng 26 m không xô nhau ngoài ý
  muốn. VRChat và sảnh Rec Room đều làm vậy. Giá phải trả: nhìn hơi kỳ khi hai người chồng nhau.
- **Khu spawn = khu ngắm cảnh** (gộp làm một). Bạn hiện ra, thứ đầu tiên nhìn thấy là hành tinh
  điểm đến, rồi mới quay người đi vào phòng. Ấn tượng đầu rơi đúng chỗ đẹp nhất, và bớt một khu.
- Nhiều người vào gần như cùng lúc → cho mỗi người xuất hiện lệch vị trí một chút, hoặc giãn
  0.3 s một người. Không cần hàng đợi.
- **Sân bóng rổ: nửa sân, một rổ.**

### Khu ngắm cảnh — vì sao cần một khu KHÔNG có gì

Một căn phòng mà mỗi mét vuông đều đòi hỏi bạn làm gì đó thì rất mệt. Khu này là:
- Chỗ đứng lì khi đã sẵn sàng xong
- Chỗ cho mắt nghỉ — nhờ đó mấy khu bận rộn mới *đọc ra* là bận rộn
- Chỗ quay video demo đẹp nhất
- Khu **rẻ nhất phòng**: không tương tác thì không có gì phải đồng bộ

Cho nó nhìn thẳng ra hành tinh điểm đến → làm luôn việc thứ hai: nói cho người chơi biết sắp đi đâu.

### File config ngoài — ĐÃ CHỐT

Một file INI đặt **cạnh file .exe** (đọc từ `OS.get_executable_path().get_base_dir()`, KHÔNG phải
`res://`) nên nằm ngoài `.pck` và sửa được sau khi build. Godot có sẵn lớp `ConfigFile` đọc INI —
không cần thư viện, không tự parse.

```ini
[photon]
app_id = ""
region = "asia"
app_version = "1.0"

[music]
folder = "C:/Nhac/PartyBash"
```

Ba dòng `[photon]` ánh xạ đúng ba tham số SDK vốn đã phơi ra:
`set_app_id(app_id)` và `connect_to_photon(user_id, region, app_version)`.

**Giải ba vấn đề cụ thể:**
1. App ID đang bị nướng cứng trong `project.godot` → nằm trong `.pck` → đổi là phải export lại
   toàn bộ. Có config thì sửa một dòng text.
2. Quota 20 CCU: mọi người chơi bản build đều đi qua đúng một app Photon. Có config thì ai muốn
   chạy nhóm riêng thì cắm App ID của họ.
3. Người chấm không phụ thuộc tài khoản Photon của mình còn sống hay không.

**Đây là extension ăn điểm thật** — đề mục 10 chấm cao hơn cho extension lập trình so với
extension hình ảnh.

**Bắt buộc validate.** Config là file người ngoài sửa: thư mục không tồn tại, App ID gõ sai,
file nhạc hỏng. Không kiểm thì một dấu chấm thừa làm game crash lúc khởi động và không ai hiểu
vì sao. Đây là ngoại lệ của việc làm tối giản — đọc, kiểm, thiếu thì rơi về mặc định và ghi
cảnh báo.

### Nhạc

**Godot 4.7.1 KHÔNG đọc được FLAC.** Đã chạy thử xác nhận: chỉ có `AudioStreamWAV`,
`AudioStreamMP3`, `AudioStreamOggVorbis`. Không có `AudioStreamFLAC`.

Không mất mát gì: FLAC là lossless để nghe nghiêm túc, làm nhạc nền game thì phí — nặng gấp 5
lần mà phát qua loa lúc bốn người đang la hét. OGG 160 kbps không phân biệt được trong hoàn cảnh đó.

```bash
for f in *.flac; do ffmpeg -i "$f" -c:a libvorbis -q:a 5 "${f%.flac}.ogg"; done
```

`AudioStreamOggVorbis.load_from_file()` **có sẵn** — nạp ogg từ ổ đĩa lúc chạy, không cần import
vào project. Đúng thứ cần cho việc quét thư mục. Quét chỉ nhận `.ogg`/`.mp3`; gặp `.flac` thì ghi
cảnh báo rồi bỏ qua, không crash.

**Máy đổi nhạc** trong phòng: ai cũng đổi bài được, cả phòng nghe cùng lúc — một số nguyên được
đồng bộ, rẻ ngang một cái công tắc, và là biểu hiện thuần khiết nhất của luật phòng chờ.

**Config giải luôn vấn đề bản quyền:** nhạc cá nhân là nhạc có bản quyền → đưa vào project nộp
bài thì vướng mục 18, quay demo lên YouTube là bị gắn cờ. Trỏ ra thư mục ngoài thì **bản build
không chứa file nhạc bản quyền nào**. Ship kèm vài bài CC0 làm mặc định. Đáng viết vào báo cáo —
đó là quyết định thiết kế có lý do.

Nhạc minigame và bàn cờ: dùng lại đúng hệ thống này, chỉ khác danh sách. Chưa cần tính.

### Năm món đề xuất — ĐÃ CHỐT

| Món | Quyết | Lý do |
|---|---|---|
| Bảng hướng dẫn điều khiển | **Lấy** | Người mới không biết bấm gì; người xem video demo cũng đọc được. Gần như miễn phí |
| Ghế ngồi khu ngắm cảnh | **Lấy** | Ngồi là một trạng thái được đồng bộ, rẻ như bệ sẵn sàng. Làm khu ngắm cảnh thật sự dùng được |
| Robot nhỏ đi lang thang | **Lấy** | Sẽ test với 2 người suốt nhiều tuần, mà phòng 26 m với 2 người là phòng bỏ hoang. Có thứ nhúc nhích thì đỡ nản. Master sở hữu, đi theo đường định sẵn |
| Máy bán mũ ngẫu nhiên | **Hoãn** | Đáng làm — cho xu một mục đích, và mũ là dấu hiệu phân biệt thứ hai khi 10 người thì màu không đủ. Nhưng cần model mũ + gắn vào xương đầu + đồng bộ ai đội gì |
| Bảng vẽ chung | **Bỏ** | Vui nhất nhưng đắt nhất, và là món duy nhất có thể nuốt một ngày. Người vào sau phải thấy bức tranh đang có → phải giữ trạng thái cả bức, và nó phình dần |

### Bản đồ chốt của phòng chờ

```
                        Máy đổi nhạc
        ┌───────────────────────────────────────────┐
        │   Bàn cờ                Khu silver flag   │
        │   vua·tướng·caro        craps 2d6·đua vịt │
   Phi  │                         cánh cụt·bàn bài  │  Cấp
   tiêu │                                           │  xu
        │            ╔═══════════════╗              │
        │            ║  Ô SẴN SÀNG   ║              │
        │  Xích đu   ║  bệ nâng 7 m  ║  Sân bóng rổ │
        │  bệ cao +  ╚═══════════════╝  nửa sân     │
        │  cầu tuột                     một rổ      │
   Chọn │                                           │  Hướng
   màu  │        Khu ngắm cảnh + spawn              │  dẫn
        │        ghế ngồi · không tương tác         │
        └───────────────────┬───────────────────────┘
              sàn tròn 26 m │ nhìn ra
                            ▼
                    hành tinh điểm đến
```

Robot nhỏ không có chỗ cố định — nó đi lang thang khắp sàn.

### Phòng chờ — còn để mở

- Quân caro lấy từ đâu (đề xuất: bát đen + bát trắng) — đề xuất: một bát quân đen, một bát quân trắng, bốc ra đặt
  (cùng cơ chế với cờ vua, không phải viết riêng). **Chưa xác nhận.**
- Trong phòng có những gì để nghịch
- Bố cục phòng, vị trí ô sẵn sàng
- Camera trong phòng chờ: bám lưng hay cố định
- Đổi màu / tên nhân vật ở đâu
- Mã phòng hiển thị ở đâu

---

## 1b. (CŨ — phương án marathon, giữ để tham khảo)

Marathon minigame kiểu **Mini-Game Mode của Lunars** / **Pummel Party** bỏ bàn cờ.

```
Main Menu → Phòng chờ (3D) → Vòng 1 → Bảng điểm
                           → Vòng 2 → Bảng điểm
                           → Vòng 3 (x2 điểm) → Podium → về Phòng chờ
```

2–4 người. 3 minigame dùng chung 1 player controller, khác nhau ~40 dòng luật:

| Minigame | Luật | Thắng bằng |
|---|---|---|
| **Sumo Shove** | Sàn tròn co dần, dash để hất nhau xuống | Trụ cuối cùng |
| **Coin Grab** | Coin spawn khắp map, 45 giây | Nhặt nhiều nhất |
| **Bomb Tag** | 1 người ôm bom, chạm để chuyền, hết giờ nổ | Không cầm bom lúc nổ |

**Vì sao bỏ bàn cờ ở v1:** bàn cờ + xúc xắc + ô sự kiện là phần tốn code nhất mà **không ăn thêm điểm nào** trong rubric. Để dành Phase 11 (optional).

---

## 2. Kiến trúc mạng — Shared Authority

```
              ┌─────────────────────┐
              │    Photon Cloud     │   CHỈ relay gói tin
              │  room = mã 4 ký tự  │   KHÔNG chạy game logic
              └──┬───────┬───────┬──┘
                 │       │       │
        ┌────────┴─┐ ┌───┴────┐ ┌┴─────────┐
        │ Client A │ │Client B│ │ Client C │
        │ (Master) │ │        │ │          │
        └──────────┘ └────────┘ └──────────┘
```

| Object | Chủ sở hữu | owner_mode | Dữ liệu sync |
|---|---|---|---|
| Player_A | Client A | `PLAYER_ATTACHED` | position, rotation.y, velocity, anim_state, name, color, is_ready |
| Player_B | Client B | `PLAYER_ATTACHED` | (như trên) |
| MatchState | Master client | `MASTER_CLIENT` | phase, round, minigame_id, timer, scores{}, winner |
| Coin / Bomb / sàn co | Master client | `MASTER_CLIENT` | position, active, holder_id, radius |

**Local, không bao giờ sync:** input, camera, HUD, particle, âm thanh, screen shake.

Đây đúng là mô hình **R.E.P.O.** (Photon PUN 2) và các co-op host-based khác: mỗi người sở hữu nhân vật mình, một người sở hữu thế giới. Chi phí server = 0.

### Chống tranh chấp quyền sở hữu

A đấm B → A **không** được đẩy B (A không sở hữu B). Luồng đúng:

```
A: phát hiện hitbox chạm B
A: Fusion.rpc_to(RpcTarget.OWNER, b.take_hit, force_vector)
B: nhận RPC, TỰ áp knockback lên chính mình
B: replicator của B đẩy vị trí mới ra cho mọi người
```

Một chiều, không ai ghi đè ai, không giật. Đây là phần viết vào **mục 13E** của báo cáo.

### Master client rời phòng

Photon **tự bầu master mới**. Bắt signal `master_client_changed` → master mới tiếp quản `MatchState`. Nếu đang giữa vòng đấu: kết thúc vòng đó, về bảng điểm. Đây là extension ăn điểm mục F (Technical Understanding).

---

## 3. Chuẩn bị asset

### 3.1 Tải về (tất cả CC0)

| Pack | Link | Dùng cho | Phase cần |
|---|---|---|---|
| **Prototype Textures** | `kenney.nl/assets/prototype-textures` | Greybox toàn bộ | 1 |
| **Mini Characters** | `kenney.nl/assets/mini-characters` | Nhân vật (25 file, có anim) | 1 |
| **Mini Arena** | `kenney.nl/assets/mini-arena` | Map Sumo + phòng chờ | 9 |
| **Mini Forest** | `kenney.nl/assets/mini-forest` | Map Coin Grab | 9 |
| **Mini Dungeon** | `kenney.nl/assets/mini-dungeon` | Map Bomb Tag | 9 |
| Kenney Audio (Impact / UI / Interface) | `kenney.nl/assets` → Audio | SFX | 9 |
| *(dự phòng)* Blocky Characters | `kenney.nl/assets/blocky-characters` | Nếu Mini Characters khó đổi màu | — |
| *(dự phòng)* Universal Animation Library | `quaternius.com` | Nếu thiếu animation | — |

4 pack **Mini** cùng một bộ → 3 map khác nhau nhưng nhìn như **một game**, không chắp vá. Đó là lý do chọn nó thay vì gom lẻ từ Sketchfab.

### 3.2 Chốt scale — làm 1 lần, mọi thứ bám theo

| Thông số | Giá trị |
|---|---|
| Chiều cao nhân vật | **1.8 m** |
| Collision | Capsule radius 0.4, height 1.8 |
| Tốc độ chạy | 6 m/s |
| Dash | 14 m/s trong 0.25 s, cooldown 1.5 s |
| Chiều cao nhảy | 1.2 m |
| Gravity | 20 m/s² (nặng hơn thật, cảm giác party game đã tay hơn) |

Kit Mini của Kenney vẽ ở scale nhỏ → **import xong phải đo rồi scale cho đúng 1.8 m**. Làm sai bước này thì mọi con số vật lý sau đều sai.

### 3.3 Pipeline import model

1. Kéo `.glb` vào `res://asset/`
2. Double-click → **Advanced Import Settings**
3. Tab *Materials*: nếu muốn đổi màu từng người → **Extract materials** ra file `.tres` riêng
4. Tab *Animations*: đặt lại tên clip cho khớp: `idle`, `run`, `jump`, `fall`, `hit`, `win`, `emote_dance`
5. Save thành `player_model.tscn`, chỉnh scale trong đó, **không** chỉnh trong `player.tscn`

### 3.4 Đổi màu theo người chơi

Kenney dùng 1 texture atlas chung. **Không** dùng `material_override` trơn (mất texture). Cách đúng:

```gdscript
var mat: StandardMaterial3D = mesh.get_active_material(0).duplicate()
mat.albedo_color = player_color      # giữ nguyên albedo_texture
mesh.set_surface_override_material(0, mat)
```

4 màu: đỏ `#E5484D`, xanh dương `#3E63DD`, vàng `#F5D90A`, xanh lá `#46A758`. Phải phân biệt được **từ xa và khi mù màu** — đừng dùng 2 màu cùng độ sáng.

### 3.5 Model thực sự cần — chỉ 3 nhóm

**1. Nhân vật: đúng 1 model.** Không cần 4 model khác nhau. Phân biệt bằng màu + tên nổi trên đầu. Animation tối thiểu: `idle`, `run`, `jump`, `fall`, `hit`, `win`.

**2. Prop tương tác: làm bằng primitive, không tải model.**

| Prop | Cách làm |
|---|---|
| Coin | `CylinderMesh` + material vàng emissive + tự xoay 90°/s |
| Bom | `SphereMesh` đen + `OmniLight3D` đỏ nhấp nháy nhanh dần |
| Hộp powerup | `BoxMesh` + dấu `?` + bay lên xuống |
| Ready pad | `CylinderMesh` mỏng + emissive, xám → xanh khi ready |

Lý do: prop phải **đọc được ở khoảng cách xa và trong video demo nén**. Primitive sáng màu ăn đứt model chi tiết.

**3. Trang trí map: lấy nguyên kit, không sửa gì.**

### 3.6 Cấu trúc `player.tscn`

```
Player (CharacterBody3D)          ← player.gd
├── CollisionShape3D (capsule)
├── Model (player_model.tscn)
│   └── AnimationPlayer
├── NameTag (Label3D, billboard)
├── DashHitbox (Area3D, chỉ bật khi dash)
├── CameraRig (SpringArm3D)       ← queue_free() nếu KHÔNG phải local
│   └── Camera3D
└── FusionSharedReplicator        ← owner_mode = PLAYER_ATTACHED
```

Quy tắc vàng: **`CameraRig` và input chỉ tồn tại trên máy sở hữu.** Không phải `set_process(false)` — mà `queue_free()` hẳn. Đơn giản hơn và không bao giờ có 2 camera cùng active.

---

## 4. Cấu trúc thư mục

```
PartyBash/
├── addons/fusion/          ← giải nén từ .7z (xoá thư mục cs/, ta dùng GDScript)
├── asset/
│   ├── kenney_mini_characters/
│   ├── kenney_mini_arena/
│   ├── kenney_prototype/
│   └── audio/
├── net/
│   ├── net_manager.gd      ← autoload: connect, host, join, room code
│   └── match_state.gd      ← MASTER_CLIENT: phase, round, scores
├── player/
│   ├── player.tscn / .gd
│   └── player_model.tscn
├── ui/
│   ├── main_menu.tscn
│   ├── hud.tscn
│   ├── scoreboard.tscn
│   └── emote_wheel.tscn
├── lobby/
│   └── lobby.tscn / .gd
├── minigames/
│   ├── minigame_base.gd    ← lớp cha: start(), tick(), end() → trả về điểm
│   ├── sumo/
│   ├── coingrab/
│   └── bombtag/
├── ROADMAP.md
└── CREDITS.md              ← tạo từ Phase 0, mục 18 bắt buộc
```

---

## 5. Roadmap theo phase

> **Quy tắc xuyên suốt: greybox trước, model sau.** Netcode chạy đúng trên hộp xám rồi mới thay asset ở Phase 9. Rubric ghi thẳng: *"visually simple that works > impressive but broken"*.

---

### Phase 0 — Spike kỹ thuật ⚠️ CHẶN MỌI THỨ
**½ ngày · không viết một dòng gameplay nào trước khi phase này xanh**

| | |
|---|---|
| **Việc** | Giải nén addon vào project trống → bật GDExtension → chạy Godot 4.7.1. Tạo tài khoản Photon, tạo app loại **Fusion**, lấy App ID. Scene test: 1 nút Connect + 1 Label. `Fusion.connect_to_photon()` → `join_or_create_room("TEST")` → in `player_joined` |
| **Asset** | Không |
| **Xong khi** | 2 instance chạy song song, mỗi cái in ra `player joined: <id>` của cái kia |
| **Rủi ro** | Extension là Preview build cho Godot **4.6**, máy đang chạy **4.7.1**. `compatibility_minimum = 4.6` nên về lý thuyết OK, nhưng phải thử |
| **Fallback** | Crash → cài thêm Godot 4.6 song song. Vẫn hỏng → ENet built-in (chỉ LAN, mất phần online) |
| **Cần bạn** | **App ID** — miễn phí 20 CCU tại `dashboard.photonengine.com`. Không có thì không kết nối được |

---

### Phase 1 — Bộ khung + player local
**1 ngày**

| | |
|---|---|
| **Việc** | Dựng cấu trúc thư mục. Import Mini Characters → đo → scale về 1.8 m → `player_model.tscn`. `CharacterBody3D`: chạy, nhảy, dash, gravity. `SpringArm3D` camera bám sau lưng, xoay bằng chuột. AnimationTree chuyển idle/run/jump/fall. Greybox arena: `CSGCylinder3D` R=12 + prototype texture |
| **Asset** | Mini Characters, Prototype Textures |
| **Xong khi** | Chạy nhảy dash mượt một mình, animation không giật, camera không xuyên tường |
| **Rubric** | 5.1 (môi trường 3D) |

---

### Phase 2 — Menu + kết nối
**1.5 ngày**

| | |
|---|---|
| **Việc** | `net_manager.gd` autoload. Main menu: ô nhập tên → nút **HOST** (sinh mã 4 ký tự A–Z, `create_room`) → nút **JOIN** (nhập mã, `join_room`) + danh sách phòng từ `get_room_list()`. Hiển thị trạng thái kết nối + thông báo lỗi. Bắt `room_joined`, `player_joined`, `player_left`, `connection_failed` |
| **Asset** | Không |
| **Xong khi** | 2 instance vào cùng phòng, mỗi bên in ra danh sách người chơi giống nhau. Nhập sai mã → báo lỗi rõ ràng, không crash |
| **Rubric** | **A — Multiplayer Connection 15%**, 5.2, 8 |

---

### Phase 3 — Spawn + ownership
**1 ngày**

| | |
|---|---|
| **Việc** | `FusionSpawner` trong lobby scene, `spawnable_scenes = [player.tscn]`. Callback `pre_spawn` set tên + màu + vị trí spawn theo index. `owner_mode = PLAYER_ATTACHED`. Trong `player.gd::_ready()`: `if not %Replicator.has_authority(): $CameraRig.queue_free(); set_process_input(false)`. Player rời phòng → object tự xoá |
| **Asset** | Không |
| **Xong khi** | ① Phím của máy A **không** điều khiển nhân vật B. ② Máy A và B mỗi máy có đúng 1 camera. ③ B tắt game → nhân vật B biến mất khỏi màn hình A trong ~1s |
| **Rubric** | **B — Player Spawning & Ownership 15%**, 5.3, 5.5, 5.6 |

---

### Phase 4 — Sync chuyển động
**1 ngày**

| | |
|---|---|
| **Việc** | `replication_config`: `position` (lerp), `rotation.y` (angle), `velocity`, `anim_state` (int, none). Bật `root_interpolation_mode = EXPONENTIAL`. Chỉnh `update_interval` (bắt đầu 20 Hz). Debug overlay góc màn hình: ping (`Fusion.get_rtt()`), player id, có/không authority |
| **Asset** | Không |
| **Xong khi** | Nhìn nhau chạy **mượt, không giật, không teleport**. Test cả khi ping cao (bật Network Profiler / chạy 1 máy ở mạng khác) |
| **Rubric** | **C — Movement Synchronisation 20%**, 5.4 |
| **Bẫy** | Sync `position` local hay global? Player là con trực tiếp của scene root → dùng global, bật `root_global_coordinates` |

---

### Phase 5 — Phòng chờ đầy đủ
**1.5 ngày** — *xem thiết kế chi tiết ở mục 6*

| | |
|---|---|
| **Việc** | Lobby là scene 3D đi lại được. **Ready pad**: `Area3D` phát sáng, đứng lên = sẵn sàng (sync qua `is_ready` của player). **Color pad**: đi lên để đổi màu. `MatchState` node (`MASTER_CLIENT`): đếm ready, đếm ngược 5s khi đủ. Bảng người chơi ở góc: màu · tên · ✓. Mã phòng hiển thị to. **Emote wheel** phím E → `Fusion.rpc()` phát animation cho mọi người |
| **Asset** | Greybox + ready pad primitive |
| **Xong khi** | 2 người đứng lên pad → đếm ngược đồng bộ trên cả 2 máy → cùng lúc chuyển sang minigame. Bước xuống pad giữa chừng → huỷ đếm ngược |
| **Rubric** | 5.2, 8, extension (ready system, lobby, emote) |

---

### Phase 6 — Sumo Shove + shared state
**2 ngày**

| | |
|---|---|
| **Việc** | Sàn co: master client giảm `radius` 12→4 trong 60s, replicate. Dash bật `DashHitbox` → chạm ai thì `rpc_to(OWNER, take_hit, force)` → nạn nhân tự knockback. `KillZone` `Area3D` ở y = −10 → bị loại → camera chuyển sang **spectator** bám người còn sống. Người trụ cuối +3 điểm, nhì +2, ba +1. `MatchState.scores` là nguồn sự thật duy nhất. Screen shake + hitstop 80ms khi trúng |
| **Asset** | Greybox |
| **Xong khi** | ① A hất B → **cả hai máy** đều thấy B bay cùng hướng. ② Bảng điểm giống hệt nhau trên mọi máy. ③ Người bị loại vẫn xem được, không nhìn màn hình đen |
| **Rubric** | **D — Multiplayer Gameplay 20%**, mục 6, mục 7 |

---

### Phase 7 — Vòng lặp trận đấu
**1.5 ngày**

| | |
|---|---|
| **Việc** | State machine trong `MatchState`: `LOBBY → INTRO → PLAYING → RESULTS → (lặp 3 vòng) → PODIUM → LOBBY`. Card giới thiệu vòng đấu + đếm ngược 3-2-1. **Roulette** quay chọn minigame (master quyết định trước rồi RPC kết quả — không random độc lập từng máy). Bảng điểm có thanh chạy. Vòng cuối **x2 điểm**. Xử lý `master_client_changed` giữa vòng |
| **Asset** | Greybox |
| **Xong khi** | Chơi trọn 1 trận 3 vòng → ra winner → về lobby chơi tiếp được **mà không cần restart game**. Master thoát giữa chừng → trận vẫn kết thúc đàng hoàng |
| **Rubric** | mục 7, mục 17 (match states), extension |

---

### Phase 8 — Minigame 2 + 3
**2 ngày**

| | |
|---|---|
| **Việc** | **Coin Grab**: master spawn coin ở 10–12 điểm cố định (random chọn), người chơi chạm → `rpc_to(MASTER, request_pickup, coin_id)` → master xác nhận, despawn, cộng điểm → chống 2 người nhặt cùng 1 coin. **Bomb Tag**: `bomb_holder_id` trong `MatchState`, chạm để chuyền (cooldown 1s chống chuyền qua lại), nổ theo `Fusion.get_network_time()` để mọi máy nổ cùng lúc |
| **Asset** | Greybox + coin/bomb primitive |
| **Xong khi** | ① Coin biến mất **đồng thời** trên mọi máy, không ai nhặt trùng. ② Bom nổ cùng một khoảnh khắc trên mọi máy |
| **Rubric** | extension (thêm 2 minigame) |

---

### Phase 9 — Thay asset + polish
**2 ngày**

| | |
|---|---|
| **Việc** | Thay greybox bằng Mini Arena / Forest / Dungeon. Name tag + màu + mũ ngẫu nhiên. SFX Kenney (dash, trúng đòn, nhặt coin, bom nổ, đếm ngược, thắng) + nhạc nền. HUD: điểm, timer, vòng hiện tại, số người, ping, trạng thái kết nối. Kill feed. Chaos event. `DirectionalLight3D` + `WorldEnvironment` (sky procedural + SSAO nhẹ) |
| **Asset** | Toàn bộ pack Mini + audio |
| **Xong khi** | Ghi hình 60 giây bất kỳ mà không thấy hộp xám nào |
| **Rubric** | **E — Extension 15%**, **G — Quality 5%**, 5.1 |

---

### Phase 10 — Test + nộp bài
**1.5 ngày** — *checklist ở mục 9 và 10*

| | |
|---|---|
| **Việc** | Chạy hết test matrix. Export build Windows. Test **2 máy thật** qua internet. Quay video demo 3–5 phút. Viết report 1–2 trang + vẽ sơ đồ kiến trúc. Hoàn thiện `CREDITS.md` |
| **Xong khi** | Người lạ tải build về chơi được mà không cần hỏi gì |
| **Rubric** | **F 10%**, **G 5%**, mục 13, 14 |

---

### Phase 11 — Bàn cờ *(optional, chỉ khi còn thời gian)*
**3 ngày**

Ô cờ vòng tròn 20 ô, xúc xắc, di chuyển theo lượt, ô sự kiện (+coin / −coin / đổi chỗ / dịch chuyển). Minigame chạy sau mỗi lượt. Đây mới là Pummel Party đầy đủ. **Không đụng vào cho tới khi Phase 10 xong hết.**

---

### Tổng: ~15 ngày công (chưa tính Phase 11)

---

## 6. Phòng chờ — thiết kế chi tiết

Phòng chờ không phải màn hình chờ. Nó là **màn tutorial ngầm** và là nơi test sync trước khi vào minigame.

```
        ┌──────────── SÂN PHÒNG CHỜ 20×20m ─────────────┐
        │                                               │
        │   [BẢNG MÃ PHÒNG]          ● ● ● ●            │
        │      " K3P9 "           color pad (4 màu)     │
        │                                               │
        │                                               │
        │              ▓▓▓▓▓▓▓▓▓▓▓                      │
        │              ▓ READY PAD ▓   ← đứng lên = sẵn sàng
        │              ▓▓▓▓▓▓▓▓▓▓▓      xám → xanh      │
        │                                               │
        │   ○ bục nhảy    ○ bục nhảy      ○ vật cản     │
        │                                               │
        └───────────────────────────────────────────────┘
        Góc trên phải: DANH SÁCH NGƯỜI CHƠI
        ┌───────────────────┐
        │ 🔴 Khang    ✓ HOST│
        │ 🔵 Nam      ✓     │
        │ 🟡 Linh     …     │
        └───────────────────┘
```

**Vì sao ready pad vật lý thay vì nút UI:**
- Nó là **một tương tác mạng thật** (`Area3D` + state sync) → tính vào mục 6 của đề
- Nhìn thấy ai đã sẵn sàng ngay trong không gian 3D, không cần nhìn UI
- Bước ra là huỷ → không cần nút "Unready"
- Quay video demo đẹp hơn nhiều so với bấm nút

**Các thành phần:**

| Thành phần | Chi tiết |
|---|---|
| Bảng mã phòng | `Label3D` cỡ to trên tường + hiện luôn ở góc UI. Có nút Copy |
| Ready pad | `Area3D` + `CylinderMesh` emissive. ≥2 người và **tất cả** ready → đếm ngược 5s |
| Color pad | 4 bệ màu, đi lên là đổi. Màu đã có người lấy thì mờ đi |
| Danh sách người chơi | Màu · tên · ✓ ready · nhãn HOST cho master client |
| Emote (phím E) | Bánh xe 4 lựa chọn: vẫy tay, nhảy múa, chỉ trỏ, cười |
| Đếm ngược | Số to giữa màn hình, có SFX. Ai bước khỏi pad → huỷ |
| Nút Start của host | Master client bỏ qua được điều kiện ready |
| Bảng luật | `Label3D` trên tường: WASD di chuyển, Space nhảy, Shift dash, E emote |
| Vào giữa chừng | Người vào muộn spawn ở phòng chờ, xem trận đang chạy ở chế độ spectator |

Phòng chờ dùng lại đúng `player.tscn` và đúng replicator của minigame → viết một lần, dùng ở mọi nơi.

---

## 7. Ý tưởng vặt — chôm từ party game khác

Sắp theo **giá trị / công sức**. Cột "Từ" là game gốc.

### Rẻ mà ăn tiền — làm hết

| Ý tưởng | Từ | Cách làm | Công |
|---|---|---|---|
| **Screen shake + hitstop** | Smash Bros | Trúng đòn: dừng 80ms + rung camera. Cảm giác đấm khác hẳn | 15 dòng |
| **Card giới thiệu vòng** | Mario Party | "SUMO SHOVE — Hất hết đối thủ xuống!" + 3-2-1 | 30 dòng |
| **Spectator sau khi bị loại** | Fall Guys | Camera bám người còn sống, đổi bằng phím ←→. **Bắt buộc phải có** — không thì người chết nhìn màn hình đen | 25 dòng |
| **Kill feed** | mọi shooter | "🔴 Khang hất 🔵 Nam xuống vực" trượt từ phải | 20 dòng |
| **Emote wheel** | Fall Guys / Fortnite | Phím E, 4 emote, RPC cho mọi người | 40 dòng |
| **Vòng cuối x2 điểm** | Mario Party | 1 dòng, đảo lộn cả cục diện | 1 dòng |
| **Roulette chọn minigame** | Mario Party | Bánh xe quay, master quyết rồi RPC | 40 dòng |
| **Podium 3 bục** | Mario Kart | Người thắng chạy anim `win`, camera xoay quanh | 30 dòng |

### Đáng làm nếu còn thời gian

| Ý tưởng | Từ | Cách làm |
|---|---|---|
| **Chaos event giữa vòng** | Pummel Party | 20s/lần master random: trọng lực thấp 10s / mọi người nhanh gấp đôi / sàn co gấp đôi. Banner cảnh báo |
| **Comeback bonus** | Mario Party (bonus star) | Người bét được +15% tốc độ vòng cuối. Giữ trận đấu căng đến phút chót |
| **Item nhặt được** | Pummel Party | Hộp `?` → dash tiếp theo knockback x2 / khiên chặn 1 đòn / bẫy dính đặt xuống đất |
| **Sudden death** | Smash Bros | Hoà điểm → sàn co về 0 |
| **Mũ ngẫu nhiên** | Fall Guys | Nhặt prop bất kỳ trong kit, gắn lên xương đầu |
| **Vệt màu khi dash** | Stumble Guys | `GPUParticles3D` màu người chơi |
| **Đếm ngược có giọng** | mọi party game | Kenney audio hoặc tự thu |

### Không làm — bẫy

| Ý tưởng | Vì sao bỏ |
|---|---|
| Ragdoll vật lý | `PhysicalBoneSimulator3D` + sync qua mạng = ác mộng. Thay bằng: bắn nhân vật đi kèm xoay tròn |
| Bot / AI | Đề chỉ cần 2 người. YAGNI |
| Voice chat | Ngoài phạm vi hoàn toàn |
| 30 minigame | 3 cái **chạy đúng** > 10 cái lỗi |
| Anti-cheat | Đề ghi rõ không cần |
| Matchmaking | Đề ghi rõ không cần. Mã phòng là đủ |

---

## 8. Rủi ro

| Rủi ro | Khả năng | Xử lý |
|---|---|---|
| Fusion Preview hỏng trên Godot 4.7.1 | Trung bình | **Phase 0 kiểm ngay.** Fallback: Godot 4.6 song song → ENet LAN |
| Không có App ID | Chắc chắn nếu chưa đăng ký | Đăng ký sớm, miễn phí. Code trước cắm ID sau vẫn được |
| Knockback giật/tranh chấp | Cao | Đã có phương án: nạn nhân tự áp lực (mục 2) |
| Master thoát giữa trận | Trung bình | Bắt `master_client_changed`, kết thúc vòng về bảng điểm |
| Kit Mini sai scale | Chắc chắn | Đo và scale ở Phase 1, trước khi chỉnh số vật lý |
| Nhặt coin trùng | Cao | Master xác nhận, không cho client tự quyết |
| Hết thời gian | Cao | Xem danh sách cắt bên dưới |
| Photon free 20 CCU | Thấp | 4 người là quá đủ |

### Cắt gì nếu hết thời gian — theo thứ tự

Cắt từ dưới lên, **không bao giờ cắt ngược lên trên**:

```
Phase 11 bàn cờ            ← cắt đầu tiên
Minigame 3 (Bomb Tag)
Minigame 2 (Coin Grab)
Chaos event, item, mũ
Emote wheel
Thay asset (giữ greybox)   ← xấu nhưng vẫn đủ điểm
─────────────────────────  ← DƯỚI ĐÂY LÀ KHÔNG ĐƯỢC CẮT
Phase 0–7 + 1 minigame + phòng chờ + video + report
```

Phần không được cắt vẫn đạt **~85%** rubric. Mọi thứ trên vạch là điểm cộng.

---

## 9. Test matrix

Chạy trước khi quay video. Cột "2 máy" nghĩa là phải test trên 2 máy thật, không phải 2 cửa sổ.

| # | Test | 1 máy | 2 máy |
|---|---|---|---|
| 1 | Host tạo phòng, hiện mã | ✓ | ✓ |
| 2 | Client nhập mã → vào được | ✓ | ✓ |
| 3 | Nhập sai mã → báo lỗi, không crash | ✓ | |
| 4 | Cả hai thấy tên nhau trong danh sách | ✓ | ✓ |
| 5 | Phím máy A không điều khiển nhân vật B | ✓ | ✓ |
| 6 | Mỗi máy đúng 1 camera | ✓ | |
| 7 | Chuyển động mượt, không teleport | ✓ | ✓ |
| 8 | Ready pad đồng bộ, huỷ được | ✓ | ✓ |
| 9 | Vào minigame cùng lúc | ✓ | ✓ |
| 10 | Hất nhau → cả 2 máy thấy giống nhau | ✓ | ✓ |
| 11 | Điểm giống hệt nhau mọi máy | ✓ | ✓ |
| 12 | Coin biến mất đồng thời, không nhặt trùng | ✓ | ✓ |
| 13 | Bom nổ cùng khoảnh khắc | ✓ | ✓ |
| 14 | Client thoát → nhân vật biến mất | ✓ | ✓ |
| 15 | **Master thoát → trận không kẹt** | ✓ | ✓ |
| 16 | Người vào giữa chừng → spectator | ✓ | ✓ |
| 17 | Hết trận → về lobby chơi lại được | ✓ | ✓ |
| 18 | Chơi 10 phút liên tục không desync | | ✓ |

---

## 10. Checklist nộp bài

### Video demo 3–5 phút — quay đúng thứ tự đề mục 14.3

```
0:00  Mở game, màn hình chính (chia đôi màn hình 2 instance)
0:20  Nhập tên → HOST → hiện mã phòng
0:35  Instance 2 nhập mã → JOIN
0:50  Cả hai trong phòng chờ, thấy nhau, tên + màu khác nhau
1:05  Di chuyển độc lập — CHỈ ROLE MỘT BÊN, chỉ bên đó nhúc nhích
1:25  Đổi màu ở color pad, emote
1:40  Cả hai lên ready pad → đếm ngược đồng bộ
1:55  Sumo Shove: hất nhau, chỉ rõ knockback giống nhau ở 2 màn hình
2:30  Bảng điểm — zoom vào cho thấy điểm TRÙNG NHAU
2:45  Coin Grab: nhặt coin, coin biến mất ở CẢ HAI màn hình
3:15  Bomb Tag
3:35  Vòng cuối x2, podium, người thắng
3:50  Instance 2 tắt đột ngột → instance 1 vẫn chạy bình thường
4:00  Hết
```

Chia đôi màn hình để **luôn nhìn thấy cả 2 instance cùng lúc** — đó là bằng chứng sync, chấm điểm dựa vào đây.

### Report 1–2 trang — bám đúng mục 13

- [ ] **A. Networking model** — Shared Authority qua Photon Fusion. Photon Cloud chỉ relay, không chạy logic. So sánh với client-server và nói vì sao chọn
- [ ] **B. Player synchronisation** — position/rotation/velocity/anim_state qua `FusionSharedReplicator`, interpolation exponential, 20 Hz
- [ ] **C. Ownership/authority** — `PLAYER_ATTACHED` cho nhân vật, `MASTER_CLIENT` cho thế giới. Bảng ở mục 2 của file này
- [ ] **D. Shared game state** — `MatchState` là nguồn sự thật duy nhất, master client sở hữu
- [ ] **E. Problems encountered** — chọn 1–2 cái kể chi tiết:
  - Tranh chấp knockback → giải bằng "nạn nhân tự áp lực" (có sơ đồ ở mục 2)
  - 2 người nhặt cùng 1 coin → master xác nhận
  - Master thoát giữa trận → bắt `master_client_changed`
- [ ] **Sơ đồ kiến trúc** — vẽ lại sơ đồ mục 2

### Nộp

- [ ] Project folder mở được bằng Godot 4.7.1
- [ ] Build Windows (.exe + .pck)
- [ ] Video 3–5 phút
- [ ] Report 1–2 trang (PDF)
- [ ] `CREDITS.md` — asset Kenney (CC0), Photon Fusion SDK, tutorial tham khảo, **và ghi rõ phần nào dùng AI hỗ trợ** (đề mục 18 bắt buộc)

---

## 11. Bảng đối chiếu rubric

| Tiêu chí | % | Phase | Đủ chưa |
|---|---|---|---|
| A. Multiplayer Connection | 15 | 2 | Host + Join + mã phòng + danh sách phòng |
| B. Spawning & Ownership | 15 | 3 | `PLAYER_ATTACHED`, camera/input local-only, xoá khi rời |
| C. Movement Sync | 20 | 4 | pos + rot + vel + anim, interpolation |
| D. Multiplayer Gameplay | 20 | 6, 8 | 3 minigame, kết quả nhất quán |
| E. Extension | 15 | 5, 7, 9 | ~9 extension: phòng chờ, ready, emote, màu, tên, điểm, 3 minigame, state machine, spectator |
| F. Technical Understanding | 10 | 10 | Report + sơ đồ + phần Problems |
| G. Demo & Quality | 5 | 9, 10 | Build chạy được, video rõ ràng |

**Đề yêu cầu ≥2 extension. Kế hoạch này có ~9.**

---

## 12. Cần bạn quyết

- [ ] **Photon App ID** — đăng ký `dashboard.photonengine.com` (miễn phí). Mặc định: code trước, cắm ID sau
- [ ] **Bỏ bàn cờ ở v1?** Mặc định: có, để Phase 11
- [ ] **Tải asset về luôn?** 5 pack Kenney, ~50 MB
