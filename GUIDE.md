# Thêm multiplayer vào Godot bằng Photon Fusion 3 (Shared)

Ghi chép từ dự án PartyBash. Mọi con số đo trên **hai máy thật** qua Photon Cloud, không chép
lại tài liệu.

| | |
|---|---|
| Engine | Godot 4.7.1 |
| SDK | Photon-Fusion-Godot 3.0.0 Preview 555 (GDExtension) |
| Ngôn ngữ | GDScript thuần |
| Chế độ | Shared Authority |
| Hạ tầng | Photon Cloud free — 20 CCU |

**Thứ tự đọc nếu đang bắt đầu:** mục 1 → 2 → 3 → 8, dựng cho được một trò chạy hai máy, rồi mới
quay lại mục 5, 6, 11 khi cần vật lý.

---

## 1. Cài addon và App ID

Fusion cho Godot là **GDExtension**, không phải plugin GDScript: giải nén vào `addons/`, mở lại
Godot, các class `Fusion*` xuất hiện thẳng trong ClassDB. Không cần `preload` gì cả.

App ID lấy ở dashboard Photon, dán vào **Project Settings → Fusion → Connection → App ID**, nó
được ghi vào `project.godot`:

```ini
[fusion]
connection/app_id="6fdcc40b-..."
```

Trước khi debug bất cứ thứ gì thuộc gameplay, kiểm tra addon đã nạp đúng chưa — chạy được mà
không cần App ID, không cần mở editor:

```gdscript
for ten in ["FusionSharedReplicator", "FusionSpawner", "FusionRoomOptions"]:
	if not ClassDB.class_exists(ten):
		push_error("Thieu class: " + ten)
```

> ⚠️ **Bẫy — cache class toàn cục.** Thêm `class_name` cho một script từ ngoài editor (qua tool,
> qua git pull) thì bảng class toàn cục vẫn là bản cũ, và script mới báo "không tìm thấy class"
> dù file nằm ngay đó. Chạy `godot --headless --path . --import` để dựng lại cache.

---

## 2. Kết nối và vào phòng

Gom toàn bộ phần mạng vào **một autoload** (ở đây là `NetManager`) phát ra signal cho phần còn
lại. Không script gameplay nào gọi thẳng `Fusion` để kết nối — chỉ nghe signal.

```gdscript
func connect_to_photon() -> bool:
	if not has_app_id():
		connect_failed.emit("Chua co App ID")
		return false
	_connect_next_frame()
	return true


func _connect_next_frame() -> void:
	await get_tree().process_frame     # BAT BUOC, xem duoi
	Fusion.connect_to_photon(_make_user_id())
```

> ⚠️ **Bẫy — gọi kết nối trong `_ready()`.** Fusion tự `add_child` một node dịch vụ khi bắt đầu
> kết nối. Gọi thẳng trong `_ready()` thì cây scene đang dựng dở, `add_child` thất bại, Fusion
> không có vòng lặp xử lý và **im lặng không kết nối** — không một dòng lỗi. Hoãn đúng một frame
> là hết.

Tạo phòng:

```gdscript
var opts := FusionRoomOptions.new()
opts.set_max_players(10)
opts.set_is_open(true)
opts.set_is_visible(true)        # false = phong an, dung khi test
opts.set_player_ttl_ms(0)        # mat ket noi la mat suat ngay
opts.set_empty_room_ttl_ms(0)    # phong rong chet ngay
room_name = "%s-%s" % [_safe_name(), _room_suffix()]
Fusion.create_room(room_name, opts)
```

### Ba thứ phải tự lo

- **Tên phòng phải duy nhất.** Lấy tên người chơi làm tên phòng thì chơi hai phiên liên tiếp là
  hai phòng trùng tên, bạn bè bấm vào danh sách lại rơi vào *phòng cũ*. Triệu chứng: chủ phòng
  ngồi một mình, người kia "thấy nhân vật" — thực ra là nhân vật còn sót trong phòng cũ. Thêm 4
  ký tự ngẫu nhiên.
- **`get_room().get_name()` trả về chuỗi rỗng.** Muốn hiện tên phòng trên HUD thì tự giữ biến
  khi tạo/vào phòng.
- **`Fusion.get_room_list()` chỉ gọi được khi CHƯA ở trong phòng.** Đang trong phòng mà gọi là
  lỗi đỏ mỗi frame. Chặn bằng `if Fusion.is_in_room(): return`.

> ⚠️ **Bẫy — phòng cũ còn sót.** Khi replication có vẻ hỏng, thứ phải kiểm *đầu tiên* không phải
> code: hai máy có đang ở cùng một phòng không. `player_ttl_ms(0)` và `empty_room_ttl_ms(0)` là
> để phòng rỗng chết hẳn thay vì sống tiếp mang theo object cũ.

---

## 3. Shared mode nghĩa là gì

Không có server riêng. Mọi máy chạy **cùng một script**, và một máy trong phòng được Photon chọn
làm **master client**. Master chỉ là một người chơi bình thường được giao thêm việc: giữ luật cho
những thứ dùng chung.

Vì cùng một script chạy ở mọi máy, mọi dòng ghi vào trạng thái dùng chung đều phải đi qua một
cái cổng:

```gdscript
if not NetManager.is_master():
	return          # may khac chi xem, khong quyet
```

Master có thể đổi giữa chừng (chủ phòng thoát). Thiết kế sao cho **mọi máy đều giữ đủ trạng
thái** thì master mới tiếp tục được ngay — xem mục 8.

> ✅ **Đã kiểm chứng.** Chủ phòng thoát giữa ván Tháp Hà Nội: máy còn lại thành master, giữ
> nguyên số bước, thời gian và kỷ lục, chơi tiếp bình thường.

---

## 4. Sinh object cho cả phòng

`FusionSpawner` lo việc này. Hai quy tắc:

1. **Đăng ký scene ở MỌI máy**, trước khi ai đó spawn. Máy nào thiếu đăng ký thì object đơn giản
   không hiện ở máy đó.
2. `spawn()` gọi ở một máy, Fusion phát lệnh cho các máy khác *và* cache lại cho người vào muộn.

```gdscript
func _ready() -> void:
	Fusion.set_scene_load_mode(Fusion.SCENE_LOAD_AUTO)
	Fusion.set_scene_parent(scene_root)
	spawner.add_spawnable_scene(PLAYER_SCENE)      # moi may deu chay
	spawner.add_spawnable_scene(DIE_SCENE)


func _on_room_joined() -> void:
	# Moi nguoi tu spawn nhan vat CUA MINH
	var p: Node3D = spawner.spawn(PLAYER_SCENE)
	p.global_transform = _lobby.spawn_transform(NetManager.local_id() - 1)

	# Do dung chung thi CHI master spawn, va chi khi chua co
	if NetManager.is_master() and get_tree().get_first_node_in_group("match_state") == null:
		spawner.spawn(MATCH_STATE_SCENE)
```

Ai spawn thì người đó sở hữu. Nhân vật thuộc về chủ của nó và **chết theo chủ** khi họ rời phòng;
đồ dùng chung (quân cờ, quả bóng, cây ky) để master spawn và sở hữu vĩnh viễn, đỡ hẳn chuyện
chuyển quyền.

---

## 5. Đồng bộ biến của riêng mình

Mỗi object cần đồng bộ có một node `FusionSharedReplicator` trỏ về gốc, kèm một file `.tres`
liệt kê các biến cần gửi:

```ini
[node name="Replicator" type="FusionSharedReplicator" parent="."]
root_path = NodePath("..")
replication_config = ExtResource("pickable_replication.tres")
owner_mode = 0
root_replication_mode = 1      # Auto: tu dong bo transform
root_interpolation_mode = 2    # Forecast
root_forecast_gravity = false  # xem muc 11
```

```ini
# pickable_replication.tres — duong dan tuong doi voi root_path
properties/0/path = NodePath(":holder_id")
properties/1/path = NodePath(":dinh_co_dinh")
```

> ❌ **Hỏng im lặng — thiếu `@export`.** Biến script thuần thì **Fusion không nhìn thấy**: schema
> hiện "Words: 0", không lỗi, không cảnh báo, giá trị không bao giờ tới máy khác. Mọi biến có tên
> trong `.tres` bắt buộc phải là `@export`.

```gdscript
@export var holder_id: int = 0

@export var player_name: String = "":
	set(value):
		player_name = value
		if is_node_ready():       # setter co the ban TRUOC _ready
			_apply_name()
```

> ⚠️ **Bẫy — setter bắn lại sau `_ready()`.** Fusion ghi giá trị replicate *ngược về cả cho chủ
> sở hữu*, nên setter chạy thêm một lần sau `_ready()`. Nếu setter dựng lại model thì model bị
> dựng hai lần, và biến trạng thái cũ còn giữ tên animation cũ nên animation đứng im. Luôn chặn
> bằng `is_node_ready()` và một cờ "đã dựng cái này rồi".

---

## 6. Đồng bộ vị trí và góc quay

`root_replication_mode = Auto` gửi luôn position + rotation, và với `RigidBody3D` thì gửi cả
**linear/angular velocity** (đo được: proxy nhận đúng vận tốc `(4.98, 3.52, 0)` và angular `13.6`
của máy chủ).

Ba kiểu nội suy, khác nhau rất rõ khi vật bay nhanh:

| Kiểu | Proxy ở máy khác | Trễ so với máy chủ | Sai số lúc nằm yên | Nhảy > 15 cm |
|---|---|---|---|---|
| Exponential (1) | đóng băng, chỉ nội suy | ≈ 120 ms | ≤ 6 cm | 0 |
| Forecast (2) | chạy vật lý riêng | 30–50 ms | ≤ 3 cm | bóng 3, phi tiêu 16 |

Mượt hay kịp thời — chọn một. Trò chơi đòi ném trúng đích thì Forecast đáng giá; trò chơi bày
quân trên bàn thì Exponential đẹp hơn.

---

## 7. RPC — gửi sự kiện, không gửi mỗi frame

Node nào muốn nhận RPC phải tự đăng ký; hàm nhận đánh dấu `@rpc("any_peer", "call_local")` để
*máy gửi cũng chạy* hàm đó, tránh viết hai nhánh xử lý.

```gdscript
func _ready() -> void:
	Fusion.register_broadcast_receiver(self)


func xin_danh(chi_so: String) -> void:
	Fusion.rpc(_net_danh, chi_so, NetManager.local_id())


@rpc("any_peer", "call_local")
func _net_danh(chi_so: String, nguoi: int) -> void:
	if not NetManager.is_master():
		return
	# ... kiem tra luat o day ...
	_phat("danh")
```

### Giới hạn đã đo

| Kiểu dữ liệu | Kết quả |
|---|---|
| `String` | Gửi 100 / 400 / 510 / 600 / 1000 / **3000 byte** — nhận đủ cả sáu, đúng độ dài |
| `PackedByteArray` | Gửi được |
| `PackedInt32Array` | **Biến thành NIL ở máy nhận** — không lỗi, không cảnh báo |

> ❌ **Hỏng im lặng — `call_local` giấu mất lỗi.** Gói trạng thái vào `PackedInt32Array` rồi test
> một máy: mọi thứ chạy hoàn hảo, vì `call_local` đưa thẳng object gốc cho chính máy gửi. Chỉ máy
> *bên kia* nhận được NIL. Bài học: mọi thứ dính tới serialize phải test hai máy, và khi nghi ngờ
> thì đóng gói bằng `String` hoặc JSON.

Con số "512 byte" trong tài liệu Photon là của Fusion 2 bản **Unity** — không áp dụng ở đây.

---

## 8. Mẫu "master cầm luật, phát nguyên trạng thái"

Đây là mẫu dùng cho cả sáu minigame trong dự án, và là thứ đáng chép lại nhất. Client **xin**,
master **quyết**, rồi master gửi **toàn bộ** trạng thái dưới dạng JSON cho mọi người.

```
May nguoi choi          Master client              Cac may khac
      |                       |                          |
      |-- rpc xin danh bai -->|                          |
      |                  kiem tra luat                   |
      |                  cap nhat trang thai             |
      |<-- rpc trang thai ----|--- rpc trang thai ------>|
      |                       |                          |
   moi may ve lai man hinh tu CUNG MOT goi JSON
```

```gdscript
func _phat(su_kien: String) -> void:
	Fusion.rpc(_net_trang_thai, JSON.stringify({
		"pha": _pha, "diem": _diem, "luot": _luot,
		"ms": _con_lai_ms(), "su_kien": su_kien,
	}))


@rpc("any_peer", "call_local")
func _net_trang_thai(json: String) -> void:
	var g = JSON.parse_string(json)
	if not (g is Dictionary):
		return
	if not NetManager.is_master():
		_ap_dung(g)                       # master da co san trang thai
	_hieu_ung(str(g.get("su_kien", "")))  # am thanh, hat no: may nao cung chay
```

Vì sao gửi nguyên gói thay vì gửi từng thay đổi:

- Máy nào cũng có đủ trạng thái → **đổi master không mất ván**.
- Mất một gói cũng không lệch vĩnh viễn: gói sau ghi đè toàn bộ.
- Người vào muộn chỉ cần xin đúng một gói. Cho object tự xin trong `_ready()`, vì lúc master phát
  gói trước đó thì scene của họ còn chưa dựng xong:

```gdscript
if not NetManager.is_master():
	_xin_trang_thai.call_deferred()
```

**Giá phải trả:** gói to hơn. Cứ giữ nó dưới vài trăm byte và chỉ phát khi có *sự kiện* — đừng
phát mỗi frame.

Kèm một trường `su_kien` ngắn trong gói để máy nhận biết vừa xảy ra chuyện gì mà kêu tiếng động /
bắn hạt. Trạng thái thì đồng bộ, còn hiệu ứng thì mỗi máy tự chơi.

---

## 9. Đồng hồ đếm ngược cho mọi máy

> ❌ **Đừng gửi mốc giờ.** `Time.get_ticks_msec()` đếm từ lúc *máy đó* mở game. Gửi mốc giờ của
> master sang máy khác thì ra một con số vô nghĩa — đồng hồ hiện sai hàng chục phút. Đã dính đúng
> lỗi này ở bàn poker.

Gửi **số mili-giây còn lại**, máy nhận tự đổi ra mốc giờ của chính nó, trừ đi nửa RTT vì gói tin
mất chừng ấy mới tới:

```gdscript
# Master gui
goi["ms"] = roundi(maxf(0.0, _han - _gio()) * 1000.0)

# May nhan
var tre := 0.0 if NetManager.is_master() else NetManager.rtt_ms() / 2000.0
_han = _gio() + float(goi["ms"]) / 1000.0 - tre
```

Sau đó mỗi máy tự đếm lùi trong `_process`, không RPC thêm gói nào. Hết giờ thì **chỉ master** ra
quyết định (tự đánh bài, tự bỏ lượt), các máy khác chỉ chờ gói trạng thái kế tiếp.

---

## 10. Quyền sở hữu

Đọc quyền từ chính replicator, đừng giữ biến riêng — một nguồn sự thật duy nhất:

```gdscript
@onready var sync: FusionSharedReplicator = $Replicator

func player_id() -> int:
	return sync.get_owner_id()

var la_cua_toi := sync.has_authority()
```

> ❌ **Không có trong bản Godot.** Nhiều hướng dẫn (viết cho Unity) nhắc tới
> `request_state_authority()`, `NetworkRigidBody3D`, `SetKinematicMode()`. Bản GDExtension
> **không có** những thứ đó. Chuyển quyền ở đây là `want_authority()` cộng hai signal
> `authority_requested` / `authority_response`.

Nhưng trước khi đụng tới chuyển quyền, hãy hỏi: có cần không? Trong dự án này **không một object
nào chuyển quyền**. Đồ dùng chung do master sở hữu suốt đời; ai nhặt lên thì chỉ gửi một RPC đặt
`holder_id` — và mọi máy tự suy ra "ai đang cầm gì" từ biến đó.

---

## 11. Vật lý và vật đang cầm

Không có class rigidbody mạng riêng: cứ để `RigidBody3D` làm gốc của scene, gắn
`FusionSharedReplicator` với `root_replication_mode = Auto`, và để **một máy duy nhất (master)
mô phỏng**. Máy khác chỉ nhận kết quả.

> ⚠️ **Bẫy — vật nằm yên mà lún 0.32 m.** `root_forecast_gravity` mặc định `true` và
> `root_max_forecast_time = 0.25`: máy khác tự "đoán thêm" 0.25 giây rơi tự do, tức
> ½·9.8·0.25² = 0.31 m. Đo thật: phi tiêu −0.324, quân cờ −0.322, xúc xắc −0.321, vận tốc ma
> 2.45 — quân cờ và xúc xắc xuyên xuống dưới sàn. Vật nào cũng nằm yên trên bàn thì đặt
> **`root_forecast_gravity = false`**.

### Vật đang cầm trên tay

Khi một người nhặt vật lên, vật thôi làm vật lý và bám theo camera của người cầm. Ba chi tiết:

- `freeze = true` với `freeze_mode = KINEMATIC`, và **tắt collision layer** (đặt layer = 0) để
  vật trên tay không xô đổ đồ trên bàn.
- Mọi máy cùng tính chỗ đặt vật từ vị trí + góc thân + góc cúi của người cầm, nên máy nào cũng
  thấy vật ở đúng chỗ. Muốn vậy thì **góc cúi camera phải là biến replicate** — hướng ngang đã
  nằm sẵn trong góc xoay thân.
- Giữ góc xoay của vật *cục bộ* ở máy người cầm. Để replicator ghi đè thì quay người xong 0.4
  giây vật vẫn lệch **38°**; giữ riêng còn **3.6°**.

> ✅ **Đã kiểm chứng.** Hai người cùng bấm nhặt một vật trong cùng một frame: master xử lý tuần
> tự nên chỉ một người cầm được, hai máy không bao giờ lệch. Người đang cầm rớt mạng thì master
> tự thả vật xuống tại chỗ.

---

## 12. Phía client — cái gì chỉ chạy ở máy mình

Phần lớn code client là *biết cái gì KHÔNG cần gửi đi*. Gửi ít thì ít lệch.

### Camera và input chỉ tồn tại ở máy sở hữu

```gdscript
func _ready() -> void:
	is_mine = sync.has_authority()
	if not is_mine:
		rig.queue_free()             # khong bao gio co hai camera active
		set_physics_process(false)   # khong xu ly input, vi tri do replicator ghi
		return
	rig.make_current()
```

### Hoàn toàn cục bộ, không tốn một byte nào

- **Ngắm và tô sáng** vật đang nhìn — người khác không cần biết mình đang ngắm cái gì.
- **Chọn bài trên tay** trước khi đánh (Liar Bar): chọn xong mới gửi một RPC. Đối thủ không thấy
  mình đang cân nhắc.
- **Âm thanh, hạt nổ, nhãn bay lên**: kích bằng trường `su_kien` trong gói trạng thái, mỗi máy tự
  chơi.
- **Animation nhân vật**: suy ra từ velocity — mà velocity thì Auto replication đã gửi sẵn. Bớt
  một biến phải truyền.
- **Lật bài riêng**: bài úp với cả phòng, chỉ máy của chủ bài lật mặt lên. Cùng một trạng thái,
  hai cách vẽ.

> ⚠️ **Bẫy — dựng sẵn câu chữ ở master.** Master ghép "Player625 thắng" rồi gửi chuỗi đó đi,
> nhưng lúc ghép thì tên người chơi ở máy master chưa kịp về — máy khác hiện "#1 thắng". Gửi
> **id**, để máy nhận tự đổi ra tên:
>
> ```gdscript
> _thang = "%s:%d" % [",".join(ids), diem]      # master gui id
> Player.ten_theo_id(get_tree(), id)            # may nhan doi ra ten
> ```

> ⚠️ **Bẫy — `user_id` của Photon nhìn từ máy khác là rỗng.** Tên hiển thị phải là **property
> replicate trên chính object người chơi**. Đừng trông vào danh tính của Photon để hiện tên.

> ❌ **Không làm được — gửi riêng cho một người.** Fusion bản Godot không có RPC gửi tới một
> người chơi cụ thể. Nghĩa là **không có bí mật thật**: bài trên tay nằm trong gói phát cho cả
> phòng, một client bị sửa vẫn đọc được. Chấp nhận và ghi rõ trong tài liệu, hoặc thiết kế trò
> chơi không cần thông tin giấu.

---

## 13. Đừng làm nghẽn vòng lặp

Fusion xử lý gói tin trong vòng lặp game. Một frame dài là một lần Photon không được phục vụ, và
nó ngắt kết nối thật.

| Mã | Nghĩa | Thường do |
|---|---|---|
| `1035` | Hàng đợi gói đến đầy | Frame dài, hoặc phát RPC quá dày |
| `1040` | Client timeout | Máy đó treo lâu |
| `1041` | Server timeout | Mạng rớt hoặc treo lâu hơn nữa |

> ✅ **Đã đo — một frame 6.9 giây.** `Mesh.create_convex_shape()` tốn 64–119 ms mỗi model. Sinh
> 32 quân cờ cùng lúc cho ra một frame dài **6874 ms** → cảnh báo 1035, máy vào sau bị ngắt 1040.
> Sửa bằng cache hình theo loại quân và giảm còn tối đa 256 đỉnh: còn 76 ms.

Nguyên tắc rút ra: mọi việc nặng (sinh hình va chạm, nạp model, dựng lại scene) phải làm **một
lần và cache**, đừng làm trong lúc phòng đang chạy.

---

## 14. Test hai máy — không thì coi như chưa test

Rất nhiều lỗi ở trên *chỉ lộ ra khi có máy thứ hai*. Cách chạy hai bản trên cùng một PC:

```bash
godot --headless --path . res://_test.tscn -- host &
godot --path . res://_test.tscn -- khach
```

- Bản host chạy `--headless` cho nhẹ; bản khách mở cửa sổ để chụp màn hình.
- Phòng test luôn `set_is_visible(false)`. Từng có người lạ vào đúng phòng test vì nó hiện trong
  danh sách công khai.
- Truyền tên phòng qua một file tạm; bên khách phải **đợi file có nội dung** rồi mới đọc — đọc
  lúc file rỗng thì `join_room("")` và rơi vào phòng của người lạ.
- Script test ghi lại trạng thái ở cả hai máy rồi so từng con số, thay vì nhìn bằng mắt.
- Xoá file test ngay sau khi chạy xong.

---

## 15. Bảo mật khi nộp bài

- **App ID nằm trong `project.godot`**, và file đó được đóng vào `.pck` khi export — ai giải nén
  cũng đọc được. Repo phải để **private**, đừng đăng build lên chỗ công khai.
- Free tier 20 CCU dùng chung cho mọi bản build đang chạy — kể cả bản gửi bạn bè thử.
- Master client là một người chơi, nên "server" ở đây **không chống gian lận** được. Với bài tập
  thì không sao, nhưng phải nói rõ trong báo cáo.

---

## 16. Bảng lỗi im lặng — dán lên tường

Điểm chung của cả bảng: **không có dòng lỗi nào**, chỉ có thứ không chạy.

| Triệu chứng | Nguyên nhân | Sửa |
|---|---|---|
| Không kết nối được, không báo gì | Gọi `connect_to_photon` trong `_ready()` | Hoãn một frame |
| Biến không tới máy khác | Thiếu `@export` | Thêm `@export`, kiểm schema khác 0 words |
| Object không hiện ở một máy | Máy đó chưa `add_spawnable_scene` | Đăng ký ở mọi máy trong `_ready()` |
| Dữ liệu về NIL, một máy vẫn chạy tốt | `PackedInt32Array` + `call_local` | Đóng gói bằng String/JSON, test hai máy |
| Vật nằm yên mà lún dưới sàn | `root_forecast_gravity = true` | Đặt `false` |
| Đồng hồ hiện sai ở máy khách | Gửi mốc giờ của master | Gửi số ms còn lại, trừ RTT/2 |
| Tên hiện thành "#1" | Ghép câu chữ ở master | Gửi id, máy nhận đổi ra tên |
| Người khác thấy mình quay lưng | Model quay mặt về +Z, Godot coi −Z là trước | Xoay model 180°, và phải hai người mới thấy |
| "Chơi một mình", người kia thấy nhân vật ma | Hai máy ở hai phòng khác nhau | Tên phòng duy nhất, TTL = 0 |
| Class mới báo không tồn tại | Cache class toàn cục cũ | `godot --headless --import` |
