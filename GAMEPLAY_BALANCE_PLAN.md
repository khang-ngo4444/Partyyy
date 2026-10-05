# Kế hoạch Phase 2 (bàn cờ) — vật phẩm, kết thúc ván, kinh tế

Trạng thái: **PLAN, chưa code.** Thay cho baseline cũ (4 rương 3 giả 1 thật, hạng 1 nhận súng).

Ý tưởng cơ chế có tham khảo các party game cùng thể loại, nhưng **tên, hình tượng, model là của
mình** (chủ đề đồ vật Việt / tuổi thơ). Không nhắc tên game khác trong game, store page, trailer;
không dùng icon/âm thanh/animation của game khác, kể cả làm placeholder.

## 0. Quyết định

Đã chốt:

- Kết thúc ván bằng **Rương báu → Cúp**, hết số vòng thì nhiều Cúp nhất thắng.
- Bộ 20 vật phẩm ở mục 3. Không làm "hộp quà ngẫu nhiên" và "thử thách arcade".
- **Tiền không được chênh lệch nhiều**: thưởng minigame dao động ±30% quanh trung bình, gục
  **không** rơi vàng, ống heo có trần.

Còn mở (đang dùng giá trị mặc định trong ngoặc):

1. Ná cao su gây 3 hay 4 máu? (**4**)
2. Vỏ sầu riêng chia đôi số bước **còn lại** của lượt đó, hay chia đôi xúc xắc lượt sau? (**còn lại**)
3. Dây thun: trúng đòn thì giật về neo **ngay lập tức**, hay chờ hết 2 lượt? (**ngay**)
4. Một ván dài khoảng 35 phút có ổn không? (**35 phút**)

## 1. Luật dùng đồ chung

- Mỗi lượt dùng **tối đa 1 món**, chỉ trong lượt mình, **trước khi tung xúc xắc**.
- Túi tối đa **3 món**. Nhặt món thứ 4 thì bỏ món cũ nhất.
- Mọi sát thương đi qua `LuatBan.tru_mau()` → Úp thúng (khiên) chặn được tất cả mà không cần code
  riêng cho từng món.
- Máu tối đa 10. Mốc sát thương: nhẹ 2, vừa 3–4, nặng 5, gục 10.
- Món **trúng chắc** (chọn người, vùng) đánh yếu; món **phải ngắm / bắn thẳng** đánh mạnh. Món
  gục ngay luôn hiếm và luôn có điều kiện.
- Chủ bẫy / chủ rào / chủ quái miễn nhiễm với đồ của chính mình.

## 2. Kết thúc ván: Rương báu và Cúp

| Luật | Giá trị |
|---|---|
| Số rương | **1 Rương báu** trên bàn |
| Mở | **Đi qua hoặc dừng** trên ô rương → hỏi có mở không. Tối đa 1 lần mỗi lượt |
| Giá | `chest_cost` = 100 vàng (setting đang có) |
| Tài nguyên rương | **+1 Cúp**. Cúp không bao giờ mất: không bị cướp, không rơi khi gục |
| Sau khi mở | Rương dời tới ô ngẫu nhiên cách ô cũ ≥ 10 ô và không có người đứng |
| Kết thúc | Hết **R vòng** (mục 4). Nhiều Cúp nhất thắng → hòa thì nhiều vàng hơn → hòa nữa thì hạng minigame cuối |
| Gục | Hồi đầy, về checkpoint. **Không mất vàng, không mất Cúp** (giữ tiền không chênh lệch) |

Mở khi **đi qua** là bắt buộc: một xúc xắc thì xác suất dừng đúng ô chỉ khoảng 1/6.

Cần gạt chống ăn đậm (mặc định **tắt**): giá mở = 100 + 20 × số Cúp đang có. Bật khi playtest thấy
người thắng thường có ≥ 5 Cúp.

## 3. Vật phẩm

Cột "Nhắm": **Ngắm** = raycast từ camera (dùng lại phần ngắm của súng) · **Thẳng** = bắn theo
hướng ngắm, trúng người đầu tiên · **Chọn người** = danh sách tên · **Tại chỗ** = ô đang đứng /
bản thân · **Chọn ô** = chọn một ô trong tầm.

| Món | ID | Độ hiếm | Nhắm | Hiệu ứng |
|---|---|---|---|---|
| Ná cao su | `sung_1_phat` (giữ ID) | Thường | Ngắm | 7 ô, −4 máu |
| Úp thúng | `khien` (giữ ID) | Thường | Tại chỗ | Chặn đòn kế tiếp, Bùa hoán đổi và Cần câu. Đang úp thì không dùng được món khác |
| Bát cháo hành | `chao_hanh` | Thường | Tại chỗ | +5 máu |
| Vỏ sầu riêng | `vo_sau_rieng` | Thường | Tại chỗ | Bẫy, xem 3.1 |
| Pháo dây | `phao_day` | Thường | Tại chỗ | Mọi người trong ±2 ô: −2 máu |
| Rào tre | `rao_tre` | Thường | Tại chỗ | Đặt rào: người đi tới phải **dừng lại ở ô trước rào**, không mất máu, rào biến mất. Kết hợp được với Vỏ sầu riêng |
| Hai hột xí ngầu | `hai_hot` | Thường | Tại chỗ | Lượt này tung 2 xúc xắc (2–12 bước) |
| Cần câu | `can_cau` | Hiếm | Thẳng | 6 ô, −2 máu, kéo người trúng về ô mình (không kích hoạt hiệu ứng ô). Mình vẫn tung xúc xắc |
| Vợt bắt cá | `vot_luoi` | Hiếm | Ngắm (hình nón) | 4 ô, cướp 1 món; không có đồ thì cướp 15 vàng |
| Xe đồ chơi chở pháo | `xe_phao` | Hiếm | Chọn ô | Lái tối đa 5 ô rồi nổ: tâm −5, ô kề −2 |
| Dừa rơi | `dua_roi` | Hiếm | Chọn người | Cả bàn, chắc trúng, −3 máu |
| Bùa hoán đổi | `bua_hoan_doi` | Hiếm | Chọn người | Đổi vị trí, **mất lượt tung xúc xắc** |
| Trâu điên | `trau_dien` | Hiếm | Tại chỗ | Lao tới 8 ô, −4 máu mỗi người trên đường, sau đó vẫn tung xúc xắc |
| Ống heo đất | `ong_heo` | Hiếm | Tại chỗ | Giữ trong túi: mỗi vòng heo +5 vàng, **tối đa 30**. Dùng thì đập lấy hết. Gục thì heo vỡ mất |
| Còi trọng tài | `coi_trong_tai` | Hiếm | Tại chỗ | Tự chọn minigame của vòng này |
| Dây thun | `day_thun` | Hiếm | Tại chỗ | Neo và giật về, xem 3.2 |
| Dép tổ ong | `dep_to_ong` | Hiếm (trọng số thấp) | Thẳng | 5 ô: gục |
| Nồi mắm tôm | `mam_tom` | Huyền thoại | Chọn người | Khoá đồ 3 lượt, −1 máu đầu mỗi lượt của nạn nhân |
| Kính lúp hội tụ | `kinh_lup` | Huyền thoại | Ngắm | Tầm vô hạn: gục |
| Chó ngao xổng chuồng | `cho_ngao` | Huyền thoại | Tại chỗ | Quái đi 4 ô mỗi vòng, ai trên đường bị gục. Biến mất sau 3 vòng |

### 3.1 Vỏ sầu riêng (bẫy)

- Đặt trên ô đang đứng. Mỗi người chỉ có 1 bẫy trên bàn; đặt cái mới thì cái cũ biến mất.
  Bẫy hiện rõ cho mọi người.
- Kích hoạt khi **đi qua hoặc dừng** (chỉ tính lúc dừng thì gần như không bao giờ trúng).
- −2 máu, rồi **số bước còn lại chia đôi, làm tròn lên** (còn 5 → 3, còn 3 → 2, còn 1 → 1, không
  bao giờ kẹt 0). Bẫy biến mất.
- Úp thúng chặn phần máu, **không** chặn phần chia bước.

### 3.2 Dây thun (neo và giật về)

- Dùng: neo ô đang đứng, rồi tung xúc xắc đi bình thường. Hiệu lực trong **2 lượt của chính
  mình**. Master lưu đường đi thật từng ô từ lúc neo (`tt["neo"][k] = {"duong": [...], "con": 2}`)
  để giật lùi đúng theo đường đã đi, kể cả đường tắt.
- **Hết 2 lượt mà không mất máu** → giật lùi về giữa quãng đường đã đi
  (lùi `floor(so_buoc / 2)` bước theo chính đường đó).
- **Mất máu trong thời gian hiệu lực** → giật ngay về ô neo, hiệu lực kết thúc. Đòn bị Úp thúng
  chặn thì không tính là mất máu.
- Đòn kích hoạt giật về chỉ gây **một nửa sát thương, làm tròn lên** (2→1, 3→2, 4→2, 5→3):
  cái giá chính là mất quãng đường, không phải máu. Đòn gục (Dép tổ ong, Kính lúp, Chó ngao)
  **vẫn gục**, không giảm.
- Nếu đòn đó làm gục: về **ô neo** thay vì checkpoint (vẫn hồi đầy như gục thường). Đây là lợi ích
  chính của món: lao lên giành rương mà không sợ bị đánh về tận checkpoint.
- Đi qua Rương báu trong lúc hiệu lực vẫn mở được bình thường; bị giật lùi qua rương **không**
  tính là đi qua.

### 3.3 Trọng số rơi ở ô Trang bị

| Nhóm | Món | Trọng số mỗi món | Cộng |
|---|---|---|---|
| Thường | 7 món | 9 | 63 |
| Hiếm | 9 món (trừ Dép tổ ong) | 4 | 36 |
| Hiếm | Dép tổ ong | 1 | 1 |
| Huyền thoại | 3 món | 0 | 0 — không rơi từ ô |

## 4. Kinh tế: tài nguyên nhận được sau mỗi vòng minigame

### Giả định

- Mỗi lượt khoảng 20 giây; minigame khoảng 90 giây + 15 giây chuyển cảnh. Ván khoảng **35 phút**.
- Bàn: vòng chính 40 ô + 16 ô đường tắt, 1 xúc xắc 6 mặt (trung bình 3,5 bước/lượt).
- Mục tiêu: mỗi người kiếm khoảng **250 vàng cả ván** (đủ khoảng 2,5 rương), **bất kể số người**.
  Đông người thì ít vòng hơn, nên vàng mỗi vòng tăng để tổng cả ván giữ nguyên.
- Ô tiền trung bình cho `tile_money% × money_gain` = 25% × 15 = 3,75 vàng/lượt.

### Công thức (master tự tính)

```
R          = round(2100 / (105 + 20·N))                 # số vòng cả ván; setting so_vong = 0 là tự tính
vang_tb    = 250 / R − tile_money% · money_gain          # vàng minigame trung bình mỗi người mỗi vòng
vang(hang) = làm tròn tới bội số 5 của vang_tb · (1.3 − 0.6·(hang−1)/(N−1))
```

Hạng nhất nhận 1,3 lần trung bình, hạng chót 0,7 lần → chênh lệch chỉ ±30%.

### Bảng tính sẵn

| Số người | R | Vàng theo hạng (1 → chót) | TB/vòng | Tổng 1 người cả ván | Chênh tối đa cả ván* |
|---|---|---|---|---|---|
| 2 | 14 | 20 · 10 | 15 | ~262 | 140 |
| 3 | 13 | 20 · 15 · 10 | 15 | ~244 | 130 |
| 4 | 11 | 25 · 20 · 15 · 15 | 19 | ~248 | 110 |
| 5 | 10 | 30 · 25 · 20 · 20 · 15 | 22 | ~258 | 150 |
| 6 | 9 | 30 · 30 · 25 · 25 · 20 · 15 | 24 | ~251 | 135 |
| 7 | 9 | 30 · 30 · 25 · 25 · 20 · 20 · 15 | 24 | ~246 | 135 |
| 8 | 8 | 35 · 35 · 30 · 30 · 25 · 25 · 20 · 20 | 27,5 | ~250 | 120 |
| 9 | 7 | 40 · 40 · 35 · 35 · 30 · 30 · 25 · 25 · 20 | 31 | ~244 | 140 |
| 10 | 7 | 40 · 40 · 35 · 35 · 35 · 30 · 30 · 25 · 25 · 20 | 31,5 | ~247 | 140 |

\* Chênh tối đa = người thắng **mọi** minigame so với người thua **mọi** minigame, chỉ tính vàng
minigame. Khoảng 1,1–1,5 rương; thực tế sẽ nhỏ hơn nhiều.

### Đồ nhận sau mỗi minigame

- **Hạng 1**: 1 món rút từ nhóm Hiếm + Huyền thoại (Huyền thoại 15%). Đây là nguồn Huyền thoại duy nhất.
- **Các hạng còn lại trong top** (ceil(N/4) người: 2–4 người → 1, 5–8 → 2, 9–10 → 3): mỗi người 1 món Thường.
- **Hạng chót** (từ 3 người trở lên): 1 món Thường để bắt kịp.
- **2 vòng cuối**: vàng minigame ×1,5 cho **mọi hạng** (không làm tăng tỷ lệ chênh lệch).

### Các nguồn vàng khác — giữ nhỏ

| Nguồn | Mức | Ghi chú |
|---|---|---|
| Ô tiền | +15 | Như hiện tại |
| Ống heo | +5/vòng, tối đa 30 | Có trần để không thành máy in tiền |
| Vợt bắt cá | cướp 15 | Chỉ khi nạn nhân không có đồ |
| Thuế đất | 10 vàng | Như hiện tại, chuyển giữa hai người |
| Gục | 0 | Không rơi vàng |

### Kiểm tra nhịp ván

- 4 người: người nhất mọi minigame kiếm khoảng 29 vàng/vòng (25 + 3,75) → đủ 100 vàng ở khoảng
  **vòng 4**; người trung bình khoảng vòng 5. Không ai mở rương trước vòng 3.
- 10 người: mỗi người cả ván chỉ đi khoảng 25 ô → luật mở khi đi qua và Hai hột xí ngầu là cần thiết.
- Dự kiến người thắng khoảng 3 Cúp, trung bình 1–1,5 Cúp mỗi người.

## 5. Cần sửa trong code

- `board/pha_ban_co.gd`: bỏ `ruong` (mảng 4 ô) và `ruong_that`; thêm `ruong_o` (1 ô), `coc`
  (Cúp theo người), `vong_con`. `thang` chỉ đặt khi `vong_con` về 0. Hỏi mở rương khi đi ngang ô rương.
  Thêm trạng thái `bay`, `rao`, `neo`, `doc`, `quai`, `heo` vào gói `tt` (vẫn một gói, khoá chuỗi).
- `board/luat_ban.gd`: `dung_do(tt, k, mon, muc_tieu)` một `match` cho mọi món; viết lại
  `thuong_minigame` theo công thức mục 4; thêm `mo_ruong`; thêm tên vào `TEN_DO`
  (Ná cao su, Úp thúng thay cho Súng một phát, Khiên — giữ ID).
- `board/gameplay_settings.gd`: thêm `so_vong` (0 = tự tính); bỏ `minigame_second_gold`,
  `minigame_reward_drop`, `minigame_min_gold`.
- Nhắm: mở rộng `_muc_tieu_sung` với tham số tầm + kiểu (tia / hình nón / trúng người đầu tiên).
  Client vẫn chỉ gửi `origin + direction`; master raycast và áp luật.

## 6. Thứ tự làm

1. **Đợt 1 — kết thúc ván + kinh tế**: Rương báu, Cúp, số vòng, thưởng minigame mới, bảng trọng số ô.
2. **Đợt 2 — không cần UI mới**: Bát cháo hành, Vỏ sầu riêng, Pháo dây, Rào tre, Hai hột xí ngầu,
   Trâu điên, Ống heo đất. Đổi tên hiển thị Ná cao su / Úp thúng.
3. **Đợt 3 — dùng lại phần ngắm**: Dép tổ ong, Cần câu, Vợt bắt cá, Kính lúp.
4. **Đợt 4 — UI chọn người / chọn ô**: Dừa rơi, Bùa hoán đổi, Xe đồ chơi chở pháo, Còi trọng tài.
5. **Đợt 5 — trạng thái theo lượt**: Dây thun, Nồi mắm tôm, Chó ngao xổng chuồng.

Mỗi đợt: test headless bằng scene (`--script` không nạp autoload), xoá file test sau khi chạy,
và ghi asset còn thiếu vào `ASSET-CAN-THEM.md`.

## 7. Asset cần làm

Ná cao su · thúng tre · bát cháo · vỏ sầu riêng · dây pháo · rào tre · 2 xúc xắc · cần câu + lưỡi ·
vợt lưới · xe đồ chơi + bánh pháo · quả dừa · lá bùa giấy · con trâu · ống heo đất · cái còi ·
cọc neo + dây thun · dép tổ ong · nồi mắm tôm + ruồi · kính lúp + tia nắng · con chó ngao ·
Rương báu · Cúp. Kèm VFX nổ, khói "bụp", vệt bay và icon túi đồ cho từng món.

## 8. Dữ liệu cần ghi khi playtest

- Số Cúp của người thắng và của người chót mỗi ván.
- Vàng cao nhất / thấp nhất sau mỗi minigame.
- Vòng đầu tiên có người mở rương.
- Số lần gục theo từng món. Món nào gây hơn 30% tổng số lần gục thì **giảm trọng số rơi trước**,
  chưa đụng sát thương.
- Tổng thời gian ván và thời gian trung bình mỗi lượt (để chỉnh công thức R).

Chỉ cân bằng sau ít nhất 10 ván; mỗi đợt không đổi quá một nhóm biến.
